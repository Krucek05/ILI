#!/usr/bin/env bash
# ILI - Mid-semester assignment automation script (Fedora Server)

IMG="/var/tmp/ukol.img"
SIZE_MB=200
MOUNT="/var/www/html/ukol"
REPO="/etc/yum.repos.d/ukol.repo"

# needed packages
echo "Installing neccesarry packages"
echo "Please wait..." 
yum -y install yum-utils createrepo_c httpd >/dev/null

# 1) Create 200 MB file
echo "1) Creating ${SIZE_MB} MB file $IMG"
dd if=/dev/zero of="$IMG" bs=1M count="$SIZE_MB" status=none

# 2) Create loop device
echo "2) Creating loop device for ukol.img"
losetup -f --show /var/tmp/ukol.img
echo created loop device /dev/loop0

# 3) Create ext4 filesystem on loop device
echo "3) Creating ext4 filesystem"
mkfs.ext4 /dev/loop0

# 4) Configure /etc/fstab for automatic mount (using loop device)
echo "4) Updating /etc/fstab for automatic mount"
mkdir -p "$MOUNT"
echo "/dev/loop0  $MOUNT  ext4  defaults  0 0" >> /etc/fstab

# 5) Mount filesystem to /var/www/html/ukol
echo "5) Mounting filesystem to $MOUNT"
mount -p "$MOUNT"

# 6) Download given packages into repository directory
echo "6) Downloading packages into $MOUNT"
if [ "$#" -gt 0 ]; then
  yumdownloader --destdir "$MOUNT" "$@"
  echo "downloaded additional packages ..."
else
  echo "no arguments specifiedmount"
fi

# 7) Generate repodata to /var/www/html/ukol
echo "7) Creating repodata"
createrepo "$MOUNT" >/dev/null
echo "applying SELinux context"
restorecon -Rv "$MOUNT"

# 8) Configure repo file with url
echo "8) Writing $REPO"
cat > "$REPO" <<'EOF'
[ukol]
name=Local ukol repo
baseurl=http://localhost/ukol
enabled=1
gpgcheck=0
EOF

# 9) Install and start Apache (httpd)
echo "9) Installing and starting httpd"
systemctl enable --now httpd >/dev/null

echo "10) Listing available yum repositories"
yum repolist

# 11) Unmount filesystem
echo "11) Unmounting $MNT"
umount "$MNT"

# 12) Run 'mount -a' and verify mount
echo "12) Running 'mount -a' and verifying"
echo "..."
mount -a
if mount | grep -q " $MNT "; then
  echo "Filesystem is mounted at $MNT"
else
  echo "Filesystem is NOT mounted at $MNT"
fi

# 13) Show info about packages from 'ukol' only
echo "13) Showing info about available packages from 'ukol' only"
yum --disablerepo="*" --enablerepo="ukol" info available || true

echo "All tasks done"
