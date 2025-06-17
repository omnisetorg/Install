#!/bin/bash

# Development Language Installation Script
# Inspired by Omakub: https://github.com/basecamp/omakub/blob/master/install/terminal/select-dev-language.sh

set -euo pipefail

# Get architecture parameter
arch=${1:-$(dpkg --print-architecture)}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_error() {
    echo -e "${RED}Error: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check if mise is available
check_mise() {
    if ! command -v mise >/dev/null 2>&1; then
        print_error "mise is not installed. Please install mise first."
        echo "Run: ./install/development/mise.sh $arch"
        exit 1
    fi
}

# Check if gum is available
check_gum() {
    if ! command -v gum >/dev/null 2>&1; then
        print_warning "gum not found. Installing gum for better interface..."
        sudo apt update
        echo 'deb [trusted=yes] https://repo.charm.sh/apt/ /' | sudo tee /etc/apt/sources.list.d/charm.list
        sudo apt update && sudo apt install -y gum
    fi
}

# Install Node.js
install_nodejs() {
    print_warning "Installing Node.js LTS..."
    mise use --global node@lts
    
    # Install common global packages
    mise x node -- npm install -g \
        yarn \
        pnpm \
        typescript \
        @vue/cli \
        @angular/cli \
        create-react-app \
        nodemon \
        pm2
    
    print_success "Node.js LTS installed with common packages"
}

# Install Go
install_go() {
    print_warning "Installing Go latest..."
    mise use --global go@latest
    
    # Set up Go workspace
    mkdir -p ~/go/{bin,src,pkg}
    echo 'export GOPATH=$HOME/go' >> ~/.bashrc
    echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc
    
    print_success "Go latest installed"
}

# Install PHP
install_php() {
    print_warning "Installing PHP 8.4..."
    
    # Add Ondrej's PPA for latest PHP
    sudo add-apt-repository -y ppa:ondrej/php
    sudo apt update
    
    # Install PHP and common extensions
    sudo apt install -y \
        php8.4 \
        php8.4-cli \
        php8.4-common \
        php8.4-curl \
        php8.4-apcu \
        php8.4-intl \
        php8.4-mbstring \
        php8.4-opcache \
        php8.4-pgsql \
        php8.4-mysql \
        php8.4-sqlite3 \
        php8.4-redis \
        php8.4-xml \
        php8.4-zip \
        php8.4-gd \
        php8.4-bcmath \
        php8.4-fpm
    
    # Install Composer
    print_warning "Installing Composer..."
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    
    # Verify installer (optional but recommended)
    HASH="$(wget -q -O - https://composer.github.io/installer.sig)"
    php -r "if (hash_file('sha384', 'composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
    
    php composer-setup.php --quiet && sudo mv composer.phar /usr/local/bin/composer
    rm -f composer-setup.php
    
    print_success "PHP 8.4 and Composer installed"
}

# Install Python
install_python() {
    print_warning "Installing Python latest..."
    mise use --global python@latest
    
    # Install common Python packages
    mise x python -- pip install --upgrade \
        pip \
        virtualenv \
        pipenv \
        poetry \
        jupyter \
        requests \
        flask \
        django \
        fastapi \
        numpy \
        pandas
    
    print_success "Python latest installed with common packages"
}

# Install Ruby
install_ruby() {
    print_warning "Installing Ruby 3.3..."
    mise use --global ruby@3.3
    
    # Install Rails and common gems
    mise x ruby -- gem install \
        rails \
        bundler \
        rake \
        rspec \
        rubocop \
        --no-document
    
    print_success "Ruby 3.3 and Rails installed"
}

# Install Elixir
install_elixir() {
    print_warning "Installing Erlang and Elixir..."
    mise use --global erlang@latest
    mise use --global elixir@latest
    
    # Install Hex package manager and Phoenix
    mise x elixir -- mix local.hex --force
    mise x elixir -- mix local.rebar --force
    mise x elixir -- mix archive.install hex phx_new --force
    
    print_success "Elixir and Phoenix installed"
}

# Install Rust
install_rust() {
    print_warning "Installing Rust..."
    
    # Install Rust via rustup
    if ! command -v rustup >/dev/null 2>&1; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source ~/.cargo/env
    fi
    
    # Install common tools
    ~/.cargo/bin/cargo install \
        cargo-edit \
        cargo-watch \
        cargo-audit \
        ripgrep \
        fd-find \
        bat \
        exa
    
    print_success "Rust and common tools installed"
}

# Install Java
install_java() {
    print_warning "Installing Java latest..."
    mise use --global java@latest
    
    # Install Maven and Gradle
    sudo apt install -y maven gradle
    
    print_success "Java latest with Maven and Gradle installed"
}

# Main installation function
main() {
    echo "Setting up development languages..."
    
    # Check dependencies
    check_mise
    check_gum
    
    # Define available languages
    AVAILABLE_LANGUAGES=(
        "Node.js"
        "Go" 
        "PHP"
        "Python"
        "Ruby"
        "Elixir"
        "Rust"
        "Java"
    )
    
    # Let user select languages
    if command -v gum >/dev/null 2>&1; then
        languages=$(gum choose "${AVAILABLE_LANGUAGES[@]}" \
            --no-limit \
            --height 10 \
            --header "Select programming languages to install")
    else
        # Fallback if gum is not available
        echo "Available languages:"
        for i in "${!AVAILABLE_LANGUAGES[@]}"; do
            echo "$((i+1))) ${AVAILABLE_LANGUAGES[i]}"
        done
        echo "Enter numbers separated by spaces (e.g., 1 3 5):"
        read -r selection
        
        languages=""
        for num in $selection; do
            if [ "$num" -ge 1 ] && [ "$num" -le ${#AVAILABLE_LANGUAGES[@]} ]; then
                languages="${languages} ${AVAILABLE_LANGUAGES[$((num-1))]}"
            fi
        done
    fi
    
    # Install selected languages
    if [[ -n "$languages" ]]; then
        echo "Installing selected languages: $languages"
        
        for language in $languages; do
            echo ""
            case $language in
                "Node.js")
                    install_nodejs
                    ;;
                "Go")
                    install_go
                    ;;
                "PHP")
                    install_php
                    ;;
                "Python")
                    install_python
                    ;;
                "Ruby")
                    install_ruby
                    ;;
                "Elixir")
                    install_elixir
                    ;;
                "Rust")
                    install_rust
                    ;;
                "Java")
                    install_java
                    ;;
                *)
                    print_error "Unknown language: $language"
                    ;;
            esac
        done
        
        echo ""
        print_success "Language installation completed!"
        echo ""
        echo "Installed languages:"
        mise list --installed
        
        echo ""
        echo "To use the installed languages, restart your shell or run:"
        echo "source ~/.bashrc"
        
    else
        echo "No languages selected. Exiting."
    fi
}

# Run main function
main "$@"