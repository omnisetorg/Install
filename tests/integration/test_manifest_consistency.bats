#!/usr/bin/env bats
# Integration tests: manifest ↔ script consistency checks

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

_get_all_module_dirs() {
    find "$OMNISET_MODULES" -name "manifest.yaml" -type f -exec dirname {} \; | sort
}

# ═══════════════════════════════════════════════════════════════
# Manifest ↔ install.sh consistency
# ═══════════════════════════════════════════════════════════════

@test "consistency: every module with install.sh has uninstall.sh" {
    local missing=0
    local missing_list=""
    while IFS= read -r dir; do
        if [[ -f "$dir/install.sh" ]] && [[ ! -f "$dir/uninstall.sh" ]]; then
            local module_path="${dir#$OMNISET_MODULES/}"
            missing_list="${missing_list}  MISSING uninstall.sh: ${module_path}\n"
            ((missing++))
        fi
    done < <(_get_all_module_dirs)

    if [[ $missing -gt 0 ]]; then
        echo -e "Modules missing uninstall.sh ($missing):" >&2
        echo -e "$missing_list" >&2
    fi
    [[ $missing -eq 0 ]]
}

@test "consistency: manifest 'name' matches directory name" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi

    local failed=0
    while IFS= read -r dir; do
        local dir_name
        dir_name=$(basename "$dir")
        local manifest_name
        manifest_name=$(yq -r '.name // empty' "$dir/manifest.yaml" 2>/dev/null)

        if [[ -n "$manifest_name" ]] && [[ "$manifest_name" != "$dir_name" ]]; then
            echo "MISMATCH: dir=$dir_name manifest.name=$manifest_name ($dir)" >&2
            ((failed++))
        fi
    done < <(_get_all_module_dirs)

    [[ $failed -eq 0 ]]
}

@test "consistency: manifest 'category' matches parent directory" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi

    local failed=0
    while IFS= read -r dir; do
        local parent_dir
        parent_dir=$(basename "$(dirname "$dir")")
        local manifest_cat
        manifest_cat=$(yq -r '.category // empty' "$dir/manifest.yaml" 2>/dev/null)

        if [[ -n "$manifest_cat" ]] && [[ "$manifest_cat" != "$parent_dir" ]]; then
            echo "MISMATCH: parent=$parent_dir manifest.category=$manifest_cat ($dir)" >&2
            ((failed++))
        fi
    done < <(_get_all_module_dirs)

    [[ $failed -eq 0 ]]
}

@test "consistency: manifest 'provides.commands' lists at least one command" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi

    local failed=0
    while IFS= read -r dir; do
        local cmd_count
        cmd_count=$(yq -r '.provides.commands | length // 0' "$dir/manifest.yaml" 2>/dev/null)
        local pkg_count
        pkg_count=$(yq -r '.provides.packages | length // 0' "$dir/manifest.yaml" 2>/dev/null)

        # Module must provide at least one command or one package
        if [[ "$cmd_count" -eq 0 ]] && [[ "$pkg_count" -eq 0 ]]; then
            local module_path="${dir#$OMNISET_MODULES/}"
            echo "NO provides.commands or provides.packages: $module_path" >&2
            ((failed++))
        fi
    done < <(_get_all_module_dirs)

    [[ $failed -eq 0 ]]
}

@test "consistency: install.sh accepts arch as first argument (no hardcoded arch)" {
    local failed=0
    while IFS= read -r dir; do
        if [[ -f "$dir/install.sh" ]]; then
            # Check that scripts don't hardcode amd64/x86_64 without also reading $1
            # A well-written script either reads ARCH="${1:-amd64}" or doesn't care about arch
            if grep -qE 'ARCH="(amd64|x86_64)"' "$dir/install.sh" 2>/dev/null; then
                # That's OK if they also have ${1:- in the same file (using it as default)
                if ! grep -q '${1:-' "$dir/install.sh" 2>/dev/null; then
                    local module_path="${dir#$OMNISET_MODULES/}"
                    echo "HARDCODED ARCH without \$1 fallback: $module_path" >&2
                    ((failed++))
                fi
            fi
        fi
    done < <(_get_all_module_dirs)

    [[ $failed -eq 0 ]]
}

@test "consistency: no module has install.sh without manifest.yaml" {
    local orphans=0
    while IFS= read -r dir; do
        if [[ -f "$dir/install.sh" ]] && [[ ! -f "$dir/manifest.yaml" ]]; then
            echo "ORPHAN install.sh (no manifest): $dir" >&2
            ((orphans++))
        fi
    done < <(find "$OMNISET_MODULES" -mindepth 2 -maxdepth 2 -type d 2>/dev/null)

    [[ $orphans -eq 0 ]]
}

@test "consistency: manifest architecture lists at least amd64" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi

    local failed=0
    while IFS= read -r dir; do
        local has_amd64
        has_amd64=$(yq -r '.architecture.amd64 // empty' "$dir/manifest.yaml" 2>/dev/null)
        if [[ -z "$has_amd64" || "$has_amd64" == "null" || "$has_amd64" == "false" ]]; then
            local module_path="${dir#$OMNISET_MODULES/}"
            echo "NO amd64 support: $module_path" >&2
            ((failed++))
        fi
    done < <(_get_all_module_dirs)

    [[ $failed -eq 0 ]]
}
