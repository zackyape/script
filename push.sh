#!/bin/bash

### =======================
### KONFIGURASI
### =======================
SF_USER="zsheesh"                       # username SourceForge
SF_API_KEY="d9ba1acb-6931-4b2d-8dab-e81b6cf8510c"   # API key langsung di script
SF_PROJECT="AOSP"            # nama project
SF_REMOTE_DIR="vayu"                    # folder tujuan upload
FILE_PATH="out/target/product/vayu/Arrow-v13.1_ext-vayu-20251117-vanilla.zip"                          # file dari argumen


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
### KIRIM SSH KEY KE SOURCEFORGE
### =======================
echo "[INFO] Mengirim SSH key ke SourceForge..."

API_RESPONSE=$(curl -s -w "%{http_code}" \
    -u "$SF_USER:$SF_API_KEY" \
    -H "Content-Type: application/json" \
    -X POST \
    -d "{\"key\": \"$PUBLIC_KEY\", \"description\": \"auto-upload-key\"}" \
    "https://sourceforge.net/rest/u/$SF_USER/ssh_keys/add")

HTTP_CODE="${API_RESPONSE: -3}"

if [[ "$HTTP_CODE" != "200" && "$HTTP_CODE" != "201" ]]; then
    echo "[ERROR] Gagal mengirim SSH key ke SourceForge! HTTP code: $HTTP_CODE"
    exit 1
fi

echo "[INFO] SSH key berhasil dikirim."


### =======================
### TEST KONEKSI SSH (ADA DELAY 2–5 MENIT)
### =======================
echo "[INFO] Menunggu aktivasi SSH key di SourceForge..."

for i in {1..10}; do
    ssh -o StrictHostKeyChecking=accept-new \
        -o BatchMode=yes \
        -i "$KEY_PATH" \
        "$SF_USER@frs.sourceforge.net" "exit" 2>/dev/null && break

    echo "[WAIT] Menunggu 15 detik... (percobaan $i/10)"
    sleep 15
done

if [[ $i -eq 10 ]]; then
    echo "[ERROR] SSH key belum aktif setelah beberapa percobaan."
    exit 1
fi

echo "[INFO] SSH OK tanpa password."


### =======================
### UPLOAD VIA RSYNC
### =======================
echo "[INFO] Mengupload file ke SourceForge..."

rsync -avP \
    -e "ssh -i $KEY_PATH -o StrictHostKeyChecking=accept-new" \
    "$FILE_PATH" \
    "$SF_USER@frs.sourceforge.net:/home/frs/project/$SF_PROJECT/$SF_REMOTE_DIR/"

STATUS=$?

if [[ $STATUS -eq 0 ]]; then
    echo "[INFO] Upload selesai!"
else
    echo "[ERROR] Upload gagal. Kode: $STATUS"
fi

exit $STATUS
