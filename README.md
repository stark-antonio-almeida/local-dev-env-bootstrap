# Recipes

Recipes define how a tool is installed and validated on a specific operating system.

The recipe file is the source of truth for workstation provisioning.

## Lingo

```
pantry  -> manager
prep    -> pre
simmer  -> package install
cook    -> custom install
season  -> post
taste   -> validation
```

## Structure

```json
{
  "git": {
    "ubuntu": {
      "manager": "apt",
      "pre": [
        "sudo add-apt-repository ppa:git-core/ppa -y",
        "sudo apt update"
      ],
      "package": "git",
      "validation": [
        "git --version"
      ]
    },

    "windows11": {
      "manager": "winget",
      "package": "Git.Git",
      "validation": [
        "git --version"
      ]
    }
  }
}
```

## Supported Managers

### Ubuntu

- apt
- snap
- cargo
- custom

### Windows 11

- winget
- choco
- custom

## Recipe Fields

### manager

Defines which installer handles the recipe.

```json
{
  "manager": "apt"
}
```

### pre

Commands executed before installation.

```json
{
  "pre": [
    "sudo add-apt-repository ppa:git-core/ppa -y",
    "sudo apt update"
  ]
}
```

### package

Package identifier used by the package manager.

```json
{
  "package": "git"
}
```

### flags

Optional package-manager-specific flags.

```json
{
  "package": "nvim",
  "flags": [
    "--classic"
  ]
}
```

### install

Used only by the `custom` manager.

The command must be fully specified.

```json
{
  "manager": "custom",
  "install": [
    "curl -sS https://starship.rs/install.sh | sh -s -- -y"
  ]
}
```

### post

Commands executed after installation.

```json
{
  "post": [
    "some-command"
  ]
}
```

### validation

Commands used to verify a successful installation.

```json
{
  "validation": [
    "git --version"
  ]
}
```

## Rules

### Package-based recipe

Uses `package`.

```json
{
  "manager": "apt",
  "package": "git"
}
```

### Custom recipe

Uses `install`.

```json
{
  "manager": "custom",
  "install": [
    "curl -sS https://starship.rs/install.sh | sh -s -- -y"
  ]
}
```

### Mutual Exclusivity

A recipe must contain either:

- `package`

or

- `install`

but never both.

✅ Valid

```json
{
  "manager": "apt",
  "package": "git"
}
```

✅ Valid

```json
{
  "manager": "custom",
  "install": [
    "curl -sS https://starship.rs/install.sh | sh -s -- -y"
  ]
}
```

❌ Invalid

```json
{
  "manager": "apt",
  "package": "git",
  "install": [
    "some-command"
  ]
}
```

### Flags

`flags` may only be used with `package`.

✅ Valid

```json
{
  "manager": "snap",
  "package": "nvim",
  "flags": [
    "--classic"
  ]
}
```

❌ Invalid

```json
{
  "manager": "custom",
  "install": [
    "some-command"
  ],
  "flags": [
    "--classic"
  ]
}
```

## Execution Order

For each recipe the bootstrap engine executes:

```text
pre
↓
install package / run install commands
↓
post
↓
validation
```

The bootstrap script decides overall execution order. The recipe only describes what must be installed and validated.

# Prerequisites

The bootstrap engine intentionally keeps external dependencies to a minimum.

## Ubuntu

Required before running the bootstrap:

```bash
sudo apt update

sudo apt install -y \
    jq \
    software-properties-common
```

### Why?

#### jq

Used by the bootstrap engine to parse recipe files.

#### software-properties-common

Provides:

```bash
add-apt-repository
```

which is required by recipes such as Git:

```bash
sudo add-apt-repository ppa:git-core/ppa -y
```

## Windows 11

Required before running the bootstrap:

- PowerShell
- Winget

Both are included with modern Windows 11 installations.

## Supported Package Managers

### Ubuntu

- apt
- snap
- cargo
- custom

### Windows 11

- winget
- choco
- custom

## Bootstrap Goal

A new machine should be provisioned with:

```bash
git clone git@github.com:<user>/local-dev-env-bootstrap.git

cd local-dev-env-bootstrap

./bootstrap-ubuntu.sh
```

or

```powershell
.\bootstrap-windows.ps1
```

with all workstation configuration defined through recipes.

## Design Principles

- Recipes are the source of truth.
- Installation order is determined by recipe order.
- Dependencies are managed explicitly.
- Package managers are thin wrappers.
- The bootstrap engine orchestrates execution.
- Validation is performed after installation.
- New machines get new SSH keys.
- Configuration is reproducible and source-controlled.

