#!/bin/bash
# Generate comprehensive test report

REPORT_FILE="tests/test_report_$(date +%Y%m%d_%H%M%S).txt"

echo "Generating test report..."

{
    echo "=========================================="
    echo "ILI Project - Test Report"
    echo "=========================================="
    echo ""
    echo "Generated: $(date)"
    echo "System: $(uname -a)"
    echo ""
    
    echo "=========================================="
    echo "1. BASIC UNIT TESTS"
    echo "=========================================="
    if [ -f "tests/test_basic.log" ]; then
        tail -20 tests/test_basic.log
    else
        echo "No basic test log found"
    fi
    echo ""
    
    echo "=========================================="
    echo "2. ADVANCED INTEGRATION TESTS"
    echo "=========================================="
    if [ -f "tests/test_advanced.log" ]; then
        tail -20 tests/test_advanced.log
    else
        echo "No advanced test log found"
    fi
    echo ""
    
    echo "=========================================="
    echo "3. CURRENT INSTALLATION STATUS"
    echo "=========================================="
    bash tests/verify.sh 2>&1
    echo ""
    
    echo "=========================================="
    echo "4. SYSTEM RESOURCES"
    echo "=========================================="
    echo "Disk Usage:"
    df -h | grep -E '(Filesystem|/var|/tmp)'
    echo ""
    echo "Memory Usage:"
    free -h
    echo ""
    echo "Loop Devices:"
    losetup -a || echo "None"
    echo ""
    
    echo "=========================================="
    echo "5. APACHE STATUS"
    echo "=========================================="
    systemctl status httpd --no-pager || echo "httpd not running"
    echo ""
    
    echo "=========================================="
    echo "6. YUM REPOSITORIES"
    echo "=========================================="
    yum repolist 2>/dev/null || echo "Unable to query repositories"
    echo ""
    
    echo "=========================================="
    echo "END OF REPORT"
    echo "=========================================="
} > "$REPORT_FILE"

echo "Report generated: $REPORT_FILE"
cat "$REPORT_FILE"
