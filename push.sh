#!/bin/bash

# ============================
# KONFIGURASI — WAJIB DIISI
# ============================
API_ID=33849224               # ganti
API_HASH="deb0f75259d603af48d9a227964ed35b"    # ganti
FOLDER_PATH="out/target/product/vayu"  # ganti
TARGET="-1002024589954"                    # "me", username, @channel, atau chat id
SESSION_NAME="telethon_session"
CAPTION=""  # opsional, boleh dikosongkan
# ============================


# --- Pastikan Python & pip tersedia ---
if ! command -v python3 &> /dev/null; then
    echo "Python3 tidak ditemukan. Install dulu."
    exit 1
fi

# --- Install Telethon jika belum ada ---
echo "[INFO] Mengecek Telethon..."
python3 - << 'EOF'
import pkgutil
import subprocess
if not pkgutil.find_loader("telethon"):
    print("[INFO] Telethon belum terpasang. Menginstall...")
    subprocess.check_call(["pip3", "install", "telethon"])
else:
    print("[INFO] Telethon sudah terinstall.")
EOF

# --- Jalankan Python Telethon ---
python3 - << EOF
import os, asyncio
from telethon import TelegramClient, errors

API_ID = $API_ID
API_HASH = "$API_HASH"
FOLDER_PATH = "$FOLDER_PATH"
TARGET = "$TARGET"
SESSION_NAME = "$SESSION_NAME"
CAPTION = "$CAPTION" if "$CAPTION" != "" else None

def human(n):
    for u in ['B','KB','MB','GB','TB']:
        if n < 1024:
            return f"{n:.1f}{u}"
        n /= 1024
    return f"{n:.1f}PB"

async def main():
    client = TelegramClient(SESSION_NAME, API_ID, API_HASH)
    await client.start()

    if not os.path.isdir(FOLDER_PATH):
        print("Folder tidak ditemukan:", FOLDER_PATH)
        return

    files = [os.path.join(FOLDER_PATH,f) for f in os.listdir(FOLDER_PATH) if f.lower().endswith(".zip")]

    if not files:
        print("Tidak ada file .zip")
        return

    print(f"Menemukan {len(files)} file .zip")

    for f in files:
        size=os.path.getsize(f)
        print("Mengirim:", f, f"({human(size)})")

        last=-1
        def progress(sent, total):
            nonlocal last
            if total != 0:
                p = int(sent*100/total)
                if p != last and p % 5 == 0:
                    print(f"  {p}% ({human(sent)}/{human(total)})")
                    last = p

        try:
            await client.send_file(
                TARGET,
                f,
                caption=CAPTION,
                progress_callback=progress,
                force_document=True
            )
            print(" -> Sukses")
        except errors.FloodWaitError as e:
            print(f"Dibatasi Telegram, tunggu {e.seconds} detik...")
            await asyncio.sleep(e.seconds)
            continue
        except Exception as e:
            print("Error:", e)
            continue

    print("\\nSemua file diproses.")
    await client.disconnect()

asyncio.run(main())
EOF
