#!/bin/bash

# JDI Installation Checker
# Shows what JDI components are currently installed

echo "==================== JDI INSTALLATION STATUS ===================="
echo ""

echo "📊 SYSTEMD SERVICES:"
if systemctl list-unit-files | grep jdi- >/dev/null 2>&1; then
    systemctl list-unit-files | grep jdi- | while read service status; do
        state=$(systemctl is-active $service 2>/dev/null || echo "inactive")
        echo "  $service: $status ($state)"
    done
else
    echo "  No JDI services found"
fi
echo ""

echo "🔧 LOADED MODULES:"
if lsmod | grep jdi >/dev/null 2>&1; then
    lsmod | grep jdi
else
    echo "  No JDI modules loaded"
fi
echo ""

echo "📁 DEVICE TREE OVERLAYS:"
if [ -f "/boot/overlays/jdi-drm-enhanced.dtbo" ]; then
    ls -la /boot/overlays/jdi-drm-enhanced.dtbo
else
    echo "  No JDI device tree overlay found"
fi
echo ""

echo "⚙️ BOOT CONFIGURATION:"
if grep -q "jdi" /boot/firmware/config.txt 2>/dev/null || grep -q "jdi" /boot/config.txt 2>/dev/null; then
    echo "  JDI configuration found in config.txt:"
    grep "jdi" /boot/firmware/config.txt 2>/dev/null || grep "jdi" /boot/config.txt 2>/dev/null
else
    echo "  No JDI configuration in boot config"
fi
echo ""

echo "🔘 BACKLIGHT DEVICE:"
if [ -d "/sys/class/backlight/jdi-backlight" ]; then
    echo "  JDI backlight device: ACTIVE"
    echo "  Current brightness: $(cat /sys/class/backlight/jdi-backlight/brightness 2>/dev/null || echo 'N/A')"
    echo "  Max brightness: $(cat /sys/class/backlight/jdi-backlight/max_brightness 2>/dev/null || echo 'N/A')"
else
    echo "  No JDI backlight device found"
fi
echo ""

echo "📝 BASHRC ALIASES:"
if grep -q "jdi\|lpm027\|brightness\|preset-" ~/.bashrc 2>/dev/null; then
    echo "  JDI aliases found in ~/.bashrc:"
    grep -c "alias.*\(jdi\|lpm027\|brightness\|preset-\)" ~/.bashrc 2>/dev/null | while read count; do
        echo "    $count JDI-related aliases"
    done
else
    echo "  No JDI aliases found in ~/.bashrc"
fi
echo ""

echo "🗂️ UDEV RULES:"
if [ -f "/etc/udev/rules.d/99-gpio.rules" ]; then
    echo "  GPIO udev rules: PRESENT"
else
    echo "  No GPIO udev rules found"
fi
echo ""

echo "📦 DRIVER DIRECTORY:"
if [ -d "/home/pi/jdi-drm64" ]; then
    echo "  Driver directory: $(du -sh /home/pi/jdi-drm64 2>/dev/null | cut -f1)"
    echo "  Files: $(find /home/pi/jdi-drm64 -type f | wc -l) files"
else
    echo "  No driver directory found"
fi
echo ""

echo "============================================================"
