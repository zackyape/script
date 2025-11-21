#!/bin/bash

# ==== CONFIG ====
USER="zsheesh"
PROJECT="AOSP"
REMOTE_DIR="AOSP/vayu"      # contoh: "ROM/Build-1"
FILE_PATH="out/target/product/vayu/Arrow-v13.1_ext-vayu-20251117-vanilla.zip"   # contoh: "/home/user/rom.zip"

# ==== UPLOAD ====
echo "[INFO] Uploading file ke SourceForge..."

rsync -avP \
    -e "ssh -o StrictHostKeyChecking=accept-new" \
    "$FILE_PATH" \
    "$USER@frs.sourceforge.net:/home/frs/project/$PROJECT/$REMOTE_DIR/"

STATUS=$?

if [ $STATUS -eq 0 ]; then
    echo "[INFO] Upload selesai!"
else
    echo "[ERROR] Upload gagal dengan kode: $STATUS"
fi
