#!/bin/bash
# Raspberry Pi Initial Setup - Episode 21
# KERNEL SHADOWS

echo "=== Raspberry Pi Setup for Episode 21 ==="
echo ""

# Update system
echo "[1/5] Updating system..."
sudo apt update && sudo apt upgrade -y

# Install GPIO tools
echo ""
echo "[2/5] Installing GPIO libraries..."
sudo apt install -y gpiod libgpiod-dev libgpiod2

# Install camera tools
echo ""
echo "[3/5] Installing camera tools..."
sudo apt install -y libcamera-apps v4l-utils

# Install development tools
echo ""
echo "[4/5] Installing development tools..."
sudo apt install -y build-essential git

# Enable interfaces
echo ""
echo "[5/5] Enabling interfaces..."
# Enable I2C, SPI (needs raspi-config on Raspberry Pi OS)
# On Ubuntu: check /boot/firmware/config.txt

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Configure /boot/firmware/config.txt (see artifacts/configs/)"
echo "  2. Reboot: sudo reboot"
echo "  3. Test GPIO: cd c-code && make && sudo ./gpio_control"
