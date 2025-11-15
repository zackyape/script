#!/bin/bash

#removals
rm -rf .repo/local_manifests

# Remove tree
rm -rf prebuilts/clang/host/linux-x86
rm -rf device/xiaomi/vayu
rm -rf hardware/xiaomi
rm -rf vendor/xiaomi/vayu
rm -rf vendor/xiaomi/sm8150-common
rm -rf kernel/xiaomi/vayu
rm -rf kernel/xiaomi/sm8150
rm -rf vendor/xiaomi/vayu-miuicamera
rm -rf packages/apps/ViPER4AndroidFX

#init
repo init -u https://github.com/ArrowOS-T/android_manifest.git -b arrow-13.1_ext --git-lfs --depth=1
echo "=================="
echo "Repo init success"
echo "=================="
#clone local
git clone https://github.com/zackyape/script -b arrow .repo/local_manifests
git clone https://github.com/kdrag0n/proton-clang --depth 1  prebuilts/clang/host/linux-x86/clang-proton
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

if [ -z "$LIBNCURSES" ]; then
    echo "libncurses.so.6 tidak ditemukan!"
    exit 1
fi

echo "Ditemukan: $LIBNCURSES"

# Dapatkan direktori
LIBDIR=$(dirname "$LIBNCURSES")

# Buat symlink
sudo ln -sf "$LIBNCURSES" "$LIBDIR/libncurses.so.5"

echo "Symlink dibuat: $LIBDIR/libncurses.so.5 -> $LIBNCURSES"

# Update ldconfig
sudo ldconfig

# Verifikasi
ls -la "$LIBDIR/libncurses.so.5"

#build
make clean
. build/envsetup.sh
lunch arrow_vayu-userdebug
mka installclean
m bacon
