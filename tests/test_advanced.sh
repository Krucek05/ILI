#!/bin/bash
# Advanced Integration Tests for ILI Project
# Tests complete workflow and integration

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

LOG_FILE="tests/test_advanced.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=================================="
echo "ILI Advanced Integration Tests"
echo "Started: $(date)"
echo "=================================="

test_start() {
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "\n${BLUE}[INTEGRATION TEST $TESTS_RUN]${NC} $1"
}

test_pass() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓ PASS${NC}: $1"
}

test_fail() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗ FAIL${NC}: $1"
}

# Cleanup before tests
echo "Cleaning up any previous installation..."
bash tests/cleanup.sh 2>/dev/null || true

# Test 1: Execute main script
test_start "Execute main script with test packages"
if bash xlogin00-fit-ili.sh wget curl vim > /tmp/script_output.log 2>&1; then
    test_pass "Script executed successfully"
else
    test_fail "Script execution failed"
    cat /tmp/script_output.log
fi

# Test 2: Verify image file creation
test_start "Verify image file exists and has correct size"
if [ -f /var/tmp/ukol.img ]; then
    SIZE=$(stat -c%s /var/tmp/ukol.img)
    EXPECTED_SIZE=$((200 * 1024 * 1024))
    if [ "$SIZE" -ge "$EXPECTED_SIZE" ]; then
        test_pass "Image file created with correct size ($SIZE bytes)"
    else
        test_fail "Image file size incorrect (expected $EXPECTED_SIZE, got $SIZE)"
    fi
else
    test_fail "Image file /var/tmp/ukol.img not found"
fi

# Test 3: Verify loop device
test_start "Verify loop device is attached"
LOOP_DEVICE=$(losetup -j /var/tmp/ukol.img | cut -d: -f1)
if [ -n "$LOOP_DEVICE" ]; then
    test_pass "Loop device attached: $LOOP_DEVICE"
else
    test_fail "No loop device found for ukol.img"
fi

# Test 4: Verify filesystem
test_start "Verify ext4 filesystem on loop device"
if [ -n "$LOOP_DEVICE" ]; then
    FS_TYPE=$(blkid -o value -s TYPE "$LOOP_DEVICE" 2>/dev/null || echo "unknown")
    if [ "$FS_TYPE" = "ext4" ]; then
        test_pass "ext4 filesystem confirmed"
    else
        test_fail "Filesystem is $FS_TYPE, expected ext4"
    fi
fi

# Test 5: Verify mount point
test_start "Verify filesystem is mounted"
if mount | grep -q "/var/www/html/ukol"; then
    test_pass "Filesystem is mounted at /var/www/html/ukol"
else
    test_fail "Filesystem not mounted"
fi

# Test 6: Verify fstab entry
test_start "Verify fstab entry exists"
if grep -q "/var/www/html/ukol" /etc/fstab; then
    test_pass "fstab entry found"
    grep "/var/www/html/ukol" /etc/fstab
else
    test_fail "fstab entry missing"
fi

# Test 7: Verify RPM packages downloaded
test_start "Verify RPM packages are present"
RPM_COUNT=$(find /var/www/html/ukol -name "*.rpm" 2>/dev/null | wc -l)
if [ "$RPM_COUNT" -gt 0 ]; then
    test_pass "Found $RPM_COUNT RPM packages"
else
    test_fail "No RPM packages found"
fi

# Test 8: Verify repository metadata
test_start "Verify repository metadata (repodata)"
if [ -d /var/www/html/ukol/repodata ]; then
    if [ -f /var/www/html/ukol/repodata/repomd.xml ]; then
        test_pass "Repository metadata created successfully"
    else
        test_fail "repomd.xml not found"
    fi
else
    test_fail "repodata directory not found"
fi

# Test 9: Verify SELinux contexts
test_start "Verify SELinux contexts are correct"
if command -v getenforce &> /dev/null && [ "$(getenforce)" != "Disabled" ]; then
    CONTEXT=$(ls -Zd /var/www/html/ukol 2>/dev/null | awk '{print $1}')
    if echo "$CONTEXT" | grep -q "httpd_sys_content_t"; then
        test_pass "Correct SELinux context applied"
    else
        test_fail "SELinux context incorrect: $CONTEXT"
    fi
else
    echo "  Skipping: SELinux is disabled"
    TESTS_RUN=$((TESTS_RUN - 1))
fi

# Test 10: Verify YUM repo configuration
test_start "Verify YUM repository configuration"
if [ -f /etc/yum.repos.d/ukol.repo ]; then
    test_pass "ukol.repo configuration file exists"
    cat /etc/yum.repos.d/ukol.repo
else
    test_fail "ukol.repo not found"
fi

# Test 11: Verify Apache is running
test_start "Verify Apache (httpd) service is running"
if systemctl is-active --quiet httpd; then
    test_pass "httpd service is active"
else
    test_fail "httpd service is not running"
fi

# Test 12: Verify repository accessibility via HTTP
test_start "Verify repository is accessible via HTTP"
if curl -s -o /dev/null -w "%{http_code}" http://localhost/ukol/repodata/repomd.xml | grep -q "200"; then
    test_pass "Repository accessible via HTTP"
else
    test_fail "Repository not accessible via HTTP"
fi

# Test 13: Verify YUM can see the repository
test_start "Verify YUM recognizes the ukol repository"
if yum repolist | grep -q "ukol"; then
    test_pass "ukol repository is in YUM repolist"
else
    test_fail "ukol repository not found in YUM repolist"
fi

# Test 14: Test unmount and remount
test_start "Test unmount and remount functionality"
umount /var/www/html/ukol
if ! mount | grep -q "/var/www/html/ukol"; then
    test_pass "Successfully unmounted"
    mount -a
    if mount | grep -q "/var/www/html/ukol"; then
        test_pass "Successfully remounted via mount -a"
    else
        test_fail "Failed to remount via mount -a"
    fi
else
    test_fail "Failed to unmount"
fi

# Test 15: Query packages from ukol repository
test_start "Query packages from ukol repository only"
PACKAGE_COUNT=$(yum --disablerepo="*" --enablerepo="ukol" list available 2>/dev/null | grep -c "^[a-zA-Z]" || echo "0")
if [ "$PACKAGE_COUNT" -gt 0 ]; then
    test_pass "Found $PACKAGE_COUNT packages in ukol repository"
else
    test_fail "No packages found in ukol repository"
fi

# Summary
echo ""
echo "=================================="
echo "Integration Test Summary"
echo "=================================="
echo "Tests Run:    $TESTS_RUN"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo "Success Rate: $(( TESTS_PASSED * 100 / TESTS_RUN ))%"
echo "=================================="
echo "Completed: $(date)"
echo "Log file: $LOG_FILE"
echo "=================================="

if [ "$TESTS_FAILED" -eq 0 ]; then
    exit 0
else
    exit 1
fi
