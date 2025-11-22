#!/bin/bash

### =======================
### KONFIGURASI
### =======================
SF_USER="zsheesh"               # username SourceForge
SF_API_KEY="d9ba1acb-6931-4b2d-8dab-e81b6cf8510c"
SF_PROJECT="zsheesh-release"
SF_REMOTE_DIR="vayu"
FILE_PATH="out/target/product/vayu/Arrow-v13.1_ext-vayu-20251117-vanilla.zip"                  # file untuk upload via argumen

### =======================
### CEK FILE
### =======================
if [[ -z "$FILE_PATH" || ! -f "$FILE_PATH" ]]; then
    echo "[ERROR] File tidak ditemukan atau argumen kosong."
    echo "Cara pakai: $0 /path/ke/file.zip"
    exit 1
fi

### =======================
### GENERATE SSH KEY JIKA BELUM ADA
### =======================
SSH_DIR="$HOME/.ssh"
KEY_PATH="$SSH_DIR/id_ed25519"
PUB_KEY_PATH="$SSH_DIR/id_ed25519.pub"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [[ ! -f "$KEY_PATH" ]]; then
    echo "[INFO] Membuat SSH key..."
    ssh-keygen -t ed25519 -N "" -C "sourceforge" -f "$KEY_PATH" >/dev/null
fi

chmod 600 "$KEY_PATH"
chmod 644 "$PUB_KEY_PATH"

PUBLIC_KEY=$(cat "$PUB_KEY_PATH")

### =======================
### DAFTARKAN SSH KEY KE SOURCEFORGE (AUTO)
### =======================
echo "[INFO] Menambahkan SSH key ke SourceForge via API..."

curl -s \
    -u "$SF_USER:$SF_API_KEY" \
    -H "Content-Type: application/json" \
    -X POST \
    -d "{\"key\": \"$PUBLIC_KEY\", \"description\": \"auto-added-by-script\"}" \
    https://sourceforge.net/rest/u/$SF_USER/ssh_keys/add >/dev/null

echo "[INFO] SSH key berhasil dikirim ke SourceForge."

### =======================
### TEST KONEKSI SSH TANPA PASSWORD
### =======================
echo "[INFO] Mengetes koneksi SSH..."

ssh -o StrictHostKeyChecking=accept-new \
    -o BatchMode=yes \
    "$SF_USER@frs.sourceforge.net" "exit" 2>/dev/null

if [[ $? -ne 0 ]]; then
    echo "[ERROR] SSH masih minta password — cek API key atau username!"
    exit 1
fi

echo "[INFO] SSH OK tanpa password."

### =======================
### UPLOAD FILE VIA RSYNC
### =======================
echo "[INFO] Mengupload file ke SourceForge..."

rsync -avP \
    -e "ssh -o StrictHostKeyChecking=accept-new" \
    "$FILE_PATH" \
    "$SF_USER@frs.sourceforge.net:/home/frs/project/$SF_PROJECT/$SF_REMOTE_DIR/"

STATUS=$?

if [[ $STATUS -eq 0 ]]; then
    echo "[INFO] Upload selesai!"
else
    echo "[ERROR] Upload gagal. Kode: $STATUS"
fi

exit $STATUS
