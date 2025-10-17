#!/bin/bash
# Cleanup script for ILI tests
# Removes all created resources

set -e

echo "Starting cleanup..."

# Unmount filesystem
if mount | grep -q "/var/www/html/ukol"; then
    echo "Unmounting /var/www/html/ukol..."
    umount /var/www/html/ukol 2>/dev/null || true
fi

# Detach loop device
LOOP_DEVICE=$(losetup -j /var/tmp/ukol.img 2>/dev/null | cut -d: -f1)
if [ -n "$LOOP_DEVICE" ]; then
    echo "Detaching loop device $LOOP_DEVICE..."
    losetup -d "$LOOP_DEVICE" 2>/dev/null || true
fi

# Remove fstab entry
if grep -q "/var/www/html/ukol" /etc/fstab 2>/dev/null; then
    echo "Removing fstab entry..."
    sed -i '/\/var\/www\/html\/ukol/d' /etc/fstab
fi

# Remove image file
if [ -f /var/tmp/ukol.img ]; then
    echo "Removing image file..."
    rm -f /var/tmp/ukol.img
fi

# Remove mount directory
if [ -d /var/www/html/ukol ]; then
    echo "Removing mount directory..."
    rm -rf /var/www/html/ukol
fi

# Remove YUM repo configuration
if [ -f /etc/yum.repos.d/ukol.repo ]; then
    echo "Removing YUM repo configuration..."
    rm -f /etc/yum.repos.d/ukol.repo
fi

# Clean YUM cache
echo "Cleaning YUM cache..."
yum clean all > /dev/null 2>&1 || true

echo "Cleanup completed successfully!"
