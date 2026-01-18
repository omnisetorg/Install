# OmniSet - Linux Development Environment Setup

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux-lightgrey.svg)](#supported-platforms)

Modular Linux setup tool. Select modules and install them with one command.

## Quick Start

```bash
git clone https://github.com/omnisetorg/omniset.git
cd omniset
./bin/omniset install docker nodejs vscode
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

## Acknowledgments

OmniSet is inspired by:

- [Tuffix](https://github.com/kevinwortman/tuffix) - Academic Linux development environment
- [node-box](https://github.com/ProfAvery/node-box) - Node.js development VM
- [Omakub](https://github.com/basecamp/omakub) - Basecamp's development environment

## License

MIT - See [LICENSE](LICENSE)
