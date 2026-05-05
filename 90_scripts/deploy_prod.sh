#!/bin/bash
set -Eeuo pipefail


# ============================================================
# CONFIG
# ============================================================

ENV="prod"
REPO_ROOT="/opt/homelab-infra"

TERRAFORM_DIR="$REPO_ROOT/10_terraform/envs/prod"
TF_VARS_FILE="$TERRAFORM_DIR/ssh_keys.auto.tfvars"

ANSIBLE_DIR="$REPO_ROOT/20_ansible"
ANSIBLE_PLAYBOOK="playbooks/homelab.yml"
ANSIBLE_INVENTORY="inventories/prod"

KEYS_DIR="$REPO_ROOT/keys"
ADMIN_KEY_PUB="$KEYS_DIR/admin_ssh_key.pub"
IAC_KEY="$KEYS_DIR/iac_ssh_key"
IAC_KEY_PUB="$KEYS_DIR/iac_ssh_key.pub"


SCRIPT_NAME="$(basename "$0")"
PLAN_FILE="$TERRAFORM_DIR/tfplan"
PLAN_COMMIT_FILE="$PLAN_FILE.commit"

DEFAULT_PHASE="all"
DEPLOY_PHASE="$DEFAULT_PHASE"
DEPLOY_COMMIT="${DEPLOY_COMMIT:-}"

# ============================================================
# HELPERS
# ============================================================

log()  { echo -e "[+] $*"; }
warn() { echo -e "[!] $*" >&2; }
die()  { echo -e "[❌] $*" >&2; exit 1; }

confirm() {
  read -r -p "Type 'deploy_prod' to continue: " input
  [[ "$input" == "deploy_prod" ]] || die "Confirmation failed"
}

usage() {
  cat <<EOF
Usage:
  $SCRIPT_NAME [all|terraform-plan|terraform-apply|ansible-deploy] [commit_sha]

Phases:
  all              Run Terraform plan, Terraform apply, inventory generation, and Ansible.
  terraform-plan   Run Terraform init, validate, and plan.
  terraform-apply  Apply the existing Terraform plan and generate inventory.
  ansible-deploy   Generate inventory and run the Ansible master playbook.

CI may pass the phase through SSH_ORIGINAL_COMMAND when this script is used as an SSH forced command.
EOF
}

parse_requested_phase() {
  local requested=()
  local requested_phase

  if [[ "$#" -gt 0 ]]; then
    requested=("$@")
  elif [[ -n "${SSH_ORIGINAL_COMMAND:-}" ]]; then
    # shellcheck disable=SC2206
    requested=(${SSH_ORIGINAL_COMMAND})
  fi

  if [[ "${#requested[@]}" -gt 2 ]]; then
    die "Too many deploy arguments"
  fi

  if [[ "${#requested[@]}" -eq 0 ]]; then
    DEPLOY_PHASE="$DEFAULT_PHASE"
    return
  fi

  requested_phase="${requested[0]}"

  if [[ "$requested_phase" == "help" || "$requested_phase" == "-h" || "$requested_phase" == "--help" ]]; then
    usage
    exit 0
  fi

  case "$requested_phase" in
    all|terraform-plan|terraform-apply|ansible-deploy)
      DEPLOY_PHASE="$requested_phase"
      ;;
    *)
      die "Unsupported deploy phase '$requested_phase'"
      ;;
  esac

  if [[ "${#requested[@]}" -gt 1 ]]; then
    DEPLOY_COMMIT="${requested[1]}"
  fi
}

terraform_plan() {
  log "Running Terraform plan (prod)"

  pushd "$TERRAFORM_DIR" >/dev/null

  log "terraform init"
  terraform init -input=false

  log "terraform validate"
  terraform validate

  log "Cleaning old plan"
  rm -f "$PLAN_FILE"
  rm -f "$PLAN_COMMIT_FILE"

  log "terraform plan"
  terraform plan -out="$PLAN_FILE"

  git rev-parse HEAD > "$PLAN_COMMIT_FILE"

  popd >/dev/null

  log "Terraform plan completed successfully"
}

terraform_apply() {
  log "Running Terraform apply (prod)"

  [[ -f "$PLAN_FILE" ]] || die "Missing Terraform plan file: $PLAN_FILE. Run terraform-plan first."
  [[ -f "$PLAN_COMMIT_FILE" ]] || die "Missing Terraform plan commit marker: $PLAN_COMMIT_FILE. Run terraform-plan first."

  local current_commit
  local planned_commit
  current_commit="$(git rev-parse HEAD)"
  planned_commit="$(cat "$PLAN_COMMIT_FILE")"

  [[ "$current_commit" == "$planned_commit" ]] || die "Terraform plan was created for commit '$planned_commit', but current commit is '$current_commit'. Run terraform-plan again."

  pushd "$TERRAFORM_DIR" >/dev/null

  log "terraform apply"
  terraform apply -input=false -lock-timeout=300s "$PLAN_FILE"

  log "Generating Ansible inventory from Terraform outputs"
  "$REPO_ROOT/90_scripts/generate_inventory.sh"

  popd >/dev/null

  log "Terraform apply completed successfully"
}

ansible_deploy() {
  log "Running Ansible (prod)"

  log "Generating Ansible inventory from Terraform outputs"
  "$REPO_ROOT/90_scripts/generate_inventory.sh"

  ansible-playbook \
  -i "$ANSIBLE_DIR/$ANSIBLE_INVENTORY" \
  "$ANSIBLE_DIR/$ANSIBLE_PLAYBOOK"

  log "Ansible completed successfully"
}

parse_requested_phase "$@"

# ============================================================
# PRE-FLIGHT CHECKS
# ============================================================

log "Ensuring SSH keys exist"

[[ -d "$REPO_ROOT/.git" ]] || die "Repo root not found at $REPO_ROOT"

[[ -f "$ADMIN_KEY_PUB" ]] || die "Missing admin SSH public key: $ADMIN_KEY_PUB"

if [[ ! -f "$IAC_KEY" ]]; then
  log "Generating IaC SSH key"
  ssh-keygen \
  -t ed25519 \
  -f "$IAC_KEY" \
  -C "iac-controller" \
  -N ""
else
  log "IaC SSH key already exists"
fi

chmod 600 "$IAC_KEY"

[[ -d "$TERRAFORM_DIR" ]] || die "Terraform prod directory missing"
command -v terraform >/dev/null || die "terraform not found"

log "Writing Terraform SSH key variables"
cat > "$TF_VARS_FILE" <<EOF
admin_ssh_public_key = "$(cat "$ADMIN_KEY_PUB")"
iac_ssh_public_key   = "$(cat "$IAC_KEY_PUB")"
EOF


[[ -d "$ANSIBLE_DIR" ]] || die "Ansible directory missing"
command -v ansible-playbook >/dev/null || die "ansible-playbook not found"

cd "$REPO_ROOT" || die "Failed to cd into repo root: $REPO_ROOT"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  die "Not inside a git repository"
fi


CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"

if [[ "${CI_MODE:-}" != "true" ]]; then
  if [[ "$CURRENT_BRANCH" != "master" ]]; then
    die "Refusing to deploy prod from branch '$CURRENT_BRANCH'"
  fi

  if [[ -n "$(git status --porcelain)" ]]; then
    die "Git working tree is dirty. Commit or stash before deploying."
  fi

  echo
  echo "⚠️  YOU ARE DEPLOYING TO PROD"
  echo "Environment : $ENV"
  echo "Branch      : $CURRENT_BRANCH"
  echo "Phase       : $DEPLOY_PHASE"
  echo "Terraform   : $TERRAFORM_DIR"
  echo "Ansible     : $ANSIBLE_DIR"
  echo
  confirm
else
  log "CI mode: skipping dirty git check"
  log "CI mode: syncing repo with origin"
  git fetch origin

  [[ -n "$DEPLOY_COMMIT" ]] || die "CI deploy requires an explicit commit SHA"
  git merge-base --is-ancestor "$DEPLOY_COMMIT" origin/master || die "Commit '$DEPLOY_COMMIT' is not on origin/master"
  git checkout --detach "$DEPLOY_COMMIT"

  log "CI mode enabled (no confirmation)"
  log "Deploy phase: $DEPLOY_PHASE"
  log "Deploy commit: $DEPLOY_COMMIT"
fi

log "Starting Prod deployment via IaC controller"

case "$DEPLOY_PHASE" in
  all)
    terraform_plan
    terraform_apply
    ansible_deploy
    ;;
  terraform-plan)
    terraform_plan
    ;;
  terraform-apply)
    terraform_apply
    ;;
  ansible-deploy)
    ansible_deploy
    ;;
esac

log "Prod deployment phase '$DEPLOY_PHASE' completed successfully"
