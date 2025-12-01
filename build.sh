#!/bin/bash

#removals
rm -rf *
echo "=================="
echo "Remove old config success"
echo "=================="

#init
repo init -u https://github.com/bananadroid/android_manifest.git -b 14 --git-lfs
echo "=================="
echo "Repo init success"
echo "=================="

sed -i '/<project path="hardware\/samsung" name="android_hardware_samsung" remote="banana" \/>/d' ".repo/manifests/banana.xml"

#clone local
git clone https://github.com/zackyape/local_manifests_samsung -b Exynos7885-new-fourteen .repo/local_manifests
echo "=================="
echo "Local manifests clone success"
echo "=================="

#sync
if [ -f /opt/crave/resync.sh ]; then
  /opt/crave/resync.sh
else
  repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags --optimized-fetch --prune
fi
echo "=================="
echo "Sync success"
echo "=================="
# custom repos
# rm -rf vendor/lineage-priv/keys
# git clone --depth=1 https://github.com/pure-soul-kk/keys vendor/lineage-priv/keys

#some stuffs

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

export BUILD_USERNAME=zsheesh
export BUILD_HOSTNAME=crave

#build
. build/envsetup.sh
m clean
lunch banana_a30s-userdebug
mka installclean
m banana
