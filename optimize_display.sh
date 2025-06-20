#!/bin/bash
# JDI Display Optimization Script
# Autor: N@Xs - Enhanced Edition 2025 - PWM FIXED VERSION

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

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

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

check_driver() {
    if ! lsmod | grep -q jdi_drm_enhanced; then
        log_error "JDI DRM Enhanced driver not loaded"
        return 1
    fi
    return 0
}

check_pwm_backlight() {
    if [ ! -f "/sys/class/backlight/jdi-backlight/brightness" ]; then
        log_error "PWM backlight not available"
        return 1
    fi
    return 0
}

optimize_all() {
    log_info "Starting JDI Display Optimization with PWM..."
    
    if ! check_driver; then
        return 1
    fi
    
    # Enable power save with 2min timeout
    log_info "Configuring power management..."
    python3 /home/pi/jdi-drm-enhanced64/powersave.py enable-powersave --timeout 120000
    
    # Enable hardware dithering
    log_info "Enabling hardware dithering..."
    python3 /home/pi/jdi-drm-enhanced64/powersave.py dither-on
    
    # Configure auto clear
    log_info "Enabling auto clear..."
    echo 'Y' > /sys/module/jdi_drm_enhanced/parameters/auto_clear
    
    # Enable color mode
    log_info "Ensuring color mode is enabled..."
    echo 'Y' > /sys/module/jdi_drm_enhanced/parameters/color
    
    # Set optimal PWM backlight level
    if check_pwm_backlight; then
        log_info "Setting optimal PWM backlight level..."
        echo '4' > /sys/class/backlight/jdi-backlight/brightness
        log_success "PWM backlight set to level 4/6"
    fi
    
    log_success "Optimization complete!"
    echo ""
    python3 /home/pi/jdi-drm-enhanced64/powersave.py status
}

show_current_status() {
    log_info "Current JDI Display Configuration"
    echo "=================================="
    
    if check_driver; then
        python3 /home/pi/jdi-drm-enhanced64/powersave.py status
        echo ""
        
        log_info "Driver Information"
        echo "Module: $(lsmod | grep jdi_drm_enhanced | awk '{print $1 " (size: " $2 ")"}')"
        
        # Check PWM backlight
        if check_pwm_backlight; then
            current_brightness=$(cat /sys/class/backlight/jdi-backlight/brightness)
            max_brightness=$(cat /sys/class/backlight/jdi-backlight/max_brightness)
            echo "PWM Backlight: $current_brightness/$max_brightness"
        fi
        
        # Check if enhanced_back.py is running
        if pgrep -f "enhanced_back.py" > /dev/null; then
            echo "Enhanced Backlight Controller: Running (PID: $(pgrep -f 'enhanced_back.py'))"
        else
            echo "Enhanced Backlight Controller: Not running"
        fi
    fi
}

start_services() {
    log_info "Starting display services..."
    
    pkill -f "enhanced_back.py" 2>/dev/null
    sleep 1
    
    log_info "Starting Enhanced PWM Backlight Controller..."
    sudo -u pi python3 /home/pi/jdi-drm-enhanced64/enhanced_back.py &
    
    sleep 2
    
    if pgrep -f "enhanced_back.py" > /dev/null; then
        log_success "Enhanced PWM Backlight Controller started successfully"
    else
        log_warning "Enhanced PWM Backlight Controller may not have started properly"
    fi
}

stop_services() {
    log_info "Stopping display services..."
    pkill -f "enhanced_back.py" 2>/dev/null
    log_success "Services stopped"
}

case "${1:-status}" in
    optimize)
        check_root
        optimize_all
        ;;
    status)
        show_current_status
        ;;
    start)
        check_root
        start_services
        ;;
    stop)
        check_root
        stop_services
        ;;
    restart)
        check_root
        stop_services
        sleep 2
        start_services
        ;;
    *)
        echo "Usage: $0 [optimize|status|start|stop|restart]"
        exit 1
        ;;
esac
