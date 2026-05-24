# Homelab Infra Context

This file is the working context for this repository. Treat it as the first place to check before making structural, Terraform, Ansible, scripting, or documentation changes.

The goal of the project is to manage a Proxmox-based homelab using infrastructure-as-code, with Terraform responsible for infrastructure lifecycle and Ansible responsible for system configuration.

## Project Shape

- `00_bootstrap/` contains first-install and Proxmox bootstrap material.
- `10_terraform/` defines infrastructure existence, sizing, placement, networking, and metadata.
- `20_ansible/` configures operating systems, services, packages, files, and runtime state.
- `90_scripts/` contains helper scripts that wrap or automate common workflows.
- `99_docs/` contains architecture notes, decisions, and long-form documentation.
- `keys/` may contain public keys and placeholders, but private secrets must not be committed.

Top-level numeric prefixes and underscore separators are intentional. Do not rename these directories casually.

## Source Of Truth

Terraform is the source of truth for resources that exist:

- VMs
- LXCs
- CPU, memory, disks, and network definitions
- Proxmox VMIDs, names, tags, and placement
- Cloud-init attachment and machine metadata

Ansible is the source of truth for how systems are configured after they exist:

- Packages
- Users and permissions
- Files and templates
- Services
- Mounts
- Application configuration
- Runtime validation

Scripts are not a source of truth. They should only make common Terraform or Ansible operations safer and easier to run.

## Naming Rules

Infrastructure names should be predictable before running any tool.

Human-readable machine names use:

```text
<env>-<role>-<index>
```

Examples:

- `prod-iac-01`
- `prod-media-02`
- `dev-test-01`

Rules:

- Use lowercase.
- Use hyphens in machine names.
- Use two-digit indexes.
- Role names describe function, not vendor or package name.
- Do not add random suffixes.

Terraform resource names use:

```text
<role>_<index>
```

Examples:

- `iac_01`
- `media_01`
- `db_postgres_01`

Do not include the environment in Terraform resource names when the environment is already represented by the directory and state.

## VMID Rules

VMIDs are explicitly assigned by Terraform. Do not rely on Proxmox auto-assignment.

Most VMIDs use this format:

```text
CCCII
```

- `CCC` is the category.
- `II` is the two-digit index.

Dedicated application stacks may use extended high-number VMIDs when they need to live outside the shared category bands. Keep extended IDs within Proxmox's 9-digit VMID limit.

Current category ranges:

| Range         | Category                    |
| ------------- | --------------------------- |
| `100xx`       | Core / Control / Networking |
| `200xx`       | Databases                   |
| `300xx`       | Monitoring                  |
| `400xx`       | Knowledge                   |
| `500xx`       | Media                       |
| `600xx`       | Project Management          |
| `700xx`       | Reserved                    |
| `800xx`       | Misc / Experiments          |
| `900xx-999xx` | Templates only              |
| `1001001xx`   | Market Diaries Storage      |
| `1001002xx`   | Market Diaries Renderers    |

## Terraform Rules

- Keep environments separated by directory and state.
- Do not mix dev and prod resources in the same state.
- Keep modules reusable and environment-specific decisions in `envs/<env>/`.
- Define disk sizes explicitly.
- Document any additional disks.
- Use stable resource names because renames imply destroy/create behavior.
- Do not use Terraform to install packages or configure services.
- Do not store passwords, tokens, or private keys in Terraform.
- Prefer explicit variables and outputs over hidden assumptions.

All Proxmox resources managed by Terraform should have useful tags, including:

- `env:<env>`
- `managed_by:terraform`
- `role:<role>`
- template name/version tags where applicable

## Ansible Rules

The master playbook is `20_ansible/playbooks/homelab.yml`.

Roles should be idempotent and safe to run repeatedly. A normal role follows this task order:

```yaml
- import_tasks: install.yml
- import_tasks: configure.yml
- import_tasks: service.yml
- import_tasks: validate.yml
```

Use this pattern unless a role has a clear reason to differ.

Role responsibilities:

- `defaults/main.yml` contains overridable defaults.
- `tasks/install.yml` installs packages, repos, and binaries.
- `tasks/configure.yml` writes configuration, directories, mounts, templates, and permissions.
- `tasks/service.yml` starts, enables, restarts, or reloads services.
- `tasks/validate.yml` checks that the desired state is actually working.
- `handlers/main.yml` contains service restarts/reloads triggered by changes.

Prefer Ansible modules over shell commands. Use `command` or `shell` only when there is no suitable module, and make the task idempotent with `creates`, `removes`, `changed_when`, or explicit checks.

## Validation Rules

Every service role should include validation that proves the role worked.

Good validation examples:

- Check a service is active.
- Check an expected port is listening.
- Check a mount exists before starting dependent services.
- Check an HTTP health endpoint responds.
- Check required directories exist with expected ownership.

Validation should fail clearly when an important dependency is missing.

## Secrets And Keys

- Do not commit private keys, API tokens, passwords, or generated secret files.
- Public keys may live in `keys/` when needed.
- Prefer secret injection outside Terraform.
- If a task needs a secret, document the expected variable name and where it should come from.
- Do not hard-code secrets in playbooks, defaults, Terraform variables, templates, or scripts.
- Parent roles should load secrets from `keys/` or another approved secret source, then pass them explicitly into reusable child roles.
- Reusable roles should expose safe empty defaults for optional secret inputs so they can be included without forcing secret management.

## Scripts

Scripts in `90_scripts/` should be boring, readable wrappers around known workflows.

Script rules:

- Make dangerous operations explicit.
- Avoid hidden destructive behavior.
- Do not become an alternate source of infrastructure truth.
- Prefer calling Terraform or Ansible with clear arguments.
- Document required environment variables near the top of the script or in `90_scripts/README.md`.

## Documentation

Use docs to capture decisions, not just current behavior.

- Put durable architecture notes in `99_docs/architecture.md`.
- Put major decisions and rationale in `99_docs/decisions.md`.
- Keep this `CONTEXT.md` focused on working rules and project conventions.
- Update docs when changing a convention, not after the convention has drifted.

## Collaboration Rules

When working in this repo:

- Read nearby files before changing a pattern.
- Keep changes small and scoped.
- Do not rewrite unrelated files.
- Do not revert local changes unless explicitly asked.
- Prefer established conventions over new abstractions.
- Make operational changes repeatable through Terraform, Ansible, or documented scripts.
- Before adding a new service, decide whether Terraform, Ansible, or both need changes.
- Before changing production resources, consider whether the change affects state, identity, storage, networking, or secrets.
- At the end of every response after repo changes, include a suggested commit message for the changes since the last commit.

## Golden Rules

- Terraform creates and manages infrastructure existence.
- Ansible configures and validates systems.
- Scripts assist, but do not define truth.
- Names, VMIDs, roles, and ownership should be predictable before execution.
- Every role should be safe to run more than once.
- Secrets stay out of Git.
