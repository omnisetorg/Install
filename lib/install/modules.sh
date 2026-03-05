#!/bin/bash
# OmniSet v2 - Module System
# lib/install/modules.sh

set -euo pipefail

# Module registry
declare -A MODULE_REGISTRY
declare -a INSTALLED_MODULES=()
declare -a FAILED_MODULES=()

# ═══════════════════════════════════════════════════════════════
# Module Discovery
# ═══════════════════════════════════════════════════════════════

# Discover all available modules
discover_modules() {
    local modules_dir="${OMNISET_MODULES}"

    for category_dir in "$modules_dir"/*/; do
        [[ -d "$category_dir" ]] || continue
        local category=$(basename "$category_dir")

        for module_dir in "$category_dir"/*/; do
            [[ -d "$module_dir" ]] || continue

            local module_id=$(basename "$module_dir")
            local manifest="${module_dir}/manifest.yaml"

            if [[ -f "$manifest" ]]; then
                MODULE_REGISTRY["$module_id"]="$module_dir"
            fi
        done
    done
}

# List all available modules
list_modules() {
    local format="${1:-table}"
    local filter_category="${2:-}"

    discover_modules

    case "$format" in
        table)
            printf "%-20s %-15s %-40s %s\n" "MODULE" "CATEGORY" "DESCRIPTION" "SIZE"
            print_divider
            ;;
        json)
            echo "["
            ;;
    esac

    local first=true
    for module_id in "${!MODULE_REGISTRY[@]}"; do
        local module_dir="${MODULE_REGISTRY[$module_id]}"
        local manifest="${module_dir}/manifest.yaml"

        # Get module info
        local name=$(yq -r '.name // "'"$module_id"'"' "$manifest" 2>/dev/null || echo "$module_id")
        local category=$(yq -r '.category // "unknown"' "$manifest" 2>/dev/null || echo "unknown")
        local description=$(yq -r '.description // ""' "$manifest" 2>/dev/null || echo "")
        local size=$(yq -r '.size_mb // 0' "$manifest" 2>/dev/null || echo "0")

        # Apply filter
        if [[ -n "$filter_category" && "$category" != "$filter_category" ]]; then
            continue
        fi

        case "$format" in
            table)
                printf "%-20s %-15s %-40s %sMB\n" "$module_id" "$category" "${description:0:40}" "$size"
                ;;
            json)
                [[ "$first" != "true" ]] && echo ","
                first=false
                echo "  {\"id\": \"$module_id\", \"name\": \"$name\", \"category\": \"$category\", \"description\": \"$description\", \"size_mb\": $size}"
                ;;
            simple)
                echo "$module_id"
                ;;
        esac
    done

    [[ "$format" == "json" ]] && echo "]"
}

# ═══════════════════════════════════════════════════════════════
# Module Information
# ═══════════════════════════════════════════════════════════════

# Validate module ID (alphanumeric, hyphens, underscores only)
validate_module_id() {
    local id="$1"
    [[ "$id" =~ ^[a-zA-Z0-9_-]+$ ]] || return 1
}

# Get module directory
get_module_dir() {
    local module_id="$1"

    # Validate module ID before filesystem operations
    if ! validate_module_id "$module_id"; then
        print_error "Invalid module ID: $module_id (only alphanumeric, hyphens, underscores allowed)"
        return 1
    fi

    # Check registry first
    if [[ -n "${MODULE_REGISTRY[$module_id]:-}" ]]; then
        echo "${MODULE_REGISTRY[$module_id]}"
        return 0
    fi

    # Search in modules directory
    for category_dir in "${OMNISET_MODULES}"/*/; do
        local module_dir="${category_dir}${module_id}"
        if [[ -d "$module_dir" ]]; then
            echo "$module_dir"
            return 0
        fi
    done

    return 1
}

# Get module manifest value
get_module_info() {
    local module_id="$1"
    local key="$2"
    local default="${3:-}"

    local module_dir
    module_dir=$(get_module_dir "$module_id") || return 1

    local manifest="${module_dir}/manifest.yaml"
    if [[ ! -f "$manifest" ]]; then
        echo "$default"
        return 1
    fi

    local value
    value=$(yq -r ".$key // null" "$manifest" 2>/dev/null)

    if [[ "$value" == "null" || -z "$value" ]]; then
        echo "$default"
    else
        echo "$value"
    fi
}

# Check if module supports current architecture
module_supports_arch() {
    local module_id="$1"
    local arch="${ARCH:-amd64}"

    local supported
    supported=$(get_module_info "$module_id" "architecture.$arch" "true")

    [[ "$supported" == "true" ]]
}

# Check if module is installed
is_module_installed() {
    local module_id="$1"
    local module_dir
    module_dir=$(get_module_dir "$module_id") || return 1

    local manifest="${module_dir}/manifest.yaml"

    # Check by commands
    local commands
    commands=$(yq -r '.provides.commands[]? // empty' "$manifest" 2>/dev/null)

    for cmd in $commands; do
        if command -v "$cmd" &>/dev/null; then
            return 0
        fi
    done

    # Check by package
    local packages
    packages=$(yq -r '.provides.packages[]? // empty' "$manifest" 2>/dev/null)

    for pkg in $packages; do
        if pkg_is_installed "$pkg"; then
            return 0
        fi
    done

    return 1
}

# ═══════════════════════════════════════════════════════════════
# Module Installation
# ═══════════════════════════════════════════════════════════════

# Install a single module
install_module() {
    local module_id="$1"
    local force="${2:-${OMNISET_FORCE_INSTALL:-false}}"
    local options="${3:-}"

    local module_dir
    module_dir=$(get_module_dir "$module_id")
    if [[ $? -ne 0 ]]; then
        print_error "Module not found: $module_id"
        FAILED_MODULES+=("$module_id")
        return 1
    fi

    local manifest="${module_dir}/manifest.yaml"
    local install_script="${module_dir}/install.sh"

    # Get module info
    local display_name
    display_name=$(get_module_info "$module_id" "display_name" "$module_id")

    print_step "Installing $display_name..."

    # Check if already installed
    if [[ "$force" != "true" ]] && is_module_installed "$module_id"; then
        print_info "$display_name is already installed"
        return 0
    fi

    # Check architecture support
    if ! module_supports_arch "$module_id"; then
        print_warning "$display_name doesn't support $ARCH architecture"
        FAILED_MODULES+=("$module_id")
        return 1
    fi

    # Check disk space
    local required_mb
    required_mb=$(get_module_info "$module_id" "requirements.disk_mb" "100")
    if [[ "$DISK_AVAILABLE_MB" -lt "$required_mb" ]]; then
        print_error "Insufficient disk space for $display_name (need ${required_mb}MB, have ${DISK_AVAILABLE_MB}MB)"
        FAILED_MODULES+=("$module_id")
        return 1
    fi

    # Install dependencies (system packages)
    local -a dep_array=()
    while IFS= read -r dep; do
        [[ -n "$dep" ]] && dep_array+=("$dep")
    done < <(yq -r '.requirements.dependencies[]? // empty' "$manifest" 2>/dev/null)
    if [[ ${#dep_array[@]} -gt 0 ]]; then
        print_bullet "Installing dependencies..."
        if ! pkg_install "${dep_array[@]}"; then
            print_error "Failed to install dependencies for $module_id"
            FAILED_MODULES+=("$module_id")
            return 1
        fi
    fi

    # Run install script if exists
    if [[ -x "$install_script" ]]; then
        print_bullet "Running install script..."
        if bash "$install_script" "$ARCH" "$options"; then
            print_success "$display_name installed successfully"
            INSTALLED_MODULES+=("$module_id")
            return 0
        else
            print_error "Failed to install $display_name"
            FAILED_MODULES+=("$module_id")
            return 1
        fi
    fi

    # Auto-install based on manifest
    if auto_install_module "$module_id" "$manifest"; then
        print_success "$display_name installed successfully"
        INSTALLED_MODULES+=("$module_id")
        return 0
    else
        print_error "Failed to install $display_name"
        FAILED_MODULES+=("$module_id")
        return 1
    fi
}

# Auto-install based on manifest install_methods
auto_install_module() {
    local module_id="$1"
    local manifest="$2"

    # Get install methods sorted by priority
    local methods_count
    methods_count=$(yq -r '.install_methods | length' "$manifest" 2>/dev/null || echo "0")

    if [[ "$methods_count" -eq 0 ]]; then
        print_error "No install methods defined for $module_id"
        return 1
    fi

    # Try each method in order
    for ((i=0; i<methods_count; i++)); do
        local method_type
        method_type=$(yq -r ".install_methods[$i].type" "$manifest")

        print_bullet "Trying install method: $method_type"

        case "$method_type" in
            apt)
                local -a pkg_array=()
                while IFS= read -r pkg; do
                    [[ -n "$pkg" ]] && pkg_array+=("$pkg")
                done < <(yq -r ".install_methods[$i].packages[]" "$manifest" 2>/dev/null)
                if [[ ${#pkg_array[@]} -gt 0 ]] && pkg_install "${pkg_array[@]}"; then
                    return 0
                fi
                ;;

            deb)
                local url
                url=$(yq -r ".install_methods[$i].url" "$manifest")
                local temp_deb
                temp_deb=$(omniset_mktemp --suffix=.deb)
                if curl -fsSL --connect-timeout 15 --max-time 300 --retry 3 --retry-delay 2 -o "$temp_deb" "$url" && install_deb "$temp_deb"; then
                    rm -f "$temp_deb"
                    return 0
                fi
                rm -f "$temp_deb"
                ;;

            apt_repo)
                local key_url repo key_name
                key_url=$(yq -r ".install_methods[$i].key_url // empty" "$manifest")
                repo=$(yq -r ".install_methods[$i].repo" "$manifest")
                key_name=$(yq -r ".install_methods[$i].key_name // \"$module_id\"" "$manifest")

                local -a repo_pkg_array=()
                while IFS= read -r pkg; do
                    [[ -n "$pkg" ]] && repo_pkg_array+=("$pkg")
                done < <(yq -r ".install_methods[$i].packages[]" "$manifest" 2>/dev/null)

                if add_apt_repo "$repo" "$key_url" "$key_name"; then
                    if [[ ${#repo_pkg_array[@]} -gt 0 ]] && pkg_install "${repo_pkg_array[@]}"; then
                        return 0
                    fi
                fi
                ;;

            flatpak)
                local app_id
                app_id=$(yq -r ".install_methods[$i].id" "$manifest")
                if install_flatpak "$app_id"; then
                    return 0
                fi
                ;;

            snap)
                local snap_name flags
                snap_name=$(yq -r ".install_methods[$i].name" "$manifest")
                flags=$(yq -r ".install_methods[$i].flags // empty" "$manifest")
                if install_snap "$snap_name" "$flags"; then
                    return 0
                fi
                ;;

            cargo)
                local crate
                crate=$(yq -r ".install_methods[$i].crate" "$manifest")
                if install_cargo "$crate"; then
                    return 0
                fi
                ;;

            script)
                local script_url
                script_url=$(yq -r ".install_methods[$i].url" "$manifest")

                # Security: Download script first for inspection
                local temp_script
                temp_script=$(omniset_mktemp --suffix=.sh)

                print_warning "This install method downloads and executes a script from:"
                print_bullet "$script_url"

                if ! curl -fsSL --connect-timeout 15 --max-time 300 --retry 3 --retry-delay 2 "$script_url" -o "$temp_script"; then
                    print_error "Failed to download install script"
                    rm -f "$temp_script"
                    continue
                fi

                # Show script hash for verification
                local script_hash=$(sha256sum "$temp_script" 2>/dev/null | cut -d' ' -f1 || md5sum "$temp_script" | cut -d' ' -f1)
                print_info "Script SHA256: ${script_hash:0:16}..."

                # Check for common trusted sources
                local trusted=false
                case "$script_url" in
                    https://get.docker.com*|https://raw.githubusercontent.com/nvm-sh/*|https://sh.rustup.rs*)
                        trusted=true
                        ;;
                esac

                if [[ "$trusted" != "true" ]] && [[ "${OMNISET_TRUST_SCRIPTS:-false}" != "true" ]]; then
                    print_confirm "Execute this script? (inspect: cat $temp_script)"
                    read -r confirm
                    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                        print_info "Skipping script execution"
                        rm -f "$temp_script"
                        continue
                    fi
                fi

                if bash "$temp_script"; then
                    rm -f "$temp_script"
                    return 0
                fi
                rm -f "$temp_script"
                ;;

            docker)
                # Docker-based installation (for databases, services, etc.)
                local image container_name
                image=$(yq -r ".install_methods[$i].image" "$manifest")
                container_name=$(yq -r ".install_methods[$i].container_name // \"$module_id\"" "$manifest")

                # Check if Docker is available
                if ! command -v docker &>/dev/null; then
                    print_warning "Docker is not installed. Installing Docker first..."
                    install_module "docker" || {
                        print_error "Failed to install Docker"
                        continue
                    }
                fi

                # Check if Docker daemon is running
                if ! docker info &>/dev/null; then
                    print_error "Docker daemon is not running"
                    print_info "Start Docker with: sudo systemctl start docker"
                    continue
                fi

                print_step "Pulling Docker image: $image"
                if ! docker pull "$image"; then
                    print_error "Failed to pull Docker image: $image"
                    continue
                fi

                # Build docker run command using safe array
                local -a docker_args=("run" "-d" "--name" "$container_name" "--restart" "unless-stopped")

                # Add ports
                while IFS= read -r port; do
                    [[ -n "$port" ]] && docker_args+=("-p" "$port")
                done < <(yq -r ".install_methods[$i].ports[]? // empty" "$manifest" 2>/dev/null)

                # Add volumes
                while IFS= read -r vol; do
                    if [[ -n "$vol" ]]; then
                        # Create host directory if needed
                        local host_path="${vol%%:*}"
                        if [[ "$host_path" == /* ]]; then
                            sudo mkdir -p "$host_path"
                        fi
                        docker_args+=("-v" "$vol")
                    fi
                done < <(yq -r ".install_methods[$i].volumes[]? // empty" "$manifest" 2>/dev/null)

                # Add environment variables (with auto-generated passwords)
                while IFS= read -r line; do
                    if [[ -n "$line" ]]; then
                        local env_key="${line%%=*}"
                        local env_value="${line#*=}"
                        if [[ "$env_value" == "__GENERATE__" ]]; then
                            env_value=$(head -c 16 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 16)
                            print_info "Generated password for $env_key: $env_value"
                        fi
                        docker_args+=("-e" "${env_key}=${env_value}")
                    fi
                done < <(yq -r ".install_methods[$i].environment | to_entries[]? | .key + \"=\" + .value" "$manifest" 2>/dev/null)

                docker_args+=("$image")

                # Remove existing container if exists
                if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
                    print_info "Removing existing container: $container_name"
                    docker stop "$container_name" 2>/dev/null || true
                    docker rm "$container_name" 2>/dev/null || true
                fi

                print_step "Starting container: $container_name"
                if docker "${docker_args[@]}"; then
                    print_success "Container $container_name started successfully"

                    # Create convenience wrapper script
                    local wrapper_script="/usr/local/bin/${module_id}-docker"
                    cat << WRAPPER | sudo tee "$wrapper_script" > /dev/null
#!/bin/bash
# OmniSet Docker wrapper for $module_id
docker exec -it "$container_name" "\$@"
WRAPPER
                    sudo chmod +x "$wrapper_script"

                    return 0
                else
                    print_error "Failed to start container"
                    continue
                fi
                ;;

            appimage)
                # AppImage installation
                local url app_name
                url=$(yq -r ".install_methods[$i].url" "$manifest")
                app_name=$(yq -r ".install_methods[$i].name // \"$module_id\"" "$manifest")

                local appimage_dir="$HOME/.local/bin"
                local appimage_path="$appimage_dir/$app_name.AppImage"

                mkdir -p "$appimage_dir"

                print_step "Downloading AppImage: $app_name"
                if curl -fsSL --connect-timeout 15 --max-time 300 --retry 3 --retry-delay 2 -o "$appimage_path" "$url"; then
                    chmod +x "$appimage_path"

                    # Create symlink
                    ln -sf "$appimage_path" "$appimage_dir/$app_name"

                    # Add to PATH if not already
                    if [[ ":$PATH:" != *":$appimage_dir:"* ]]; then
                        echo "export PATH=\"\$PATH:$appimage_dir\"" >> "$HOME/.bashrc"
                        print_info "Added $appimage_dir to PATH in .bashrc"
                    fi

                    print_success "AppImage installed: $appimage_path"
                    return 0
                fi
                ;;

            binary)
                # Direct binary download
                local url bin_name install_path
                url=$(yq -r ".install_methods[$i].url" "$manifest")
                bin_name=$(yq -r ".install_methods[$i].name // \"$module_id\"" "$manifest")
                install_path=$(yq -r ".install_methods[$i].install_path // \"/usr/local/bin\"" "$manifest")

                local temp_file
                temp_file=$(omniset_mktemp)

                print_step "Downloading binary: $bin_name"
                if curl -fsSL --connect-timeout 15 --max-time 300 --retry 3 --retry-delay 2 -o "$temp_file" "$url"; then
                    chmod +x "$temp_file"

                    # Handle archives
                    local temp_extract_dir
                    case "$url" in
                        *.tar.gz|*.tgz)
                            temp_extract_dir=$(omniset_mktemp -d)
                            tar -xzf "$temp_file" -C "$temp_extract_dir"
                            local extracted
                            extracted=$(find "$temp_extract_dir" -maxdepth 2 -name "$bin_name" -type f 2>/dev/null | head -1)
                            if [[ -n "$extracted" ]]; then
                                sudo mv "$extracted" "$install_path/$bin_name"
                            fi
                            rm -rf "$temp_extract_dir"
                            ;;
                        *.zip)
                            temp_extract_dir=$(omniset_mktemp -d)
                            unzip -o "$temp_file" -d "$temp_extract_dir"
                            local extracted
                            extracted=$(find "$temp_extract_dir" -maxdepth 2 -name "$bin_name" -type f 2>/dev/null | head -1)
                            if [[ -n "$extracted" ]]; then
                                sudo mv "$extracted" "$install_path/$bin_name"
                            fi
                            rm -rf "$temp_extract_dir"
                            ;;
                        *)
                            sudo mv "$temp_file" "$install_path/$bin_name"
                            ;;
                    esac

                    sudo chmod +x "$install_path/$bin_name"
                    print_success "Binary installed: $install_path/$bin_name"
                    rm -f "$temp_file"
                    return 0
                fi
                rm -f "$temp_file"
                ;;
        esac
    done

    return 1
}

# Install multiple modules
install_modules() {
    local parallel="${OMNISET_PARALLEL:-false}"
    local -a modules=("$@")
    local total=${#modules[@]}

    if [[ "$parallel" == "true" && $total -gt 1 ]]; then
        install_modules_parallel "${modules[@]}"
        return $?
    fi

    local current=0

    print_header "Installing ${total} modules"

    for module_id in "${modules[@]}"; do
        ((current++))
        print_step "[$current/$total] $module_id"
        install_module "$module_id"
    done

    # Summary
    print_header "Installation Summary"
    print_kv "Total" "$total"
    print_kv "Installed" "${#INSTALLED_MODULES[@]}"
    print_kv "Failed" "${#FAILED_MODULES[@]}"

    if [[ ${#FAILED_MODULES[@]} -gt 0 ]]; then
        print_warning "Failed modules: ${FAILED_MODULES[*]}"
        return 1
    fi

    return 0
}

# Install modules in parallel using background jobs
install_modules_parallel() {
    local -a modules=("$@")
    local total=${#modules[@]}
    local results_dir
    results_dir=$(omniset_mktemp -d)
    local -a pids=()

    print_header "Installing ${total} modules (parallel)"

    for module_id in "${modules[@]}"; do
        (
            if install_module "$module_id"; then
                echo "ok" > "$results_dir/$module_id"
            else
                echo "fail" > "$results_dir/$module_id"
            fi
        ) &
        pids+=($!)
    done

    # Wait for all jobs
    for pid in "${pids[@]}"; do
        wait "$pid" 2>/dev/null || true
    done

    # Collect results
    for module_id in "${modules[@]}"; do
        local result_file="$results_dir/$module_id"
        if [[ -f "$result_file" ]] && [[ "$(cat "$result_file")" == "ok" ]]; then
            INSTALLED_MODULES+=("$module_id")
        else
            FAILED_MODULES+=("$module_id")
        fi
    done

    rm -rf "$results_dir"

    # Summary
    print_header "Installation Summary"
    print_kv "Total" "$total"
    print_kv "Installed" "${#INSTALLED_MODULES[@]}"
    print_kv "Failed" "${#FAILED_MODULES[@]}"

    if [[ ${#FAILED_MODULES[@]} -gt 0 ]]; then
        print_warning "Failed modules: ${FAILED_MODULES[*]}"
        return 1
    fi
    return 0
}

# ═══════════════════════════════════════════════════════════════
# Module Uninstallation
# ═══════════════════════════════════════════════════════════════

uninstall_module() {
    local module_id="$1"

    local module_dir
    module_dir=$(get_module_dir "$module_id") || {
        print_error "Module not found: $module_id"
        return 1
    }

    local uninstall_script="${module_dir}/uninstall.sh"
    local display_name
    display_name=$(get_module_info "$module_id" "display_name" "$module_id")

    print_step "Uninstalling $display_name..."

    if [[ -x "$uninstall_script" ]]; then
        if bash "$uninstall_script"; then
            print_success "$display_name uninstalled"
            return 0
        else
            print_error "Failed to uninstall $display_name"
            return 1
        fi
    fi

    # Fallback: try to remove packages
    local -a rm_pkg_array=()
    while IFS= read -r pkg; do
        [[ -n "$pkg" ]] && rm_pkg_array+=("$pkg")
    done < <(yq -r '.provides.packages[]? // empty' "$(get_module_dir "$module_id")/manifest.yaml" 2>/dev/null)
    if [[ ${#rm_pkg_array[@]} -gt 0 ]]; then
        pkg_remove "${rm_pkg_array[@]}"
    fi

    return 0
}
