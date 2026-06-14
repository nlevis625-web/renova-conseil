#!/bin/bash
# Reparer audio adoonline.click
set -e

BP="/var/www/blackpage"
mkdir -p "$BP"

echo "=== 1. FFmpeg ==="
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq ffmpeg || apt install -y -qq ffmpeg

echo "=== 2. Generer les audios ==="
ffmpeg -hide_banner -loglevel error -f lavfi -i "sine=frequency=880:duration=30" -y "$BP/script-audio.mp3"
ffmpeg -hide_banner -loglevel error -f lavfi -i "sine=frequency=1200:duration=30" -y "$BP/script-audio-2.mp3"

chown www-data:www-data "$BP/script-audio.mp3" "$BP/script-audio-2.mp3"
chmod 444 "$BP/script-audio.mp3" "$BP/script-audio-2.mp3"

echo "=== 3. Tests ==="
ls -la "$BP/script-audio.mp3" "$BP/script-audio-2.mp3"
curl -skI --max-time 10 "https://127.0.0.1/script-audio.mp3" -H "Host: adoonline.click" | head -2
curl -skI --max-time 10 "https://127.0.0.1/script-audio-2.mp3" -H "Host: adoonline.click" | head -2
echo "=== OK AUDIO ==="
