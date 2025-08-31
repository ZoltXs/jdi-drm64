#!/usr/bin/python3
"""
Enhanced Power Management for JDI Display
Autor: N@Xs - Enhanced Edition 2025 -
"""

import os
import sys
import argparse
import time
from pathlib import Path

class JDIPowerManager:
    def __init__(self):
        # Module parameters (still used for power management)
        self.module_path = Path('/sys/module/jdi_drm_enhanced/parameters')
        self.params = {
            'auto_power_save': self.module_path / 'auto_power_save',
            'idle_timeout': self.module_path / 'idle_timeout',
            'dither': self.module_path / 'dither',
            'auto_clear': self.module_path / 'auto_clear',
            'color': self.module_path / 'color',
        }
        
        # PWM Backlight control (NEW - real illumination control)
        self.pwm_backlight_path = Path('/sys/class/backlight/jdi-backlight/brightness')
        self.pwm_max_brightness_path = Path('/sys/class/backlight/jdi-backlight/max_brightness')
        self.pwm_power_path = Path('/sys/class/backlight/jdi-backlight/bl_power')
        
        # Colors for output
        self.colors = {
            'RED': '\033[0;31m',
            'GREEN': '\033[0;32m',
            'YELLOW': '\033[1;33m',
            'BLUE': '\033[0;34m',
            'PURPLE': '\033[0;35m',
            'CYAN': '\033[0;36m',
            'NC': '\033[0m'
        }
        
    def log(self, level, message):
        """Colored logging"""
        color_map = {
            'INFO': self.colors['BLUE'],
            'SUCCESS': self.colors['GREEN'],
            'WARNING': self.colors['YELLOW'],
            'ERROR': self.colors['RED']
        }
        color = color_map.get(level, self.colors['NC'])
        print(f"{color}[{level}]{self.colors['NC']} {message}")
    
    def check_driver(self):
        """Check if JDI driver is loaded"""
        if not self.module_path.exists():
            self.log('ERROR', 'JDI DRM Enhanced driver not loaded')
            return False
        return True
    
    def check_pwm_backlight(self):
        """Check if PWM backlight is available"""
        if not self.pwm_backlight_path.exists():
            self.log('ERROR', 'PWM backlight not available')
            return False
        return True
    
    def read_param(self, param_name):
        """Read parameter value"""
        try:
            if param_name in self.params:
                with open(self.params[param_name], 'r') as f:
                    return f.read().strip()
            return None
        except PermissionError:
            self.log('ERROR', f'Permission denied reading {param_name}. Try with sudo.')
            return None
        except Exception as e:
            self.log('ERROR', f'Error reading {param_name}: {e}')
            return None
    
    def write_param(self, param_name, value):
        """Write parameter value"""
        try:
            if param_name in self.params:
                with open(self.params[param_name], 'w') as f:
                    f.write(str(value))
                return True
            return False
        except PermissionError:
            self.log('ERROR', f'Permission denied writing {param_name}. Try with sudo.')
            return False
        except Exception as e:
            self.log('ERROR', f'Error writing {param_name}: {e}')
            return False
    
    def read_pwm_brightness(self):
        """Read current PWM brightness"""
        try:
            with open(self.pwm_backlight_path, 'r') as f:
                return int(f.read().strip())
        except Exception as e:
            self.log('ERROR', f'Error reading PWM brightness: {e}')
            return None
    
    def read_pwm_max_brightness(self):
        """Read maximum PWM brightness"""
        try:
            with open(self.pwm_max_brightness_path, 'r') as f:
                return int(f.read().strip())
        except Exception as e:
            self.log('ERROR', f'Error reading max PWM brightness: {e}')
            return 6  # Default fallback
    
    def set_pwm_brightness(self, level):
        """Set PWM brightness level"""
        try:
            with open(self.pwm_backlight_path, 'w') as f:
                f.write(str(level))
            return True
        except PermissionError:
            self.log('ERROR', 'Permission denied setting brightness. Try with sudo.')
            return False
        except Exception as e:
            self.log('ERROR', f'Error setting PWM brightness: {e}')
            return False
    
    def show_status(self):
        """Show current power management status"""
        if not self.check_driver():
            return
            
        self.log('INFO', 'JDI Display Power Management Status')
        print('=' * 40)
        
        # Show module parameters
        for param_name in self.params.keys():
            value = self.read_param(param_name)
            if value is not None:
                if value in ['Y', 'N']:
                    formatted_value = f"{value} ({'ON' if value == 'Y' else 'OFF'})"
                    color = self.colors['GREEN'] if value == 'Y' else self.colors['RED']
                else:
                    formatted_value = value
                    color = self.colors['CYAN']
                
                print(f"{param_name:15}: {color}{formatted_value}{self.colors['NC']}")
        
        # Show PWM backlight status
        print(f"\n{self.colors['PURPLE']}PWM Backlight Status:{self.colors['NC']}")
        if self.check_pwm_backlight():
            current_brightness = self.read_pwm_brightness()
            max_brightness = self.read_pwm_max_brightness()
            
            if current_brightness is not None:
                status = 'ON' if current_brightness > 0 else 'OFF'
                color = self.colors['GREEN'] if current_brightness > 0 else self.colors['RED']
                print(f"  Brightness: {color}{current_brightness}/{max_brightness} ({status}){self.colors['NC']}")
                
                if current_brightness > 0:
                    percentage = int((current_brightness / max_brightness) * 100)
                    print(f"  Percentage: {percentage}%")
        else:
            print(f"  {self.colors['RED']}PWM backlight not available{self.colors['NC']}")
        
        # Show auto power save info
        auto_save = self.read_param('auto_power_save')
        timeout = self.read_param('idle_timeout')
        
        if auto_save and timeout:
            print(f"\n{self.colors['PURPLE']}Power Save Info:{self.colors['NC']}")
            if auto_save == 'Y':
                timeout_sec = int(timeout) / 1000
                print(f"  Auto sleep after: {timeout_sec}s of inactivity")
            else:
                print("  Auto sleep: Disabled")
    
    def enable_powersave(self, timeout_ms=120000):
        """Enable auto power save with timeout"""
        if not self.check_driver():
            return False
            
        self.log('INFO', f'Enabling auto power save (timeout: {timeout_ms}ms)')
        
        success = True
        success &= self.write_param('auto_power_save', 'Y')
        success &= self.write_param('idle_timeout', timeout_ms)
        
        if success:
            self.log('SUCCESS', f'Auto power save enabled - sleep after {timeout_ms/1000}s')
        else:
            self.log('ERROR', 'Failed to enable auto power save')
        
        return success
    
    def disable_powersave(self):
        """Disable auto power save"""
        if not self.check_driver():
            return False
            
        self.log('INFO', 'Disabling auto power save')
        success = self.write_param('auto_power_save', 'N')
        
        if success:
            self.log('SUCCESS', 'Auto power save disabled')
        else:
            self.log('ERROR', 'Failed to disable auto power save') 
        
        return success
    
    def set_dithering(self, enable):
        """Enable/disable hardware dithering"""
        if not self.check_driver():
            return False
            
        value = '1' if enable else '0'
        self.log('INFO', f'Setting dithering to {"ON" if enable else "OFF"}')
        
        success = self.write_param('dither', value)
        
        if success:
            self.log('SUCCESS', f'Hardware dithering {"enabled" if enable else "disabled"}')
        else:
            self.log('ERROR', 'Failed to set dithering')
        
        return success
    
    def set_backlight(self, enable, level=None):
        """Enable/disable PWM backlight"""
        if not self.check_pwm_backlight():
            return False
            
        if enable:
            if level is None:
                level = 4  # Default level
            new_level = max(1, min(level, self.read_pwm_max_brightness()))
        else:
            new_level = 0
            
        self.log('INFO', f'Setting PWM backlight to {"ON" if enable else "OFF"}' + 
                (f' (level {new_level})' if enable else ''))
        
        success = self.set_pwm_brightness(new_level)
        
        if success:
            self.log('SUCCESS', f'PWM backlight {"enabled" if enable else "disabled"}')
        else:
            self.log('ERROR', 'Failed to set PWM backlight')
        
        return success
    
    def optimize_power(self):
        """Apply optimal power settings"""
        self.log('INFO', 'Applying optimal power settings...')
        
        # Enable auto power save with 2 minute timeout
        self.enable_powersave(120000)
        
        # Enable hardware dithering
        self.set_dithering(True)
        
        # Enable auto clear
        self.write_param('auto_clear', 'Y')
        
        # Set backlight to medium level
        if self.check_pwm_backlight():
            self.set_backlight(True, 4)
        
        self.log('SUCCESS', 'Optimal power settings applied')

def main():
    parser = argparse.ArgumentParser(description='JDI Display Power Management with PWM')
    parser.add_argument('command', nargs='?', default='status')
    parser.add_argument('--timeout', type=int, default=120000)
    parser.add_argument('--level', type=int, default=4, help='Brightness level (0-6)')
    
    args = parser.parse_args()
    pm = JDIPowerManager()
    
    if args.command == 'status':
        pm.show_status()
    elif args.command == 'enable-powersave':
        pm.enable_powersave(args.timeout)
    elif args.command == 'disable-powersave':
        pm.disable_powersave()
    elif args.command == 'dither-on':
        pm.set_dithering(True)
    elif args.command == 'dither-off':
        pm.set_dithering(False)
    elif args.command == 'backlight-on':
        pm.set_backlight(True, args.level)
    elif args.command == 'backlight-off':
        pm.set_backlight(False)
    elif args.command == 'brightness':
        if pm.check_pwm_backlight():
            pm.set_pwm_brightness(args.level)
    elif args.command == 'optimize':
        pm.optimize_power()
    else:
        print(f"Unknown command: {args.command}")
        print("Available commands: status, enable-powersave, disable-powersave,")
        print("                   dither-on, dither-off, backlight-on, backlight-off,")
        print("                   brightness, optimize")
        sys.exit(1)

if __name__ == '__main__':
    main()
