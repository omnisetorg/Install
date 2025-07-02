# OmniSet - Automated Linux Development Environment Setup

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Debian%20%7C%20Ubuntu%20%7C%20Raspberry%20Pi-lightgrey.svg)](#supported-platforms)
[![Version](https://img.shields.io/badge/version-0.1.0-green.svg)](version)

**Transform your fresh Linux installation into a fully-configured development environment with a single command.**

OmniSet is an intelligent setup script that automatically installs and configures essential development tools, applications, and environments for Debian-based Linux distributions. Choose from pre-configured personalities or customize your installation to match your workflow.

## Quick Start

```bash
git clone https://github.com/omnisetorg/omniset.git
cd omniset
./install.sh
```

Or run directly:

```bash
curl -fsSL https://raw.githubusercontent.com/omnisetorg/omniset/main/install.sh | bash
```

## Features

- **Personality-Based Setup** - Choose from 8 pre-configured development environments
- **Multi-Architecture Support** - Works on x86_64, ARM64, and ARMv7 systems
- **Smart Configuration** - Automatically detects your system and installs compatible packages
- **Comprehensive Tool Collection** - 50+ essential development tools and applications
- **Easy Uninstallation** - Remove installed software with included uninstall scripts
- **System Maintenance** - Built-in maintenance and cleanup utilities

## Available Personalities

| Personality | Best For | Includes |
|-------------|----------|----------|
| **Minimalist** | Basic development | Essential tools, VLC, Thunderbird |
| **Full Stack** | Web development | VS Code, Chrome, Docker, Languages, Databases |
| **Content Creator** | Media production | DaVinci Resolve, Discord, VS Code, Chrome |
| **Cloud Native** | DevOps & containers | Docker, development languages, storage solutions |
| **Gamer** | Gaming setup | Steam, Discord, Chrome, VLC |
| **Student** | Academic work | Chrome, VS Code, Thunderbird, VLC |
| **Designer** | Creative work | Chrome, VS Code, DaVinci Resolve, Discord |
| **Data Scientist** | Data analysis | VS Code, Docker, languages, databases, VirtualBox |

## Supported Platforms

OmniSet works seamlessly across all major Debian-based Linux distributions:

- **Ubuntu** (20.04 LTS, 22.04 LTS, 24.04 LTS)
- **Debian** (11 Bullseye, 12 Bookworm)
- **Raspberry Pi OS** (formerly Raspbian)
- **Linux Mint**
- **Elementary OS**
- **Pop!_OS**
- **Zorin OS**

### Architecture Support

- **x86_64 (amd64)** - Full feature support
- **ARM64 (aarch64)** - Most features supported
- **ARMv7 (armhf)** - Essential tools supported

## Installation Options

### Interactive Installation

```bash
./install.sh
```

Choose your personality interactively with a user-friendly menu.

### Direct Personality Installation

```bash
./install.sh fullstack    # Install Full Stack personality
./install.sh gamer        # Install Gaming personality
./install.sh minimalist   # Install Minimalist personality
```

### What Gets Installed

#### Development Tools

- **Editors**: VS Code, Nano, Vim
- **Version Control**: Git with optimized configuration
- **Languages**: Node.js, Python, Go, PHP, Java, Rust, Ruby, Elixir
- **Containers**: Docker with Docker Compose
- **Databases**: MySQL, PostgreSQL, Redis, MongoDB (in Docker)

#### Creative & Media Tools

- **Video Editing**: DaVinci Resolve, Kdenlive
- **Image Editing**: GIMP, Inkscape, Krita
- **Audio**: Audacity, VLC
- **3D Modeling**: Blender

#### Communication & Productivity

- **Browsers**: Google Chrome, Firefox
- **Communication**: Discord, Slack, Telegram, Teams, Zoom
- **Email**: Thunderbird
- **Office**: LibreOffice suite

## Uninstallation

Remove installed software easily:

```bash
./uninstall.sh
```

Select specific applications to remove or uninstall everything at once.

## System Maintenance

Keep your system clean and optimized:

```bash
./system-maintenance.sh
```

Features include:

- System updates and cleanup
- Disk space monitoring
- Docker resource cleanup
- Log rotation
- System health checks

## Requirements

- **Operating System**: Debian-based Linux distribution
- **Memory**: 2GB RAM minimum (4GB recommended)
- **Storage**: 10GB free space minimum
- **Network**: Internet connection for package downloads
- **Privileges**: sudo/root access

## Advanced Usage

### Custom Installation Paths

Most applications install to standard system locations:

- Applications: `/usr/local/bin`, `/opt/`
- Configuration: `~/.config/`
- Data: `~/.local/share/`

### Development Environment Setup

After installation, your development environment includes:

- Pre-configured shell (Zsh with optimizations)
- Essential development packages
- Language version managers (mise)
- Container orchestration tools
- Database clients and servers

## Contributing

We welcome contributions! See [CONTRIBUTIONS.MD](CONTRIBUTIONS.MD) for guidelines.

### Development Setup

```bash
git clone https://github.com/omnisetorg/omniset.git
cd omniset
./install.sh minimalist  # Use minimalist setup for development
```

## License

OmniSet is open-source software. See [LICENSE](LICENSE) for details.

## Acknowledgments

OmniSet is inspired by excellent projects in the development automation space:

- [Omakub](https://github.com/basecamp/omakub) - Basecamp's development environment
- [Tuffix](https://github.com/kevinwortman/tuffix) - Academic Linux development environment
- [node-box](https://github.com/ProfAvery/node-box) - Node.js development VM
