#!/usr/bin/python3
"""
GPIO17 Button Handler for JDI Backlight Control - FIXED VERSION
Author: N@Xs - Enhanced Edition 2025

This script listens to the kernel input device created by the device tree
and handles button presses to control backlight brightness.
FIXED: Uses custom key code (240) to avoid power button interference.
"""

import os
import sys
import time
import select
import struct
import signal
import subprocess

# Configuration
BACKLIGHT_PATH = "/sys/class/backlight/jdi-backlight/brightness"
BACKLIGHT_MAX_PATH = "/sys/class/backlight/jdi-backlight/max_brightness"
BRIGHTNESS_LEVELS = [0, 1, 2, 3]  # OFF, Low, Medium, High
INPUT_DEVICE_PATH = None
BRIGHTNESS_KEY_CODE = 240  # Custom key code - NOT power button

# Global state
current_brightness_index = 2  # Start at medium (level 3)
running = True

def find_button_device():
    """Find the input device for our GPIO button"""
    devices_path = "/proc/bus/input/devices"
    if not os.path.exists(devices_path):
        return None
    
    try:
        with open(devices_path, 'r') as f:
            content = f.read()
            
        # Look for our brightness button
        lines = content.split('\n')
        for i, line in enumerate(lines):
            if "Brightness Button" in line or "gpio-keys" in line:
                # Find the corresponding event device
                for j in range(i, min(i + 10, len(lines))):
                    if lines[j].startswith('H: Handlers='):
                        handlers = lines[j].split('=')[1].strip()
                        for handler in handlers.split():
                            if handler.startswith('event'):
                                return f"/dev/input/{handler}"
    except:
        pass
    
    return None

def check_backlight():
    """Check if backlight interface is available"""
    return os.path.exists(BACKLIGHT_PATH) and os.path.exists(BACKLIGHT_MAX_PATH)

def get_current_brightness():
    """Get current brightness level"""
    if not check_backlight():
        return current_brightness_index
        
    try:
        with open(BACKLIGHT_PATH, 'r') as f:
            brightness = int(f.read().strip())
            # Map to our brightness levels
            for i, level in enumerate(BRIGHTNESS_LEVELS):
                if brightness <= level:
                    return i
            return len(BRIGHTNESS_LEVELS) - 1
    except:
        return current_brightness_index

def set_brightness(level_index):
    """Set brightness level"""
    global current_brightness_index
    
    if level_index < 0 or level_index >= len(BRIGHTNESS_LEVELS):
        return False
        
    brightness_value = BRIGHTNESS_LEVELS[level_index]
    current_brightness_index = level_index
    
    if check_backlight():
        try:
            with open(BACKLIGHT_PATH, 'w') as f:
                f.write(str(brightness_value))
            status = "ON" if brightness_value > 0 else "OFF"
            print(f"GPIO17: Brightness → {brightness_value}/3 ({status})")
            return True
        except Exception as e:
            print(f"Error setting brightness: {e}")
            return False
    else:
        status = "ON" if brightness_value > 0 else "OFF"
        print(f"Simulation: Brightness → {brightness_value}/3 ({status})")
        return True

def handle_button_press():
    """Handle button press - cycle through brightness levels"""
    global current_brightness_index
    
    # Cycle through: 0 -> 1 -> 3 -> 6 -> 0
    current_brightness_index = (current_brightness_index + 1) % len(BRIGHTNESS_LEVELS)
    set_brightness(current_brightness_index)

def signal_handler(sig, frame):
    """Handle shutdown signals"""
    global running
    print("\nShutting down GPIO17 button handler...")
    running = False
    sys.exit(0)

def main():
    """Main function"""
    global running, INPUT_DEVICE_PATH
    
    print("GPIO17 Button Handler - FIXED VERSION (No Power Interference)")
    print("Looking for GPIO button input device...")
    
    # Setup signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Find the input device
    INPUT_DEVICE_PATH = find_button_device()
    
    if not INPUT_DEVICE_PATH:
        print("Warning: GPIO button input device not found")
        print("Trying direct GPIO access as fallback...")
        
        # Fallback to gpiozero if available
        try:
            from gpiozero import Button
            button = Button(17, pull_up=True)
            button.when_pressed = handle_button_press
            
            print("✅ GPIO17 configured with gpiozero (fallback mode)")
            print(f"Current brightness: {get_current_brightness()}")
            print("Press GPIO17 button to cycle brightness: 0→1→2→3→0")
            print("Press Ctrl+C to exit")
            
            while running:
                time.sleep(1)
                
        except ImportError:
            print("❌ Error: Neither input device nor gpiozero available")
            return 1
        except Exception as e:
            print(f"❌ Error setting up GPIO: {e}")
            return 1
    else:
        print(f"✅ Found GPIO button device: {INPUT_DEVICE_PATH}")
        
        try:
            # Open the input device
            device = open(INPUT_DEVICE_PATH, 'rb')
            print("✅ GPIO17 button handler started (input device mode)")
            print(f"Current brightness: {get_current_brightness()}")
            print("Press GPIO17 button to cycle brightness: 0→1→2→3→0")
            print(f"Listening for key code: {BRIGHTNESS_KEY_CODE} (NOT power button)")
            print("Press Ctrl+C to exit")
            
            # Input event structure: time_sec, time_usec, type, code, value
            event_format = 'llHHI'
            event_size = struct.calcsize(event_format)
            
            while running:
                # Use select to check for input with timeout
                ready, _, _ = select.select([device], [], [], 1.0)
                
                if ready:
                    data = device.read(event_size)
                    if len(data) == event_size:
                        _, _, ev_type, ev_code, ev_value = struct.unpack(event_format, data)
                        
                        # Key press event: type=1 (EV_KEY), value=1 (press)
                        # Only respond to our brightness button (key code 240)
                        if ev_type == 1 and ev_value == 1 and ev_code == BRIGHTNESS_KEY_CODE:
                            print(f"✅ Brightness button pressed (code: {ev_code})")
                            handle_button_press()
                        elif ev_type == 1 and ev_value == 1:
                            print(f"⚠️  Ignoring key press (code: {ev_code}) - not brightness button")
            
            device.close()
            
        except PermissionError:
            print(f"❌ Permission denied accessing {INPUT_DEVICE_PATH}")
            print("Try running with sudo or add user to input group")
            return 1
        except Exception as e:
            print(f"❌ Error handling input device: {e}")
            return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
