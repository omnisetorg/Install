#!/bin/bash
# Nginx Installation (Docker)
# modules/devops/nginx/install.sh

set -euo pipefail

ARCH="${1:-amd64}"
OPTIONS="${2:-}"

# Parse options
NGINX_VERSION="${OPTIONS:-latest}"
NGINX_HTTP_PORT="${NGINX_HTTP_PORT:-8080}"
NGINX_HTTPS_PORT="${NGINX_HTTPS_PORT:-8443}"

# Source library functions if available
if [[ -f "${OMNISET_LIB:-}/ui/print.sh" ]]; then
    source "${OMNISET_LIB}/ui/print.sh"
else
    print_step() { echo "==> $1"; }
    print_success() { echo "✓ $1"; }
    print_warning() { echo "⚠ $1"; }
    print_error() { echo "✗ $1" >&2; }
    print_bullet() { echo "  • $1"; }
fi

check_docker() {
    if ! command -v docker &>/dev/null; then
        print_error "Docker is required but not installed"
        print_bullet "Run: omniset install docker"
        exit 1
    fi
}

install_nginx() {
    print_step "Installing Nginx ${NGINX_VERSION} via Docker..."

    # Check if container exists
    if docker ps -a --format '{{.Names}}' | grep -q "^omniset-nginx$"; then
        print_warning "Nginx container already exists"

        if docker ps --format '{{.Names}}' | grep -q "^omniset-nginx$"; then
            print_bullet "Container is running"
        else
            print_bullet "Starting existing container..."
            docker start omniset-nginx
        fi
        return 0
    fi

    # Create directories for config and content
    mkdir -p ~/.local/share/omniset/nginx/conf.d
    mkdir -p ~/.local/share/omniset/nginx/html
    mkdir -p ~/.local/share/omniset/nginx/logs

    # Create default config
    cat > ~/.local/share/omniset/nginx/conf.d/default.conf <<'CONF'
server {
    listen 80;
    server_name localhost;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }
}
CONF

    # Create default index page
    cat > ~/.local/share/omniset/nginx/html/index.html <<'HTML'
<!DOCTYPE html>
<html><head><title>OmniSet Nginx</title></head>
<body><h1>Nginx is running via OmniSet</h1></body></html>
HTML

    # Run Nginx container
    docker run -d \
        --name omniset-nginx \
        --restart unless-stopped \
        -v ~/.local/share/omniset/nginx/conf.d:/etc/nginx/conf.d \
        -v ~/.local/share/omniset/nginx/html:/usr/share/nginx/html \
        -v ~/.local/share/omniset/nginx/logs:/var/log/nginx \
        -p "${NGINX_HTTP_PORT}:80" \
        -p "${NGINX_HTTPS_PORT}:443" \
        "nginx:${NGINX_VERSION}"

    print_success "Nginx installed"
}

main() {
    print_step "Installing Nginx for $ARCH"

    check_docker
    install_nginx

    echo ""
    echo "════════════════════════════════════════════"
    echo "Nginx Installation Complete"
    echo "════════════════════════════════════════════"

    print_success "Nginx ${NGINX_VERSION} running in Docker"

    echo ""
    print_bullet "HTTP:  http://localhost:${NGINX_HTTP_PORT}"
    print_bullet "HTTPS: https://localhost:${NGINX_HTTPS_PORT}"
    print_bullet "Config: ~/.local/share/omniset/nginx/conf.d/"
    print_bullet "Webroot: ~/.local/share/omniset/nginx/html/"
    echo ""
    print_bullet "Stop:    docker stop omniset-nginx"
    print_bullet "Start:   docker start omniset-nginx"
    print_bullet "Reload:  docker exec omniset-nginx nginx -s reload"
    print_bullet "Logs:    docker logs omniset-nginx"
}

main "$@"
