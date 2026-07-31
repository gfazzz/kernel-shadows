#!/bin/bash
# Camera Test Script - Raspberry Pi
# Episode 21: KERNEL SHADOWS

echo "=== Raspberry Pi Camera Test ==="
echo ""

# Check if camera is detected
if vcgencmd get_camera | grep -q "detected=1"; then
    echo "✅ Camera detected!"
    vcgencmd get_camera
else
    echo "❌ Camera NOT detected"
    echo "Check:"
    echo "  1. Camera cable connected"
    echo "  2. /boot/firmware/config.txt has: start_x=1"
    echo "  3. Run: sudo raspi-config → Interface → Camera → Enable"
    exit 1
fi

echo ""
echo "=== Test image capture ==="

# Test capture (requires libcamera-apps)
if command -v libcamera-still &> /dev/null; then
    echo "Capturing test image..."
    libcamera-still -o /tmp/test.jpg -t 2000
    echo "✅ Image saved to /tmp/test.jpg"
else
    echo "⚠️  libcamera-still not installed"
    echo "Install: sudo apt install libcamera-apps"
fi

echo ""
echo "Camera test complete!"
