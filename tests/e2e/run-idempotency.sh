#!/usr/bin/env bash
# E2E idempotency tests — run install.sh twice, verify no errors on second run.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONF="$SCRIPT_DIR/modules.conf"
IMAGE="omniset-e2e"
ARCH="${ARCH:-amd64}"
TIMEOUT=600  # 10 minutes (two installs)
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

echo -e "${BOLD}OmniSet E2E Idempotency Tests${RESET}"
echo -e "Architecture: ${CYAN}${ARCH}${RESET}"
echo ""

# Build image
echo -e "${BOLD}Building Docker image...${RESET}"
docker build -t "$IMAGE" -f "$SCRIPT_DIR/Dockerfile" "$REPO_ROOT" || {
    echo -e "${RED}Failed to build Docker image${RESET}"; exit 1
}
echo ""

while IFS='|' read -r module verify_cmd; do
    module=$(echo "$module" | xargs)
    [[ -z "$module" || "$module" == \#* ]] && continue
    verify_cmd=$(echo "$verify_cmd" | xargs)

    if [[ -n "$FILTER" ]] && [[ "$module" != *"$FILTER"* ]]; then
        skipped=$((skipped + 1))
        continue
    fi

    category="${module%%/*}"
    id="${module##*/}"

    printf "%-30s" "$module"
    mod_start=$(date +%s)

    # Run install twice in the same container, verify after each
    if timeout "$TIMEOUT" docker run --rm "$IMAGE" bash -c "
        cd /home/testuser/omniset &&
        echo '=== First install ===' &&
        bash modules/${category}/${id}/install.sh ${ARCH} &&
        ${verify_cmd} &&
        echo '=== Second install ===' &&
        bash modules/${category}/${id}/install.sh ${ARCH} &&
        ${verify_cmd}
    " > /tmp/e2e-idempotency-$$ 2>&1; then
        mod_end=$(date +%s)
        echo -e "${GREEN}PASS${RESET}  ($((mod_end - mod_start))s)"
        passed=$((passed + 1))
    else
        mod_end=$(date +%s)
        echo -e "${RED}FAIL${RESET}  ($((mod_end - mod_start))s)"
        failed=$((failed + 1))
        failures+=("$module")
        echo -e "${YELLOW}--- output (last 30 lines) ---${RESET}"
        tail -30 /tmp/e2e-idempotency-$$
        echo -e "${YELLOW}------------------------------${RESET}"
    fi
    rm -f /tmp/e2e-idempotency-$$

done < "$CONF"

# Summary
end_time=$(date +%s)
total=$((passed + failed))

echo ""
echo -e "${BOLD}Results (Idempotency)${RESET}"
echo "───────────────────────────────"
echo -e "Total:   ${total}"
echo -e "Passed:  ${GREEN}${passed}${RESET}"
echo -e "Failed:  ${RED}${failed}${RESET}"
echo -e "Skipped: ${YELLOW}${skipped}${RESET}"
echo -e "Time:    $((end_time - start_time))s"

if [[ ${#failures[@]} -gt 0 ]]; then
    echo ""
    echo -e "${RED}Failed modules:${RESET}"
    for f in "${failures[@]}"; do echo "  - $f"; done
    exit 1
fi
