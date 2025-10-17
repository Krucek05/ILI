# Makefile for ILI - Linux System Administration Automation
# Author: ILI Project
# Description: Build, test, and validate the automation script

.PHONY: all test clean install uninstall help check-root validate lint run test-basic test-advanced test-cleanup test-all setup-tests

# Variables
SCRIPT_NAME = xlogin00-fit-ili.sh
TEST_DIR = tests
BACKUP_DIR = backups
VM_IMAGE = fedora-server-test
TIMESTAMP = $(shell date +%Y%m%d_%H%M%S)

# Colors for output
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[1;33m
BLUE = \033[0;34m
NC = \033[0m # No Color

# Default target
all: help

## help: Display this help message
help:
	@echo "$(BLUE)═══════════════════════════════════════════════════════════════$(NC)"
	@echo "$(BLUE)  ILI - Linux System Administration Automation - Makefile$(NC)"
	@echo "$(BLUE)═══════════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(GREEN)Available targets:$(NC)"
	@echo ""
	@grep -E '^## ' Makefile | sed 's/## /  $(YELLOW)make $(NC)/'
	@echo ""
	@echo "$(BLUE)═══════════════════════════════════════════════════════════════$(NC)"## check-root: Verify script is run with root privileges
check-root:
    @if [ "$$(id -u)" -ne 0 ]; then \
        echo "$(RED)✗ Error: This script must be run as root$(NC)"; \
        exit 1; \
    fi
    @echo "$(GREEN)✓ Running with root privileges$(NC)"

## validate: Validate script syntax and structure
validate:
    @echo "$(BLUE)Validating script syntax...$(NC)"
    @if [ -f "$(SCRIPT_NAME)" ]; then \
        bash -n $(SCRIPT_NAME) && echo "$(GREEN)✓ Syntax is valid$(NC)" || (echo "$(RED)✗ Syntax error detected$(NC)" && exit 1); \
    else \
        echo "$(RED)✗ Script $(SCRIPT_NAME) not found$(NC)"; \
        exit 1; \
    fi

## lint: Run shellcheck on the script
lint:
    @echo "$(BLUE)Running shellcheck...$(NC)"
    @if command -v shellcheck >/dev/null 2>&1; then \
        shellcheck -x $(SCRIPT_NAME) || echo "$(YELLOW)⚠ Shellcheck warnings detected$(NC)"; \
    else \
        echo "$(YELLOW)⚠ shellcheck not installed, skipping...$(NC)"; \
        echo "  Install with: sudo dnf install -y ShellCheck"; \
    fi

## test-basic: Run basic unit tests
test-basic: check-root validate
    @echo "$(BLUE)Running basic unit tests...$(NC)"
    @bash $(TEST_DIR)/test_basic.sh

## test-advanced: Run advanced integration tests
test-advanced: check-root validate
    @echo "$(BLUE)Running advanced integration tests...$(NC)"
    @bash $(TEST_DIR)/test_advanced.sh

## test-cleanup: Run cleanup verification tests
test-cleanup: check-root
    @echo "$(BLUE)Running cleanup tests...$(NC)"
    @bash $(TEST_DIR)/test_cleanup.sh

## test-all: Run all tests
test-all: lint test-basic test-advanced test-cleanup
    @echo ""
    @echo "$(GREEN)═══════════════════════════════════════════════════════════════$(NC)"
    @echo "$(GREEN)  All tests completed successfully!$(NC)"
    @echo "$(GREEN)═══════════════════════════════════════════════════════════════$(NC)"

## test: Alias for test-all
test: test-all

## run: Execute the main script with default packages
run: check-root validate
    @echo "$(BLUE)Executing main script...$(NC)"
    @bash $(SCRIPT_NAME) wget curl vim

## install: Install the script to /usr/local/bin
install: validate
    @echo "$(BLUE)Installing script...$(NC)"
    @install -m 755 $(SCRIPT_NAME) /usr/local/bin/ili-setup
    @echo "$(GREEN)✓ Script installed to /usr/local/bin/ili-setup$(NC)"

## uninstall: Remove the script from system
uninstall: check-root
    @echo "$(BLUE)Uninstalling script...$(NC)"
    @rm -f /usr/local/bin/ili-setup
    @echo "$(GREEN)✓ Script uninstalled$(NC)"

## backup: Create a backup of current state
backup: check-root
    @echo "$(BLUE)Creating backup...$(NC)"
    @mkdir -p $(BACKUP_DIR)
    @if [ -f /var/tmp/ukol.img ]; then \
        cp /var/tmp/ukol.img $(BACKUP_DIR)/ukol.img.$(TIMESTAMP); \
    fi
    @if [ -f /etc/yum.repos.d/ukol.repo ]; then \
        cp /etc/yum.repos.d/ukol.repo $(BACKUP_DIR)/ukol.repo.$(TIMESTAMP); \
    fi
    @if grep -q "/var/www/html/ukol" /etc/fstab 2>/dev/null; then \
        grep "/var/www/html/ukol" /etc/fstab > $(BACKUP_DIR)/fstab.entry.$(TIMESTAMP); \
    fi
    @echo "$(GREEN)✓ Backup created in $(BACKUP_DIR)$(NC)"

## clean: Clean up all created resources
clean: check-root
    @echo "$(BLUE)Cleaning up resources...$(NC)"
    @bash $(TEST_DIR)/cleanup.sh
    @echo "$(GREEN)✓ Cleanup completed$(NC)"

## clean-all: Deep clean including backups and logs
clean-all: clean
    @echo "$(BLUE)Performing deep clean...$(NC)"
    @rm -rf $(BACKUP_DIR) $(TEST_DIR)/*.log
    @echo "$(GREEN)✓ Deep clean completed$(NC)"

## setup-tests: Create test directory and files
setup-tests:
    @echo "$(BLUE)Setting up test environment...$(NC)"
    @mkdir -p $(TEST_DIR)
    @echo "$(GREEN)✓ Test environment ready$(NC)"

## verify: Quick verification of current installation
verify: check-root
    @echo "$(BLUE)Verifying installation...$(NC)"
    @bash $(TEST_DIR)/verify.sh

## benchmark: Run performance benchmarks
benchmark: check-root
    @echo "$(BLUE)Running benchmarks...$(NC)"
    @bash $(TEST_DIR)/benchmark.sh

## report: Generate test report
report:
    @echo "$(BLUE)Generating test report...$(NC)"
    @bash $(TEST_DIR)/generate_report.sh