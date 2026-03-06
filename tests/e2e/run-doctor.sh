#!/usr/bin/env bash
# E2E doctor tests — install modules and verify `omniset doctor` runs cleanly.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
IMAGE="omniset-e2e"
ARCH="${ARCH:-amd64}"
TIMEOUT=300

# Colors
if [[ -t 1 ]] && [[ -z "${CI:-}" ]]; then
    GREEN='\033[0;32m' RED='\033[0;31m' YELLOW='\033[0;33m'
    CYAN='\033[0;36m' BOLD='\033[1m' RESET='\033[0m'
else
    GREEN='' RED='' YELLOW='' CYAN='' BOLD='' RESET=''
fi

passed=0
failed=0
failures=()
start_time=$(date +%s)

echo -e "${BOLD}OmniSet E2E Doctor Tests${RESET}"
echo ""

# Build image
echo -e "${BOLD}Building Docker image...${RESET}"
docker build -t "$IMAGE" -f "$SCRIPT_DIR/Dockerfile" "$REPO_ROOT" || {
    echo -e "${RED}Failed to build Docker image${RESET}"; exit 1
}
echo ""

# Test 1: doctor runs on a clean system (no modules installed)
printf "%-50s" "doctor: clean system"
test_start=$(date +%s)
if timeout "$TIMEOUT" docker run --rm "$IMAGE" bash -c "
    cd /home/testuser/omniset && bash bin/omniset doctor
" > /tmp/e2e-doctor-$$ 2>&1; then
    echo -e "${GREEN}PASS${RESET}  ($(($(date +%s) - test_start))s)"
    passed=$((passed + 1))
else
    echo -e "${RED}FAIL${RESET}  ($(($(date +%s) - test_start))s)"
    failed=$((failed + 1))
    failures+=("doctor: clean system")
    echo -e "${YELLOW}--- output (last 20 lines) ---${RESET}"
    tail -20 /tmp/e2e-doctor-$$
    echo -e "${YELLOW}------------------------------${RESET}"
fi
rm -f /tmp/e2e-doctor-$$

# Test 2: doctor runs after installing a module
printf "%-50s" "doctor: after development/python install"
test_start=$(date +%s)
if timeout "$TIMEOUT" docker run --rm "$IMAGE" bash -c "
    cd /home/testuser/omniset &&
    bash modules/development/python/install.sh ${ARCH} &&
    bash bin/omniset doctor
" > /tmp/e2e-doctor-$$ 2>&1; then
    echo -e "${GREEN}PASS${RESET}  ($(($(date +%s) - test_start))s)"
    passed=$((passed + 1))
else
    echo -e "${RED}FAIL${RESET}  ($(($(date +%s) - test_start))s)"
    failed=$((failed + 1))
    failures+=("doctor: after python install")
    echo -e "${YELLOW}--- output (last 20 lines) ---${RESET}"
    tail -20 /tmp/e2e-doctor-$$
    echo -e "${YELLOW}------------------------------${RESET}"
fi
rm -f /tmp/e2e-doctor-$$

# Test 3: doctor runs after installing multiple modules
printf "%-50s" "doctor: after multiple installs"
test_start=$(date +%s)
if timeout "$TIMEOUT" docker run --rm "$IMAGE" bash -c "
    cd /home/testuser/omniset &&
    bash modules/cli/essentials/install.sh ${ARCH} &&
    bash modules/databases/sqlite/install.sh ${ARCH} &&
    bash bin/omniset doctor
" > /tmp/e2e-doctor-$$ 2>&1; then
    echo -e "${GREEN}PASS${RESET}  ($(($(date +%s) - test_start))s)"
    passed=$((passed + 1))
else
    echo -e "${RED}FAIL${RESET}  ($(($(date +%s) - test_start))s)"
    failed=$((failed + 1))
    failures+=("doctor: after multiple installs")
    echo -e "${YELLOW}--- output (last 20 lines) ---${RESET}"
    tail -20 /tmp/e2e-doctor-$$
    echo -e "${YELLOW}------------------------------${RESET}"
fi
rm -f /tmp/e2e-doctor-$$

# Test 4: doctor runs after install + uninstall cycle
printf "%-50s" "doctor: after install + uninstall cycle"
test_start=$(date +%s)
if timeout "$TIMEOUT" docker run --rm "$IMAGE" bash -c "
    cd /home/testuser/omniset &&
    bash modules/cli/lazygit/install.sh ${ARCH} &&
    lazygit --version &&
    bash modules/cli/lazygit/uninstall.sh &&
    bash bin/omniset doctor
" > /tmp/e2e-doctor-$$ 2>&1; then
    echo -e "${GREEN}PASS${RESET}  ($(($(date +%s) - test_start))s)"
    passed=$((passed + 1))
else
    echo -e "${RED}FAIL${RESET}  ($(($(date +%s) - test_start))s)"
    failed=$((failed + 1))
    failures+=("doctor: after install+uninstall")
    echo -e "${YELLOW}--- output (last 20 lines) ---${RESET}"
    tail -20 /tmp/e2e-doctor-$$
    echo -e "${YELLOW}------------------------------${RESET}"
fi
rm -f /tmp/e2e-doctor-$$

# Summary
end_time=$(date +%s)
total=$((passed + failed))

echo ""
echo -e "${BOLD}Results (Doctor)${RESET}"
echo "───────────────────────────────"
echo -e "Total:   ${total}"
echo -e "Passed:  ${GREEN}${passed}${RESET}"
echo -e "Failed:  ${RED}${failed}${RESET}"
echo -e "Time:    $((end_time - start_time))s"

if [[ ${#failures[@]} -gt 0 ]]; then
    echo ""
    echo -e "${RED}Failed tests:${RESET}"
    for f in "${failures[@]}"; do echo "  - $f"; done
    exit 1
fi
