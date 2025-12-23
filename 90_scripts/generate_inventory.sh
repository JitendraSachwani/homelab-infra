#!/usr/bin/env bash
set -Eeuo pipefail

# Resolve repo root (no matter where script is called from)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TF_DIR="$REPO_ROOT/10_terraform/envs/prod"
INV_DIR="$REPO_ROOT/20_ansible/inventories/prod"
INV_FILE="$INV_DIR/hosts.yml"

mkdir -p "$INV_DIR"

terraform -chdir="$TF_DIR" output -json ansible_hosts | jq -r '
{
  all: {
    vars: {
      ansible_user: "iac",
      ansible_become: true
    },
    children: (
      . | to_entries | map({
        (.key): {
          hosts: (
            .value | to_entries | map({
              (.key): { ansible_host: .value }
            }) | add
          )
        }
      }) | add
    )
  }
}
' > "$INV_FILE"

echo "[+] Ansible inventory written to $INV_FILE"
