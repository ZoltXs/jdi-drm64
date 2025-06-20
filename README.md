# JDI LPM027M128C Enhanced Driver - N@Xs Edition

**DRIVER COMPLETELY OPTIMIZED FOR LPM027M128C WITH FULL SYSTEMD INTEGRATION**

## 📋 LPM027M128C Technical Specifications

Based on official PDF specifications:

- **Display**: 2.7" Reflective TFT LCD
- **Technology**: Memory in Pixel (MIP) - Ultra low power
- **Interface**: SPI (Serial Peripheral Interface)  
- **Colors**: 8 colors (3-bit data mode)
- **Resolution**: 400×240 pixels
- **Technology**: IGZO (Indium Gallium Zinc Oxide)
- **Type**: Reflective LCD with advanced contrast
- **Power**: Ultra-low consumption with MIP technology

## 🎯 New Features in Enhanced Edition

- ✅ **GPIO17 Button Control** - Hardware button for brightness cycling
- ✅ **SystemD Integration** - Auto-start services for all features
- ✅ **PWM Backlight Control** - 7 brightness levels (0-6)
- ✅ **Intelligent Power Management** - 5-minute auto power saving
- ✅ **40+ Command Aliases** - Complete LPM027M128C command set
- ✅ **Quick Configuration Presets** - One-command display optimization
- ✅ **Comprehensive Status Monitor** - Real-time system monitoring

## 🚀 Quick Installation

### 1. Download & Extract
```bash
sudo git clone https://github.com/ZoltXs/jdi-drm64
cd jdi-drm-enhanced64-COMPLETE
```

### 2. Run Complete Installer  
```bash
chmod +x JDI_INSTALLER_COMPLETE.sh
./JDI_INSTALLER_COMPLETE.sh
```

### 3. Reboot & Enjoy
```bash
sudo reboot
```


## ✨ What Gets Installed Automatically

### 🔧 SystemD Services (Auto-start at boot)
- **jdi-backlight-button.service** - GPIO 17 button for brightness control
- **jdi-auto-optimize.service** - Automatic LPM027M128C optimization
- **jdi-powersave.service** - Intelligent 5-minute power saving
- **jdi-permissions.service** - Boot-time permissions setup

### ⚙️ System Configuration
- **System Update**: Updates all packages automatically
- **Dependencies**: Installs kernel headers, build-essential, git, dtc
- **Device Tree Overlay**: dtoverlay=jdi-drm-enhanced in /boot/firmware/config.txt
- **SPI Interface**: Automatically enabled
- **GPIO Permissions**: pi user added to gpio, spi, i2c groups
- **Auto Module Loading**: Driver loads at boot
- **PWM Backlight**: Full 7-level brightness control (0-6)

### 🎯 Complete Command Set (40+ aliases)
- **LPM027M128C-specific commands** based on PDF specifications
- **Quick configuration presets** for different use cases
- **Power management commands** for MIP technology
- **System monitoring tools** with real-time status
- **Advanced help system** with comprehensive documentation

## 📱 LPM027M128C Command Reference

### 📊 System Status & Control
```bash
jdi-status              # Complete system status monitor
                        # Shows: Driver status, PWM backlight, display mode,
                        #        power management, GPIO button status,
                        #        SystemD services, and available commands
                        
brightness              # Show current PWM brightness (0-6)
brightness-set N        # Set PWM brightness (0-6)
```

### 🔧 SystemD Service Management
```bash
power-status            # Show jdi-powersave.service status
power-performance       # Stop power saving (performance mode)
power-eco               # Start power saving (eco mode)
```

### 🖥️ LPM027M128C Specific Commands
Based on official PDF specifications:

```bash
lpm027-status           # LPM027M128C color/mono status
lmp027-8colors          # Enable 8-color mode (3-bit data) 
lpm027-mono             # Enable monochrome mode
lpm027-reflective       # Optimize for reflective LCD
lpm027-mip              # Optimize Memory in Pixel technology
lpm027-lowpower         # MIP low power mode  
lpm027-optimize         # Advanced display optimizer
```

### 🎛️ Quick Configuration Presets
```bash
preset-indoor           # Optimized for indoor use
                        # (8-color mode + brightness 4)
                        
preset-outdoor          # Optimized for outdoor use
                        # (reflective mode + max brightness 6)
                        
preset-battery          # Maximum battery life
                        # (low power mode + brightness 1)
                        
preset-performance      # Maximum performance
                        # (8-color mode + full optimization)
                        
preset-reading          # Optimized for reading
                        # (8-color mode + brightness 3)
```

### ⚡ Power Management (MIP Technology)
```bash
powersave               # Advanced power management
power-status            # Power management status  
power-performance       # Performance power mode
power-eco               # Eco power mode
```

## 🔧 Advanced Configuration

### SystemD Services Explained

#### GPIO17 Button Service
- **Service**: `jdi-backlight-button.service`
- **Function**: Monitors GPIO17 for button presses
- **Behavior**: Cycles brightness levels: 0→1→3→6→0
- **Auto-start**: Enabled at boot
- **User**: Runs as 'pi' user with proper GPIO permissions

#### Power Management Service
- **Service**: `jdi-powersave.service`
- **Function**: Intelligent 5-minute power saving
- **Behavior**: Automatically reduces power after inactivity
- **Control**: `power-eco` (enable) / `power-performance` (disable)

#### Auto-Optimization Service
- **Service**: `jdi-auto-optimize.service`
- **Function**: Applies LPM027M128C-specific optimizations at boot
- **Includes**: Display parameters, MIP settings, PWM configuration

### Display Modes Based on LPM027M128C Specs

#### 8-Color Mode (Recommended)
```bash
lmp027-8colors
```
- Enables full 8-color mode (3-bit data)
- Best for general use
- Optimized color cutoffs (110-140)
- Full MIP technology benefits

#### Reflective Mode (Outdoor Use)
```bash  
lpm027-reflective
```
- Optimized for outdoor reflective use
- Enhanced contrast for sunlight visibility
- Best with maximum brightness

#### Low Power Mode (Battery Saving)
```bash
lpm027-lowpower  
```
- Activates MIP ultra-low power features
- Automatic 60-second timeout to mono
- Memory protection enabled
- Minimal power consumption

## 📖 Help & Documentation

### Help System
```bash
jdi-help                # Complete command reference with categories:
                        # 📊 System Status & Control
                        # 🖥️ LPM027M128C Specific Commands
                        # 🎛️ Quick Configuration Presets
                        # ⚡ Power Management
                        # 🔧 System Commands
```

### Diagnostic Commands
```bash
jdi-status              # Real-time system status monitor
                        # Shows all services, PWM status, GPIO button
                        
testjdi                 # Complete driver test suite
jdi-permissions         # Fix script permissions if needed
```

### Advanced Monitoring
```bash
# Monitor SystemD services
systemctl status jdi-backlight-button.service
systemctl status jdi-powersave.service
systemctl status jdi-auto-optimize.service
systemctl status jdi-permissions.service

# Real-time logs
journalctl -u jdi-backlight-button.service -f
journalctl -u jdi-powersave.service -f
```

## 🎯 Usage Examples

### Daily Use Scenarios

#### Indoor Work Setup
```bash
preset-indoor           # 8-color mode + brightness 4
# Result: Perfect for office/home use
# - Enables 8-color mode with MIP optimization
# - Sets brightness to level 4 (comfortable for indoor)
# - Optimized color cutoffs for general computing
```

#### Outdoor Reading
```bash  
preset-outdoor          # Reflective mode + max brightness 6
# Result: Maximum visibility in sunlight
# - Enables reflective LCD optimization
# - Sets maximum brightness (level 6)
# - Enhanced contrast for outdoor visibility
```

#### Battery Conservation
```bash
preset-battery          # Low power + brightness 1
# Result: Maximum battery life
# - Enables 60-second power saving timeout
# - Sets minimum brightness (level 1)
# - Activates all MIP power-saving features
```

### GPIO17 Button Usage

The hardware button on GPIO17 provides instant brightness control:
- **Press once**: Brightness 0 (OFF)
- **Press again**: Brightness 1 (Low)
- **Press again**: Brightness 3 (Medium)
- **Press again**: Brightness 6 (High)
- **Press again**: Back to OFF (cycles continuously)

### Power Management

```bash
# Enable intelligent power saving
power-eco               # 5-minute auto power saving

# Disable for performance
power-performance       # No auto power saving

# Check current status
power-status            # Show service status and settings
```

## 🔍 jdi-status Tool Explained

The `jdi-status` command is a comprehensive system monitor that provides real-time information about:

### What jdi-status Shows:
- **Driver Status**: Whether jdi-drm-enhanced module is loaded
- **Framebuffer**: Availability and resolution (400,240)
- **PWM Backlight**: Current brightness level and interface status
- **Display Mode**: Color/mono mode and current settings
- **Power Management**: Auto power save settings and timeouts
- **GPIO Button**: Service status, uptime, and functionality
- **SystemD Services**: All JDI-related service statuses
- **Available Commands**: Quick reference to common commands

### How to Use jdi-status:
```bash
jdi-status              # Run anytime to check system status
```

This tool is essential for troubleshooting and monitoring the complete JDI driver ecosystem.

## 💝 Credits & License

**Author**: N@Xs - Enhanced Edition 2025  
**Display**: LPM027M128C specifications-based implementation  
**Technology**: Memory in Pixel (MIP) + IGZO optimization  

Based on official LPM027M128C PDF specifications.

---

*This driver is specifically optimized for the LPM027M128C display based on official technical documentation. All features are designed to maximize the potential of Memory in Pixel technology while maintaining ultra-low power consumption. The enhanced edition includes full SystemD integration for seamless operation.*
