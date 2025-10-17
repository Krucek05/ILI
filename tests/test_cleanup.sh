#!/bin/bash
# Tests for cleanup functionality

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=================================="
echo "ILI Cleanup Tests"
echo "Started: $(date)"
echo "=================================="

# Run cleanup
echo -e "\n${BLUE}Running cleanup script...${NC}"
bash tests/cleanup.sh

# Verify cleanup
FAILURES=0

echo -e "\n${BLUE}Verifying cleanup results:${NC}"

echo -n "  Checking if loop device is detached... "
if losetup -a | grep -q "ukol.img"; then
    echo -e "${RED}FAIL${NC}"
    FAILURES=$((FAILURES + 1))
else
    echo -e "${GREEN}PASS${NC}"
fi

echo -n "  Checking if image file is removed... "
if [ -f /var/tmp/ukol.img ]; then
    echo -e "${RED}FAIL${NC}"
    FAILURES=$((FAILURES + 1))
else
    echo -e "${GREEN}PASS${NC}"
fi

echo -n "  Checking if fstab entry is removed... "
if grep -q "/var/www/html/ukol" /etc/fstab 2>/dev/null; then
    echo -e "${RED}FAIL${NC}"
    FAILURES=$((FAILURES + 1))
else
    echo -e "${GREEN}PASS${NC}"
fi

echo -n "  Checking if mount directory is removed... "
if [ -d /var/www/html/ukol ]; then
    echo -e "${RED}FAIL${NC}"
    FAILURES=$((FAILURES + 1))
else
    echo -e "${GREEN}PASS${NC}"
fi

echo -n "  Checking if repo config is removed... "
if [ -f /etc/yum.repos.d/ukol.repo ]; then
    echo -e "${RED}FAIL${NC}"
    FAILURES=$((FAILURES + 1))
else
    echo -e "${GREEN}PASS${NC}"
fi

echo ""
echo "=================================="
if [ $FAILURES -eq 0 ]; then
    echo -e "${GREEN}All cleanup tests passed!${NC}"
    echo "=================================="
    exit 0
else
    echo -e "${RED}$FAILURES cleanup test(s) failed!${NC}"
    echo "=================================="
    exit 1
fi
