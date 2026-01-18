#!/bin/bash
# OmniSet v2 - Module System
# lib/install/modules.sh

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

# Get module directory
get_module_dir() {
    local module_id="$1"

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
    local force="${2:-false}"
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
    local deps
    deps=$(yq -r '.requirements.dependencies[]? // empty' "$manifest" 2>/dev/null)
    if [[ -n "$deps" ]]; then
        print_bullet "Installing dependencies..."
        pkg_install $deps || true
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
                local packages
                packages=$(yq -r ".install_methods[$i].packages[]" "$manifest" 2>/dev/null)
                if [[ -n "$packages" ]] && pkg_install $packages; then
                    return 0
                fi
                ;;

            deb)
                local url
                url=$(yq -r ".install_methods[$i].url" "$manifest")
                local temp_deb="/tmp/${module_id}.deb"
                if curl -fsSL -o "$temp_deb" "$url" && install_deb "$temp_deb"; then
                    rm -f "$temp_deb"
                    return 0
                fi
                rm -f "$temp_deb"
                ;;

            apt_repo)
                local key_url repo key_name packages
                key_url=$(yq -r ".install_methods[$i].key_url // empty" "$manifest")
                repo=$(yq -r ".install_methods[$i].repo" "$manifest")
                key_name=$(yq -r ".install_methods[$i].key_name // \"$module_id\"" "$manifest")
                packages=$(yq -r ".install_methods[$i].packages[]" "$manifest" 2>/dev/null)

                if add_apt_repo "$repo" "$key_url" "$key_name"; then
                    if [[ -n "$packages" ]] && pkg_install $packages; then
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
                if curl -fsSL "$script_url" | bash; then
                    return 0
                fi
                ;;
        esac
    done

    return 1
}

# Install multiple modules
install_modules() {
    local -a modules=("$@")
    local total=${#modules[@]}
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
    local packages
    packages=$(get_module_info "$module_id" "provides.packages" "")
    if [[ -n "$packages" ]]; then
        pkg_remove $packages
    fi

    return 0
}
