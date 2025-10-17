# ILI - Linux System Administration Automation

[![Language](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square&logo=gnu-bash)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Fedora_Server-294172?style=flat-square&logo=fedora)](https://getfedora.org/)
[![License](https://img.shields.io/badge/License-Academic-blue?style=flat-square)](LICENSE)

## 📋 Overview

This project is a **mid-semester assignment** focused on Linux system administration and automation. The goal is to create a comprehensive Bash script that demonstrates proficiency in:

- **Storage Management** (loop devices, filesystems)
- **Package Management** (YUM repositories)
- **Web Server Configuration** (Apache/httpd)
- **System Automation** (fstab, systemd services)
- **SELinux Configuration**

The script automates the creation of a local YUM repository hosted on a web server, utilizing loop devices and proper filesystem management.

## 🎯 Project Objectives

### Core Functionality

The automation script performs the following operations:

1. **Storage Setup**
   - Creates a 200 MB disk image file (`/var/tmp/ukol.img`)
   - Configures a loop device for the image
   - Formats the loop device with ext4 filesystem

2. **Filesystem Management**
   - Configures automatic mounting via `/etc/fstab`
   - Mounts filesystem to `/var/www/html/ukol`
   - Ensures persistence across reboots

3. **Repository Creation**
   - Downloads specified RPM packages from system repositories
   - Generates repository metadata (repodata)
   - Applies correct SELinux contexts

4. **Web Server Configuration**
   - Installs and configures Apache (httpd)
   - Serves the local repository via HTTP
   - Creates repository configuration at `/etc/yum.repos.d/ukol.repo`

5. **Validation & Testing**
   - Verifies repository availability
   - Tests automatic mounting functionality
   - Lists packages from the custom repository

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│         Script Execution Flow           │
└─────────────────────────────────────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │  1. Image Creation    │
        │  /var/tmp/ukol.img    │
        └───────────────────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │  2. Loop Device Setup │
        │  /dev/loopX           │
        └───────────────────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │  3. Filesystem Format │
        │  ext4                 │
        └───────────────────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │  4. fstab Config      │
        │  Auto-mount setup     │
        └───────────────────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │  5. Mount Filesystem  │
        │  /var/www/html/ukol   │
        └───────────────────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │  6. Download Packages │
        │  yum download         │
        └───────────────────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │  7. Create Repodata   │
        │  + SELinux context    │
        └───────────────────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │  8. Repository Config │
        │  /etc/yum.repos.d/    │
        └───────────────────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │  9. Apache Setup      │
        │  http://localhost     │
        └───────────────────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │  10-13. Verification  │
        │  Testing & Validation │
        └───────────────────────┘
```

## 📝 Requirements Breakdown

| # | Requirement | Points | Description |
|---|-------------|--------|-------------|
| 1 | **Image File Creation** | 1 | Create 200 MB file at `/var/tmp/ukol.img` |
| 2 | **Loop Device** | 1 | Attach loop device to the image file |
| 3 | **Filesystem** | 1 | Format loop device with ext4 filesystem |
| 4 | **fstab Configuration** | 2 | Configure automatic mounting via fstab |
| 5 | **Mount Point** | 1 | Mount filesystem to `/var/www/html/ukol` |
| 6 | **Package Download** | 2 | Download RPM packages (script arguments) using yum |
| 7 | **Repository Metadata** | 1 | Generate repodata + apply SELinux context |
| 8 | **YUM Configuration** | 2 | Configure `/etc/yum.repos.d/ukol.repo` |
| 9 | **Web Server** | 2 | Install and start Apache httpd service |
| 10 | **Repository List** | 2 | Display available YUM repositories |
| 11 | **Unmount Test** | 1 | Unmount the filesystem |
| 12 | **Auto-Mount Test** | 2 | Verify `mount -a` functionality |
| 13 | **Package Query** | 2 | List packages from "ukol" repository only |

**Total: 20 Points**

## 🔧 Technical Requirements

### Environment
- **Operating System**: Fedora Server (clean, default installation)
- **Shell**: Bash
- **Execution**: Root user privileges
- **Line Endings**: Unix format (LF)

### Dependencies
The script must automatically install required packages:
```bash
yum install -y createrepo httpd yum-utils
```

### File Naming
- Submission file: `xloginXX-fit-ili.sh`
- Replace `xloginXX` with your actual login ID

## 📤 Submission Guidelines

### Requirements
✅ **Uploaded to FIT system**  
✅ **Named correctly**: `xloginXX-fit-ili.sh`  
✅ **Executable**: `chmod +x xloginXX-fit-ili.sh`  
✅ **Runs on clean Fedora Server**  
✅ **No command-line arguments needed** (for 10 core requirements)  
✅ **Outputs descriptive logs** to stdout  

### Example Output Format
```bash
1) Creating 200 MB file /var/tmp/ukol.img
   .. allocating disk space
   .. file created successfully

2) Creating loop device for ukol.img
   .. loop device /dev/loop0 created
   
3) Creating ext4 filesystem on loop device
   .. formatting /dev/loop0
   .. filesystem created
```

## 🧪 Testing & Validation

### Recommended Testing Approach
1. **Use VM snapshots** for clean environment testing
2. **Test script multiple times** on fresh Fedora installation
3. **Verify each requirement** individually
4. **Check log output** for clarity and completeness
5. **Validate services** are running (httpd)
6. **Confirm repository accessibility** via HTTP

### Verification Commands
```bash
# Check loop device
losetup -a

# Verify mount
df -h | grep ukol

# Test repository
yum repolist
yum --disablerepo="*" --enablerepo="ukol" list available

# Check web server
systemctl status httpd
curl http://localhost/ukol/repodata/repomd.xml
```

## 🚀 Quick Start

### Execution
```bash
# Run as root
sudo ./xloginXX-fit-ili.sh [package1] [package2] ...

# Example
sudo ./xlogin00-fit-ili.sh wget curl vim
```

### Cleanup (Optional)
```bash
# Unmount filesystem
umount /var/www/html/ukol

# Detach loop device
losetup -d /dev/loopX

# Remove files
rm -rf /var/tmp/ukol.img /var/www/html/ukol
```

## 📚 Key Concepts Demonstrated

- **Loop Devices**: Virtual block devices backed by regular files
- **Filesystem Management**: Creating, formatting, and mounting filesystems
- **fstab Configuration**: Automatic mounting at boot time
- **YUM Repositories**: Creating custom package repositories
- **Apache Web Server**: Serving content via HTTP
- **SELinux**: Security context management
- **Bash Scripting**: System automation and logging

## ⚠️ Important Notes

- Script must be **idempotent** where possible
- All operations require **root privileges**
- Proper **error handling** is recommended
- **SELinux context** must be applied: `restorecon -Rv /var/www/html/ukol`
- Script should handle **missing dependencies** gracefully

## 📖 Resources

- [Fedora Server Documentation](https://docs.fedoraproject.org/en-US/fedora-server/)
- [Bash Scripting Guide](https://www.gnu.org/software/bash/manual/)
- [YUM/DNF Documentation](https://dnf.readthedocs.io/)
- [Apache HTTP Server](https://httpd.apache.org/docs/)

---

**Course**: ILI - Linux Administration  
**Assignment Type**: Mid-semester (20 points)  
**Academic Year**: 2024/2025