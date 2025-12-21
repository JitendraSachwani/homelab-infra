# Homelab Infra

Infrastructure-as-Code for my Proxmox-based homelab running on ODROID H4 with Proxmox VE 9.x.

This repository bootstraps Proxmox and manages the infrastructure lifecycle using Terraform and Ansible.

---

## High Level Architecture

- Host OS: Proxmox VE 9.x  
- Storage: BTRFS with subvolumes for VMs, LXCs, and ISOs  
- Dedicated disks: SSD for SLOG and scratch  
- IaC controller: Ubuntu VM running Terraform and Ansible  
- VMs and LXCs: Defined and managed under `terraform/`  
  - VM definitions: `terraform/modules/proxmox-vm`
  - LXC definitions: `terraform/modules/proxmox-lxc`
  - Environment-specific resources: `terraform/envs/dev` and `terraform/envs/prod`

---

## Bootstrap Phase

#### Pre-install Requirement
---
Before installing Proxmox, replace any environment- or hardware-specific variables in:

- `bootstrap/auto-install-answer.toml`
- `bootstrap/first-boot.sh`
- `bootstrap/create-iac-controller.sh`

This includes (but is not limited to):

- Disk IDs (`/dev/disk/by-id/...`)
- Storage names
- Network bridges
- VM / LXC resource defaults

**Note:** Always use the correct disk IDs obtained from the installer shell to avoid accidental data loss.

---

### Proxmox Bootstrap
---

The bootstrap process creates a fully unattended Proxmox installation using a custom auto-install ISO.

Steps:

1. Download the official Proxmox VE 9.1+ ISO.
2. Use the Proxmox Auto Install Assistant to generate a custom ISO:
   - Provide `bootstrap/auto-install-answer.toml` as the answers file.
   - Attach `bootstrap/first-boot.sh` as the first-boot script.
3. Boot the ODROID H4 using the generated `pve_auto.iso`.
4. Proxmox installs automatically and executes the first-boot logic.

During bootstrap, the system:

- Runs Proxmox auto installation
- Partitions disks
- Creates BTRFS subvolumes
- Configures Proxmox storage
- Creates initial VM templates
- Creates the IaC controller VM

---

## Infrastructure Lifecycle

After bootstrap, all infrastructure changes are managed from the **IaC controller VM**.

Terraform manages:

- Virtual machines
- Containers (LXCs)
- Network primitives
- Resource sizing and placement

Ansible manages:

- Base operating system configuration
- Security hardening
- Monitoring agents
- Proxmox host and guest configuration

Terraform is used for **creation and lifecycle**, while Ansible is used for **configuration and state enforcement**.

---

## Environments

Environments are separated by directories, not by branches.

- `dev` – experimental and sandbox workloads
- `prod` – stable workloads

Each environment has:

- Its own Terraform state
- Its own variable definitions
- Its own Ansible inventory

This ensures isolation while keeping infrastructure definitions shared and reusable.
