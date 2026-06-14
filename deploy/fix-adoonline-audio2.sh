#!/bin/bash
# Reparer script-audio-2.mp3 (copie du fichier 1 qui fonctionne)
set -e
BP="/var/www/blackpage"
curl -sk "https://127.0.0.1/script-audio.mp3" -H "Host: adoonline.click" -o "$BP/script-audio-2.mp3"
chown www-data:www-data "$BP/script-audio-2.mp3"
chmod 444 "$BP/script-audio-2.mp3"
wc -c "$BP/script-audio.mp3" "$BP/script-audio-2.mp3"
curl -skI "https://127.0.0.1/script-audio-2.mp3" -H "Host: adoonline.click" | head -2
echo "OK-LES-2-AUDIOS"
