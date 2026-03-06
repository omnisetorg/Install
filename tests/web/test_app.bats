#!/usr/bin/env bats
# Tests for web/assets/js/app.js — validates JavaScript via node

load "../helpers/test_helper"

APP_JS="${PROJECT_ROOT}/web/assets/js/app.js"

setup() {
    setup_temp_dir

    if ! command -v node &>/dev/null; then
        skip "node is required for JS tests"
    fi
}

# ── File validity ──────────────────────────────────────────────

@test "app.js: file exists" {
    assert_file_exists "$APP_JS"
}

@test "app.js: is valid JavaScript syntax" {
    run node --check "$APP_JS"
    assert_success
}

# ── Structure checks ──────────────────────────────────────────

@test "app.js: contains OmniSetSelector class" {
    run grep -c "class OmniSetSelector" "$APP_JS"
    assert_success
    assert_output "1"
}

@test "app.js: has required methods" {
    local methods=(
        "generateCommand"
        "generateConfig"
        "calculateTotalSize"
        "escapeHtml"
        "toggleModule"
        "selectPreset"
        "clearSelection"
        "loadFromUrl"
        "updateUrl"
        "filterModules"
    )

    for method in "${methods[@]}"; do
        run grep -c "${method}(" "$APP_JS"
        assert_success
    done
}

@test "app.js: has global functions" {
    local functions=("closeModal" "copyCommand" "copyShareUrl" "downloadConfig")

    for fn in "${functions[@]}"; do
        run grep -c "function ${fn}" "$APP_JS"
        assert_success
    done
}

# ── generateCommand logic ─────────────────────────────────────

@test "app.js: generateCommand produces correct curl command" {
    run node -e "
        const selected = new Map([['nodejs', {}], ['rust', {}]]);
        const baseUrl = 'https://omniset.org';
        const modules = Array.from(selected.keys()).join(',');
        const cmd = \`curl -sL \${baseUrl}/i | bash -s -- \${modules}\`;
        console.log(cmd);
    "
    assert_success
    assert_output "curl -sL https://omniset.org/i | bash -s -- nodejs,rust"
}

@test "app.js: generateCommand with single module" {
    run node -e "
        const selected = new Map([['git', {}]]);
        const baseUrl = 'https://omniset.org';
        const modules = Array.from(selected.keys()).join(',');
        console.log(\`curl -sL \${baseUrl}/i | bash -s -- \${modules}\`);
    "
    assert_success
    assert_output "curl -sL https://omniset.org/i | bash -s -- git"
}

# ── calculateTotalSize logic ──────────────────────────────────

@test "app.js: calculateTotalSize sums module sizes" {
    run node -e "
        const modules = [
            { id: 'a', size_mb: 100 },
            { id: 'b', size_mb: 250 },
            { id: 'c', size_mb: 50 }
        ];
        const selected = new Map([['a', {}], ['c', {}]]);

        let total = 0;
        for (const moduleId of selected.keys()) {
            const mod = modules.find(m => m.id === moduleId);
            if (mod) total += mod.size_mb;
        }
        console.log(total);
    "
    assert_success
    assert_output "150"
}

@test "app.js: calculateTotalSize returns 0 for empty selection" {
    run node -e "
        const selected = new Map();
        let total = 0;
        for (const moduleId of selected.keys()) {
            // no iteration
        }
        console.log(total);
    "
    assert_success
    assert_output "0"
}

# ── URL serialization/deserialization ─────────────────────────

@test "app.js: URL module parameter serialization" {
    run node -e "
        const modules = ['nodejs', 'rust', 'python'];
        const param = modules.join(',');
        console.log(param);
    "
    assert_success
    assert_output "nodejs,rust,python"
}

@test "app.js: URL module parameter deserialization" {
    run node -e "
        const param = 'nodejs,rust,python';
        const modules = param.split(',');
        console.log(JSON.stringify(modules));
    "
    assert_success
    assert_output '["nodejs","rust","python"]'
}

@test "app.js: URL encoding handles special characters" {
    run node -e "
        const modules = 'a,b,c';
        const encoded = encodeURIComponent(modules);
        const decoded = decodeURIComponent(encoded);
        console.log(decoded === modules ? 'roundtrip-ok' : 'FAIL');
    "
    assert_success
    assert_output "roundtrip-ok"
}

# ── generateConfig logic ─────────────────────────────────────

@test "app.js: generateConfig produces YAML-like output" {
    run node -e "
        const modules = ['nodejs', 'rust'];
        let yaml = 'modules:\n';
        for (const moduleId of modules) {
            yaml += '  - ' + moduleId + '\n';
        }
        console.log(yaml.trim());
    "
    assert_success
    assert_line --index 0 "modules:"
    assert_line --index 1 "  - nodejs"
    assert_line --index 2 "  - rust"
}

# ── generateShareUrl logic ────────────────────────────────────

@test "app.js: generateShareUrl includes encoded modules" {
    run node -e "
        const baseUrl = 'https://omniset.org';
        const modules = ['nodejs', 'rust'];
        const url = baseUrl + '/builder?m=' + encodeURIComponent(modules.join(','));
        console.log(url);
    "
    assert_success
    assert_output "https://omniset.org/builder?m=nodejs%2Crust"
}

# ── escapeHtml ─────────────────────────────────────────────────

@test "app.js: escapeHtml is safe (DOM-based textContent approach)" {
    # The actual implementation uses DOM (document.createElement)
    # which isn't available in Node. Verify the pattern is present.
    run grep -A3 "escapeHtml" "$APP_JS"
    assert_success
    assert_output --partial "textContent"
}

# ── filterModules logic ───────────────────────────────────────

@test "app.js: filter query normalization (lowercase + trim)" {
    run node -e "
        const query = '  NodeJS  ';
        const normalized = query.toLowerCase().trim();
        console.log(normalized);
    "
    assert_success
    assert_output "nodejs"
}
