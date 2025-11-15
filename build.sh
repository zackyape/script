#!/bin/bash

#removals
rm -rf .repo/local_manifests

# Remove tree
rm -rf device/xiaomi/vayu
rm -rf hardware/xiaomi
rm -rf vendor/xiaomi/vayu
rm -rf kernel/xiaomi/vayu
rm -rf vendor/xiaomi/vayu-miuicamera
rm -rf packages/apps/ViPER4AndroidFX

#init
repo init -u https://github.com/ArrowOS-T/android_manifest.git -b arrow-13.1_ext --git-lfs --depth=1
echo "=================="
echo "Repo init success"
echo "=================="
#clone local
git clone https://github.com/zackyape/script -b arrow .repo/local_manifests
git clone https://github.com/TogoFire/packages_apps_ViPER4AndroidFX.git -b v4a packages/apps/ViPER4AndroidFX
echo "=================="
echo "Local manifests clone success"
echo "=================="

#sync
if [ -f /opt/crave/resync.sh ]; then
  /opt/crave/resync.sh
else
  repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
fi
echo "=================="
echo "Sync success"
echo "=================="
# custom repos
# rm -rf vendor/lineage-priv/keys
# git clone --depth=1 https://github.com/pure-soul-kk/keys vendor/lineage-priv/keys

#some stuffs
sed -i 's/preprocessed: true,/\/\/ preprocessed: true, \/\/ Removed - unsupported/' \
    packages/apps/ViPER4AndroidFX/Android.bp

export BUILD_USERNAME=zsheesh
export BUILD_HOSTNAME=crave

# Cari file libncurses
LIBNCURSES=$(find /usr/lib /lib /usr/local/lib -name "libncurses.so.6*" 2>/dev/null | head -n 1)
LIBTINFO=$(find /usr/lib /lib /usr/local/lib -name "libtinfo.so.6*" 2>/dev/null | head -n 1)

if [ -z "$LIBNCURSES" ]; then
    echo "libncurses.so.6 tidak ditemukan!"
    exit 1
fi

echo "Ditemukan: $LIBNCURSES"

if [ -z "$LIBTINFO" ]; then
    echo "libtinfo.so.6 tidak ditemukan!"
    exit 1
fi

echo "Ditemukan: $LIBTINFO"

# Dapatkan direktori
LIBDIRNCURSES=$(dirname "$LIBNCURSES")
LIBDIRTINFO=$(dirname "$LIBTINFO")

# Buat symlink
sudo ln -sf "$LIBNCURSES" "$LIBDIRNCURSES/libncurses.so.5"

echo "Symlink dibuat: $LIBDIRNCURSES/libncurses.so.5 -> $LIBNCURSES"

sudo ln -sf "$LIBTINFO" "$LIBDIRTINFO/libtinfo.so.5"

echo "Symlink dibuat: $LIBDIRTINFO/libtinfo.so.5 -> $LIBTINFO"

# Update ldconfig
sudo ldconfig

# Verifikasi
ls -la "$LIBDIRNCURSES/libncurses.so.5"
ls -la "$LIBDIRTINFO/libtinfo.so.5"

# SELinux Duplicate Attribute Fix Script
# Fixes duplicate hal_misys declaration in Xiaomi MIUI Camera sepolicy

set -e

SEPOLICY_FILE="vendor/xiaomi/vayu-miuicamera/sepolicy/vendor/attributes"
BACKUP_FILE="${SEPOLICY_FILE}.backup"
ATTRIBUTE_NAME="hal_misys"

echo "=========================================="
echo "SELinux Duplicate Attribute Fixer"
echo "=========================================="
echo ""

# Check if running from Android source root
if [ ! -d "vendor" ] || [ ! -d "system/sepolicy" ]; then
    echo "ERROR: This script must be run from the Android source root directory"
    exit 1
fi

# Check if the problematic file exists
if [ ! -f "$SEPOLICY_FILE" ]; then
    echo "ERROR: File not found: $SEPOLICY_FILE"
    exit 1
fi

echo "[1/4] Searching for duplicate declarations of '$ATTRIBUTE_NAME'..."
echo ""

# Find all declarations
echo "Declarations found:"
grep -rn "attribute $ATTRIBUTE_NAME" vendor/ device/ system/sepolicy/ 2>/dev/null || true
echo ""

# Create backup
echo "[2/4] Creating backup..."
cp "$SEPOLICY_FILE" "$BACKUP_FILE"
echo "Backup created: $BACKUP_FILE"
echo ""

# Check if attribute exists in the file
if grep -q "attribute $ATTRIBUTE_NAME" "$SEPOLICY_FILE"; then
    echo "[3/4] Fixing duplicate declaration in $SEPOLICY_FILE..."
    
    # Comment out the duplicate line
    sed -i "s/^attribute $ATTRIBUTE_NAME;/# attribute $ATTRIBUTE_NAME; # Commented out - duplicate declaration/g" "$SEPOLICY_FILE"
    
    echo "Fixed! The line has been commented out."
    echo ""

#build
make clean
. build/envsetup.sh
lunch arrow_vayu-userdebug
mka installclean
m bacon
