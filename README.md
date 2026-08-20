# Local Dev Environment Bootstrap

Provision a new workstation from a single command.

## Quick Start

The installer will:

1. Install prerequisites.
2. Clone or update the bootstrap repository.
3. Run `bootstrap.sh`.
4. Apply dotfiles using `stow.sh --seed`.

Preview what will be installed:

```bash
curl -fsSL https://myhost/debian_install.sh | \
bash -s -- \
  --platform=wsl-ubuntu \
  --dry-run
```
_Note: this will clone the project and run but not install the ./bootstrap.sh and ./stow.sh_

Install:

```bash
curl -fsSL https://myhost/debian_install.sh | \
bash -s -- \
  --platform=wsl-ubuntu
```

## Lingo

```text
pantry  → manager
prep    → pre
simmer  → package install
cook    → custom install
season  → post
taste   → validation
```

## Philosophy

- Recipes are the source of truth.
- Managers are thin wrappers.
- Validation proves installation.
- Configuration is reproducible.
- New machines should be provisionable from a single command.

## Limitations

- Execution order is recipe order.
- Dependencies between recipes are not resolved automatically.
- Validation commands should be side-effect free.
- Secrets and private keys are not source controlled.
- Recipes are platform specific.

## Recipes

Recipes are the source of truth for workstation provisioning.

Example:

```json
{
  "git": {
    "wsl-ubuntu": {
      "manager": "apt",
      "package": "git",
      "validation": [
        "git --version"
      ]
    }
  }
}
```

## Supported Managers

### Linux

```text
apt
apt-get
snap
cargo
ssh
custom
```

### Windows

```text
winget
choco
custom
```

## Recipe Fields

| Field | Purpose |
|---------|---------|
| manager | Installation handler |
| pre | Commands before install |
| package | Package identifier |
| flags | Additional installer arguments |
| install | Custom installation commands |
| post | Commands after installation |
| validation | Success checks |

## Execution Flow

```text
prep
↓
simmer / cook
↓
season
↓
taste
```

## How To

### Install a Package

```json
{
  "git": {
    "wsl-ubuntu": {
      "manager": "apt",
      "package": "git",
      "validation": [
        "git --version"
      ]
    }
  }
}
```

### Install Using a Script

```json
{
  "starship": {
    "wsl-ubuntu": {
      "manager": "custom",
      "install": [
        "curl -sS https://starship.rs/install.sh | sh -s -- -y"
      ],
      "validation": [
        "starship --version"
      ]
    }
  }
}
```

### Generate an SSH Key

```json
{
  "ssh-key": {
    "wsl-ubuntu": {
      "manager": "ssh",
      "package": "id_devops",
      "flags": [
        "-t",
        "rsa",
        "-b",
        "3072"
      ]
    }
  }
}
```
