# apt_repo role

Reusable role to add third-party APT repositories on Ubuntu 22.04+.

## Features
- Uses /etc/apt/keyrings
- No apt-key
- signed-by enforced
- Idempotent
- Jammy-safe

## Variables

Required:
- apt_repo_name
- apt_repo_key_url
- apt_repo_repo_line

Optional:
- apt_repo_arch (default: amd64)
- apt_repo_update_cache (default: true)

## Example

```yaml
- role: apt_repo
  vars:
    apt_repo_name: sonarr
    apt_repo_key_url: https://apt.sonarr.tv/sonarr.gpg.key
    apt_repo_repo_line: "https://apt.sonarr.tv/ master main"
```
---
