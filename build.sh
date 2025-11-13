#!/bin/bash

#removals
rm -rf .repo/local_manifests

#sync
repo init -u https://github.com/ArrowOS-T/android_manifest.git -b arrow-13.1_ext --git-lfs --depth=1
git clone https://github.com/zackyape/scripts -b arrow .repo/local_manifests
if [ -f /opt/crave/resync.sh ]; then
  /opt/crave/resync.sh
else
  repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
fi

# custom repos
# rm -rf vendor/lineage-priv/keys
# git clone --depth=1 https://github.com/pure-soul-kk/keys vendor/lineage-priv/keys

export BUILD_USERNAME=zsheesh
export BUILD_HOSTNAME=crave

#build
. build/envsetup.sh
lunch arrow_vayu-user
mka installclean
m bacon
