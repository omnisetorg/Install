#!/usr/bin/env bash
# E2E conflict tests — install overlapping modules together, verify both work.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONF="$SCRIPT_DIR/conflicts.conf"
IMAGE="omniset-e2e"
ARCH="${ARCH:-amd64}"
TIMEOUT=600
FILTER="${1:-}"

# Colors
if [[ -t 1 ]] && [[ -z "${CI:-}" ]]; then
    GREEN='\033[0;32m' RED='\033[0;31m' YELLOW='\033[0;33m'
    CYAN='\033[0;36m' BOLD='\033[1m' RESET='\033[0m'
else
    GREEN='' RED='' YELLOW='' CYAN='' BOLD='' RESET=''
fi

passed=0
failed=0
skipped=0
failures=()
start_time=$(date +%s)

echo -e "${BOLD}OmniSet E2E Conflict Tests${RESET}"
echo -e "Architecture: ${CYAN}${ARCH}${RESET}"
echo ""

# Build image
echo -e "${BOLD}Building Docker image...${RESET}"
docker build -t "$IMAGE" -f "$SCRIPT_DIR/Dockerfile" "$REPO_ROOT" || {
    echo -e "${RED}Failed to build Docker image${RESET}"; exit 1
}
echo ""

# Read conflicts.conf
# Format: module_a + module_b | verify_command
while IFS='|' read -r modules_pair verify_cmd; do
    modules_pair=$(echo "$modules_pair" | xargs)
    [[ -z "$modules_pair" || "$modules_pair" == \#* ]] && continue
    verify_cmd=$(echo "$verify_cmd" | xargs)

    if [[ -n "$FILTER" ]] && [[ "$modules_pair" != *"$FILTER"* ]]; then
        skipped=$((skipped + 1))
        continue
    fi

    # Parse "category_a/id_a + category_b/id_b"
    module_a=$(echo "$modules_pair" | cut -d'+' -f1 | xargs)
    module_b=$(echo "$modules_pair" | cut -d'+' -f2 | xargs)

    cat_a="${module_a%%/*}"; id_a="${module_a##*/}"
    cat_b="${module_b%%/*}"; id_b="${module_b##*/}"

    test_name="${module_a} + ${module_b}"
    printf "%-50s" "$test_name"
    mod_start=$(date +%s)

    # Install both modules in the same container, then verify
    if timeout "$TIMEOUT" docker run --rm "$IMAGE" bash -c "
        cd /home/testuser/omniset &&
        echo '=== Installing ${module_a} ===' &&
        bash modules/${cat_a}/${id_a}/install.sh ${ARCH} &&
        echo '=== Installing ${module_b} ===' &&
        bash modules/${cat_b}/${id_b}/install.sh ${ARCH} &&
        echo '=== Verifying ===' &&
        ${verify_cmd}
    " > /tmp/e2e-conflict-$$ 2>&1; then
        mod_end=$(date +%s)
        echo -e "${GREEN}PASS${RESET}  ($((mod_end - mod_start))s)"
        passed=$((passed + 1))
    else
        mod_end=$(date +%s)
        echo -e "${RED}FAIL${RESET}  ($((mod_end - mod_start))s)"
        failed=$((failed + 1))
        failures+=("$test_name")
        echo -e "${YELLOW}--- output (last 20 lines) ---${RESET}"
        tail -20 /tmp/e2e-conflict-$$
        echo -e "${YELLOW}------------------------------${RESET}"
    fi
    rm -f /tmp/e2e-conflict-$$

done < "$CONF"

# Summary
end_time=$(date +%s)
total=$((passed + failed))

echo ""
echo -e "${BOLD}Results (Conflicts)${RESET}"
echo "───────────────────────────────"
echo -e "Total:   ${total}"
echo -e "Passed:  ${GREEN}${passed}${RESET}"
echo -e "Failed:  ${RED}${failed}${RESET}"
echo -e "Skipped: ${YELLOW}${skipped}${RESET}"
echo -e "Time:    $((end_time - start_time))s"

if [[ ${#failures[@]} -gt 0 ]]; then
    echo ""
    echo -e "${RED}Failed pairs:${RESET}"
    for f in "${failures[@]}"; do echo "  - $f"; done
    exit 1
fi
