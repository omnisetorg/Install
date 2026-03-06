# OmniSet Test Suite

## Architecture

Tests are organized in three tiers:

| Tier | Framework | What it validates | Speed |
|------|-----------|-------------------|-------|
| **Unit** | BATS | Library functions with mocks (colors, printing, detection, module loading) | ~10s |
| **Integration** | BATS | Module manifests, directory structure, YAML validity, manifest ↔ script consistency | ~20s |
| **E2E** | Docker | Real installations on clean Ubuntu — verifies binaries actually work | ~15min |

## Running Tests

```bash
cd tests

# All unit + integration tests
make test

# Individual suites
make test-unit
make test-integration
make test-core
make test-ui
make test-system
make test-install
make test-cli

# Priority tiers (P0 = most critical)
make test-p0
make test-p1
make test-p2
make test-p3

# E2E tests (requires Docker)
make test-e2e              # Install + verify
make test-e2e-uninstall    # Install → uninstall → verify removal
make test-e2e-idempotency  # Install twice, verify no errors
make test-e2e-conflicts    # Install overlapping modules together
make test-e2e-doctor       # Verify omniset doctor after installs
make test-e2e-all          # All of the above
```

### Running a single e2e module

```bash
cd tests/e2e
./run-e2e.sh development/python
./run-uninstall.sh cli/lazygit
./run-idempotency.sh editors/neovim
```

The filter matches any substring, so `./run-e2e.sh dev` runs all `development/*` and `devops/*` modules.

### ARM64 testing

```bash
ARCH=arm64 ./run-e2e.sh
```

## E2E Test Design

### Why Docker?

- **Isolation** — each module installs in a fresh Ubuntu 22.04 container, no host pollution
- **Reproducibility** — identical base image every run
- **Clean state** — each module gets its own container, so install order doesn't matter
- **CI-friendly** — no special kernel or display server needed (for testable modules)

### E2E test types

| Test | Script | What it validates |
|------|--------|-------------------|
| **Install** | `run-e2e.sh` | Module installs and binary works |
| **Uninstall** | `run-uninstall.sh` | Install → verify → uninstall → verify binary is gone |
| **Idempotency** | `run-idempotency.sh` | Running install.sh twice causes no errors |
| **Conflicts** | `run-conflicts.sh` | Overlapping modules coexist without breaking |
| **Doctor** | `run-doctor.sh` | `omniset doctor` runs cleanly after installs/uninstalls |

### How it works

1. Each script builds a Docker image from `tests/e2e/Dockerfile` (Ubuntu 22.04 + basic deps)
2. Reads config files (`modules.conf` or `conflicts.conf`) for test definitions
3. For each test case, spins up a fresh container that runs the test scenario
4. Reports pass/fail with timing, exits non-zero if any failures

### Install test coverage

**17 modules tested:**

| Module | Verify command |
|--------|---------------|
| base/essentials | `curl --version && git --version && vim --version` |
| cli/essentials | `curl --version && jq --version && tmux -V` |
| cli/lazygit | `lazygit --version` |
| development/python | `python3 --version && pip3 --version` |
| development/nodejs | `node --version && npm --version` |
| development/go | `/usr/local/go/bin/go version` |
| development/rust | `bash -lc 'rustc --version && cargo --version'` |
| development/java | `java --version` |
| development/php | `php --version` |
| development/dotnet | `dotnet --version` |
| devops/terraform | `terraform version` |
| devops/helm | `helm version --short` |
| devops/ansible | `ansible --version` |
| editors/neovim | `nvim --version` |
| editors/helix | `hx --version` |
| databases/sqlite | `sqlite3 --version` |

### Uninstall test coverage

**9 modules tested** (those with clean, well-defined uninstall scripts):

| Module | Uninstall verify |
|--------|-----------------|
| cli/lazygit | binary removed from /usr/local/bin |
| development/go | /usr/local/go directory removed |
| development/rust | ~/.cargo directory removed |
| databases/sqlite | sqlite3 binary removed |
| devops/terraform | terraform binary removed |
| devops/helm | helm binary removed |
| editors/neovim | nvim binary removed |
| editors/helix | hx binary removed |
| devops/ansible | ansible binary removed |

### Conflict test coverage

**5 pairs tested:**

| Pair | Why they might conflict |
|------|----------------------|
| base/essentials + cli/essentials | Both install curl, git via apt |
| development/python + development/nodejs | Both modify shell rc files |
| development/go + development/rust | Both add to PATH via .bashrc |
| editors/neovim + editors/helix | Both are terminal editors |
| devops/terraform + devops/helm | Both install to /usr/local/bin |

### Skipped modules (and why)

| Category | Reason |
|----------|--------|
| databases (postgresql, mysql, mongodb, redis, mariadb, valkey) | Require Docker daemon (Docker-in-Docker) |
| devops/kubernetes | k3s needs systemd/kernel features |
| devops/tailscale, devops/wireguard | Need network/kernel access |
| cli/modern-cli | Multi-tool interactive installer |
| browsers/\*, communication/\*, creative/\*, desktop/\*, devtools/\*, gaming/\*, media/\*, productivity/\*, terminals/\* | Require GUI/display server |
| system/\* | Require GUI or special kernel modules |

## Integration Tests: Manifest Consistency

The `test_manifest_consistency.bats` suite validates that manifests and scripts stay in sync:

- Every module with `install.sh` has a matching `uninstall.sh`
- Manifest `name` matches directory name
- Manifest `category` matches parent directory name
- Every module provides at least one command or package
- Install scripts accept arch as `$1` (no hardcoded architecture)
- Every module with `install.sh` has a `manifest.yaml`
- All manifests list amd64 architecture support

## Adding Tests for a New Module

### Unit/integration tests

Module manifest and structure are validated automatically by the integration suite. No action needed if your module follows the standard format.

### E2E tests

1. Add a line to `tests/e2e/modules.conf`:
   ```
   category/module | command --version
   ```
2. Optionally add an uninstall entry to `run-uninstall.sh`'s `MODULES` array
3. If the module overlaps with another, add a conflict pair to `tests/e2e/conflicts.conf`
4. Run it: `cd tests/e2e && ./run-e2e.sh category/module`

Only add modules that can install in a headless Docker container without Docker-in-Docker or a display server.

## CI Configuration

The GitHub Actions workflow (`.github/workflows/test.yml`) runs:

- **Unit + integration** — on every push to `main` and every PR (both x86_64 and arm64)
- **E2E (all types)** — weekly (Sunday 3am UTC) and on manual `workflow_dispatch` (both architectures)

E2E tests are separated because they take ~15 minutes and make network calls to install real packages.
