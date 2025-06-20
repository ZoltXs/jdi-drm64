#!/bin/bash
# Advanced Dithering for LPM027M128C
# Dithering optimizado para Sharp Memory LCD IGZO
# Autor: N@Xs - Enhanced Edition 2025

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_driver() {
    if ! lsmod | grep -q jdi_drm_enhanced; then
        log_error "JDI DRM Enhanced driver not loaded"
        return 1
    fi
    return 0
}

show_dither_status() {
    log_info "LPM027M128C Dithering Status"
    echo "============================"
    
    if check_driver; then
        dither_state=$(sudo cat /sys/module/jdi_drm_enhanced/parameters/dither 2>/dev/null || echo "N/A")
        color_mode=$(sudo cat /sys/module/jdi_drm_enhanced/parameters/color 2>/dev/null || echo "N/A")
        
        echo "Hardware Dithering: $dither_state"
        echo "Color Mode: $color_mode"
        
        if [ "$dither_state" = "1" ]; then
            echo -e "Status: ${GREEN}ENABLED${NC} (optimized for IGZO)"
        else
            echo -e "Status: ${RED}DISABLED${NC}"
        fi
        
        if [ "$color_mode" = "Y" ]; then
            color_cutoff=$(sudo cat /sys/module/jdi_drm_enhanced/parameters/color_cutoff 2>/dev/null)
            echo "Color cutoff: $color_cutoff (affects dithering quality)"
        else
            mono_cutoff=$(sudo cat /sys/module/jdi_drm_enhanced/parameters/mono_cutoff 2>/dev/null)
            echo "Mono cutoff: $mono_cutoff (affects dithering quality)"
        fi
    fi
}

enable_igzo_dithering() {
    log_info "Enabling IGZO-optimized dithering for LPM027M128C..."
    
    if ! check_driver; then
        return 1
    fi
    
    # Enable hardware dithering
    echo '1' | sudo tee /sys/module/jdi_drm_enhanced/parameters/dither > /dev/null
    
    # Optimize cutoff values for IGZO characteristics
    current_mode=$(sudo cat /sys/module/jdi_drm_enhanced/parameters/color 2>/dev/null)
    
    if [ "$current_mode" = "Y" ]; then
        # Color mode - optimize for IGZO color response
        echo '125' | sudo tee /sys/module/jdi_drm_enhanced/parameters/color_cutoff > /dev/null
        log_success "Color dithering enabled (cutoff: 125 for IGZO)"
    else
        # Mono mode - optimize for IGZO contrast
        echo '45' | sudo tee /sys/module/jdi_drm_enhanced/parameters/mono_cutoff > /dev/null
        log_success "Mono dithering enabled (cutoff: 45 for IGZO)"
    fi
    
    log_success "IGZO-optimized dithering enabled"
}

disable_dithering() {
    log_info "Disabling dithering..."
    
    if ! check_driver; then
        return 1
    fi
    
    echo '0' | sudo tee /sys/module/jdi_drm_enhanced/parameters/dither > /dev/null
    log_success "Dithering disabled"
}

test_dithering_patterns() {
    log_info "Testing dithering patterns for LPM027M128C..."
    
    if ! check_driver; then
        return 1
    fi
    
    # Test pattern 1: Standard IGZO
    log_info "Testing Pattern 1: Standard IGZO..."
    echo '1' | sudo tee /sys/module/jdi_drm_enhanced/parameters/dither > /dev/null
    echo '110' | sudo tee /sys/module/jdi_drm_enhanced/parameters/color_cutoff > /dev/null
    sleep 2
    
    # Test pattern 2: High contrast
    log_info "Testing Pattern 2: High contrast..."
    echo '140' | sudo tee /sys/module/jdi_drm_enhanced/parameters/color_cutoff > /dev/null
    sleep 2
    
    # Test pattern 3: Low contrast
    log_info "Testing Pattern 3: Low contrast..."
    echo '90' | sudo tee /sys/module/jdi_drm_enhanced/parameters/color_cutoff > /dev/null
    sleep 2
    
    # Return to optimal
    log_info "Returning to optimal settings..."
    echo '125' | sudo tee /sys/module/jdi_drm_enhanced/parameters/color_cutoff > /dev/null
    
    log_success "Dithering pattern test completed"
}

optimize_for_text() {
    log_info "Optimizing dithering for text (LPM027M128C)..."
    
    if ! check_driver; then
        return 1
    fi
    
    # Text optimization
    echo '1' | sudo tee /sys/module/jdi_drm_enhanced/parameters/dither > /dev/null
    echo 'N' | sudo tee /sys/module/jdi_drm_enhanced/parameters/color > /dev/null
    echo '55' | sudo tee /sys/module/jdi_drm_enhanced/parameters/mono_cutoff > /dev/null
    echo 'N' | sudo tee /sys/module/jdi_drm_enhanced/parameters/mono_invert > /dev/null
    
    log_success "Text-optimized dithering enabled"
}

optimize_for_graphics() {
    log_info "Optimizing dithering for graphics (LPM027M128C)..."
    
    if ! check_driver; then
        return 1
    fi
    
    # Graphics optimization
    echo '1' | sudo tee /sys/module/jdi_drm_enhanced/parameters/dither > /dev/null
    echo 'Y' | sudo tee /sys/module/jdi_drm_enhanced/parameters/color > /dev/null
    echo '115' | sudo tee /sys/module/jdi_drm_enhanced/parameters/color_cutoff > /dev/null
    
    log_success "Graphics-optimized dithering enabled"
}

case "${1:-status}" in
    on|enable)
        enable_igzo_dithering
        echo ""
        show_dither_status
        ;;
    off|disable)
        disable_dithering
        echo ""
        show_dither_status
        ;;
    test)
        test_dithering_patterns
        echo ""
        show_dither_status
        ;;
    text)
        optimize_for_text
        echo ""
        show_dither_status
        ;;
    graphics)
        optimize_for_graphics
        echo ""
        show_dither_status
        ;;
    status)
        show_dither_status
        ;;
    *)
        echo "LPM027M128C Advanced Dithering Control"
        echo "======================================"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  on|enable    - Enable IGZO-optimized dithering"
        echo "  off|disable  - Disable dithering"
        echo "  test         - Test dithering patterns"
        echo "  text         - Optimize for text display"
        echo "  graphics     - Optimize for graphics"
        echo "  status       - Show dithering status"
        echo ""
        echo "Optimized for Sharp Memory LCD LPM027M128C IGZO technology"
        ;;
esac
