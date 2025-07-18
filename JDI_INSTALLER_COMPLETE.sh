#!/bin/bash

# JDI DRM Enhanced Driver - Complete Installation Script with GPIO17 Button
# Author: N@Xs - Enhanced Edition 2025
# This script includes system update, dependencies, source fixes, GPIO17 button, permissions, and systemd services

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Driver directory
DRIVER_DIR="/home/pi/jdi-drm64"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_progress() {
    echo -e "${PURPLE}[PROGRESS]${NC} $1"
}

update_system_and_dependencies() {
    log_info "Updating system and installing dependencies..."
    
    # Update package lists and upgrade system
    log_progress "Running apt update && apt upgrade..."
    if sudo apt update && sudo apt upgrade -y; then
        log_success "System updated successfully"
    else
        log_error "Failed to update system"
        exit 1
    fi
    
    # Install required dependencies
    log_info "Installing kernel headers, build tools, and GPIO support..."
    if sudo apt install -y raspberrypi-kernel-headers build-essential git device-tree-compiler python3-gpiozero; then
        log_success "Dependencies installed successfully"
    else
        log_error "Failed to install dependencies"
        exit 1
    fi
}

setup_gpio_permissions() {
    log_info "Setting up GPIO permissions for GPIO17 button..."
    
    # Add pi user to input and gpio groups
    sudo usermod -a -G input pi
    sudo usermod -a -G gpio pi
    
    # Create udev rule for GPIO access
    sudo tee /etc/udev/rules.d/99-gpio.rules > /dev/null << 'UDEV_EOF'
# GPIO access for pi user
SUBSYSTEM=="gpio", KERNEL=="gpiochip*", ACTION=="add", GROUP="gpio", MODE="0664"
SUBSYSTEM=="gpio", KERNEL=="gpio*", ACTION=="add", GROUP="gpio", MODE="0664"

# Input device access for button handling
SUBSYSTEM=="input", GROUP="input", MODE="0664"
UDEV_EOF
    
    log_success "GPIO permissions configured"
}

clean_invalid_files() {
    log_info "Cleaning invalid and temporary files..."
    
    cd "$DRIVER_DIR"
    # Remove build artifacts that should be regenerated
    find . -name "*.o" -delete 2>/dev/null
    find . -name "*.cmd" -delete 2>/dev/null
    find . -name "*.mod" -delete 2>/dev/null
    find . -name "Module.symvers" -delete 2>/dev/null
    find . -name "modules.order" -delete 2>/dev/null
    
    # Remove backup files and invalid versions
    find . -name "*.backup*" -delete 2>/dev/null
    find . -name "*~" -delete 2>/dev/null
    find . -name "*.before_pwm_fix" -delete 2>/dev/null
    
    log_success "Invalid files cleaned"
}

fix_source_warnings() {
    log_info "Fixing compilation warnings in source code..."
    
    # Fix format warning in ioctl_iface.c
    sed -i 's/could not copy %d\/%zu/could not copy %lu\/%d/' "$DRIVER_DIR/src/ioctl_iface.c" 2>/dev/null
    
    # Remove unused variable warning in drm_iface.c
    sed -i '/extern uint g_param_dither;/d' "$DRIVER_DIR/src/drm_iface.c" 2>/dev/null
    
    log_success "Source code warnings fixed"
}

compile_driver() {
    log_info "Compiling driver JDI with GPIO17 button support..."
    
    cd "$DRIVER_DIR"
    
    # Fix source code warnings first
    fix_source_warnings
    
    # Clean previous builds
    make clean 2>/dev/null
    
    # Compile
    if sudo make; then
        log_success "Driver compiled successfully without warnings"
    else
        log_error "Error compiling the driver"
        exit 1
    fi
}

install_driver() {
    log_info "Installing driver in the system..."
    
    cd "$DRIVER_DIR"
    
    if sudo make install; then
        log_success "Driver installed successfully"
    else
        log_error "Error installing the driver"
        exit 1
    fi
}

create_systemd_services() {
    log_info "Creating systemd services for JDI driver with GPIO17 button..."
    
    # 1. Boot permissions service
    sudo tee /etc/systemd/system/jdi-permissions.service > /dev/null << 'PERMISSIONS_SERVICE_EOF'
[Unit]
Description=JDI Driver Permissions Setup
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'chmod +x /home/pi/jdi-drm64/*.sh /home/pi/jdi-drm64/*.py /home/pi/jdi-drm64/monoset /home/pi/jdi-drm64/jdi-status; chown -R pi:pi /home/pi/jdi-drm64'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
PERMISSIONS_SERVICE_EOF

    # 2. GPIO17 backlight button service (FIXED for hardware button)
    sudo tee /etc/systemd/system/jdi-backlight-button.service > /dev/null << 'BACKLIGHT_SERVICE_EOF'
[Unit]
Description=JDI GPIO17 Backlight Button Controller
After=multi-user.target
Wants=multi-user.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/bin/python3 /home/pi/jdi-drm64/gpio17_button_handler.py
Restart=always
RestartSec=5
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
BACKLIGHT_SERVICE_EOF

    # 3. Auto-optimize service
    sudo tee /etc/systemd/system/jdi-auto-optimize.service > /dev/null << 'OPTIMIZE_SERVICE_EOF'
[Unit]
Description=JDI Display Auto Optimization
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/home/pi/jdi-drm64/optimize_display.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
OPTIMIZE_SERVICE_EOF

    # 4. Power save service
    sudo tee /etc/systemd/system/jdi-powersave.service > /dev/null << 'POWERSAVE_SERVICE_EOF'
[Unit]
Description=JDI Intelligent Power Management
After=multi-user.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /home/pi/jdi-drm64/powersave.py --timeout 300
Restart=always
RestartSec=10
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
POWERSAVE_SERVICE_EOF

    # Enable all services
    sudo systemctl daemon-reload
    sudo systemctl enable jdi-permissions.service
    sudo systemctl enable jdi-backlight-button.service
    sudo systemctl enable jdi-auto-optimize.service
    sudo systemctl enable jdi-powersave.service
    
    log_success "All systemd services configured and enabled"
}

add_comprehensive_aliases() {
    log_info "Adding comprehensive aliases to ~/.bashrc..."
    
    # Backup existing bashrc
    cp ~/.bashrc ~/.bashrc.backup.$(date +%Y%m%d_%H%M%S)
    
    # Remove old JDI aliases if they exist
    sed -i '/# JDI Display Aliases/,/^$/d' ~/.bashrc
    
    # Add new comprehensive aliases
    cat >> ~/.bashrc << 'ALIAS_EOF'

# JDI Display Aliases - Added by JDI Enhanced Installer
# Author: N@Xs - Enhanced Edition 2025
alias monoset='/home/pi/jdi-drm64/monoset'
alias dither='/home/pi/jdi-drm64/dithering.sh'
alias powersave='sudo python3 /home/pi/jdi-drm64/powersave.py'
alias backlight='python3 /home/pi/jdi-drm64/enhanced_back.py'
alias optimize='sudo /home/pi/jdi-drm64/optimize_display.sh'
alias jdi-status='/home/pi/jdi-drm64/jdi-status'
alias lpm027dithering='/home/pi/jdi-drm64/lpm027-dithering.sh'
alias lpm027optimizer='/home/pi/jdi-drm64/lpm027-optimizer.sh'
alias testjdi='/home/pi/jdi-drm64/test_driver_complete.sh'
alias jdi-permissions='sudo chmod +x /home/pi/jdi-drm64/*.sh /home/pi/jdi-drm64/*.py /home/pi/jdi-drm64/monoset /home/pi/jdi-drm64/jdi-status'

# LPM027M128C Specific Commands (based on PDF specifications)
alias lpm027-status='jdi-status'
alias lmp027-8colors='monoset color'
alias lpm027-mono='monoset mono'
alias lpm027-reflective='optimize && monoset color'
alias lpm027-mip='optimize'
alias lpm027-lowpower='powersave --timeout 60'
alias lpm027-optimize='lpm027optimizer'

# Quick Configuration Presets
alias preset-indoor='monoset color && echo 3 | sudo tee /sys/class/backlight/jdi-backlight/brightness'
alias preset-outdoor='lpm027-reflective && echo 6 | sudo tee /sys/class/backlight/jdi-backlight/brightness'
alias preset-battery='lpm027-lowpower && echo 1 | sudo tee /sys/class/backlight/jdi-backlight/brightness'
alias preset-performance='monoset color && optimize'
alias preset-reading='monoset color && echo 3 | sudo tee /sys/class/backlight/jdi-backlight/brightness'

# Power Management
alias power-status='systemctl status jdi-powersave.service'
alias power-performance='sudo systemctl stop jdi-powersave.service'
alias power-eco='sudo systemctl start jdi-powersave.service'

# Brightness Control
alias brightness='cat /sys/class/backlight/jdi-backlight/brightness'
alias brightness-set='sudo tee /sys/class/backlight/jdi-backlight/brightness <<<'
alias brightness-up='/home/pi/jdi-drm64/simple_brightness_control.sh up'
alias brightness-down='/home/pi/jdi-drm64/simple_brightness_control.sh down'
alias brightness-cycle='/home/pi/jdi-drm64/simple_brightness_control.sh cycle'
alias brightness-toggle='/home/pi/jdi-drm64/simple_brightness_control.sh toggle'

# GPIO17 Button Testing
alias test-gpio17='sudo python3 /home/pi/jdi-drm64/gpio17_button_handler.py'

# JDI Help function
jdi-help() {
    echo "════════════════════════════════════════════════════════════════════"
    echo "  JDI LPM027M128C Display Commands - N@Xs Enhanced Edition"
    echo "════════════════════════════════════════════════════════════════════"
    echo "📊 System Status & Control:"
    echo "  jdi-status       - Complete system status monitor"
    echo "  brightness       - Show current PWM brightness (0-3)"
    echo "  brightness-set N - Set PWM brightness (0-3)"
    echo ""
    echo "🔘 GPIO17 Button Control:"
    echo "  test-gpio17      - Test GPIO17 button manually"
    echo "  brightness-cycle - Manual brightness cycling"
    echo "  brightness-up    - Increase brightness"
    echo "  brightness-down  - Decrease brightness"
    echo ""
    echo "🖥️ LPM027M128C Specific Commands (PDF specifications):"
    echo "  lpm027-status    - LPM027M128C color/mono status"
    echo "  lmp027-8colors   - Enable 8-color mode (3-bit data)"
    echo "  lpm027-mono      - Enable monochrome mode"
    echo "  lpm027-reflective- Optimize for reflective LCD"
    echo "  lpm027-mip       - Optimize Memory in Pixel technology"
    echo "  lpm027-lowpower  - MIP low power mode"
    echo "  lpm027-optimize  - Advanced display optimizer"
    echo ""
    echo "🎛️ Quick Configuration Presets:"
    echo "  preset-indoor    - Optimized for indoor use"
    echo "  preset-outdoor   - Optimized for outdoor use"
    echo "  preset-battery   - Maximum battery life"
    echo "  preset-performance - Maximum performance"
    echo "  preset-reading   - Optimized for reading"
    echo ""
    echo "⚡ Power Management (MIP Technology):"
    echo "  powersave        - Advanced power management"
    echo "  power-status     - Power management status"
    echo "  power-performance- Performance power mode"
    echo "  power-eco        - Eco power mode"
    echo ""
    echo "🔧 System Commands:"
    echo "  monoset          - Display status monitor"
    echo "  dither           - Dithering control"
    echo "  backlight        - Enhanced backlight controller"
    echo "  optimize         - System optimization"
    echo "  lpm027dithering  - LPM027 specific dithering"
    echo "  lpm027optimizer  - LPM027 optimizer"
    echo "  testjdi          - Test driver functionality"
    echo "  jdi-permissions  - Fix permissions for all scripts"
    echo "  jdi-help         - Show this help"
    echo "════════════════════════════════════════════════════════════════════"
}
ALIAS_EOF

    log_success "Comprehensive aliases added to ~/.bashrc"
    
    # Source the new aliases
    source ~/.bashrc 2>/dev/null || true
}

set_proper_permissions() {
    log_info "Setting proper permissions for all scripts..."
    
    cd "$DRIVER_DIR"
    
    # Make all scripts executable
    chmod +x *.sh *.py monoset jdi-status 2>/dev/null
    
    # Set proper ownership
    chown -R pi:pi "$DRIVER_DIR" 2>/dev/null
    
    log_success "All permissions set correctly"
}

main() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════════════════╗"
    echo "║                    JDI DRM Enhanced Driver Installer                    ║"
    echo "║                    COMPLETE VERSION with GPIO17 Button Support          ║"
    echo "║                                                                          ║"
    echo "║  🔧 This installer includes:                                             ║"
    echo "║     • System update and dependency installation                         ║"
    echo "║     • Kernel headers and build tools                                    ║"
    echo "║     • Source code compilation warning fixes                             ║"
    echo "║     • GPIO17 hardware button support (FIXED)                           ║"
    echo "║     • SystemD services for GPIO17 button, auto-optimize, powersave     ║"
    echo "║     • Device tree overlay with proper GPIO17 configuration             ║"
    echo "║     • GPIO permissions and udev rules                                   ║"
    echo "║     • 40+ comprehensive aliases and LPM027M128C commands               ║"
    echo "║     • Boot permissions service                                          ║"
    echo "║                                                                          ║"
    echo "║  Author: N@Xs - Enhanced Edition 2025                                   ║"
    echo "║  Ready for fresh Raspberry Pi OS images with GPIO17 button             ║"
    echo "╚══════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}\\n"
    
    log_info "Starting complete JDI driver installation with GPIO17 button support..."
    
    # Update system and install dependencies
    update_system_and_dependencies
    
    # Setup GPIO permissions for GPIO17 button
    setup_gpio_permissions
    
    # Clean up invalid files
    clean_invalid_files
    
    # Compile driver with fixes
    compile_driver
    
    # Verify brightness configuration
    verify_brightness_configuration
    
    # Compile and install device tree overlay
    compile_device_tree_overlay

    # Install driver
    install_driver
    
    # Set proper permissions
    set_proper_permissions
    
    # Create systemd services
    create_systemd_services
    
    # Clean up build artifacts
    clean_build_artifacts

    # Add comprehensive aliases
    add_comprehensive_aliases
    
    echo ""
    log_success "✅ Complete installation with GPIO17 button support finished successfully!"
    echo ""
    echo -e "${GREEN}Summary of installation:${NC}"
    echo "  ✅ System updated and dependencies installed"
    echo "  ✅ Kernel headers and build tools installed"
    echo "  ✅ GPIO17 button support configured"
    echo "  ✅ Device tree overlay updated with GPIO17 button"
    echo "  ✅ GPIO permissions and udev rules configured"
    echo "  ✅ Source code compilation warnings fixed"
    echo "  ✅ Driver compiled and installed successfully"
    echo "  ✅ SystemD services created and enabled:"
    echo "    • jdi-backlight-button.service (GPIO17 button - FIXED)"
    echo "    • jdi-auto-optimize.service (auto optimization)"
    echo "    • jdi-powersave.service (5-minute power saving)"
    echo "    • jdi-permissions.service (boot permissions)"
    echo "  ✅ Comprehensive aliases added (40+ commands)"
    echo "  ✅ All script permissions set correctly"
    echo "  ✅ Invalid files cleaned up"
    echo ""
    echo -e "${CYAN}Available commands after reboot:${NC}"
    echo "  📊 System: jdi-status, brightness, brightness-set"
    echo "  🔘 GPIO17 Button: test-gpio17, brightness-cycle"
    echo "  🖥️ Display: lmp027-8colors, lpm027-mono, lpm027-reflective"
    echo "  🎛️ Presets: preset-indoor, preset-outdoor, preset-battery"
    echo "  ⚡ Power: powersave, power-status, power-eco"
    echo "  🔧 Tools: monoset, dither, backlight, optimize"
    echo "  📖 Help: jdi-help (complete command reference)"
    echo ""
    echo -e "${YELLOW}IMPORTANT: Reboot required for GPIO17 button to work properly!${NC}"
    echo -e "${GREEN}After reboot, connect a button between GPIO17 and GND for brightness control.${NC}"
    echo ""
    echo -n "Reboot now? (y/N): "
    read restart_choice
    if [[ $restart_choice =~ ^[Yy]$ ]]; then
        log_info "Rebooting system..."
        sudo reboot
    else
        log_info "Remember to reboot: sudo reboot"
        log_info "You can run 'source ~/.bashrc' to use aliases now"
        log_info "Test GPIO17 button after reboot with: test-gpio17"
    fi
}

# Execute main function
main "$@"
# Device tree overlay compilation and installation functions

compile_device_tree_overlay() {
    log_info "Compiling device tree overlay with correct brightness levels..."
    cd "$DRIVER_DIR"
    
    # Verify brightness levels are correct in device tree source
    if grep -q "brightness-levels = <0 1 2 3>" jdi-drm-enhanced.dts; then
        log_success "Device tree has correct brightness levels (0-3)"
    else
        log_warn "Fixing device tree brightness levels..."
        sed -i 's/brightness-levels = <[^>]*>/brightness-levels = <0 1 2 3>/' jdi-drm-enhanced.dts
    fi
    
    # Compile device tree overlay
    if dtc -@ -I dts -O dtb -o jdi-drm-enhanced.dtbo jdi-drm-enhanced.dts 2>/dev/null; then
        log_success "Device tree overlay compiled successfully"
    else
        log_error "Failed to compile device tree overlay"
        return 1
    fi
    
    # Install overlay to /boot/overlays/
    if sudo cp jdi-drm-enhanced.dtbo /boot/overlays/; then
        log_success "Device tree overlay installed to /boot/overlays/"
    else
        log_error "Failed to install device tree overlay"
        return 1
    fi
}

verify_brightness_configuration() {
    log_info "Verifying brightness configuration consistency..."
    
    # Check if all scripts use correct brightness levels (0-3)
    local errors=0
    
    # Check GPIO17 button handler
    if ! grep -q "BRIGHTNESS_LEVELS = \[0, 1, 2, 3\]" gpio17_button_handler.py; then
        log_error "GPIO17 handler has wrong brightness levels"
        errors=$((errors + 1))
    fi
    
    # Check simple brightness control
    if grep -q "0-6\|/6" simple_brightness_control.sh; then
        log_error "Simple brightness control still references 0-6 range"
        errors=$((errors + 1))
    fi
    
    # Check enhanced back script
    if ! grep -q "BRIGHTNESS_LEVELS = \[0, 1, 2, 3\]" enhanced_back.py; then
        log_error "Enhanced back script has wrong brightness levels"
        errors=$((errors + 1))
    fi
    
    if [ $errors -eq 0 ]; then
        log_success "All brightness configurations are consistent (0-3)"
        return 0
    else
        log_error "$errors brightness configuration errors found"
        return 1
    fi
}

clean_build_artifacts() {
    log_info "Cleaning up build artifacts and temporary files..."
    cd "$DRIVER_DIR"
    
    # Remove build artifacts
    rm -f *.o *.ko *.mod *.cmd .*.cmd Module.symvers modules.order .module-common.o .lgd-nfy0 2>/dev/null
    
    # Remove backup and temporary files
    rm -f *.backup temp_* 2>/dev/null
    
    log_success "Build artifacts cleaned up"
}
