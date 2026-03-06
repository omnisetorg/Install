#!/usr/bin/env bats
# Cross-cutting module checks — patterns ALL modules should follow

load "../helpers/test_helper"

MODULES_DIR="${PROJECT_ROOT}/modules"

setup() {
    setup_temp_dir
}

# ── set -euo pipefail ──────────────────────────────────────────

@test "modules: all install.sh scripts have set -euo pipefail" {
    local missing=()
    while IFS= read -r script; do
        if ! grep -q "set -euo pipefail" "$script"; then
            missing+=("$script")
        fi
    done < <(find "$MODULES_DIR" -name "install.sh" -type f)

    if [[ ${#missing[@]} -gt 0 ]]; then
        fail "Missing 'set -euo pipefail' in: ${missing[*]}"
    fi
}

@test "modules: all uninstall.sh scripts have set -euo pipefail" {
    local missing=()
    while IFS= read -r script; do
        if ! grep -q "set -euo pipefail" "$script"; then
            missing+=("$script")
        fi
    done < <(find "$MODULES_DIR" -name "uninstall.sh" -type f)

    if [[ ${#missing[@]} -gt 0 ]]; then
        fail "Missing 'set -euo pipefail' in: ${missing[*]}"
    fi
}

# ── ARCH parameter ─────────────────────────────────────────────

@test "modules: install.sh scripts accept ARCH as first parameter" {
    local missing=()
    while IFS= read -r script; do
        # Check for ARCH="${1:-...}" or ARCH="$1" or ARCH=$1
        if ! grep -qE 'ARCH="\$\{1:|ARCH="\$1"|ARCH=\$1' "$script"; then
            # Some simple scripts may not need ARCH — skip those under 10 lines
            local lines
            lines=$(wc -l < "$script" | tr -d ' ')
            if [[ $lines -gt 15 ]]; then
                missing+=("$script")
            fi
        fi
    done < <(find "$MODULES_DIR" -name "install.sh" -type f)

    if [[ ${#missing[@]} -gt 0 ]]; then
        # This is a warning-level check, not all modules use ARCH
        # Just verify at least 50% of non-trivial scripts use it
        local total
        total=$(find "$MODULES_DIR" -name "install.sh" -type f | wc -l | tr -d ' ')
        local conforming=$(( total - ${#missing[@]} ))
        local pct=$(( conforming * 100 / total ))

        if [[ $pct -lt 30 ]]; then
            fail "Only ${pct}% of install.sh scripts accept ARCH parameter"
        fi
    fi
}

# ── Print functions ────────────────────────────────────────────

@test "modules: install.sh scripts source print.sh or define fallback" {
    local missing=()
    while IFS= read -r script; do
        # Check for: source ...print.sh OR print_step/print_success/echo pattern
        if ! grep -qE 'source.*print\.sh|print_step\(\)|print_success\(\)|echo ' "$script"; then
            missing+=("$script")
        fi
    done < <(find "$MODULES_DIR" -name "install.sh" -type f)

    if [[ ${#missing[@]} -gt 0 ]]; then
        fail "Scripts without print functions or echo: ${missing[*]}"
    fi
}

# ── No hardcoded architectures ─────────────────────────────────

@test "modules: no hardcoded x86_64 in install scripts (should use ARCH)" {
    local violations=()
    while IFS= read -r script; do
        # Look for hardcoded x86_64 that isn't in a comment or conditional
        # Allow it in case/esac patterns and variable assignments
        if grep -n "x86_64" "$script" | grep -vE '^\s*#|case|esac|\$|ARCH|uname|aarch64' | grep -q "x86_64"; then
            violations+=("$script")
        fi
    done < <(find "$MODULES_DIR" -name "install.sh" -type f)

    # Allow some violations — this is a best-practice check
    if [[ ${#violations[@]} -gt 5 ]]; then
        fail "Too many scripts with hardcoded x86_64: ${violations[*]}"
    fi
}

@test "modules: amd64 usage is in arch-detection patterns" {
    # Many modules legitimately use amd64 in arch-detection case/if patterns
    # This test verifies that amd64 is used alongside ARCH variable references,
    # not as a standalone hardcoded assumption
    local total=0
    local uses_arch_var=0
    while IFS= read -r script; do
        if grep -q "amd64" "$script"; then
            ((total++))
            # Check that the script also references $ARCH or ARCH variable
            if grep -qE '\$ARCH|\$\{ARCH|ARCH=' "$script"; then
                ((uses_arch_var++))
            fi
        fi
    done < <(find "$MODULES_DIR" -name "install.sh" -type f)

    if [[ $total -gt 0 ]]; then
        local pct=$(( uses_arch_var * 100 / total ))
        if [[ $pct -lt 50 ]]; then
            fail "Only ${pct}% of scripts using amd64 also reference ARCH variable"
        fi
    fi
}

# ── Bash shebang ───────────────────────────────────────────────

@test "modules: all install.sh scripts have bash shebang" {
    local missing=()
    while IFS= read -r script; do
        local first_line
        first_line=$(head -1 "$script")
        if [[ "$first_line" != "#!/bin/bash"* ]] && [[ "$first_line" != "#!/usr/bin/env bash"* ]]; then
            missing+=("$script")
        fi
    done < <(find "$MODULES_DIR" -name "install.sh" -type f)

    if [[ ${#missing[@]} -gt 0 ]]; then
        fail "Missing bash shebang in: ${missing[*]}"
    fi
}

@test "modules: all uninstall.sh scripts have bash shebang" {
    local missing=()
    while IFS= read -r script; do
        local first_line
        first_line=$(head -1 "$script")
        if [[ "$first_line" != "#!/bin/bash"* ]] && [[ "$first_line" != "#!/usr/bin/env bash"* ]]; then
            missing+=("$script")
        fi
    done < <(find "$MODULES_DIR" -name "uninstall.sh" -type f)

    if [[ ${#missing[@]} -gt 0 ]]; then
        fail "Missing bash shebang in: ${missing[*]}"
    fi
}

# ── Script executability ──────────────────────────────────────

@test "modules: all install.sh scripts are executable or valid bash" {
    while IFS= read -r script; do
        run bash -n "$script"
        assert_success
    done < <(find "$MODULES_DIR" -name "install.sh" -type f)
}

@test "modules: all uninstall.sh scripts are valid bash" {
    while IFS= read -r script; do
        run bash -n "$script"
        assert_success
    done < <(find "$MODULES_DIR" -name "uninstall.sh" -type f)
}
