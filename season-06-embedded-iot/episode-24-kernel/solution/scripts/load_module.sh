#!/bin/bash
# Auto-load kernel module - Episode 24

MODULE_NAME="hello_complete"
MODULE_PATH="/path/to/${MODULE_NAME}.ko"

echo "Loading ${MODULE_NAME}..."
sudo insmod ${MODULE_PATH}

if lsmod | grep -q ${MODULE_NAME}; then
    echo "✓ Module loaded successfully"
    dmesg | tail -3
else
    echo "✗ Failed to load module"
    exit 1
fi
