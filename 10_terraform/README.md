# Terraform Conventions

Terraform is the **source of truth for infrastructure existence** in this homelab.

This document defines naming, VMID allocation, tagging, and layout conventions.
These conventions are intentional and should not be changed casually.

---

## Environment Model

Environments are separated by directories.

Structure:

- envs/dev
- envs/prod

Each environment has:
- Its own Terraform state
- Its own variable definitions
- The same reusable modules


Rule:
Do not mix resources from different environments in the same Terraform state.

---

## VM and LXC Naming Convention

Human-readable names follow this format:

`<env>-<role>-<index>`

Examples:
- `dev-iac-01`
- `prod-monitoring-01`
- `prod-media-02`
- `dev-test-01`

Rules:
- Lowercase only
- Hyphen separated
- Role describes function, not software
- Index is always two digits

---

## Proxmox VMID Allocation

Most VMIDs use a 5-digit number where the first three digits represent the category and the last two digits represent the index.

```
CCC II
 │  └─ index (01–99)
 └── category
```

VMIDs are explicitly assigned by Terraform and never auto-generated.
Dedicated application stacks may use an extended high-number range when they need to live outside the shared category bands. Keep extended IDs within Proxmox's 9-digit VMID limit.

VMID ranges:
---

| Range       | Category                    | Notes                                    |
| ----------- | --------------------------- | ---------------------------------------- |
| 100xx       | Core / Control / Networking | IaC controller, DNS, gateway, infra glue |
| 200xx       | Databases                   | Postgres, MySQL, Redis, etc              |
| 300xx       | Monitoring                  | Prometheus, Grafana, Loki                |
| 400xx       | Knowledge                   | Docs, wikis, runbooks, knowledge bases   |
| 500xx       | Media                       | Jellyfin, *arr stack, downloads          |
| 600xx       | Project Management          | Plane, roadmaps, task/project tools      |
| 700xx       | Reserved                    | Reserved for a future category           |
| 800xx       | Misc / Experiments          | Experiments, temporary services          |
| 900xx–999xx | Templates                   | VM templates only                        |
| 1001001xx   | Market Diaries Storage      | Dedicated market diaries storage nodes   |
| 1001002xx   | Market Diaries Renderers    | Dedicated market diaries renderer nodes  |
---

Examples:
---

| VM Name                         | VMID      | Meaning                 |
| ------------------------------- | --------- | ----------------------- |
| prod-iac-01                     | 10001     | Core IaC controller     |
| prod-db-01                      | 20001     | First database VM       |
| prod-monitoring-01              | 30001     | Monitoring stack        |
| prod-docs-01                    | 40001     | Knowledge base          |
| prod-media-02                   | 50002     | Second media VM         |
| prod-proj-mgmt-01               | 60001     | Project management      |
| dev-test-01                     | 80001     | Misc / experimental     |
| prod-market-diaries-storage-01  | 100100101 | Market diaries storage  |
| prod-market-diaries-renderer-01 | 100100201 | Market diaries renderer |


---

## Terraform Resource Naming

Terraform resource names must be stable and predictable.

Format:

`<role>_<index>`

Examples:
- `iac_01`
- `monitoring_01`
- `media_01`

Rules:
- Do not include environment in resource names
- Do not use random suffixes
- Renaming a resource implies destruction and should be avoided

---

## Resource Tagging

All Proxmox resources managed by Terraform must include tags.

Required tags:
- `env:dev` or `env:prod`
- `managed_by:terraform`
- `role:<role>`
- `template:<template_name>`
- `template_version:<version>`

Tags are used for filtering, automation, and future maintenance.

---

## Cloud-init and OS Conventions

- Hostname must match the VM name
- One primary user per role
- SSH key authentication only
- No passwords stored in Terraform
- Secrets are injected outside Terraform

---

## Disk and Filesystem Conventions

- Each VM has one primary disk (scsi0)
- Disk size must be explicitly defined (20G default)
- Additional disks must be explicit and documented
- No implicit disk resizing

---

## Responsibility Boundaries

Terraform is responsible for:
- Creating and destroying VMs and LXCs
- Defining CPU, memory, disks, and networking
- Attaching cloud-init configuration
- Setting VMID, name, and tags

Terraform must not:
- Install packages
- Configure services
- Perform OS-level configuration
- Run ad-hoc scripts

Those responsibilities belong to Ansible.

---

## Golden Rule

If the name, VMID, and purpose of a resource cannot be predicted before running Terraform,
the design is incorrect.

---
