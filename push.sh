#!/bin/bash

# === CONFIG ===
BOT_TOKEN="8197408884:AAFbP7Xmgd3prMPY04gGC5it2oIkxy6N17k"
CHAT_ID="-1002024589954"
FOLDER_PATH="out/target/product/vayu"  

# === Pussy ===
for file in "$FOLDER_PATH"/*.zip; do
    # cek apakah file zip ada
    [ -e "$file" ] || { echo "Tidak ada file .zip dalam folder"; exit 0; }

    if [ -f "$file" ]; then
        echo "Mengirim ZIP: $file"
        
        curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument" \
            -F chat_id="${CHAT_ID}" \
            -F document=@"${file}" > /dev/null

        echo "Selesai: $file"
        sleep 1
    fi
done

echo "Wis kelar cuk!"
