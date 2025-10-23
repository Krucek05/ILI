#!/usr/bin/env bash
# ILI - Mid-semester assignment automation script (Fedora Server)

IMG="/var/tmp/ukol.img"
SIZE_MB=200
MOUNT="/var/www/html/ukol"
REPO="/etc/yum.repos.d/ukol.repo"


# ---- cleanup support ----
cleanup() {
  echo "Cleaning ukol setup"

  # 1) Unmount if mounted
  if mountpoint -q "$MOUNT"; then
    echo " - Unmounting $MOUNT"
    umount -l "$MOUNT" || true
  fi

  # 2) Remove fstab entry/entries for this mount
  if grep -q "/var/www/html/ukol" /etc/fstab 2>/dev/null; then
    echo " - Removing /etc/fstab entries"
    sed -i '\|/var/www/html/ukol|d' /etc/fstab
    systemctl daemon-reload || true
  fi

  # 3) Detach any loop device backed by the image
  for dev in $(losetup -j "$IMG" | cut -d: -f1); do
    echo " - Detaching $dev"
    losetup -d "$dev" || true
  done

  # 4) Remove the image
  if [ -f "$IMG" ]; then
    echo " - Deleting image $IMG"
    rm -f "$IMG"
  fi

  # 5) Remove repo file
  if [ -f "$REPO" ]; then
    echo " - Removing repo file $REPO"
    rm -f "$REPO"
  fi

  # 6) Clean repo dir (only if not mounted)
  if [ -d "$MOUNT" ] && ! mountpoint -q "$MOUNT"; then
    echo " - Cleaning $MOUNT directory"
    rm -rf "$MOUNT"/*
  fi

  echo "Cleanup done."
}

# Call cleanup and exit if requested
if [ "${1:-}" = "-clean" ] || [ "${1:-}" = "--clean" ]; then
  cleanup
  exit 0
fi

# needed packages
echo "Installing neccesarry packages"
echo "Please wait..." 
yum -y install yum-utils createrepo_c httpd >/dev/null

# 1) Create 200 MB file
echo "1) Creating ${SIZE_MB} MB file $IMG"
dd if=/dev/zero of="$IMG" bs=1M count="$SIZE_MB" status=none

# 2) Create loop device
echo "2) Creating loop device for ukol.img"
LOOP_NAME="$(losetup -f --show "$IMG")"
echo "created loop device $LOOP_NAME"

# 3) Create ext4 filesystem on loop device
echo "3) Creating ext4 filesystem"
mkfs.ext4 -F "$LOOP_NAME"  >/dev/null

# 4) Configure /etc/fstab for automatic mount (using loop device)
echo "4) Updating /etc/fstab for automatic mount"
mkdir -p "$MOUNT"
sed -i '/\/var\/www\/html\/ukol/d' /etc/fstab
ENTRY="$IMG  $MOUNT  ext4  loop,defaults,nofail  0 0"
grep -qF "$ENTRY" /etc/fstab || printf "%s\n" "$ENTRY" >> /etc/fstab


# 5) Mount filesystem to /var/www/html/ukol
echo "5) Mounting filesystem to $MOUNT"
mount -a
mountpoint -q "$MOUNT" && echo "   .. mounted" || { echo "   .. mount FAILED"; exit 1; }

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
echo "11) Unmounting $MOUNT"
umount "$MOUNT"

# 12) Run 'mount -a' and verify mount
echo "12) Running 'mount -a' and verifying"
echo "..."
mount -a
if mount | grep -q " $MOUNT "; then
  echo "Filesystem is mounted at $MOUNT"
else
  echo "Filesystem is NOT mounted at $MOUNT"
fi

# 13) Show info about packages from 'ukol' only
echo "13) Showing info about available packages from 'ukol' only"
yum --disablerepo="*" --enablerepo="ukol" info available || true

echo "All tasks done"


# ---- cleanup support ----
cleanup() {
  echo "Cleaning ukol setup"

  # 1) Unmount if mounted
  if mountpoint -q "$MOUNT"; then
    echo " - Unmounting $MOUNT"
    umount -l "$MOUNT" || true
  fi

  # 2) Remove fstab entry/entries for this mount
  if grep -q "/var/www/html/ukol" /etc/fstab 2>/dev/null; then
    echo " - Removing /etc/fstab entries"
    sed -i '\|/var/www/html/ukol|d' /etc/fstab
    systemctl daemon-reload || true
  fi

  # 3) Detach any loop device backed by the image
  for dev in $(losetup -j "$IMG" | cut -d: -f1); do
    echo " - Detaching $dev"
    losetup -d "$dev" || true
  done

  # 4) Remove the image
  if [ -f "$IMG" ]; then
    echo " - Deleting image $IMG"
    rm -f "$IMG"
  fi

  # 5) Remove repo file
  if [ -f "$REPO" ]; then
    echo " - Removing repo file $REPO"
    rm -f "$REPO"
  fi

  # 6) Clean repo dir (only if not mounted)
  if [ -d "$MOUNT" ] && ! mountpoint -q "$MOUNT"; then
    echo " - Cleaning $MOUNT directory"
    rm -rf "$MOUNT"/*
  fi

  echo "Cleanup done."
}

# Call cleanup and exit if requested
if [ "${1:-}" = "-clean" ] || [ "${1:-}" = "--clean" ]; then
  cleanup
  exit 0
fi
