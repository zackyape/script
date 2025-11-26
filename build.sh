#!/bin/bash

#removals
rm -rf .repo/local_manifests
rm -rf device/samsung
rm -rf vendor/samsung
rm -rf kernel/samsung
rm -rf hardware/samsung
rm -rf hardware/samsung_slsi-linaro
rm -rf device/samsung_slsi/sepolicy
rm -rf hardware/samsung-ext
rm -rf out
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
git clone https://github.com/Roynas-Android-Playground/local_manifests -b Exynos7885-new-fourteen .repo/local_manifests
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
export BANANA_MAINTAINER=zsheesh

# stufs
ROOT="$(pwd)"
SOONG_DIR="$ROOT/build/soong"
GO_FILE="$SOONG_DIR/install_symlink.go"
BP_FILE="$SOONG_DIR/Android.bp"
BACKUP_DIR="$ROOT/.soong_install_symlink_backup_$(date +%Y%m%d_%H%M%S)"

echo "Running from: $ROOT"
echo "SOONG dir: $SOONG_DIR"

# Basic checks
if [ ! -d "$ROOT/build" ]; then
  echo "Error: did not find 'build' directory in current folder. Run this from Android source root." >&2
  exit 1
fi

mkdir -p "$BACKUP_DIR"
echo "Created backup dir: $BACKUP_DIR"

# Backup existing files if present
if [ -f "$GO_FILE" ]; then
  echo "Backing up existing $GO_FILE -> $BACKUP_DIR/"
  cp -a "$GO_FILE" "$BACKUP_DIR/"
fi
if [ -f "$BP_FILE" ]; then
  echo "Backing up existing $BP_FILE -> $BACKUP_DIR/"
  cp -a "$BP_FILE" "$BACKUP_DIR/"
fi

# Create build/soong directory if missing
mkdir -p "$SOONG_DIR"

# Write Go implementation (idempotent - overwrite only if different)
cat > "$GO_FILE.tmp" <<'GO_SRC'
package installsymlink

import (
	"android/soong/android"
	"path/filepath"
)

func init() {
	android.RegisterModuleType("install_symlink", installSymlinkFactory)
}

func installSymlinkFactory() android.Module {
	m := &installSymlink{}
	android.InitAndroidModule(m)
	return m
}

type installSymlink struct {
	android.ModuleBase

	properties struct {
		Installed_location string `android:"path"`
		Symlink_target     string `android:"path"`
		Soc_specific       *bool
	}
}

func (m *installSymlink) GenerateAndroidBuildActions(ctx android.ModuleContext) {
	// installed_location is where module wants the symlink placed inside the image
	// We will create an empty file (or copy) so that downstream packaging can include it.
	// For host-side operation, write an empty file as a marker in the module install path.
	installed := android.PathForModuleInstall(ctx, m.properties.Installed_location)
	// Ensure parent dir exists in build output
	parent := installed.Dir()
	ctx.Build(pctx, android.BuildParams{
		Rule:   android.Mkdir,
		Output: parent,
		Args:   map[string]string{"path": parent.String()},
	})

	// Create an empty file at the installed location so it can be packaged.
	// We cannot create a real symlink at build-time in output that survives packaging reliably,
	// but having the file present lets packagers process it; the device-specific packaging step
	// may convert it into a symlink in the image.
	ctx.Build(pctx, android.BuildParams{
		Rule:   android.WriteFile,
		Output: installed,
		Args:   map[string]string{"content": "symlink -> " + m.properties.Symlink_target},
	})
}
GO_SRC

# Only replace if content differs (keeps timestamp noise down)
if [ ! -f "$GO_FILE" ] || ! cmp -s "$GO_FILE.tmp" "$GO_FILE"; then
  mv "$GO_FILE.tmp" "$GO_FILE"
  echo "Written $GO_FILE"
else
  rm "$GO_FILE.tmp"
  echo "No changes to $GO_FILE"
fi

# Ensure pctx helpers exist: create a small pctx file if not present (pctx rules used above)
PCTX_FILE="$SOONG_DIR/install_symlink_pctx.go"
cat > "$PCTX_FILE.tmp" <<'PCTX_SRC'
package installsymlink

import "android/soong/android"

var pctx = android.NewPackageContext("android/soong/install_symlink")

func init() {
	// pctx rules are provided by android package; this file ensures package compiles when bootstrapping.
	// No explicit rule declaration needed here if platform provides android.Mkdir and android.WriteFile.
	// This file exists as a placeholder to avoid missing-package errors.
	_ = pctx
}
PCTX_SRC

if [ ! -f "$PCTX_FILE" ] || ! cmp -s "$PCTX_FILE.tmp" "$PCTX_FILE"; then
  mv "$PCTX_FILE.tmp" "$PCTX_FILE"
  echo "Written $PCTX_FILE"
else
  rm "$PCTX_FILE.tmp"
  echo "No changes to $PCTX_FILE"
fi

# Update (or add) bootstrap_go_package in build/soong/Android.bp
BOOTSTRAP_BLOCK=$'bootstrap_go_package {\n    name: "install_symlink",\n    pkgPath: "build/soong/install_symlink",\n    srcs: ["install_symlink.go", "install_symlink_pctx.go"],\n}\n'

# If Android.bp missing, create one with the bootstrap block
if [ ! -f "$BP_FILE" ]; then
  echo "No $BP_FILE found — creating new one with bootstrap block."
  echo -e "$BOOTSTRAP_BLOCK" > "$BP_FILE"
  echo "Created $BP_FILE"
else
  # Check if block already present
  if grep -q 'name: "install_symlink"' "$BP_FILE"; then
    echo "Bootstrap entry for install_symlink already present in $BP_FILE — skipping edit."
  else
    # Append bootstrap block at end
    echo "" >> "$BP_FILE"
    echo "// Added by add_install_symlink_module.sh" >> "$BP_FILE"
    echo -e "$BOOTSTRAP_BLOCK" >> "$BP_FILE"
    echo "Appended bootstrap_go_package block to $BP_FILE"
  fi
fi

echo
echo "=== Done ==="

#build
. build/envsetup.sh
m clean
lunch banana_a30s-userdebug
mka installclean
m banana
