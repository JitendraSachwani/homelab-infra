#!/bin/bash
set -Eeuo pipefail


# ============================================================
# CONFIG
# ============================================================

ENV="prod"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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

log "Ensuring SSH keys exist"

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

# ============================================================
# HUMAN CONFIRMATION
# ============================================================

if [[ "$AUTO_MODE" -eq 0 ]]; then
  echo
  echo "⚠️  YOU ARE DEPLOYING TO PROD"
  echo "Environment : $ENV"
  echo "Branch      : $CURRENT_BRANCH"
  echo "Terraform   : $TERRAFORM_DIR"
  echo "Ansible     : $ANSIBLE_DIR"
  echo
  confirm
else
  log "Auto mode enabled (no confirmation)"
fi

log "Strating Prod deployment via IaC controller"

# ============================================================
# TERRAFORM
# ============================================================

log "Running Terraform (prod)"

pushd "$TERRAFORM_DIR" >/dev/null

log "terraform init"
terraform init -input=false

log "terraform validate"
terraform validate

log "Cleaning old plan"
rm -f tfplan

log "terraform plan"
terraform plan -out=tfplan

log "terraform apply"
terraform apply -input=false -lock-timeout=300s tfplan

log "Generating Ansible inventory from Terraform outputs"
"$REPO_ROOT/90_scripts/generate_inventory.sh"

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