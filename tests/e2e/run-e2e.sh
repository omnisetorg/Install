#!/usr/bin/env bash
# E2E test runner — installs modules in Docker containers and verifies binaries.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONF="$SCRIPT_DIR/modules.conf"
IMAGE="omniset-e2e"
ARCH="${ARCH:-amd64}"
TIMEOUT=300  # 5 minutes per module
FILTER="${1:-}"

# Colors (disabled when not a terminal or in CI)
if [[ -t 1 ]] && [[ -z "${CI:-}" ]]; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    YELLOW='\033[0;33m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    RESET='\033[0m'
else
    GREEN='' RED='' YELLOW='' CYAN='' BOLD='' RESET=''
fi

passed=0
failed=0
skipped=0
failures=()
start_time=$(date +%s)

echo -e "${BOLD}OmniSet E2E Tests${RESET}"
echo -e "Architecture: ${CYAN}${ARCH}${RESET}"
echo ""

# Build the Docker image
echo -e "${BOLD}Building Docker image...${RESET}"
docker build -t "$IMAGE" -f "$SCRIPT_DIR/Dockerfile" "$REPO_ROOT" || {
    echo -e "${RED}Failed to build Docker image${RESET}"
    exit 1
}
echo ""

# Read modules.conf
while IFS='|' read -r module verify_cmd; do
    # Skip comments and blank lines
    module=$(echo "$module" | xargs)
    [[ -z "$module" || "$module" == \#* ]] && continue
    verify_cmd=$(echo "$verify_cmd" | xargs)

    # Apply filter if specified
    if [[ -n "$FILTER" ]] && [[ "$module" != *"$FILTER"* ]]; then
        skipped=$((skipped + 1))
        continue
    fi

    # Extract category and id
    category="${module%%/*}"
    id="${module##*/}"

    printf "%-30s" "$module"
    mod_start=$(date +%s)

    # Run install + verify in a fresh container
    if timeout "$TIMEOUT" docker run --rm "$IMAGE" bash -c "
        cd /home/testuser/omniset &&
        bash modules/${category}/${id}/install.sh ${ARCH} &&
        ${verify_cmd}
    " > /tmp/e2e-output-$$ 2>&1; then
        mod_end=$(date +%s)
        duration=$((mod_end - mod_start))
        echo -e "${GREEN}PASS${RESET}  (${duration}s)"
        passed=$((passed + 1))
    else
        mod_end=$(date +%s)
        duration=$((mod_end - mod_start))
        echo -e "${RED}FAIL${RESET}  (${duration}s)"
        failed=$((failed + 1))
        failures+=("$module")
        # Show last 20 lines of output on failure
        echo -e "${YELLOW}--- output (last 20 lines) ---${RESET}"
        tail -20 /tmp/e2e-output-$$
        echo -e "${YELLOW}------------------------------${RESET}"
    fi
    rm -f /tmp/e2e-output-$$

done < "$CONF"

# Summary
end_time=$(date +%s)
total_duration=$((end_time - start_time))
total=$((passed + failed))

echo ""
echo -e "${BOLD}Results${RESET}"
echo "───────────────────────────────"
echo -e "Total:   ${total}"
echo -e "Passed:  ${GREEN}${passed}${RESET}"
echo -e "Failed:  ${RED}${failed}${RESET}"
echo -e "Skipped: ${YELLOW}${skipped}${RESET}"
echo -e "Time:    ${total_duration}s"

if [[ ${#failures[@]} -gt 0 ]]; then
    echo ""
    echo -e "${RED}Failed modules:${RESET}"
    for f in "${failures[@]}"; do
        echo "  - $f"
    done
    exit 1
fi
