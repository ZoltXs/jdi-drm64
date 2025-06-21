#!/bin/bash

# JDI Driver Services and Aliases Setup
# Author: N@Xs - Enhanced Edition 2025

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

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

create_systemd_services() {
    log_info "Creating systemd services for JDI driver features..."
    
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

    # 2. GPIO17 backlight button service
    sudo tee /etc/systemd/system/jdi-backlight-button.service > /dev/null << 'BACKLIGHT_SERVICE_EOF'
[Unit]
Description=JDI GPIO17 Backlight Button Controller
After=multi-user.target
Wants=multi-user.target

[Service]
Type=simple
User=pi
Group=pi
ExecStart=/usr/bin/python3 /home/pi/jdi-drm64/enhanced_back.py
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
alias preset-indoor='monoset color && echo 4 | sudo tee /sys/class/backlight/jdi-backlight/brightness'
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

main() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════════════════╗"
    echo "║                    JDI Services and Aliases Setup                       ║"
    echo "║                         N@Xs Enhanced Edition                           ║"
    echo "╚══════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}\\n"
    
    log_info "Setting up JDI SystemD services and aliases..."
    
    # Create systemd services
    create_systemd_services
    
    # Add comprehensive aliases
    add_comprehensive_aliases
    
    echo ""
    log_success "✅ Setup completed successfully!"
    echo ""
    echo -e "${GREEN}Services created and enabled:${NC}"
    echo "  ✅ jdi-backlight-button.service (GPIO17 button)"
    echo "  ✅ jdi-auto-optimize.service (auto optimization)"
    echo "  ✅ jdi-powersave.service (5-minute power saving)"
    echo "  ✅ jdi-permissions.service (boot permissions)"
    echo ""
    echo -e "${CYAN}Available commands:${NC}"
    echo "  📊 System: jdi-status, brightness, brightness-set"
    echo "  🖥️ Display: lmp027-8colors, lpm027-mono, lpm027-reflective"
    echo "  🎛️ Presets: preset-indoor, preset-outdoor, preset-battery"
    echo "  ⚡ Power: powersave, power-status, power-eco"
    echo "  🔧 Tools: monoset, dither, backlight, optimize"
    echo "  📖 Help: jdi-help (complete command reference)"
    echo ""
    echo -e "${YELLOW}Run 'source ~/.bashrc' to use aliases now or reboot for full functionality${NC}"
}

# Execute main function
main "$@"
