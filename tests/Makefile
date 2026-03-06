BATS := ./bats/bats-core/bin/bats
BATS_FLAGS := --print-output-on-failure --timing

.PHONY: test test-unit test-integration test-p0 test-p1 test-p2 test-p3 setup-bats

setup-bats:
	git submodule update --init --recursive ../tests/bats/bats-core
	git submodule update --init --recursive ../tests/bats/bats-support
	git submodule update --init --recursive ../tests/bats/bats-assert
	git submodule update --init --recursive ../tests/bats/bats-file

test: test-unit test-integration

test-unit:
	$(BATS) $(BATS_FLAGS) core/ ui/ system/ install/ cli/

test-integration:
	$(BATS) $(BATS_FLAGS) integration/

test-p0:
	$(BATS) $(BATS_FLAGS) install/test_modules.bats system/test_detect.bats

test-p1:
	$(BATS) $(BATS_FLAGS) system/test_packages.bats integration/test_manifest_validation.bats

test-p2:
	$(BATS) $(BATS_FLAGS) cli/test_cli_commands.bats integration/test_module_structure.bats

test-p3:
	$(BATS) $(BATS_FLAGS) core/test_constants.bats core/test_init.bats ui/test_colors.bats ui/test_print.bats install/test_uninstall.bats

test-core:
	$(BATS) $(BATS_FLAGS) core/

test-ui:
	$(BATS) $(BATS_FLAGS) ui/

test-system:
	$(BATS) $(BATS_FLAGS) system/

test-install:
	$(BATS) $(BATS_FLAGS) install/

test-cli:
	$(BATS) $(BATS_FLAGS) cli/
