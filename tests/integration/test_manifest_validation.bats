#!/usr/bin/env bats
# Integration tests: validate all real module manifests

load "../helpers/test_helper"

setup() {
    setup_temp_dir
    setup_mock_bin
    disable_colors
    export OMNISET_MODULES="${PROJECT_ROOT}/modules"
}

teardown() {
    teardown_temp_dir
}

# Helper: find all manifest files
_get_all_manifests() {
    find "$OMNISET_MODULES" -name "manifest.yaml" -type f | sort
}

# ═══════════════════════════════════════════════════════════════
# YAML validity
# ═══════════════════════════════════════════════════════════════

@test "integration: all manifests are valid YAML" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi

    local failed=0
    local total=0

    while IFS= read -r manifest; do
        ((total++))
        if ! yq '.' "$manifest" &>/dev/null; then
            echo "INVALID YAML: $manifest" >&2
            ((failed++))
        fi
    done < <(_get_all_manifests)

    [[ $total -gt 0 ]]  # at least some manifests found
    [[ $failed -eq 0 ]]
}

# ═══════════════════════════════════════════════════════════════
# Required fields
# ═══════════════════════════════════════════════════════════════

@test "integration: all manifests have 'name' field" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi

    local failed=0
    while IFS= read -r manifest; do
        local name
        name=$(yq -r '.name // empty' "$manifest" 2>/dev/null)
        if [[ -z "$name" ]]; then
            echo "MISSING 'name': $manifest" >&2
            ((failed++))
        fi
    done < <(_get_all_manifests)

    [[ $failed -eq 0 ]]
}

@test "integration: all manifests have 'display_name' field" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi

    local failed=0
    while IFS= read -r manifest; do
        local display_name
        display_name=$(yq -r '.display_name // empty' "$manifest" 2>/dev/null)
        if [[ -z "$display_name" ]]; then
            echo "MISSING 'display_name': $manifest" >&2
            ((failed++))
        fi
    done < <(_get_all_manifests)

    [[ $failed -eq 0 ]]
}

@test "integration: all manifests have 'category' field" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi

    local failed=0
    while IFS= read -r manifest; do
        local category
        category=$(yq -r '.category // empty' "$manifest" 2>/dev/null)
        if [[ -z "$category" ]]; then
            echo "MISSING 'category': $manifest" >&2
            ((failed++))
        fi
    done < <(_get_all_manifests)

    [[ $failed -eq 0 ]]
}

@test "integration: all manifests have 'description' field" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi

    local failed=0
    while IFS= read -r manifest; do
        local description
        description=$(yq -r '.description // empty' "$manifest" 2>/dev/null)
        if [[ -z "$description" ]]; then
            echo "MISSING 'description': $manifest" >&2
            ((failed++))
        fi
    done < <(_get_all_manifests)

    [[ $failed -eq 0 ]]
}

# ═══════════════════════════════════════════════════════════════
# Architecture section
# ═══════════════════════════════════════════════════════════════

@test "integration: all manifests have architecture section" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi

    local failed=0
    while IFS= read -r manifest; do
        local has_arch
        has_arch=$(yq -r '.architecture // empty' "$manifest" 2>/dev/null)
        if [[ -z "$has_arch" || "$has_arch" == "null" ]]; then
            echo "MISSING 'architecture': $manifest" >&2
            ((failed++))
        fi
    done < <(_get_all_manifests)

    [[ $failed -eq 0 ]]
}

# ═══════════════════════════════════════════════════════════════
# Install methods
# ═══════════════════════════════════════════════════════════════

@test "integration: all manifests have install_methods with type" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi

    local failed=0
    while IFS= read -r manifest; do
        local methods_count
        methods_count=$(yq -r '.install_methods | length // 0' "$manifest" 2>/dev/null)
        if [[ "$methods_count" -eq 0 ]]; then
            echo "NO install_methods: $manifest" >&2
            ((failed++))
            continue
        fi

        # Check each method has a 'type'
        for ((i=0; i<methods_count; i++)); do
            local method_type
            method_type=$(yq -r ".install_methods[$i].type // empty" "$manifest" 2>/dev/null)
            if [[ -z "$method_type" ]]; then
                echo "MISSING 'type' in install_methods[$i]: $manifest" >&2
                ((failed++))
            fi
        done
    done < <(_get_all_manifests)

    [[ $failed -eq 0 ]]
}

# ═══════════════════════════════════════════════════════════════
# Provides section
# ═══════════════════════════════════════════════════════════════

@test "integration: all manifests have provides section" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi

    local failed=0
    while IFS= read -r manifest; do
        local has_provides
        has_provides=$(yq -r '.provides // empty' "$manifest" 2>/dev/null)
        if [[ -z "$has_provides" || "$has_provides" == "null" ]]; then
            echo "MISSING 'provides': $manifest" >&2
            ((failed++))
        fi
    done < <(_get_all_manifests)

    [[ $failed -eq 0 ]]
}

# ═══════════════════════════════════════════════════════════════
# Manifest count sanity
# ═══════════════════════════════════════════════════════════════

@test "integration: at least 30 manifests exist" {
    local count
    count=$(_get_all_manifests | wc -l | tr -d ' ')
    [[ $count -ge 30 ]]
}

@test "integration: manifest count matches module directory count" {
    local manifest_count dir_count
    manifest_count=$(_get_all_manifests | wc -l | tr -d ' ')
    # Count dirs that have a manifest
    dir_count=$(find "$OMNISET_MODULES" -name "manifest.yaml" -type f | wc -l | tr -d ' ')
    [[ "$manifest_count" -eq "$dir_count" ]]
}
