# OmniSet

!!! This project is in BETA. Please use with caution. !!!

OmniSet is a script that turns a fresh installation of a Debian-based Linux distribution (including Raspberry Pi OS) into a fully-configured, beautiful, and modern web development system with a single command. It eliminates the need to write bespoke configs for every essential tool just to get started or to be up on all the latest command-line tools.

## "Supported" Platforms

OmniSet works on most Debian-based Linux distributions, including:

- Ubuntu
- Debian
- Raspberry Pi OS (formerly Raspbian)
- Linux Mint
- Elementary OS
- Pop!_OS
- Zorin OS

The script automatically detects the CPU architecture (x86_64, armhf, or arm64) and installs the appropriate packages accordingly.

## Usage

To use OmniSet, follow these steps:

1. Run the following command in your terminal:

   ```bash
   wget -qO- <https://omniset.org/install> | bash
   ```

The script will update the system packages, install the required tools and applications, and configure the development environment. Once the setup is complete, you'll have a modern and beautiful web development system ready to use.


## Disclaimer

OmniSet is provided as-is without any warranty. Use it at your own risk. Always review the scripts before running them to ensure they meet your security and privacy requirements.

## Acknowledgments

OmniSet draws inspiration from several excellent projects in the development environment automation space:

- [Tuffix](https://github.com/kevinwortman/tuffix) - California State University Fullerton's Linux development environment
- [node-box](https://github.com/ProfAvery/node-box) - CPSC 473: Vagrant VM for Node.js development
- [Omakub](https://github.com/basecamp/omakub) - Basecamp's approach to development environment setup
- And many other open-source projects that have paved the way for automated development environment setup

We're grateful to these projects and their maintainers for sharing their work with the community and inspiring better development workflows.

## License

OmniSet is open-source software licensed under the [License](LICENSE).