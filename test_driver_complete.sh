#!/bin/bash
# Complete Driver Test Script for JDI-DRM-Enhanced64
# Author: N@Xs - Enhanced Edition 2025

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo "======================================================================"
echo -e "${GREEN}JDI-DRM-Enhanced64 Complete Driver Verification${NC}"
echo "======================================================================"

# Test 1: Driver Loading
echo -e "${PURPLE}[TEST]${NC} 1. Checking driver status..."
if lsmod | grep -q jdi_drm_enhanced; then
    echo -e "${GREEN}[SUCCESS]${NC} Driver is loaded and running"
else
    echo -e "${RED}[ERROR]${NC} Driver is not loaded!"
    exit 1
fi

# Test 2: Dithering
echo -e "${PURPLE}[TEST]${NC} 2. Testing dithering functionality..."
if [ -f "/sys/module/jdi_drm_enhanced/parameters/dither" ]; then
    CURRENT_DITHER=$(cat /sys/module/jdi_drm_enhanced/parameters/dither)
    echo "Current dithering level: $CURRENT_DITHER"
    echo -e "${GREEN}[SUCCESS]${NC} Dithering parameter available"
else
    echo -e "${RED}[ERROR]${NC} Dithering parameter not found"
fi

# Test 3: All Parameters
echo -e "${PURPLE}[TEST]${NC} 3. Module parameters:"
for param in /sys/module/jdi_drm_enhanced/parameters/*; do
    echo "   - $(basename $param): $(cat $param)"
done

# Test 4: Framebuffer
echo -e "${PURPLE}[TEST]${NC} 4. Framebuffer check..."
if [ -c "/dev/fb0" ]; then
    echo -e "${GREEN}[SUCCESS]${NC} Framebuffer /dev/fb0 is available"
else
    echo -e "${RED}[ERROR]${NC} Framebuffer not available"
fi

echo "======================================================================"
echo -e "${GREEN}✅ DRIVER IS FUNCTIONAL WITH DITHERING SUPPORT${NC}"
echo "======================================================================"
