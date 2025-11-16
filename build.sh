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

echo "=========================================="
echo "Fix Complete!"
echo "=========================================="
echo ""

# SELinux Duplicate Declaration Fixer
# This script finds and fixes duplicate type/attribute declarations in Android SELinux policies
ANDROID_ROOT="/tmp/src/android"
BACKUP_DIR="${ANDROID_ROOT}/sepolicy_backups_$(date +%Y%m%d_%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== SELinux Policy Duplicate Declaration Fixer ===${NC}\n"

# Create backup directory
mkdir -p "$BACKUP_DIR"
echo -e "${YELLOW}Backups will be saved to: $BACKUP_DIR${NC}\n"

cd "$ANDROID_ROOT"

# Function to backup a file
backup_file() {
    local file="$1"
    local backup_path="$BACKUP_DIR/$(dirname "$file")"
    mkdir -p "$backup_path"
    cp "$file" "$backup_path/"
    echo -e "${GREEN}Backed up: $file${NC}"
}

# Function to comment out a line in a file
comment_out_line() {
    local file="$1"
    local line_num="$2"
    local pattern="$3"
    
    backup_file "$file"
    
    # Comment out the specific line
    sed -i "${line_num}s/^/# DUPLICATE - /" "$file"
    echo -e "${GREEN}Fixed duplicate in $file at line $line_num${NC}"
}

echo -e "${YELLOW}Step 1: Searching for hal_misys attribute declarations...${NC}"
grep -rn "^attribute hal_misys;" device/ vendor/ 2>/dev/null | while IFS=: read -r file line content; do
    echo "Found: $file:$line"
done

echo -e "\n${YELLOW}Step 2: Searching for hal_misys_default type declarations...${NC}"
DECLARATIONS=$(grep -rn "^type hal_misys_default" device/ vendor/ 2>/dev/null || true)

if [ -z "$DECLARATIONS" ]; then
    echo -e "${RED}No duplicate declarations found with 'type hal_misys_default'${NC}"
else
    echo "$DECLARATIONS"
    
    # Count occurrences
    COUNT=$(echo "$DECLARATIONS" | wc -l)
    echo -e "\n${YELLOW}Found $COUNT declaration(s)${NC}"
    
    if [ "$COUNT" -gt 1 ]; then
        echo -e "${RED}Multiple declarations detected! Will fix duplicates...${NC}\n"
        
        # Keep the first one, comment out the rest
        FIRST=true
        echo "$DECLARATIONS" | while IFS=: read -r file line content; do
            if [ "$FIRST" = true ]; then
                echo -e "${GREEN}Keeping: $file:$line${NC}"
                FIRST=false
            else
                echo -e "${YELLOW}Commenting out duplicate: $file:$line${NC}"
                backup_file "$file"
                sed -i "${line}s/^type /# DUPLICATE - type /" "$file"
            fi
        done
    fi
fi

echo -e "\n${YELLOW}Step 3: Fixing device/xiaomi/vayu/sepolicy/vendor/hal_misys_default.te...${NC}"
TARGET_FILE="device/xiaomi/vayu/sepolicy/vendor/hal_misys_default.te"

if [ -f "$TARGET_FILE" ]; then
    backup_file "$TARGET_FILE"
    
    # Comment out the type declaration line
    sed -i 's/^type hal_misys_default, domain;/# DUPLICATE - type hal_misys_default, domain; # Declared elsewhere/' "$TARGET_FILE"
    
    echo -e "${GREEN}Fixed: $TARGET_FILE${NC}"
    echo -e "${YELLOW}The type declaration has been commented out.${NC}"
else
    echo -e "${RED}File not found: $TARGET_FILE${NC}"
fi

echo -e "\n${YELLOW}Step 4: Checking for attribute hal_misys duplicates...${NC}"
ATTR_FILE="vendor/xiaomi/vayu-miuicamera/sepolicy/vendor/attributes"

if [ -f "$ATTR_FILE" ]; then
    if grep -q "^attribute hal_misys;" "$ATTR_FILE"; then
        echo -e "${YELLOW}Found hal_misys attribute in $ATTR_FILE${NC}"
        backup_file "$ATTR_FILE"
        sed -i 's/^attribute hal_misys;/# DUPLICATE - attribute hal_misys; # Declared in AOSP base/' "$ATTR_FILE"
        echo -e "${GREEN}Fixed: $ATTR_FILE${NC}"
    fi
else
    echo -e "${YELLOW}File not found: $ATTR_FILE (may not exist)${NC}"
fi

echo -e "\n${YELLOW}Step 5: Verification - Searching for remaining issues...${NC}"
echo "Remaining 'attribute hal_misys' declarations:"
grep -rn "^attribute hal_misys;" device/ vendor/ 2>/dev/null || echo -e "${GREEN}None found (all commented out)${NC}"

echo -e "\nRemaining 'type hal_misys_default' declarations:"
grep -rn "^type hal_misys_default" device/ vendor/ 2>/dev/null || echo -e "${GREEN}None found (all commented out)${NC}"

echo -e "\n${GREEN}=== Fix Complete ===${NC}"
echo -e "${YELLOW}Backups saved to: $BACKUP_DIR${NC}"
echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Review the changes in the backed up files"
echo "2. Run: ${GREEN}m recovery_sepolicy.cil${NC}"
echo "3. If issues persist, restore from: $BACKUP_DIR"
echo -e "\n${YELLOW}To restore backups:${NC}"
echo "cp -r $BACKUP_DIR/* $ANDROID_ROOT/"

export BUILD_USERNAME=zsheesh
export BUILD_HOSTNAME=crave

#build
. build/envsetup.sh
lunch arrow_vayu-userdebug
mka installclean
m bacon
