# Bootstrap

This directory contains one-time Proxmox installation and first-boot logic.

Scripts in this directory:
- Are intended to run once
- Should NOT be rerun on an existing system
- Handle disk layout, storage, and initial VM creation

If you need to re-run anything here, something upstream is wrong.

# Proxmox VE 9 Bootstrap (Auto-Install)

This folder contains everything required to generate a **fully automated Proxmox VE 9 installer ISO** with:

- BTRFS RAID1 root
- Deterministic networking
- Post-install first-boot provisioning
- IaC controller cloud-init template creation

---

## Files

- `auto-install-answer.toml`  
  Proxmox automated install answer file

- `first-boot.sh`  
  One-time post-install bootstrap script (storage, repos, IaC template)

---

## Requirements

- Linux host
- `proxmox-auto-install-assistant` available in `$PATH`
- Proxmox VE 9 installer ISO

---

## Build Auto-Install ISO

Run the following command **from this directory**:

```bash
proxmox-auto-install-assistant prepare-iso \
  </path/to/proxmox-ve-9.iso> \
  --answer-file auto-install-answer.toml \
  --first-boot first-boot.sh \
  --output pve_auto.iso
```

This produces:

```bash
pve_auto.iso
```

Boot the target machine using this ISO to perform a fully unattended install.