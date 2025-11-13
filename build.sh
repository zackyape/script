#!/bin/bash

#removals
rm -rf .repo/local_manifests

#sync
repo init -u https://github.com/AxionAOSP/android.git -b lineage-23.0 --git-lfs --depth=1
git clone https://gitlab.com/pure-soul-kk/scripts -b ax-av .repo/local_manifests
if [ -f /opt/crave/resync.sh ]; then
  /opt/crave/resync.sh
else
  repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
fi

# custom repos
# rm -rf vendor/lineage-priv/keys
# git clone --depth=1 https://github.com/pure-soul-kk/keys vendor/lineage-priv/keys

export BUILD_USERNAME=krishna
export BUILD_HOSTNAME=crave

#build
. build/envsetup.sh
axion avalon user gms
mka installclean
ax -b
