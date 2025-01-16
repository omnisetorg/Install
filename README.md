# X

X is a script that turns a fresh installation of a Debian-based Linux distribution), including Raspberry Pi OS, into a fully-configured, beautiful, and modern web development system with a single command. It eliminates the need to write bespoke configs for every essential tool just to get started or to be up on all the latest command-line tools.

## Supported Platforms

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

## Disclaimer

X is provided as-is without any warranty. Use it at your own risk. Always review the scripts before running them to ensure they meet your security and privacy requirements.

## License

X is open-source software licensed under the [ License](LICENSE).

---

Feel free to customize the README file further based on your specific project details, such as adding a logo, badges, or additional sections like contributing guidelines or troubleshooting tips.
