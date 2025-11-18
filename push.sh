#!/bin/bash
set -uo pipefail

# === KONFIGURASI ===
BOT_TOKEN="8197408884:AAFbP7Xmgd3prMPY04gGC5it2oIkxy6N17k"
CHAT_ID="-1002024589954"
FOLDER_PATH="out/target/product/vayu"   # contoh: /home/user/backups

# === KIRIM SEMUA .ZIP (TANPA LIMIT) ===
shopt -s nullglob
zip_files=("$FOLDER_PATH"/*.zip)

if [ ${#zip_files[@]} -eq 0 ]; then
    echo "Tidak ada file .zip dalam folder: $FOLDER_PATH"
    exit 0
fi

for file in "${zip_files[@]}"; do
    if [ ! -f "$file" ]; then
        continue
    fi

    echo "----------------------------"
    echo "Mengirim: $file"
    
    # kirim file dan tampilkan body + http code untuk debug
    response=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument" \
        -F chat_id="${CHAT_ID}" \
        -F document=@"${file}")

    echo "Response:"
    echo "$response"

    # cek field "ok" sederhana (tanpa jq)
    ok=$(echo "$response" | sed -n 's/.*"ok":[[:space:]]*\([^,}]*\).*/\1/p' | tr -d ' ')
    if [ "$ok" = "true" ]; then
        echo "-> Upload sukses untuk: $file"
    else
        echo "-> Upload mungkin gagal untuk: $file (cek response di atas)"
    fi

    # jeda kecil supaya tidak spam (opsional)
    sleep 1
done

echo "Selesai."
