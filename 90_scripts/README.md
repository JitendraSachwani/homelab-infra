# Scripts

Helper scripts for local use.

Scripts here:
- Must be safe
- Must NOT be the source of truth
- Should only wrap Terraform or Ansible commands

## Production Deploy

`deploy_prod.sh` is the production deploy entrypoint used by the IaC controller.

Supported phases:

- `all` - run Terraform plan, Terraform apply, inventory generation, and Ansible.
- `terraform-plan` - run Terraform init, validate, and plan.
- `terraform-apply` - apply the existing Terraform plan and generate Ansible inventory.
- `ansible-deploy` - generate inventory and run the Ansible master playbook.

Manual usage defaults to `all` and requires confirmation:

```bash
./90_scripts/deploy_prod.sh
```

Manual deploys fail when the Git working tree is dirty.

CI usage runs with `CI_MODE=true` through an SSH forced command and passes the requested phase and commit SHA through `SSH_ORIGINAL_COMMAND`.
