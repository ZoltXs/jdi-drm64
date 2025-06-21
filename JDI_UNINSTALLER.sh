#!/bin/bash

# JDI DRM Enhanced Driver - Complete Uninstaller Script
# Author: N@Xs - Enhanced Edition 2025
# This script removes everything installed by JDI_INSTALLER_COMPLETE.sh

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

stop_and_remove_services() {
    log_info "Stopping and removing JDI systemd services..."
    
    # Stop all JDI services
    sudo systemctl stop jdi-backlight-button.service 2>/dev/null || true
    sudo systemctl stop jdi-auto-optimize.service 2>/dev/null || true
    sudo systemctl stop jdi-powersave.service 2>/dev/null || true
    sudo systemctl stop jdi-permissions.service 2>/dev/null || true
    
    # Disable all JDI services
    sudo systemctl disable jdi-backlight-button.service 2>/dev/null || true
    sudo systemctl disable jdi-auto-optimize.service 2>/dev/null || true
    sudo systemctl disable jdi-powersave.service 2>/dev/null || true
    sudo systemctl disable jdi-permissions.service 2>/dev/null || true
    
    # Remove service files
    sudo rm -f /etc/systemd/system/jdi-backlight-button.service
    sudo rm -f /etc/systemd/system/jdi-auto-optimize.service
    sudo rm -f /etc/systemd/system/jdi-powersave.service
    sudo rm -f /etc/systemd/system/jdi-permissions.service
    
    # Reload systemd
    sudo systemctl daemon-reload
    sudo systemctl reset-failed
    
    log_success "All JDI systemd services removed"
}

unload_and_remove_driver() {
    log_info "Unloading and removing JDI driver..."
    
    # Unload the driver module
    sudo modprobe -r jdi_drm_enhanced 2>/dev/null || true
    
    # Remove from auto-load
    sudo sed -i '/jdi-drm-enhanced/d' /etc/modules 2>/dev/null || true
    
    # Remove installed driver modules
    sudo find /lib/modules -name "*jdi*drm*" -delete 2>/dev/null || true
    sudo find /lib/modules -name "*jdi*enhanced*" -delete 2>/dev/null || true
    
    # Remove device tree overlay
    sudo rm -f /boot/overlays/jdi-drm-enhanced.dtbo
    
    # Update module dependencies
    sudo depmod -A
    
    log_success "JDI driver modules removed"
}

remove_boot_configuration() {
    log_info "Removing boot configuration..."
    
    # Remove device tree overlay from config.txt
    sudo sed -i '/dtoverlay=jdi-drm-enhanced/d' /boot/firmware/config.txt 2>/dev/null || true
    sudo sed -i '/dtoverlay=jdi-drm-enhanced/d' /boot/config.txt 2>/dev/null || true
    
    # Remove SPI enablement if it was added by JDI installer
    # (Note: We'll leave dtparam=spi=on as it might be used by other things)
    
    # Remove console configuration changes
    sudo sed -i 's/ console=tty2 fbcon=font:VGA8x8 fbcon=map:10//g' /boot/firmware/cmdline.txt 2>/dev/null || true
    sudo sed -i 's/ console=tty2 fbcon=font:VGA8x8 fbcon=map:10//g' /boot/cmdline.txt 2>/dev/null || true
    
    log_success "Boot configuration cleaned"
}

remove_gpio_permissions() {
    log_info "Removing GPIO permissions and udev rules..."
    
    # Remove udev rules
    sudo rm -f /etc/udev/rules.d/99-gpio.rules
    
    # Note: We don't remove users from groups as they might need them for other purposes
    log_warning "User groups (input, gpio) not removed - may be needed for other purposes"
    
    log_success "GPIO udev rules removed"
}

remove_aliases() {
    log_info "Removing JDI aliases from ~/.bashrc..."
    
    # Backup current bashrc
    cp ~/.bashrc ~/.bashrc.backup.uninstall.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
    
    # Remove JDI aliases section
    sed -i '/# JDI Display Aliases/,/^$/d' ~/.bashrc 2>/dev/null || true
    
    # Remove any individual JDI aliases that might be left
    sed -i '/alias.*jdi-/d' ~/.bashrc 2>/dev/null || true
    sed -i '/alias.*lpm027/d' ~/.bashrc 2>/dev/null || true
    sed -i '/alias.*preset-/d' ~/.bashrc 2>/dev/null || true
    sed -i '/alias.*brightness/d' ~/.bashrc 2>/dev/null || true
    sed -i '/alias.*power-/d' ~/.bashrc 2>/dev/null || true
    sed -i '/alias.*test-gpio17/d' ~/.bashrc 2>/dev/null || true
    sed -i '/alias monoset/d' ~/.bashrc 2>/dev/null || true
    sed -i '/alias dither/d' ~/.bashrc 2>/dev/null || true
    sed -i '/alias powersave/d' ~/.bashrc 2>/dev/null || true
    sed -i '/alias backlight/d' ~/.bashrc 2>/dev/null || true
    sed -i '/alias optimize/d' ~/.bashrc 2>/dev/null || true
    sed -i '/alias testjdi/d' ~/.bashrc 2>/dev/null || true
    
    # Remove JDI help function
    sed -i '/^jdi-help()/,/^}$/d' ~/.bashrc 2>/dev/null || true
    
    log_success "JDI aliases removed from ~/.bashrc"
}

clean_driver_directory() {
    log_info "Cleaning driver directory build artifacts..."
    
    if [ -d "$DRIVER_DIR" ]; then
        cd "$DRIVER_DIR"
        
        # Remove build artifacts
        find . -name "*.o" -delete 2>/dev/null || true
        find . -name "*.cmd" -delete 2>/dev/null || true
        find . -name "*.mod" -delete 2>/dev/null || true
        find . -name "*.ko" -delete 2>/dev/null || true
        find . -name "*.dtbo" -delete 2>/dev/null || true
        find . -name "Module.symvers" -delete 2>/dev/null || true
        find . -name "modules.order" -delete 2>/dev/null || true
        
        # Remove backup files
        find . -name "*.backup*" -delete 2>/dev/null || true
        
        log_success "Driver directory cleaned"
    else
        log_warning "Driver directory not found: $DRIVER_DIR"
    fi
}

remove_backlight_configuration() {
    log_info "Removing backlight configuration..."
    
    # Check if jdi-backlight exists and remove references
    if [ -d "/sys/class/backlight/jdi-backlight" ]; then
        log_warning "JDI backlight device still active - will be removed after reboot"
    fi
    
    log_success "Backlight configuration marked for removal"
}

verify_removal() {
    log_info "Verifying removal..."
    
    # Check for remaining services
    if systemctl list-unit-files | grep -q jdi-; then
        log_warning "Some JDI services may still be listed"
    else
        log_success "No JDI services found"
    fi
    
    # Check for loaded modules
    if lsmod | grep -q jdi; then
        log_warning "JDI module still loaded - will be removed after reboot"
    else
        log_success "No JDI modules loaded"
    fi
    
    # Check for device tree overlay
    if [ -f "/boot/overlays/jdi-drm-enhanced.dtbo" ]; then
        log_warning "Device tree overlay still present"
    else
        log_success "Device tree overlay removed"
    fi
    
    # Check for aliases
    if grep -q "jdi-" ~/.bashrc 2>/dev/null; then
        log_warning "Some JDI aliases may still be present in ~/.bashrc"
    else
        log_success "No JDI aliases found in ~/.bashrc"
    fi
}

show_manual_cleanup() {
    log_info "Manual cleanup instructions..."
    
    echo ""
    echo -e "${YELLOW}Items that may need manual attention:${NC}"
    echo "1. Check ~/.bashrc for any remaining JDI aliases"
    echo "2. Remove driver source directory if no longer needed:"
    echo "   rm -rf $DRIVER_DIR"
    echo "3. If you installed additional packages, you may want to remove them:"
    echo "   sudo apt remove python3-gpiozero device-tree-compiler"
    echo "4. Reboot to ensure all kernel modules are unloaded"
    echo ""
}

main() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════════════════╗"
    echo "║                        JDI DRM Enhanced Driver Uninstaller              ║"
    echo "║                                                                          ║"
    echo "║  ⚠️  This will remove ALL components installed by JDI_INSTALLER_COMPLETE ║"
    echo "║                                                                          ║"
    echo "║  Components to be removed:                                               ║"
    echo "║     • All JDI systemd services                                          ║"
    echo "║     • JDI driver modules                                                ║"
    echo "║     • Device tree overlays                                              ║"
    echo "║     • Boot configuration changes                                        ║"
    echo "║     • GPIO permissions and udev rules                                   ║"
    echo "║     • All JDI aliases from ~/.bashrc                                    ║"
    echo "║     • Build artifacts and temporary files                               ║"
    echo "║                                                                          ║"
    echo "║  Author: N@Xs - Enhanced Edition 2025                                   ║"
    echo "╚══════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}\\n"
    
    echo -n "Are you sure you want to completely uninstall the JDI driver? (y/N): "
    read confirm_choice
    if [[ ! $confirm_choice =~ ^[Yy]$ ]]; then
        log_info "Uninstallation cancelled by user"
        exit 0
    fi
    
    log_info "Starting complete JDI driver uninstallation..."
    echo ""
    
    # Stop and remove all services
    stop_and_remove_services
    
    # Unload and remove driver
    unload_and_remove_driver
    
    # Remove boot configuration
    remove_boot_configuration
    
    # Remove GPIO permissions
    remove_gpio_permissions
    
    # Remove aliases
    remove_aliases
    
    # Remove backlight configuration
    remove_backlight_configuration
    
    # Clean driver directory
    clean_driver_directory
    
    # Verify removal
    verify_removal
    
    echo ""
    log_success "✅ JDI driver uninstallation completed!"
    echo ""
    echo -e "${GREEN}Summary of removal:${NC}"
    echo "  ✅ All JDI systemd services stopped and removed"
    echo "  ✅ JDI driver modules unloaded and removed"
    echo "  ✅ Device tree overlay removed"
    echo "  ✅ Boot configuration cleaned"
    echo "  ✅ GPIO udev rules removed"
    echo "  ✅ All JDI aliases removed from ~/.bashrc"
    echo "  ✅ Build artifacts cleaned"
    echo ""
    
    # Show manual cleanup instructions
    show_manual_cleanup
    
    echo -e "${YELLOW}Reboot recommended to ensure all changes take effect.${NC}"
    echo -e "${GREEN}After reboot, you can safely run JDI_INSTALLER_COMPLETE.sh again.${NC}"
    echo ""
    echo -n "Reboot now? (y/N): "
    read reboot_choice
    if [[ $reboot_choice =~ ^[Yy]$ ]]; then
        log_info "Rebooting system..."
        sudo reboot
    else
        log_info "Remember to reboot before reinstalling: sudo reboot"
        log_info "You can also run 'source ~/.bashrc' to reload shell aliases"
    fi
}

# Execute main function
main "$@"
