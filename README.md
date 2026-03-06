# OmniSet - Linux Development Environment Setup

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux-lightgrey.svg)](#supported-platforms)

Modular Linux setup tool. Select modules and install them with one command.

## Quick Start

**One command - opens browser, you select, it installs:**

```bash
curl -sL https://omniset.org/install | bash
```

**Or clone and use CLI:**
```bash
git clone https://github.com/omnisetorg/omniset.git
cd omniset
./bin/omniset install --web        # browser selection
./bin/omniset install docker vscode nodejs   # direct
```

## Commands

```bash
# Install modules
./bin/omniset install docker nodejs vscode

# Interactive selection (requires whiptail or dialog)
./bin/omniset install --interactive

# List all modules
./bin/omniset list

# List by category
./bin/omniset list --category development

# Show module info
./bin/omniset info docker

# System check
./bin/omniset doctor
```

## Available Modules (32)

### Base
- **essentials** - build-essential, curl, wget, git, vim, htop, unzip

### CLI
- **essentials** - curl, wget, git, vim, htop, jq, tmux
- **modern-cli** - fzf, ripgrep, eza, fd, bat, zoxide

### Desktop
- **chrome** - Google Chrome
- **firefox** - Mozilla Firefox
- **vscode** - Visual Studio Code

### Development
- **docker** - Container platform with Docker Compose
- **nodejs** - Node.js via NVM
- **python** - Python 3 with pip, venv, pyenv
- **go** - Go programming language
- **rust** - Rust via rustup
- **php** - PHP 8.4 with Composer

### Databases (Docker)
- **postgresql** - PostgreSQL 16
- **mysql** - MySQL 8.4
- **redis** - Redis 7
- **mongodb** - MongoDB 7

### Communication
- **discord** - Voice and text chat
- **slack** - Team collaboration
- **zoom** - Video conferencing
- **telegram** - Messaging
- **signal** - Encrypted messaging
- **thunderbird** - Email client

### Creative
- **gimp** - Image editor
- **inkscape** - Vector graphics
- **blender** - 3D creation
- **obs** - Streaming and recording
- **kdenlive** - Video editor
- **audacity** - Audio editor

### Gaming
- **steam** - Gaming platform
- **lutris** - Open gaming platform

### Media
- **vlc** - Media player

### System
- **virtualbox** - Virtual machine manager

## Supported Platforms

**Distributions:** Ubuntu 20.04+, Debian 11+, Fedora, Arch, openSUSE, Alpine

**Architectures:** amd64 (full), arm64 (most), armhf (CLI tools)

## Project Structure

```
omniset/
├── bin/omniset       # CLI
├── lib/              # Core libraries
├── modules/          # 32 module definitions
│   └── <category>/<module>/
│       ├── manifest.yaml
│       └── install.sh
└── web/              # Web selector
```

## Module Format

```yaml
# modules/development/docker/manifest.yaml
name: docker
display_name: Docker
category: development
description: Container platform

install_methods:
  - type: apt_repo
    priority: 1
    packages: [docker-ce, docker-ce-cli]
  - type: snap
    priority: 2  # fallback
    name: docker
```

Modules prefer apt/deb packages. Flatpak/Snap used only as fallback.

## Testing

Tests use [BATS](https://github.com/bats-core/bats-core) (Bash Automated Testing System). The test framework libraries are included as git submodules.

### Prerequisites

```bash
# Initialize BATS submodules (one-time)
cd tests
make setup-bats

# yq is required for integration tests
# Ubuntu/Debian:
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq
```

### Running Tests

All commands run from the `tests/` directory:

```bash
make test              # Unit + integration (all non-E2E tests)
make test-unit         # Unit tests only (~287 tests)
make test-integration  # Integration tests only (manifest validation)
```

#### By module

```bash
make test-core         # core/ — constants, init, temp files
make test-ui           # ui/ — colors, print functions
make test-system       # system/ — detect, packages
make test-install      # install/ — module install/uninstall logic
make test-cli          # cli/ — CLI command parsing
make test-web          # web/ — server, app.js
make test-modules      # modules/ — apt, docker, script, fallback modules
```

#### By priority (for quick feedback)

```bash
make test-p0           # Critical: module install + system detect
make test-p1           # Important: packages + manifest validation
make test-p2           # Standard: CLI + module structure
make test-p3           # Low: constants, colors, print, uninstall
```

#### E2E tests (require Docker)

E2E tests run real installs inside Docker containers. They are slow (~30 min total) and triggered manually via GitHub Actions.

```bash
make test-e2e              # Install verification
make test-e2e-uninstall    # Uninstall verification
make test-e2e-idempotency  # Double install causes no errors
make test-e2e-conflicts    # Overlapping modules coexist
make test-e2e-doctor       # omniset doctor works after installs
make test-e2e-all          # All of the above
```

### CI

Tests run on-demand via `workflow_dispatch` (GitHub Actions → Run workflow). The workflow runs unit + integration tests on both x86_64 and arm64 runners.

See [tests/README.md](tests/README.md) for more details.

## Acknowledgments

OmniSet is inspired by:

- [Tuffix](https://github.com/kevinwortman/tuffix) - Academic Linux development environment
- [node-box](https://github.com/ProfAvery/node-box) - Node.js development VM
- [Omakub](https://github.com/basecamp/omakub) - Basecamp's development environment

## License

MIT - See [LICENSE](LICENSE)
