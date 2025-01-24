# X

![Installation Scripts](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/{username}/{repo}/main/install_badge.json)
![Uninstallation Scripts](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/{username}/{repo}/main/uninstall_badge.json)
![Utility Scripts](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/{username}/{repo}/main/utility_badge.json)

X is a script that turns a fresh installation of a Debian-based Linux distribution), including Raspberry Pi OS, into a fully-configured, beautiful, and modern web development system with a single command. It eliminates the need to write bespoke configs for every essential tool just to get started or to be up on all the latest command-line tools.

## "Supported" Platforms

X works on most Debian-based Linux distributions, including:

- Ubuntu
- Debian
- Raspberry Pi OS (formerly Raspbian)
- Linux Mint
- Elementary OS
- Pop!_OS
- Zorin OS

The script automatically detects the CPU architecture (x86_64, armhf, or arm64) and installs the appropriate packages accordingly.

## Features

X installs and configures the following tools and applications:

- Essential tools (Git, Zsh, curl, wget, unzip, build-essential)
- Node.js and npm
- Visual Studio Code
- Google Chrome
- Postman
- MongoDB
- Docker
- Oh My Zsh with Powerlevel10k theme

## Usage

To use X, follow these steps:

1. Clone the X repository:

   ```bash
   git clone https://github.com/yourusername/X.git
   cd X
   ```

2. Make the setup script executable:

   ```bash
   chmod +x setup.sh
   ```

3. Run the setup script:

   ```bash
   ./setup.sh
   ```

The script will update the system packages, install the required tools and applications, and configure the development environment. Once the setup is complete, you'll have a modern and beautiful web development system ready to use.

## Customization

X is an opinionated take on what Linux can be at its best for web development. However, you can easily customize the script to suit your preferences and requirements. Each application has its own installation script in the `apps` directory, so you can add, remove, or modify the scripts as needed.

## Development Stacks

X provides specialized installation stacks for different types of developers. You can install one or multiple stacks based on your needs:

- PHP Stack (PHP 8.4, MariaDB, Composer)
- Node.js Stack (Node.js LTS, MongoDB, TypeScript)
- Python Stack (Python 3, PostgreSQL, Development Tools)
- Java Stack (OpenJDK 17, Maven, Gradle)

To install stacks, use:

```bash
./setup_stack.sh [stack1] [stack2] ...
```

## Application compatibility

Latest script scan results can be found in the [Actions tab](../../actions/workflows/check-scripts.yml).

## Disclaimer

X is provided as-is without any warranty. Use it at your own risk. Always review the scripts before running them to ensure they meet your security and privacy requirements.

## Acknowledgments

X draws inspiration from several excellent projects in the development environment automation space:

- [Tuffix](https://github.com/kevinwortman/tuffix) - California State University Fullerton's Linux development environment
- [node-box](https://github.com/ProfAvery/node-box) - CPSC 473: Vagrant VM for Node.js development
- [Omakub](https://github.com/basecamp/omakub) - Basecamp's approach to development environment setup
- And many other open-source projects that have paved the way for automated development environment setup

We're grateful to these projects and their maintainers for sharing their work with the community and inspiring better development workflows.

## License

X is open-source software licensed under the [License](LICENSE).

---

Feel free to customize the README file further based on your specific project details, such as adding a logo, badges, or additional sections like contributing guidelines or troubleshooting tips.
