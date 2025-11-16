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
rm -rf sepolicy_backups_20251116_092239

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
echo "=========================================="
echo "SELinux Duplicate Attribute Fixer"
echo "=========================================="
echo ""

grep -q "attribute hal_misys" "vendor/xiaomi/vayu-miuicamera/sepolicy/vendor/attributes"
sed -i "s/^attribute hal_misys;/# attribute hal_misys; # Commented out - duplicate declaration/g" "vendor/xiaomi/vayu-miuicamera/sepolicy/vendor/attributes"

grep -q "attribute hal_misys_client" "vendor/xiaomi/vayu-miuicamera/sepolicy/vendor/attributes"
sed -i "s/^attribute hal_misys_client;/# attribute hal_misys_client; # Commented out - duplicate declaration/g" "vendor/xiaomi/vayu-miuicamera/sepolicy/vendor/attributes"

grep -q "attribute hal_misys_server" "vendor/xiaomi/vayu-miuicamera/sepolicy/vendor/attributes"
sed -i "s/^attribute hal_misys_server;/# attribute hal_misys_server; # Commented out - duplicate declaration/g" "vendor/xiaomi/vayu-miuicamera/sepolicy/vendor/attributes"

sed -i 's/^type hal_misys_default, domain;/# DUPLICATE - type hal_misys_default, domain; # Declared elsewhere/' "device/xiaomi/vayu/sepolicy/vendor/hal_misys_default.te"
sed -i 's/^type hal_misys_default_exec, exec_type, vendor_file_type, file_type;/# DUPLICATE - type hal_misys_default_exec, exec_type, vendor_file_type, file_type; # Declared elsewhere/' "device/xiaomi/vayu/sepolicy/vendor/hal_misys_default.te"

echo "=========================================="
echo "Fix Complete!"
echo "=========================================="
echo ""

export BUILD_USERNAME=zsheesh
export BUILD_HOSTNAME=crave

#build
. build/envsetup.sh
lunch arrow_vayu-userdebug
mka installclean
m bacon
