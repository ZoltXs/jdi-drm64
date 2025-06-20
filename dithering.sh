#!/bin/bash
# Dithering control for JDI display
# Autor: N@Xs - Enhanced Edition 2025

echo "JDI Dithering Control"
echo "===================="

if lsmod | grep -q jdi_drm_enhanced; then
    echo "Driver: ✓ Loaded"
    echo "Software dithering: Available"
else
    echo "Driver: ✗ Not loaded"
fi
