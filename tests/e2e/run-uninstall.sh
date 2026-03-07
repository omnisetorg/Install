#!/usr/bin/env bash
# E2E uninstall tests — install → verify → uninstall → verify binary is gone.
# Each module runs in a single container to test the full lifecycle.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
IMAGE="omniset-e2e"
ARCH="${ARCH:-amd64}"
TIMEOUT=300
FILTER="${1:-}"

# Colors
if [[ -t 1 ]] && [[ -z "${CI:-}" ]]; then
    GREEN='\033[0;32m' RED='\033[0;31m' YELLOW='\033[0;33m'
    CYAN='\033[0;36m' BOLD='\033[1m' RESET='\033[0m'
else
    GREEN='' RED='' YELLOW='' CYAN='' BOLD='' RESET=''
fi

# Module → install verify → uninstall verify (binary should be gone)
# Format: category/module | install_verify | uninstall_verify
MODULES=(
    "cli/lazygit           | lazygit --version                                | ! command -v lazygit"
    "development/go        | /usr/local/go/bin/go version                     | ! test -d /usr/local/go"
    "development/rust      | bash -lc 'rustc --version && cargo --version'    | ! test -d ~/.cargo"
    "databases/sqlite      | sqlite3 --version                                | ! command -v sqlite3"
    "devops/terraform      | terraform version                                | ! command -v terraform"
    "devops/helm           | helm version --short                             | ! command -v helm"
    "editors/neovim        | nvim --version                                   | ! command -v nvim"
    "editors/helix         | hx --version                                     | ! command -v hx"
    "devops/ansible        | ansible --version                                | ! command -v ansible"
    "devops/awscli         | aws --version                                    | ! command -v aws"
    "cli/github-cli        | gh --version                                     | ! command -v gh"
    "cli/modern-cli        | fzf --version && rg --version && bat --version   | ! command -v fzf && ! command -v rg"
    "development/ruby      | ruby --version && gem --version                  | ! command -v ruby"
)

passed=0
failed=0
skipped=0
failures=()
start_time=$(date +%s)

echo -e "${BOLD}OmniSet E2E Uninstall Tests${RESET}"
echo -e "Architecture: ${CYAN}${ARCH}${RESET}"
echo ""

# Build image
echo -e "${BOLD}Building Docker image...${RESET}"
docker build -t "$IMAGE" -f "$SCRIPT_DIR/Dockerfile" "$REPO_ROOT" || {
    echo -e "${RED}Failed to build Docker image${RESET}"; exit 1
}
echo ""

for entry in "${MODULES[@]}"; do
    IFS='|' read -r module install_verify uninstall_verify <<< "$entry"
    module=$(echo "$module" | xargs)
    install_verify=$(echo "$install_verify" | xargs)
    uninstall_verify=$(echo "$uninstall_verify" | xargs)

    # Apply filter
    if [[ -n "$FILTER" ]] && [[ "$module" != *"$FILTER"* ]]; then
        skipped=$((skipped + 1))
        continue
    fi

    category="${module%%/*}"
    id="${module##*/}"

    printf "%-30s" "$module"
    mod_start=$(date +%s)

    if timeout "$TIMEOUT" docker run --rm "$IMAGE" bash -c "
        cd /home/testuser/omniset &&
        bash modules/${category}/${id}/install.sh ${ARCH} &&
        ${install_verify} &&
        echo '--- UNINSTALLING ---' &&
        bash modules/${category}/${id}/uninstall.sh &&
        ${uninstall_verify}
    " > /tmp/e2e-uninstall-$$ 2>&1; then
        mod_end=$(date +%s)
        echo -e "${GREEN}PASS${RESET}  ($((mod_end - mod_start))s)"
        passed=$((passed + 1))
    else
        mod_end=$(date +%s)
        echo -e "${RED}FAIL${RESET}  ($((mod_end - mod_start))s)"
        failed=$((failed + 1))
        failures+=("$module")
        echo -e "${YELLOW}--- output (last 20 lines) ---${RESET}"
        tail -20 /tmp/e2e-uninstall-$$
        echo -e "${YELLOW}------------------------------${RESET}"
    fi
    rm -f /tmp/e2e-uninstall-$$
done

# Summary
end_time=$(date +%s)
total=$((passed + failed))

echo ""
echo -e "${BOLD}Results (Uninstall)${RESET}"
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
