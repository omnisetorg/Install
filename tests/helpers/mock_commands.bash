#!/bin/bash
# OmniSet Test Mock Framework
# Creates mock executables in $MOCK_BIN that log calls and return configured values

# Create a mock command
# Usage: create_mock "cmd" [exit_code] ["stdout_text"]
create_mock() {
    local cmd="$1"
    local exit_code="${2:-0}"
    local stdout="${3:-}"
    local mock_path="${MOCK_BIN}/${cmd}"
    local log_file="${MOCK_LOG_DIR}/${cmd}.log"

    cat > "$mock_path" << MOCK_SCRIPT
#!/bin/bash
echo "\$@" >> "${log_file}"
if [[ -n "${stdout}" ]]; then
    echo "${stdout}"
fi
exit ${exit_code}
MOCK_SCRIPT
    chmod +x "$mock_path"
}

# Create a sudo mock that runs commands without privilege
create_sudo_passthrough() {
    cat > "${MOCK_BIN}/sudo" << 'MOCK_SCRIPT'
#!/bin/bash
echo "$@" >> "${MOCK_LOG_DIR}/sudo.log"
# Strip sudo flags and execute the command
while [[ "$1" == -* ]]; do shift; done
"$@"
MOCK_SCRIPT
    chmod +x "${MOCK_BIN}/sudo"
}

# Create a sudo mock that does nothing
create_sudo_noop() {
    create_mock "sudo" 0
}

# Mock uname -m output
# Usage: mock_uname "x86_64"
mock_uname() {
    local arch="$1"
    cat > "${MOCK_BIN}/uname" << MOCK_SCRIPT
#!/bin/bash
echo "\$@" >> "${MOCK_LOG_DIR}/uname.log"
if [[ "\$1" == "-m" ]]; then
    echo "${arch}"
else
    # Fall through to real uname for other flags
    /usr/bin/uname "\$@"
fi
MOCK_SCRIPT
    chmod +x "${MOCK_BIN}/uname"
}

# Mock curl that copies from a fixture file
# Usage: mock_curl_file "fixture_path"
mock_curl_file() {
    local fixture_path="$1"
    cat > "${MOCK_BIN}/curl" << MOCK_SCRIPT
#!/bin/bash
echo "\$@" >> "${MOCK_LOG_DIR}/curl.log"
# Find the -o flag to know where to write
local output_file=""
local args=("\$@")
for ((i=0; i<\${#args[@]}; i++)); do
    if [[ "\${args[\$i]}" == "-o" ]]; then
        output_file="\${args[\$((i+1))]}"
        break
    fi
done
if [[ -n "\$output_file" ]]; then
    cp "${fixture_path}" "\$output_file"
else
    cat "${fixture_path}"
fi
exit 0
MOCK_SCRIPT
    chmod +x "${MOCK_BIN}/curl"
}

# Mock command -v: make a command appear to exist
# Usage: mock_command_exists "docker"
mock_command_exists() {
    local cmd="$1"
    if [[ ! -f "${MOCK_BIN}/${cmd}" ]]; then
        create_mock "$cmd" 0
    fi
}

# Mock command -v: make a command appear to NOT exist
# Usage: mock_command_not_exists "docker"
mock_command_not_exists() {
    local cmd="$1"
    rm -f "${MOCK_BIN}/${cmd}"
}

# ── Assertion helpers ───────────────────────────────────────────

# Assert a mock was called exactly N times
# Usage: assert_mock_called "cmd" [N]
assert_mock_called() {
    local cmd="$1"
    local expected="${2:-}"
    local log_file="${MOCK_LOG_DIR}/${cmd}.log"

    if [[ ! -f "$log_file" ]]; then
        fail "Mock '$cmd' was never called"
    fi

    if [[ -n "$expected" ]]; then
        local actual
        actual=$(wc -l < "$log_file" | tr -d ' ')
        if [[ "$actual" -ne "$expected" ]]; then
            fail "Mock '$cmd' called $actual times, expected $expected"
        fi
    fi
}

# Assert a mock was called with specific args (substring match)
# Usage: assert_mock_called_with "cmd" "expected_args"
assert_mock_called_with() {
    local cmd="$1"
    local expected_args="$2"
    local log_file="${MOCK_LOG_DIR}/${cmd}.log"

    if [[ ! -f "$log_file" ]]; then
        fail "Mock '$cmd' was never called"
    fi

    if ! grep -q "$expected_args" "$log_file"; then
        fail "Mock '$cmd' was not called with args matching '$expected_args'. Actual calls: $(cat "$log_file")"
    fi
}

# Assert a mock was never called
# Usage: assert_mock_not_called "cmd"
assert_mock_not_called() {
    local cmd="$1"
    local log_file="${MOCK_LOG_DIR}/${cmd}.log"

    if [[ -f "$log_file" ]] && [[ -s "$log_file" ]]; then
        fail "Mock '$cmd' was called but shouldn't have been. Calls: $(cat "$log_file")"
    fi
}

# Mock ping (for network detection)
# Usage: mock_ping_success or mock_ping_failure
mock_ping_success() {
    create_mock "ping" 0
}

mock_ping_failure() {
    create_mock "ping" 1
}

# Mock ip command
# Usage: mock_ip_route "192.168.1.100"
mock_ip_route() {
    local ip="$1"
    cat > "${MOCK_BIN}/ip" << MOCK_SCRIPT
#!/bin/bash
echo "\$@" >> "${MOCK_LOG_DIR}/ip.log"
echo "8.8.8.8 via 192.168.1.1 dev eth0 src ${ip}"
MOCK_SCRIPT
    chmod +x "${MOCK_BIN}/ip"
}

# Mock systemctl
mock_systemctl_noop() {
    create_mock "systemctl" 0
}

# Mock dpkg for pkg_is_installed checks
# Usage: mock_dpkg_installed "package"
mock_dpkg_installed() {
    local package="$1"
    cat > "${MOCK_BIN}/dpkg" << MOCK_SCRIPT
#!/bin/bash
echo "\$@" >> "${MOCK_LOG_DIR}/dpkg.log"
if [[ "\$1" == "-l" && "\$2" == "${package}" ]]; then
    echo "ii  ${package}  1.0.0  amd64  Description"
    exit 0
fi
exit 1
MOCK_SCRIPT
    chmod +x "${MOCK_BIN}/dpkg"
}

# Mock yq for manifest reading
# Usage: mock_yq_value "value"
mock_yq_value() {
    local value="$1"
    cat > "${MOCK_BIN}/yq" << MOCK_SCRIPT
#!/bin/bash
echo "\$@" >> "${MOCK_LOG_DIR}/yq.log"
echo "${value}"
MOCK_SCRIPT
    chmod +x "${MOCK_BIN}/yq"
}
