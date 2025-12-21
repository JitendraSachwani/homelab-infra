#!/bin/bash
set -Eeuo pipefail

# ==============================================================
# GLOBALS & MODES
# ==============================================================

LOG="/tmp/postinstall.log"
exec > >(tee -a "$LOG") 2>&1

DRY_RUN="${DRY_RUN:-0}"
CHECK_ONLY="${CHECK_ONLY:-0}"

CURRENT_SECTION="INIT"
SECTION_START=0

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "[DRY-RUN] $*"
  else
    eval "$@"
  fi
}

section_start() {
  CURRENT_SECTION="$1"
  SECTION_START=$(date +%s)
  echo
  echo "------------------------------------------------"
  echo "[$CURRENT_SECTION] START"
  echo "------------------------------------------------"
}

section_end() {
  local end
  end=$(date +%s)
  echo "[✓] $CURRENT_SECTION completed in $((end - SECTION_START))s"
}

on_error() {
  local ec=$?
  echo
  echo "❌ ERROR in section: $CURRENT_SECTION"
  echo "   Command: ${BASH_COMMAND}"
  echo "   Exit code: $ec"
  echo "   Log file : $LOG"
  exit "$ec"
}
trap on_error ERR

# ==============================================================
# VARIABLES
# ==============================================================

BTRFS_LABEL="pve-btrfs"
BTRFS_MNT="/mnt/pve"

SLOG_DISK="/dev/disk/by-id/ata-CT120BX500SSD1_2036E40EFFF9"

IAC_TEMPLATE_ID=9001
IAC_TEMPLATE_NAME="tmpl-ubuntu-22-iac"
IAC_STORAGE="local-btrfs"
IAC_BRIDGE="vmbr1"

CLOUD_IMG_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
CLOUD_IMG_PATH="/var/lib/vz/template/iso/jammy-server-cloudimg-amd64.img"

# ==============================================================
# SANITY CHECK MODE
# ==============================================================

if [[ "$CHECK_ONLY" == "1" ]]; then
  echo "🧪 SANITY CHECK MODE"
  command -v qm >/dev/null || { echo "❌ qm missing"; exit 1; }
  command -v btrfs >/dev/null || { echo "❌ btrfs missing"; exit 1; }
  blkid | grep -q "$BTRFS_LABEL" || { echo "❌ BTRFS label not found"; exit 1; }
  [[ -b "$SLOG_DISK" ]] || echo "⚠️ SLOG disk missing (optional)"
  echo "✅ Sanity checks passed"
  exit 0
fi

# ==============================================================
# 1. Mount BTRFS root
# ==============================================================

section_start "1. Mount BTRFS root"

run "mkdir -p $BTRFS_MNT"
mountpoint -q "$BTRFS_MNT" || \
  run "mount -o compress=zstd:1,autodefrag,ssd,space_cache,discard=async LABEL=$BTRFS_LABEL $BTRFS_MNT"

section_end

# ==============================================================
# 2. BTRFS subvolumes
# ==============================================================

section_start "2. BTRFS subvolumes"

SUBVOLS=(config vms lxc iso dbs docker scratch)
for s in "${SUBVOLS[@]}"; do
  [[ -d "$BTRFS_MNT/$s" ]] && continue
  run "btrfs subvolume create $BTRFS_MNT/$s"
done

section_end

# ==============================================================
# 3. fstab configuration
# ==============================================================

section_start "3. fstab configuration (BTRFS)"

if ! grep -q "LABEL=${BTRFS_LABEL} ${BTRFS_MNT}" /etc/fstab; then
  run "cat >> /etc/fstab <<EOF

# BTRFS RAID1 root + subvolumes
LABEL=${BTRFS_LABEL} ${BTRFS_MNT} btrfs defaults,compress=zstd:1,ssd,autodefrag,space_cache,discard=async 0 0
LABEL=${BTRFS_LABEL} ${BTRFS_MNT}/config btrfs subvol=config,compress=zstd:1,ssd,autodefrag,space_cache,discard=async 0 0
LABEL=${BTRFS_LABEL} ${BTRFS_MNT}/vms btrfs subvol=vms,compress=zstd:1,ssd,autodefrag,space_cache,discard=async 0 0
LABEL=${BTRFS_LABEL} ${BTRFS_MNT}/lxc btrfs subvol=lxc,compress=zstd:1,ssd,autodefrag,space_cache,discard=async 0 0
LABEL=${BTRFS_LABEL} ${BTRFS_MNT}/iso btrfs subvol=iso,compress=zstd:1,ssd,autodefrag,space_cache,discard=async 0 0
LABEL=${BTRFS_LABEL} ${BTRFS_MNT}/dbs btrfs subvol=dbs,compress=zstd:1,ssd,autodefrag,space_cache,discard=async 0 0
LABEL=${BTRFS_LABEL} ${BTRFS_MNT}/docker btrfs subvol=docker,compress=zstd:1,ssd,autodefrag,space_cache,discard=async 0 0
LABEL=${BTRFS_LABEL} ${BTRFS_MNT}/scratch btrfs subvol=scratch,compress=zstd:1,ssd,autodefrag,space_cache,discard=async 0 0
EOF"
else
  echo "[i] BTRFS fstab entries already present"
fi

section_end

# ==============================================================
# 4. SLOG / SCRATCH partitioning
# ==============================================================

section_start "4. SLOG / SCRATCH partitioning"

if [[ ! -b "$SLOG_DISK" ]]; then
  echo "⚠️ SLOG disk not found, skipping"
elif lsblk -no NAME "$SLOG_DISK" | grep -q part; then
  echo "[i] Disk already partitioned"
else
  run "wipefs -a $SLOG_DISK || true"
  run "sgdisk --zap-all $SLOG_DISK"
  run "partx -u $SLOG_DISK || true"
  run "udevadm settle"
  sleep 2

  run "sgdisk -n1:0:+50G -t1:8300 -c1:truenas-slog $SLOG_DISK"
  run "sgdisk -n2:0:0     -t2:8300 -c2:pve-scratch  $SLOG_DISK"

  run "partx -u $SLOG_DISK || true"
  run "udevadm settle"
  sleep 2
fi

section_end

# ==============================================================
# 5. Scratch filesystem
# ==============================================================

section_start "5. Scratch filesystem"

SCRATCH_PART=$(lsblk -no PATH "$SLOG_DISK" | tail -n 1 || true)

if [[ -b "$SCRATCH_PART" ]]; then
  FS_TYPE=$(blkid -s TYPE -o value "$SCRATCH_PART" || true)
  if [[ "$FS_TYPE" != "ext4" ]]; then
    run "wipefs -a $SCRATCH_PART"
    run "mkfs.ext4 -F $SCRATCH_PART"
  fi

  SCRATCH_UUID=$(blkid -s UUID -o value "$SCRATCH_PART")
  run "mkdir -p /mnt/pve/scratch-local"

  grep -q "/mnt/pve/scratch-local" /etc/fstab || \
    run "echo 'UUID=$SCRATCH_UUID /mnt/pve/scratch-local ext4 defaults,noatime,nofail 0 0' >> /etc/fstab"

  run "mount /mnt/pve/scratch-local || true"
else
  echo "⚠️ Scratch partition missing"
fi

section_end

# ==============================================================
# 6. Proxmox storage.cfg
# ==============================================================

section_start "6. Proxmox storage.cfg"

cat > /etc/pve/storage.cfg <<'EOF'
dir: local
        path /var/lib/vz
        content iso,vztmpl,backup
        disable

dir: local-btrfs
        path /mnt/pve/vms
        content images,rootdir,import,snippets

dir: iso-btrfs
        path /mnt/pve/iso
        content iso

dir: scratch-local
        path /mnt/pve/scratch-local
        content backup,iso,vztmpl
EOF


section_end


# ==============================================================
# 7. IaC cloud-init template
# ==============================================================

section_start "7. IaC cloud-init template"

if qm list | awk '{print $1}' | grep -qx "$IAC_TEMPLATE_ID"; then
  echo "[i] IaC template VMID $IAC_TEMPLATE_ID already exists"
  section_end
  return 0 2>/dev/null || true
fi

run "mkdir -p /var/lib/vz/template/iso"
[[ -f "$CLOUD_IMG_PATH" ]] || run "curl -L -o $CLOUD_IMG_PATH $CLOUD_IMG_URL"

run "qm create $IAC_TEMPLATE_ID \
  --name $IAC_TEMPLATE_NAME \
  --memory 2048 \
  --cores 2 \
  --net0 virtio,bridge=$IAC_BRIDGE \
  --agent enabled=1 \
  --ostype l26"

run "qm importdisk $IAC_TEMPLATE_ID $CLOUD_IMG_PATH $IAC_STORAGE"

VOLID=$(qm config "$IAC_TEMPLATE_ID" | awk '/^unused0:/ {print $2}')
if [[ -z "$VOLID" ]]; then
  echo "❌ Failed to resolve imported disk volume ID"
  qm config "$IAC_TEMPLATE_ID"
  exit 1
fi
echo "[i] Imported disk volume resolved as: $VOLID"

run "qm set $IAC_TEMPLATE_ID \
  --scsihw virtio-scsi-pci \
  --scsi0 $VOLID \
  --boot order=scsi0 \
  --ide2 $IAC_STORAGE:cloudinit \
  --serial0 socket \
  --vga serial0 \
  --ipconfig0 ip=dhcp"

run "qm template $IAC_TEMPLATE_ID"

section_end

# ==============================================================
# 8. Maintenance + APT repos
# ==============================================================

section_start "8. Maintenance"

for f in /etc/apt/sources.list.d/*.sources; do
  grep -q "enterprise.proxmox.com" "$f" || continue
  sed -i '/^Enabled:/d' "$f"
  sed -i '1i Enabled: no' "$f"
done

cat > /etc/apt/sources.list.d/pve-no-subscription.sources <<EOF
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
Enabled: yes
EOF

run "apt update"
run "apt install -y smartmontools"

run "cat > /etc/cron.weekly/btrfs-scrub <<EOF
#!/bin/bash
btrfs scrub start -B /mnt/pve || true
EOF"

run "chmod +x /etc/cron.weekly/btrfs-scrub"
run "proxmox-boot-tool refresh || true"

section_end

# ==============================================================
# FINAL
# ==============================================================

echo
echo "==============================================="
echo " ✅ Proxmox First-Boot Completed Successfully"
echo "==============================================="
echo " IaC Template: $IAC_TEMPLATE_NAME ($IAC_TEMPLATE_ID)"
echo " Log file    : $LOG"
exit 0
