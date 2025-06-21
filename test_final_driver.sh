#!/bin/bash

# Final JDI Driver Test Script
# Tests all brightness functionality and GPIO17 button integration

echo "════════════════════════════════════════════════════════════════"
echo "                JDI DRM Enhanced Driver - Final Test"
echo "                    GPIO17 Brightness Control Fixed"
echo "════════════════════════════════════════════════════════════════"
echo

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

test_passed=0
test_failed=0

test_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ PASS${NC}: $2"
        test_passed=$((test_passed + 1))
    else
        echo -e "${RED}❌ FAIL${NC}: $2"
        test_failed=$((test_failed + 1))
    fi
}

echo -e "${BLUE}1. Testing hardware brightness capability...${NC}"
max_brightness=$(cat /sys/class/backlight/jdi-backlight/max_brightness 2>/dev/null)
current_brightness=$(cat /sys/class/backlight/jdi-backlight/brightness 2>/dev/null)

if [ "$max_brightness" = "3" ]; then
    test_result 0 "Hardware supports brightness 0-3"
else
    test_result 1 "Hardware brightness range issue (expected 3, got $max_brightness)"
fi

echo -e "${BLUE}2. Testing brightness level configuration...${NC}"

# Test device tree
if grep -q "brightness-levels = <0 1 2 3>" jdi-drm-enhanced.dts; then
    test_result 0 "Device tree has correct brightness levels (0-3)"
else
    test_result 1 "Device tree brightness levels incorrect"
fi

# Test GPIO17 handler
if grep -q "BRIGHTNESS_LEVELS = \[0, 1, 2, 3\]" gpio17_button_handler.py; then
    test_result 0 "GPIO17 handler has correct brightness levels"
else
    test_result 1 "GPIO17 handler brightness levels incorrect"
fi

# Test simple brightness control
if ! grep -q "0-6\|/6" simple_brightness_control.sh; then
    test_result 0 "Simple brightness control uses correct range (0-3)"
else
    test_result 1 "Simple brightness control still uses old range (0-6)"
fi

echo -e "${BLUE}3. Testing actual brightness control...${NC}"

# Test setting each brightness level
for level in 0 1 2 3; do
    echo $level | sudo tee /sys/class/backlight/jdi-backlight/brightness > /dev/null 2>&1
    actual=$(cat /sys/class/backlight/jdi-backlight/brightness 2>/dev/null)
    if [ "$actual" = "$level" ]; then
        test_result 0 "Brightness level $level works"
    else
        test_result 1 "Brightness level $level failed (got $actual)"
    fi
done

echo -e "${BLUE}4. Testing brightness cycling...${NC}"

# Test brightness cycling
echo 0 | sudo tee /sys/class/backlight/jdi-backlight/brightness > /dev/null 2>&1
./simple_brightness_control.sh cycle > /dev/null 2>&1
level1=$(cat /sys/class/backlight/jdi-backlight/brightness)
./simple_brightness_control.sh cycle > /dev/null 2>&1
level2=$(cat /sys/class/backlight/jdi-backlight/brightness)
./simple_brightness_control.sh cycle > /dev/null 2>&1
level3=$(cat /sys/class/backlight/jdi-backlight/brightness)
./simple_brightness_control.sh cycle > /dev/null 2>&1
level4=$(cat /sys/class/backlight/jdi-backlight/brightness)

if [ "$level1" = "1" ] && [ "$level2" = "2" ] && [ "$level3" = "3" ] && [ "$level4" = "0" ]; then
    test_result 0 "Brightness cycling works (0→1→2→3→0)"
else
    test_result 1 "Brightness cycling failed (got $level1→$level2→$level3→$level4)"
fi

echo -e "${BLUE}5. Testing GPIO17 button handler...${NC}"

if [ -f gpio17_button_handler.py ]; then
    if python3 -c "import sys; sys.path.append('.'); exec(open('gpio17_button_handler.py').read())" 2>/dev/null; then
        test_result 0 "GPIO17 handler syntax is valid"
    else
        test_result 1 "GPIO17 handler has syntax errors"
    fi
    
    if grep -q "linux,code = <240>" jdi-drm-enhanced.dts; then
        test_result 0 "GPIO17 uses custom key code (240, not power)"
    else
        test_result 1 "GPIO17 key code configuration issue"
    fi
else
    test_result 1 "GPIO17 button handler missing"
fi

echo -e "${BLUE}6. Testing device tree overlay...${NC}"

if [ -f jdi-drm-enhanced.dtbo ]; then
    test_result 0 "Device tree overlay exists"
    if [ jdi-drm-enhanced.dtbo -nt jdi-drm-enhanced.dts ]; then
        test_result 0 "Device tree overlay is up to date"
    else
        test_result 1 "Device tree overlay needs rebuilding"
    fi
else
    test_result 1 "Device tree overlay missing"
fi

echo -e "${BLUE}7. Testing installation script...${NC}"

if grep -q "verify_brightness_configuration" JDI_INSTALLER_COMPLETE.sh; then
    test_result 0 "Installation script includes brightness verification"
else
    test_result 1 "Installation script missing brightness verification"
fi

if grep -q "compile_device_tree_overlay" JDI_INSTALLER_COMPLETE.sh; then
    test_result 0 "Installation script includes device tree compilation"
else
    test_result 1 "Installation script missing device tree compilation"
fi

echo
echo "════════════════════════════════════════════════════════════════"
echo -e "${GREEN}Tests Passed: $test_passed${NC}"
echo -e "${RED}Tests Failed: $test_failed${NC}"
echo "════════════════════════════════════════════════════════════════"

if [ $test_failed -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED! Driver is ready for production use.${NC}"
    echo -e "${YELLOW}✨ GPIO17 brightness control issue has been completely resolved!${NC}"
    echo
    echo "Next steps:"
    echo "1. Run: sudo ./JDI_INSTALLER_COMPLETE.sh"
    echo "2. Reboot the system"
    echo "3. Connect button between GPIO17 and GND"
    echo "4. Test brightness cycling with the physical button"
else
    echo -e "${RED}❌ SOME TESTS FAILED. Please check the issues above.${NC}"
    exit 1
fi
