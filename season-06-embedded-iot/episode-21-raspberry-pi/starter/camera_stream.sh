#!/bin/bash
# Camera Streaming Script - Episode 21
# Mission: Stream surveillance feed
# 
# TODO: Complete this script

echo "=== Camera Streaming - Episode 21 ==="
echo "Mission: Surveillance feed for HQ"
echo ""

# Configuration
STREAM_PORT=8080
STREAM_HOST="0.0.0.0"

# TODO 1: Check if camera is available
# Hint: vcgencmd get_camera

echo "Checking camera..."
# Your code here

# TODO 2: Start camera stream using libcamera-vid
# Hint: libcamera-vid -t 0 --width 1920 --height 1080 -o - | ...
# Options: ffmpeg or netcat for streaming

echo "Starting stream on port $STREAM_PORT..."
# Your code here

# Example (complete it):
# libcamera-vid -t 0 --width 1280 --height 720 -o - | \
#   ffmpeg -i - -f mpegts udp://$STREAM_HOST:$STREAM_PORT

echo ""
echo "Stream should be running at:"
echo "  URL: http://$(hostname -I | awk '{print $1}'):$STREAM_PORT"
echo ""
echo "Press Ctrl+C to stop"
