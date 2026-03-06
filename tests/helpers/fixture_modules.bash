#!/bin/bash
# OmniSet Test Module Fixtures
# Creates temporary module directory trees for testing

# Create a single fixture module with manifest + install.sh + uninstall.sh
# Usage: create_fixture_module "module_id" "category" "display_name" [extra_manifest_yaml]
create_fixture_module() {
    local module_id="$1"
    local category="$2"
    local display_name="${3:-$module_id}"
    local extra_yaml="${4:-}"

    local module_dir="${TEST_TEMP_DIR}/modules/${category}/${module_id}"
    mkdir -p "$module_dir"

    # Create manifest.yaml
    cat > "${module_dir}/manifest.yaml" << YAML
name: ${module_id}
display_name: ${display_name}
version: "1.0.0"
category: ${category}
description: "Test module ${display_name}"
architecture:
  amd64: true
  arm64: true
  armhf: false
requirements:
  disk_mb: 100
  ram_mb: 256
  dependencies: []
install_methods:
  - type: apt
    priority: 1
    packages:
      - ${module_id}
provides:
  commands:
    - ${module_id}
  packages:
    - ${module_id}
tags:
  - test
${extra_yaml}
YAML

    # Create install.sh
    cat > "${module_dir}/install.sh" << 'INSTALL'
#!/bin/bash
echo "Installing ${1:-unknown} module"
exit 0
INSTALL
    chmod +x "${module_dir}/install.sh"

    # Create uninstall.sh
    cat > "${module_dir}/uninstall.sh" << 'UNINSTALL'
#!/bin/bash
echo "Uninstalling module"
exit 0
UNINSTALL
    chmod +x "${module_dir}/uninstall.sh"

    echo "$module_dir"
}

# Create a small module tree with 3 modules across categories
# Returns the modules base dir path
create_fixture_module_tree() {
    create_fixture_module "test-editor" "editors" "Test Editor" > /dev/null
    create_fixture_module "test-browser" "browsers" "Test Browser" > /dev/null
    create_fixture_module "test-tool" "development" "Test Tool" > /dev/null
    echo "${TEST_TEMP_DIR}/modules"
}

# Create a fixture module with NO manifest (for testing discover_modules filtering)
create_fixture_module_no_manifest() {
    local module_id="$1"
    local category="$2"
    local module_dir="${TEST_TEMP_DIR}/modules/${category}/${module_id}"
    mkdir -p "$module_dir"
    # Only create install.sh, no manifest
    echo '#!/bin/bash' > "${module_dir}/install.sh"
    chmod +x "${module_dir}/install.sh"
    echo "$module_dir"
}

# Create a fixture module with a failing install script
create_fixture_module_failing() {
    local module_id="$1"
    local category="$2"
    local module_dir
    module_dir=$(create_fixture_module "$module_id" "$category" "$module_id")

    cat > "${module_dir}/install.sh" << 'INSTALL'
#!/bin/bash
echo "Install failed!" >&2
exit 1
INSTALL
    chmod +x "${module_dir}/install.sh"
    echo "$module_dir"
}

# Create a fixture module that does NOT support the current arch
create_fixture_module_unsupported_arch() {
    local module_id="$1"
    local category="$2"
    local module_dir="${TEST_TEMP_DIR}/modules/${category}/${module_id}"
    mkdir -p "$module_dir"

    cat > "${module_dir}/manifest.yaml" << YAML
name: ${module_id}
display_name: ${module_id}
version: "1.0.0"
category: ${category}
description: "Unsupported arch module"
architecture:
  amd64: false
  arm64: false
  armhf: false
provides:
  commands: []
  packages: []
install_methods:
  - type: apt
    packages:
      - ${module_id}
YAML

    echo '#!/bin/bash' > "${module_dir}/install.sh"
    chmod +x "${module_dir}/install.sh"
    echo "$module_dir"
}
