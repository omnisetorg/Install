#!/usr/bin/env bats
# Integration tests: validate module directory structure

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

# Helper: get all module directories (those with manifest.yaml)
_get_all_module_dirs() {
    find "$OMNISET_MODULES" -name "manifest.yaml" -type f -exec dirname {} \; | sort
}

# ═══════════════════════════════════════════════════════════════
# Directory structure
# ═══════════════════════════════════════════════════════════════

@test "structure: all module dirs have manifest.yaml" {
    # By definition from our find, this is always true.
    # What we actually test: every dir at depth 2 that has an install.sh also has manifest.yaml
    local failed=0
    while IFS= read -r dir; do
        if [[ -f "$dir/install.sh" ]] && [[ ! -f "$dir/manifest.yaml" ]]; then
            echo "MISSING manifest.yaml: $dir" >&2
            ((failed++))
        fi
    done < <(find "$OMNISET_MODULES" -mindepth 2 -maxdepth 2 -type d 2>/dev/null)

    [[ $failed -eq 0 ]]
}

@test "structure: all module dirs have install.sh" {
    local failed=0
    local total=0
    while IFS= read -r dir; do
        ((total++))
        if [[ ! -f "$dir/install.sh" ]]; then
            echo "MISSING install.sh: $dir" >&2
            ((failed++))
        fi
    done < <(_get_all_module_dirs)

    [[ $total -gt 0 ]]
    [[ $failed -eq 0 ]]
}

@test "structure: all install.sh files are executable" {
    local failed=0
    while IFS= read -r dir; do
        if [[ -f "$dir/install.sh" ]] && [[ ! -x "$dir/install.sh" ]]; then
            echo "NOT EXECUTABLE: $dir/install.sh" >&2
            ((failed++))
        fi
    done < <(_get_all_module_dirs)

    [[ $failed -eq 0 ]]
}

@test "structure: all uninstall.sh files are executable (if present)" {
    local failed=0
    while IFS= read -r dir; do
        if [[ -f "$dir/uninstall.sh" ]] && [[ ! -x "$dir/uninstall.sh" ]]; then
            echo "NOT EXECUTABLE: $dir/uninstall.sh" >&2
            ((failed++))
        fi
    done < <(_get_all_module_dirs)

    [[ $failed -eq 0 ]]
}

@test "structure: all install.sh have valid bash syntax" {
    local failed=0
    while IFS= read -r dir; do
        if [[ -f "$dir/install.sh" ]]; then
            if ! bash -n "$dir/install.sh" 2>/dev/null; then
                echo "SYNTAX ERROR: $dir/install.sh" >&2
                ((failed++))
            fi
        fi
    done < <(_get_all_module_dirs)

    [[ $failed -eq 0 ]]
}

@test "structure: all uninstall.sh have valid bash syntax (if present)" {
    local failed=0
    while IFS= read -r dir; do
        if [[ -f "$dir/uninstall.sh" ]]; then
            if ! bash -n "$dir/uninstall.sh" 2>/dev/null; then
                echo "SYNTAX ERROR: $dir/uninstall.sh" >&2
                ((failed++))
            fi
        fi
    done < <(_get_all_module_dirs)

    [[ $failed -eq 0 ]]
}

@test "structure: module IDs contain no special characters" {
    local failed=0
    while IFS= read -r dir; do
        local module_id
        module_id=$(basename "$dir")
        if [[ ! "$module_id" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            echo "INVALID ID: $module_id ($dir)" >&2
            ((failed++))
        fi
    done < <(_get_all_module_dirs)

    [[ $failed -eq 0 ]]
}

@test "structure: at least 30 modules exist" {
    local count
    count=$(_get_all_module_dirs | wc -l | tr -d ' ')
    [[ $count -ge 30 ]]
}

@test "structure: modules span at least 5 categories" {
    local category_count
    category_count=$(find "$OMNISET_MODULES" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
    [[ $category_count -ge 5 ]]
}
