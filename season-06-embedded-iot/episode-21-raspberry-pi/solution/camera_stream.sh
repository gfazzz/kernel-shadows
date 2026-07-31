#!/bin/bash
# Camera Streaming Script - Episode 21 SOLUTION
# Mission: Stream surveillance feed

set -e

echo "=== Camera Streaming - Episode 21 ==="
echo "Mission: Surveillance feed for HQ"
echo ""

# Configuration
STREAM_PORT=8080
STREAM_HOST="0.0.0.0"
WIDTH=1280
HEIGHT=720
FPS=30
BITRATE=2000000  # 2 Mbps

# Check if camera is available
echo "Checking camera..."
if ! vcgencmd get_camera | grep -q "detected=1"; then
    echo "❌ Camera not detected!"
    echo "Check:"
    echo "  1. Camera cable connected"
    echo "  2. /boot/firmware/config.txt has: start_x=1"
    echo "  3. Reboot after config change"
    exit 1
fi

echo "✓ Camera detected"

# Check dependencies
if ! command -v libcamera-vid &> /dev/null; then
    echo "❌ libcamera-vid not found"
    echo "Install: sudo apt install libcamera-apps"
    exit 1
fi

if ! command -v ffmpeg &> /dev/null; then
    echo "⚠️  ffmpeg not found (optional for advanced streaming)"
    echo "Install: sudo apt install ffmpeg"
fi

# Get Pi IP
PI_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "Starting surveillance stream..."
echo "  Resolution: ${WIDTH}x${HEIGHT}"
echo "  FPS: ${FPS}"
echo "  Port: ${STREAM_PORT}"
echo ""

# Method 1: Simple UDP stream (works without ffmpeg)
if command -v ffmpeg &> /dev/null; then
    echo "Using H.264 stream with ffmpeg..."
    echo "  Stream URL: http://${PI_IP}:${STREAM_PORT}"
    
    libcamera-vid -t 0 \
        --width $WIDTH --height $HEIGHT \
        --framerate $FPS \
        --bitrate $BITRATE \
        --inline \
        -o - | \
    ffmpeg -re -i - \
        -c:v copy \
        -f mpegts \
        "udp://${STREAM_HOST}:${STREAM_PORT}"
else
    # Method 2: Raw stream to port
    echo "Using raw H.264 stream..."
    echo "  View with: vlc tcp://${PI_IP}:${STREAM_PORT}"
    
    libcamera-vid -t 0 \
        --width $WIDTH --height $HEIGHT \
        --framerate $FPS \
        --bitrate $BITRATE \
        --inline \
        --listen -o tcp://0.0.0.0:${STREAM_PORT}
fi
