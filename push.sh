#!/bin/bash

# ------------------------------
# SourceForge Upload Script
# ------------------------------

# Your SourceForge project name (NOT the URL)
PROJECT="AOSP"

# Your SF username
USER="zsheesh"

# Local file or directory to upload
FILE_PATH="out/target/product/vayu/Arrow-v13.1_ext-vayu-20251117-vanilla.zip"

# Remote folder inside your FRS project
REMOTE_DIR="vayu"

# Exit if no file provided
if [ -z "$FILE_PATH" ]; then
    echo "Usage: ./upload-sf.sh <file_or_directory>"
    exit 1
fi

# Upload using rsync (recommended)
rsync -e "ssh -o StrictHostKeyChecking=accept-new"-avP "$FILE_PATH" \
    "$USER@frs.sourceforge.net:/home/frs/project/$PROJECT/$REMOTE_DIR/"

echo "Upload complete!"
