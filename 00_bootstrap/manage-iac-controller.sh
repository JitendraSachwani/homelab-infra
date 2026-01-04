#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# USAGE
# ============================================================

usage() {
  echo "Usage: $0 {create|remove|recreate}"
  exit 1
}

MODE="${1:-}"
[[ -z "$MODE" ]] && usage

# ============================================================
# CONFIG
# ============================================================

VM_ID=10101
VM_NAME="prod-infra-ctrl-01"

TEMPLATE_ID=9001
STORAGE="local-btrfs"
BRIDGE="vmbr0"

MEMORY=4096
CORES=4

SNIPPETS_DIR="/mnt/pve/vms/snippets"
CLOUDINIT_FILE="${SNIPPETS_DIR}/iac-user-data.yaml"

SSH_PUB_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDYkMRx4ynSGF9pCQvJgbk+Ff4i9xI72I5WNAm5I7y49GajmIwUQ5YGwLsq4BWf27aCV7gktZT90dtxVV8uI16jQkaAxZoxOcX4dsYEa/25nlabkBm6vvDRW+m46D6S4L5RSI5LRIZiRhggSiFmhX50SC+h1TajNcxfZj9qTsm/7iho1/AV80aelOH5iE1u68VIk1NWr4mZ4cxF+k8UlXFzVNkYE28ulFdbjEv2xHyQTAgbUDgqRkMoTHA5sowpossk54pyGcU94GxCRPORAsZSLQqar2HoLeG3yRs3q8rzX9RrDv8+lf+9y2+LNCbDN31r3W/yH8iJJ1rVpkoSLnX+IOORWMPE3fji7KpSmyLElPeJQAOVRP4n2ZzWae6HIiKLg14O1YTq7C/uC7XlKSXtSFoHWGpfwskb6ZGu8dlzZ5+WRkwxJXQD+QeyJBXgy0r/zN2yix+BmGTpK/+oWe4tcx0b7NzBY1Sg7FF465oKyTExb9HkZLYHlmKPtKWisO0= sachw@DESKTOP-5JGQPLC"

TERRAFORM_VERSION="1.14.3"

INFRA_REPO="https://github.com/JitendraSachwani/homelab-infra.git"

# ============================================================
# HELPERS
# ============================================================

log()  { echo -e "[+] $*"; }
warn() { echo -e "[!] $*" >&2; }
die()  { echo -e "[❌] $*" >&2; exit 1; }

vm_exists() {
  qm list | awk '{print $1}' | grep -qx "$VM_ID"
}

# ============================================================
# PRECHECKS
# ============================================================

log "Verifying required storage paths"

[[ -d /mnt/pve/vms ]] || die "/mnt/pve/vms not mounted"
mkdir -p "$SNIPPETS_DIR"

# ============================================================
# WRITE CLOUD-INIT
# ============================================================
write_cloudinit() {
  log "Writing cloud-init user-data"

  cat > "$CLOUDINIT_FILE" <<EOF
#cloud-config
hostname: iac-controller
manage_etc_hosts: true

users:
  - name: iac
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users,admin,sudo,docker
    ssh_authorized_keys:
      - ${SSH_PUB_KEY}

disable_root: true
ssh_pwauth: false

package_update: true
package_upgrade: false

packages:
  - ca-certificates
  - curl
  - git
  - jq
  - unzip
  - qemu-guest-agent

write_files:
  - path: /etc/profile.d/iac-aliases.sh
    permissions: "0644"
    content: |
      alias deploy_prod='cd /opt/homelab-infra && git pull && ./90_scripts/deploy_prod.sh'

runcmd:
  - set -eux
  - systemctl enable --now qemu-guest-agent

  - |
    curl -fsSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o /tmp/terraform.zip
    unzip /tmp/terraform.zip -d /usr/local/bin
    ln -sf /usr/local/bin/terraform /usr/bin/terraform
    terraform version

  - add-apt-repository -y universe
  - apt-get update
  - apt-get install -y ansible
  - ansible --version

  - |
    mkdir -p /opt/homelab-infra
    chown iac:iac /opt/homelab-infra
  - |
    sudo -u iac bash -lc '
      if [ ! -d /opt/homelab-infra/.git ]; then
        git clone https://github.com/JitendraSachwani/homelab-infra.git /opt/homelab-infra
      fi
      chmod +x /opt/homelab-infra/90_scripts/deploy_prod.sh
      /opt/homelab-infra/90_scripts/deploy_prod.sh
    '

final_message: |
  IaC Controller ready!.
EOF
}

# ============================================================
# ACTIONS
# ============================================================

create_vm() {
  write_cloudinit

  if vm_exists; then
    warn "VM $VM_ID already exists"
    exit 1
  else
    log "Cloning VM $VM_ID from template $TEMPLATE_ID"
    qm clone "$TEMPLATE_ID" "$VM_ID" --name "$VM_NAME" --full --storage "$STORAGE"
  fi

  qm set "$VM_ID" \
    --memory "$MEMORY" \
    --cores "$CORES" \
    --net0 "virtio,bridge=${BRIDGE}" \
    --agent enabled=1 \
    --onboot 1 \
    --cicustom "user=${STORAGE}:snippets/iac-user-data.yaml" \
    --ipconfig0 "ip=10.0.1.1/16,gw=10.0.0.1"

  qm cloudinit update "$VM_ID"
  qm start "$VM_ID"

  log "Waiting for guest agent"
  for i in {1..60}; do
    qm guest exec "$VM_ID" -- true &>/dev/null && break
    sleep 5
  done

  log "Waiting for cloud-init"
  for i in {1..120}; do
    qm guest exec "$VM_ID" -- cloud-init status 2>/dev/null | grep -q "done" && break
    sleep 5
  done

  log "IaC controller created successfully"
}

remove_vm() {
  if ! vm_exists; then
    warn "VM $VM_ID does not exist"
    return
  fi

  log "Stopping VM $VM_ID"
  qm stop "$VM_ID" --skiplock true || true

  log "Destroying VM $VM_ID"
  qm destroy "$VM_ID" --purge true
}

# ============================================================
# MODE DISPATCH
# ============================================================

case "$MODE" in
  create)   create_vm ;;
  remove)   remove_vm ;;
  recreate)
    remove_vm
    create_vm
    ;;
  *) usage ;;
esac