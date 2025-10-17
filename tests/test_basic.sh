#!/bin/bash
# Basic Unit Tests for ILI Project
# Tests individual components and requirements

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Logging
LOG_FILE="tests/test_basic.log"
mkdir -p tests
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=================================="
echo "ILI Basic Unit Tests"
echo "Started: $(date)"
echo "=================================="

# Helper functions
test_start() {
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "\n${BLUE}[TEST $TESTS_RUN]${NC} $1"
}

test_pass() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓ PASS${NC}: $1"
}

test_fail() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗ FAIL${NC}: $1"
}

# Test 1: Check if script exists
test_start "Script file exists"
if [ -f "xlogin00-fit-ili.sh" ]; then
    test_pass "Script file found"
else
    test_fail "Script file not found"
fi

# Test 2: Check script permissions
test_start "Script is executable"
if [ -x "xlogin00-fit-ili.sh" ]; then
    test_pass "Script has execute permissions"
else
    test_fail "Script is not executable"
    chmod +x xlogin00-fit-ili.sh
fi

# Test 3: Check bash shebang
test_start "Script has correct shebang"
if head -n 1 xlogin00-fit-ili.sh 2>/dev/null | grep -q "^#!/bin/bash"; then
    test_pass "Correct bash shebang found"
else
    test_fail "Missing or incorrect shebang"
fi

# Test 4: Check for required commands
test_start "Required commands are available"
REQUIRED_CMDS=("dd" "losetup" "mkfs.ext4" "mount" "umount" "yum" "systemctl")
for cmd in "${REQUIRED_CMDS[@]}"; do
    if command -v "$cmd" &> /dev/null; then
        test_pass "Command '$cmd' is available"
    else
        test_fail "Command '$cmd' not found"
    fi
done

# Test 5: Check if running as root
test_start "Running with root privileges"
if [ "$(id -u)" -eq 0 ]; then
    test_pass "Running as root"
else
    test_fail "Not running as root"
fi

# Test 6: Check disk space
test_start "Sufficient disk space in /var/tmp"
AVAILABLE_SPACE=$(df /var/tmp | tail -1 | awk '{print $4}')
if [ "$AVAILABLE_SPACE" -gt 204800 ]; then  # 200 MB in KB
    test_pass "Sufficient disk space available"
else
    test_fail "Insufficient disk space (need 200 MB)"
fi

# Test 7: Check if loop module is loaded
test_start "Loop device support"
if lsmod | grep -q "^loop"; then
    test_pass "Loop module is loaded"
else
    modprobe loop && test_pass "Loop module loaded successfully" || test_fail "Cannot load loop module"
fi

# Test 8: Check Apache availability
test_start "Apache (httpd) package availability"
if yum list httpd &> /dev/null; then
    test_pass "httpd package is available"
else
    test_fail "httpd package not available"
fi

# Test 9: Check createrepo availability
test_start "createrepo package availability"
if yum list createrepo &> /dev/null || yum list createrepo_c &> /dev/null; then
    test_pass "createrepo package is available"
else
    test_fail "createrepo package not available"
fi

# Test 10: Check SELinux status
test_start "SELinux configuration"
if command -v getenforce &> /dev/null; then
    SELINUX_STATUS=$(getenforce)
    echo "  SELinux status: $SELINUX_STATUS"
    test_pass "SELinux is configured ($SELINUX_STATUS)"
else
    test_fail "SELinux tools not available"
fi

# Summary
echo ""
echo "=================================="
echo "Test Summary"
echo "=================================="
echo "Tests Run:    $TESTS_RUN"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo "Success Rate: $(( TESTS_PASSED * 100 / TESTS_RUN ))%"
echo "=================================="
echo "Completed: $(date)"
echo "Log file: $LOG_FILE"
echo "=================================="

# Exit with appropriate code
if [ "$TESTS_FAILED" -eq 0 ]; then
    exit 0
else
    exit 1
fi
