#!/bin/bash
set -Eeuo pipefail


# ============================================================
# CONFIG
# ============================================================

ENV="prod"
TERRAFORM_DIR="10_terraform/envs/prod"
ANSIBLE_DIR="20_ansible"
ANSIBLE_PLAYBOOK="playbooks/homelab.yml"
ANSIBLE_INVENTORY="inventories/prod"

SCRIPT_NAME="$(basename "$0")"

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

# ============================================================
# MODE DETECTION
# ============================================================

AUTO_MODE=0
if [[ "${DEPLOY_MODE:-}" == "auto" ]]; then
  AUTO_MODE=1
fi

# ============================================================
# PRE-FLIGHT CHECKS
# ============================================================


[[ -d "$TERRAFORM_DIR" ]] || die "Terraform prod directory missing"
[[ -d "$ANSIBLE_DIR" ]] || die "Ansible directory missing"

command -v terraform >/dev/null || die "terraform not found"
command -v ansible-playbook >/dev/null || die "ansible-playbook not found"

log "Strating Prod deployment via IaC controller"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  die "Not inside a git repository"
fi

if [[ "$AUTO_MODE" -eq 0 ]]; then
  if [[ -n "$(git status --porcelain)" ]]; then
    die "Git working tree is dirty. Commit or stash before deploying."
  fi
else
  log "Auto mode: skipping dirty git check"
fi

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$CURRENT_BRANCH" != "master" ]]; then
  die "Refusing to deploy prod from branch '$CURRENT_BRANCH'"
fi

# ------------------------------------------------------------
# Human confirmation
# ------------------------------------------------------------

if [[ "$AUTO_MODE" -eq 0 ]]; then
  echo
  echo "⚠️  You are about to DEPLOY TO PROD"
  echo "Environment : $ENV"
  echo "Branch      : $CURRENT_BRANCH"
  echo "Terraform   : $TERRAFORM_DIR"
  echo "Ansible     : $ANSIBLE_DIR"
  echo
  confirm
else
  log "Auto mode enabled (no confirmation)"
fi


# ============================================================
# TERRAFORM
# ============================================================

log "Running Terraform (prod)"

pushd "$TERRAFORM_DIR" >/dev/null

log "terraform init"
terraform init -input=false

log "terraform plan"
terraform plan -out=tfplan

log "terraform apply"
terraform apply -input=false tfplan

popd >/dev/null

log "Terraform apply completed successfully"

# ============================================================
# ANSIBLE
# ============================================================

log "Running Ansible (prod)"

ansible-playbook \
  -i "$ANSIBLE_DIR/$ANSIBLE_INVENTORY" \
  "$ANSIBLE_DIR/$ANSIBLE_PLAYBOOK"

log "Ansible completed successfully"

# ============================================================
# DONE
# ============================================================

log "✅ PROD deployment completed successfully"