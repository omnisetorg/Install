#!/bin/bash
# OmniSet v2 - State Tracking
# lib/install/state.sh
#
# Persistent state for installed modules.
# Each installed module gets a shell-sourceable key=value file
# in $OMNISET_STATE_DIR (typically ~/.local/share/omniset/installed/).

set -euo pipefail

# ═══════════════════════════════════════════════════════════════
# State Directory Management
# ═══════════════════════════════════════════════════════════════

# Initialize state directory
state_init() {
    mkdir -p "${OMNISET_STATE_DIR}"
}

# ═══════════════════════════════════════════════════════════════
# State Record Operations
# ═══════════════════════════════════════════════════════════════

# Record a module installation
# Usage: state_record_install module_id category display_name method
state_record_install() {
    local module_id="$1"
    local category="${2:-unknown}"
    local display_name="${3:-$module_id}"
    local method="${4:-script}"

    # Validate module_id to prevent path traversal
    if ! validate_module_id "$module_id"; then
        print_error "state_record_install: invalid module ID: $module_id"
        return 1
    fi

    local state_file="${OMNISET_STATE_DIR}/${module_id}"
    local timestamp
    timestamp="$(date -u '+%Y-%m-%dT%H:%M:%S' 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S')"
    local arch="${ARCH:-unknown}"

    # Sanitize values — remove shell metacharacters
    category="${category//\"/}"
    category="${category//\`/}"
    category="${category//\$/}"
    display_name="${display_name//\"/}"
    display_name="${display_name//\`/}"
    display_name="${display_name//\$/}"
    method="${method//\"/}"
    method="${method//\`/}"
    method="${method//\$/}"

    cat > "$state_file" << EOF
MODULE_ID="$module_id"
CATEGORY="$category"
DISPLAY_NAME="$display_name"
INSTALL_METHOD="$method"
INSTALLED_AT="$timestamp"
ARCH="$arch"
EOF
}

# Remove a module's state record
# Usage: state_record_uninstall module_id
state_record_uninstall() {
    local module_id="$1"

    if ! validate_module_id "$module_id"; then
        print_error "state_record_uninstall: invalid module ID: $module_id"
        return 1
    fi

    local state_file="${OMNISET_STATE_DIR}/${module_id}"
    rm -f "$state_file"
}

# ═══════════════════════════════════════════════════════════════
# State Query Operations
# ═══════════════════════════════════════════════════════════════

# Check if a module has a state record
# Usage: state_is_installed module_id
state_is_installed() {
    local module_id="$1"

    if ! validate_module_id "$module_id"; then
        return 1
    fi

    [[ -f "${OMNISET_STATE_DIR}/${module_id}" ]]
}

# List all module IDs with state records
# Usage: state_list_installed
state_list_installed() {
    if [[ ! -d "${OMNISET_STATE_DIR}" ]]; then
        return 0
    fi

    local f
    for f in "${OMNISET_STATE_DIR}"/*; do
        [[ -f "$f" ]] || continue
        basename "$f"
    done
}

# Read a specific field from a module's state file
# Usage: state_get_field module_id field_name
state_get_field() {
    local module_id="$1"
    local field="$2"

    if ! validate_module_id "$module_id"; then
        return 1
    fi

    local state_file="${OMNISET_STATE_DIR}/${module_id}"
    if [[ ! -f "$state_file" ]]; then
        return 1
    fi

    # Extract value safely without sourcing the file
    local line
    line=$(grep "^${field}=" "$state_file" 2>/dev/null) || return 1
    # Strip key= prefix and surrounding quotes
    local value="${line#*=}"
    value="${value#\"}"
    value="${value%\"}"
    echo "$value"
}
