#!/bin/bash
# Quick verification script for ILI installation

echo "=================================="
echo "ILI Installation Verification"
echo "=================================="
echo ""

echo "1. Loop Device Status:"
if losetup -a | grep -q ukol; then
    losetup -a | grep ukol
else
    echo "  ✗ Not found"
fi

echo ""
echo "2. Mount Status:"
if mount | grep -q ukol; then
    mount | grep ukol
else
    echo "  ✗ Not mounted"
fi

echo ""
echo "3. Filesystem Information:"
if df -h | grep -q ukol; then
    df -h | grep ukol
else
    echo "  ✗ Not found"
fi

echo ""
echo "4. Repository Files:"
if [ -d /var/www/html/ukol ]; then
    RPM_COUNT=$(ls -1 /var/www/html/ukol/*.rpm 2>/dev/null | wc -l)
    echo "  RPM packages: $RPM_COUNT"
    if [ -d /var/www/html/ukol/repodata ]; then
        echo "  Repodata: ✓ Present"
    else
        echo "  Repodata: ✗ Missing"
    fi
else
    echo "  ✗ Directory not found"
fi

echo ""
echo "5. Apache (httpd) Service:"
if systemctl is-active --quiet httpd; then
    echo "  Status: ✓ Active"
    echo "  Port 80: $(ss -tlnp | grep -q ':80' && echo '✓ Listening' || echo '✗ Not listening')"
else
    echo "  Status: ✗ Inactive"
fi

echo ""
echo "6. YUM Repository Configuration:"
if [ -f /etc/yum.repos.d/ukol.repo ]; then
    echo "  Config file: ✓ Present"
    if yum repolist 2>/dev/null | grep -q ukol; then
        echo "  Repository: ✓ Available"
    else
        echo "  Repository: ✗ Not in repolist"
    fi
else
    echo "  Config file: ✗ Missing"
fi

echo ""
echo "7. fstab Entry:"
if grep -q "/var/www/html/ukol" /etc/fstab 2>/dev/null; then
    echo "  ✓ Present"
    grep "/var/www/html/ukol" /etc/fstab | sed 's/^/  /'
else
    echo "  ✗ Missing"
fi

echo ""
echo "8. HTTP Accessibility:"
if command -v curl &> /dev/null; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ukol/repodata/repomd.xml 2>/dev/null)
    if [ "$HTTP_CODE" = "200" ]; then
        echo "  ✓ Repository accessible (HTTP 200)"
    else
        echo "  ✗ Not accessible (HTTP $HTTP_CODE)"
    fi
else
    echo "  ⚠ curl not available for testing"
fi

echo ""
echo "=================================="
echo "Verification Complete"
echo "=================================="
