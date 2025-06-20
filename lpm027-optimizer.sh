#!/bin/bash
# LPM027M128C Display Optimizer
# Optimización específica para Sharp Memory LCD LPM027M128C
# Autor: N@Xs - Enhanced Edition 2025

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

show_banner() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                   LPM027M128C Display Optimizer                 ║"
    echo "║                Sharp Memory LCD 400×240 IGZO                    ║"
    echo "║                    N@Xs Enhanced Edition                        ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

check_display() {
    log_info "Verificando compatibilidad con LPM027M128C..."
    
    # Verificar resolución
    if [ -f "/sys/class/graphics/fb0/virtual_size" ]; then
        resolution=$(cat /sys/class/graphics/fb0/virtual_size)
        if [ "$resolution" = "400,240" ]; then
            log_success "Resolución 400×240 confirmada - Compatible con LPM027M128C"
        else
            log_warning "Resolución $resolution no coincide con LPM027M128C (400×240)"
        fi
    fi
    
    # Verificar driver
    if lsmod | grep -q jdi_drm_enhanced; then
        log_success "Driver JDI Enhanced cargado"
    else
        log_error "Driver JDI Enhanced no cargado"
        return 1
    fi
    
    return 0
}

# Configuraciones optimizadas para LPM027M128C
optimize_for_performance() {
    log_info "Aplicando optimización de rendimiento para LPM027M128C..."
    
    # Configuración de dithering optimizada para IGZO
    echo '1' | sudo tee /sys/module/jdi_drm_enhanced/parameters/dither > /dev/null
    log_success "Dithering habilitado (optimizado para IGZO)"
    
    # Configuración de color optimizada
    echo 'Y' | sudo tee /sys/module/jdi_drm_enhanced/parameters/color > /dev/null
    echo '120' | sudo tee /sys/module/jdi_drm_enhanced/parameters/color_cutoff > /dev/null
    log_success "Modo color habilitado con cutoff optimizado (120)"
    
    # Mono settings optimizados para contraste IGZO
    echo '48' | sudo tee /sys/module/jdi_drm_enhanced/parameters/mono_cutoff > /dev/null
    log_success "Mono cutoff optimizado para contraste IGZO (48)"
    
    # Auto clear para preservar la memoria LCD
    echo 'Y' | sudo tee /sys/module/jdi_drm_enhanced/parameters/auto_clear > /dev/null
    log_success "Auto clear habilitado (preserva memoria LCD)"
    
    # Overlays para mejor rendimiento
    echo 'Y' | sudo tee /sys/module/jdi_drm_enhanced/parameters/overlays > /dev/null
    log_success "Overlays habilitados"
}

optimize_for_battery() {
    log_info "Aplicando optimización de batería para LPM027M128C..."
    
    # Auto power save con timeout agresivo
    echo 'Y' | sudo tee /sys/module/jdi_drm_enhanced/parameters/auto_power_save > /dev/null
    echo '300000' | sudo tee /sys/module/jdi_drm_enhanced/parameters/idle_timeout > /dev/null
    log_success "Auto power save configurado (60s timeout)"
    
    # Modo mono para ahorro de energía
    echo 'N' | sudo tee /sys/module/jdi_drm_enhanced/parameters/color > /dev/null
    echo '40' | sudo tee /sys/module/jdi_drm_enhanced/parameters/mono_cutoff > /dev/null
    log_success "Modo mono para ahorro de energía (cutoff 40)"
    
    # PWM backlight al mínimo
    echo '1' > /sys/class/backlight/jdi-backlight/brightness
    log_success "Backlight PWM al mínimo (nivel 1)"
}

optimize_for_quality() {
    log_info "Aplicando optimización de calidad para LPM027M128C..."
    
    # Configuración de alta calidad
    echo 'Y' | sudo tee /sys/module/jdi_drm_enhanced/parameters/color > /dev/null
    echo '140' | sudo tee /sys/module/jdi_drm_enhanced/parameters/color_cutoff > /dev/null
    log_success "Modo color de alta calidad (cutoff 140)"
    
    # Dithering avanzado
    echo '1' | sudo tee /sys/module/jdi_drm_enhanced/parameters/dither > /dev/null
    log_success "Dithering avanzado habilitado"
    
    # Mono settings para máximo contraste
    echo '60' | sudo tee /sys/module/jdi_drm_enhanced/parameters/mono_cutoff > /dev/null
    echo 'N' | sudo tee /sys/module/jdi_drm_enhanced/parameters/mono_invert > /dev/null
    log_success "Configuración mono de alta calidad"
    
    # PWM backlight óptimo
    echo '4' > /sys/class/backlight/jdi-backlight/brightness
    log_success "Backlight PWM óptimo (nivel 4)"
}

calibrate_display() {
    log_info "Calibrando display LPM027M128C..."
    
    # Configuración específica para IGZO
    echo 'Y' | sudo tee /sys/module/jdi_drm_enhanced/parameters/auto_clear > /dev/null
    echo 'Y' | sudo tee /sys/module/jdi_drm_enhanced/parameters/overlays > /dev/null
    
    # Test de colores para calibración
    log_info "Aplicando configuración de calibración..."
    echo '110' | sudo tee /sys/module/jdi_drm_enhanced/parameters/color_cutoff > /dev/null
    echo '50' | sudo tee /sys/module/jdi_drm_enhanced/parameters/mono_cutoff > /dev/null
    
    log_success "Calibración LPM027M128C completada"
}

show_status() {
    log_info "Estado actual del LPM027M128C:"
    echo "=============================="
    
    # Información del display
    if [ -f "/sys/class/graphics/fb0/virtual_size" ]; then
        resolution=$(cat /sys/class/graphics/fb0/virtual_size)
        echo "Resolución: $resolution"
    fi
    
    # PWM Backlight
    if [ -f "/sys/class/backlight/jdi-backlight/brightness" ]; then
        brightness=$(cat /sys/class/backlight/jdi-backlight/brightness)
        max_brightness=$(cat /sys/class/backlight/jdi-backlight/max_brightness)
        percentage=$((brightness * 100 / max_brightness))
        echo "Backlight PWM: $brightness/$max_brightness (${percentage}%)"
    fi
    
    # Configuración de color/mono
    color_mode=$(sudo cat /sys/module/jdi_drm_enhanced/parameters/color 2>/dev/null)
    if [ "$color_mode" = "Y" ]; then
        color_cutoff=$(sudo cat /sys/module/jdi_drm_enhanced/parameters/color_cutoff 2>/dev/null)
        echo "Modo: COLOR (cutoff: $color_cutoff)"
    else
        mono_cutoff=$(sudo cat /sys/module/jdi_drm_enhanced/parameters/mono_cutoff 2>/dev/null)
        mono_invert=$(sudo cat /sys/module/jdi_drm_enhanced/parameters/mono_invert 2>/dev/null)
        echo "Modo: MONO (cutoff: $mono_cutoff, invert: $mono_invert)"
    fi
    
    # Otros parámetros
    dither=$(sudo cat /sys/module/jdi_drm_enhanced/parameters/dither 2>/dev/null)
    auto_save=$(sudo cat /sys/module/jdi_drm_enhanced/parameters/auto_power_save 2>/dev/null)
    timeout=$(sudo cat /sys/module/jdi_drm_enhanced/parameters/idle_timeout 2>/dev/null)
    
    echo "Dithering: $dither"
    echo "Auto Power Save: $auto_save (timeout: ${timeout}ms)"
}

case "${1:-help}" in
    performance)
        show_banner
        check_display && optimize_for_performance
        echo ""
        show_status
        ;;
    battery)
        show_banner
        check_display && optimize_for_battery
        echo ""
        show_status
        ;;
    quality)
        show_banner
        check_display && optimize_for_quality
        echo ""
        show_status
        ;;
    calibrate)
        show_banner
        check_display && calibrate_display
        echo ""
        show_status
        ;;
    status)
        show_banner
        check_display
        echo ""
        show_status
        ;;
    help|*)
        show_banner
        echo "LPM027M128C Display Optimizer"
        echo "============================="
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  performance  - Optimize for best performance"
        echo "  battery      - Optimize for battery life"
        echo "  quality      - Optimize for display quality"
        echo "  calibrate    - Calibrate for LPM027M128C"
        echo "  status       - Show current configuration"
        echo "  help         - Show this help"
        echo ""
        echo "Examples:"
        echo "  $0 performance   # Best performance settings"
        echo "  $0 battery       # Battery saving settings"
        echo "  $0 quality       # Highest quality settings"
        ;;
esac
