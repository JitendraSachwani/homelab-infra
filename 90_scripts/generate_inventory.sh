#!/usr/bin/env bash
set -Eeuo pipefail

OUT_DIR="../../20_ansible/inventories/prod"
OUT_FILE="$OUT_DIR/hosts.yml"

mkdir -p "$OUT_DIR"

terraform output -json ansible_hosts | jq -r '
{
  all: {
    vars: {
      ansible_user: "iac",
      ansible_become: true
    },
    children: {
      ci_runners: {
        hosts: (.ci_runners | to_entries | map({
          (.key): { ansible_host: .value }
        }) | add)
      }
    }
  }
}
' > "$OUT_FILE"

echo "[+] Ansible inventory written to $OUT_FILE"
