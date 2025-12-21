#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# CONFIG
# ============================================================

VM_ID=10001
VM_NAME="iac-controller"

TEMPLATE_ID=9001
STORAGE="local-btrfs"
BRIDGE="vmbr0"

MEMORY=4096
CORES=4

SNIPPETS_DIR="/mnt/pve/vms/snippets"
CLOUDINIT_FILE="${SNIPPETS_DIR}/iac-user-data.yaml"

SSH_PUB_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDYkMRx4ynSGF9pCQvJgbk+Ff4i9xI72I5WNAm5I7y49GajmIwUQ5YGwLsq4BWf27aCV7gktZT90dtxVV8uI16jQkaAxZoxOcX4dsYEa/25nlabkBm6vvDRW+m46D6S4L5RSI5LRIZiRhggSiFmhX50SC+h1TajNcxfZj9qTsm/7iho1/AV80aelOH5iE1u68VIk1NWr4mZ4cxF+k8UlXFzVNkYE28ulFdbjEv2xHyQTAgbUDgqRkMoTHA5sowpossk54pyGcU94GxCRPORAsZSLQqar2HoLeG3yRs3q8rzX9RrDv8+lf+9y2+LNCbDN31r3W/yH8iJJ1rVpkoSLnX+IOORWMPE3fji7KpSmyLElPeJQAOVRP4n2ZzWae6HIiKLg14O1YTq7C/uC7XlKSXtSFoHWGpfwskb6ZGu8dlzZ5+WRkwxJXQD+QeyJBXgy0r/zN2yix+BmGTpK/+oWe4tcx0b7NzBY1Sg7FF465oKyTExb9HkZLYHlmKPtKWisO0= sachw@DESKTOP-5JGQPLC"

TERRAFORM_VERSION="1.14.3"

INFRA_REPO="git@github.com:JitendraSachwani/homelab-infra.git"

# ============================================================
# HELPERS
# ============================================================

log() {
  echo -e "[+] $*"
}

warn() {
  echo -e "[!] $*" >&2
}

die() {
  echo -e "[❌] $*" >&2
  exit 1
}

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
# WRITE CLOUD-INIT (INLINE, AUTHORITATIVE)
# ============================================================

log "Writing cloud-init user-data snippet"

cat > "$CLOUDINIT_FILE" <<EOF
#cloud-config
hostname: iac-controller
manage_etc_hosts: true

users:
  - name: iac
    gecos: IaC Controller
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

apt:
  preserve_sources_list: false
  primary:
    - arches: [default]
      uri: http://archive.ubuntu.com/ubuntu

write_files:
  - path: /etc/profile.d/iac-aliases.sh
    permissions: "0644"
    content: |
      alias deploy_prod='cd /opt/homelab-infra && git pull && ./90_scripts/deploy-prod.sh'

runcmd:
  - set -eux
  - apt-get update
  - systemctl enable --now qemu-guest-agent
  
  # -----------------------------
  # Terraform install
  # -----------------------------
  - |
    curl -fsSL \
      https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
      -o /tmp/terraform.zip
    unzip /tmp/terraform.zip -d /usr/local/bin
    chmod +x /usr/local/bin/terraform
    ln -sf /usr/local/bin/terraform /usr/bin/terraform
    terraform version

  # -----------------------------
  # Ansible install
  # -----------------------------
  - add-apt-repository -y universe
  - apt-get update
  - apt-get install -y ansible
  # hard verification (fail cloud-init if broken)
  - ansible --version

  # -----------------------------
  # Infra Repo Setup
  # -----------------------------
  - mkdir -p /opt/homelab-infra
  - chown iac:iac /opt/homelab-infra
  - sudo -u iac bash -lc '
      if [ ! -d /opt/homelab-infra/.git ]; then
        git clone ${INFRA_REPO} /opt/homelab-infra
      fi
    '
  - chmod +x /opt/homelab-infra/90_scripts/*.sh || true

final_message: |
  IaC Controller ready!
  Use: 'deploy_prod' for any future deployments.
EOF

# ============================================================
# VM CREATION
# ============================================================

if vm_exists; then
  warn "VM $VM_ID already exists, skipping clone"
else
  log "Cloning IaC controller VM from template $TEMPLATE_ID"

  qm clone "$TEMPLATE_ID" "$VM_ID" \
    --name "$VM_NAME" \
    --full \
    --storage "$STORAGE"
fi

# ============================================================
# VM CONFIGURATION
# ============================================================

log "Applying VM configuration"

qm set "$VM_ID" \
  --memory "$MEMORY" \
  --cores "$CORES" \
  --net0 "virtio,bridge=${BRIDGE}" \
  --agent enabled=1 \
  --onboot 1 \
  --cicustom "user=${STORAGE}:snippets/iac-user-data.yaml" \
  --ipconfig0 ip=dhcp

# ============================================================
# START VM
# ============================================================
log "Updating cloud-init configuration for VM"

qm cloudinit update "$VM_ID"

# ============================================================
# START VM
# ============================================================

log "Starting IaC controller VM"

qm start "$VM_ID"

# ============================================================
# WAIT FOR INITIAL BOOT (AGENT NOT READY YET)
# ============================================================

log "Allowing initial boot (guest agent not available yet)"
sleep 60

# ============================================================
# WAIT FOR GUEST AGENT
# ============================================================

log "Waiting for QEMU guest agent"

for i in {1..60}; do
  if qm guest exec "$VM_ID" -- true &>/dev/null; then
    log "Guest agent is responding"
    break
  fi
  sleep 5
done

# ============================================================
# WAIT FOR CLOUD-INIT COMPLETION
# ============================================================

log "Waiting for cloud-init to complete"

for i in {1..120}; do
  STATUS=$(qm guest exec "$VM_ID" -- cloud-init status 2>/dev/null || true)
  if echo "$STATUS" | grep -q "status: done"; then
    log "cloud-init completed successfully"
    break
  fi
  sleep 5
done

# ============================================================
# FINAL HEALTH CHECK
# ============================================================

log "Running final health checks"

qm guest exec "$VM_ID" -- bash -lc '
set -eux
which terraform
ls -l /usr/local/bin/terraform
ls -l /usr/bin/terraform
terraform version
cat /var/log/terraform.done
cloud-init status --long
'

log "IaC controller VM is ready"
