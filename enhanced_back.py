#!/usr/bin/python3
"""
Enhanced Backlight control script for JDI DRM Enhanced Driver
Author: N@Xs - Enhanced Edition 2025 - FIXED VERSION

Features:
- GPIO17 button control with gpiozero (more stable)
- PWM brightness control (0-6 levels)
- Auto-dimming for battery saving
- Status monitoring
- Error handling and fallback modes
"""

import signal
import sys
import os
import time
import threading
import subprocess

# Global GPIO availability flag
GPIO_AVAILABLE = False

# Try to import gpiozero, fallback to simulation mode if not available
try:
    from gpiozero import Button
    GPIO_AVAILABLE = True
    print("GPIO support available via gpiozero")
except ImportError:
    print("Warning: gpiozero not available, installing...")
    try:
        subprocess.run(['sudo', 'apt', 'install', '-y', 'python3-gpiozero'], 
                      check=True, capture_output=True)
        from gpiozero import Button
        GPIO_AVAILABLE = True
        print("GPIO support enabled")
    except:
        GPIO_AVAILABLE = False
        print("GPIO not available, running in simulation mode")
        
        # Create dummy Button class for simulation
        class Button:
            def __init__(self, pin, pull_up=True):
                self.pin = pin
                self._when_pressed = None
                
            @property
            def when_pressed(self):
                return self._when_pressed
                
            @when_pressed.setter
            def when_pressed(self, func):
                self._when_pressed = func
                
            def close(self):
                pass

# Configuration
BUTTON_GPIO = 21
POWER_BUTTON_GPIO = 27
BRIGHTNESS_LEVELS = [0, 1, 2, 3]  # 0=OFF, 1=Low, 3=Medium, 6=High
current_brightness_index = 2  # Start at medium brightness (level 3)

# Paths for backlight control
BACKLIGHT_PATH = "/sys/class/backlight/jdi-backlight/brightness"
BACKLIGHT_MAX_PATH = "/sys/class/backlight/jdi-backlight/max_brightness"

# Global state
running = True
last_button_press = 0
button_debounce = 0.3
auto_dim_timer = None
auto_dim_timeout = 300  # 5 minutes
main_button = None
power_button = None

def check_backlight():
    """Check if PWM backlight is available"""
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
            print(f"Brightness set to: {brightness_value}/3 ({status})")
            return True
        except Exception as e:
            print(f"Error setting brightness: {e}")
            return False
    else:
        # Simulation mode
        status = "ON" if brightness_value > 0 else "OFF"
        print(f"Brightness cycled to: Level {brightness_value} ({status})")
        return True

def button_pressed():
    """Handle main button press"""
    global current_brightness_index, last_button_press
    
    current_time = time.time()
    if current_time - last_button_press < button_debounce:
        return
        
    last_button_press = current_time
    
    # Cycle through brightness levels: 0 -> 1 -> 3 -> 6 -> 0
    current_brightness_index = (current_brightness_index + 1) % len(BRIGHTNESS_LEVELS)
    set_brightness(current_brightness_index)
    
    # Reset auto-dim timer
    reset_auto_dim_timer()

def power_button_pressed():
    """Handle power button press (toggle on/off)"""
    global current_brightness_index
    
    if current_brightness_index == 0:
        # Turn on to medium brightness
        current_brightness_index = 2  # Level 3
    else:
        # Turn off
        current_brightness_index = 0  # Level 0
        
    set_brightness(current_brightness_index)
    print("Power button: toggled display")

def auto_dim():
    """Auto-dim after timeout"""
    global current_brightness_index
    if current_brightness_index > 1:
        current_brightness_index = 1  # Dim to low
        set_brightness(current_brightness_index)
        print("Auto-dimmed to low brightness after timeout")

def reset_auto_dim_timer():
    """Reset the auto-dim timer"""
    global auto_dim_timer
    
    if auto_dim_timer:
        auto_dim_timer.cancel()
        
    auto_dim_timer = threading.Timer(auto_dim_timeout, auto_dim)
    auto_dim_timer.start()

def signal_handler(sig, frame):
    """Handle Ctrl+C gracefully"""
    global running
    print("\nShutting down Enhanced Backlight Controller...")
    running = False
    cleanup()
    
    # Show final status
    print("=" * 50)
    print("Enhanced PWM Backlight Controller Status")
    print("=" * 50)
    current_level = get_current_brightness()
    brightness_value = BRIGHTNESS_LEVELS[current_level] if current_level < len(BRIGHTNESS_LEVELS) else 0
    max_brightness = max(BRIGHTNESS_LEVELS)
    print(f"Current brightness: {brightness_value}/{max_brightness}")
    print(f"Backlight: {'ON' if brightness_value > 0 else 'OFF'}")
    print(f"Auto-dim timeout: {auto_dim_timeout}s")
    if last_button_press > 0:
        print(f"Last activity: {time.time() - last_button_press:.1f}s ago")
    print("Power state: Normal")
    print("Button behavior: Cycle levels (0→1→3→3→0)")
    print("=" * 50)
    
    sys.exit(0)

def cleanup():
    """Cleanup resources"""
    global auto_dim_timer, main_button, power_button
    
    if auto_dim_timer:
        auto_dim_timer.cancel()
        
    if GPIO_AVAILABLE and main_button:
        main_button.close()
    if GPIO_AVAILABLE and power_button:
        power_button.close()

def main():
    """Main function"""
    global running, main_button, power_button
    
    print("Enhanced Backlight Controller - N@Xs Edition PWM FIXED")
    print(f"PWM Backlight control: {BACKLIGHT_PATH}")
    
    # Setup signal handler
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Initialize buttons if GPIO is available
    if GPIO_AVAILABLE:
        try:
            print(f"Power button configured on GPIO {POWER_BUTTON_GPIO}")
            power_button = Button(POWER_BUTTON_GPIO, pull_up=True)
            power_button.when_pressed = power_button_pressed
            
            print(f"Main button GPIO {BUTTON_GPIO} configured successfully")
            main_button = Button(BUTTON_GPIO, pull_up=True)
            main_button.when_pressed = button_pressed
            
        except Exception as e:
            print(f"Error setting up GPIO: {e}")
            print("Continuing in simulation mode...")
    else:
        print("GPIO not available - simulation mode")
    
    # Show initial status
    current_level = get_current_brightness()
    brightness_value = BRIGHTNESS_LEVELS[current_level] if current_level < len(BRIGHTNESS_LEVELS) else 0
    max_brightness = max(BRIGHTNESS_LEVELS)
    print(f"Current brightness level: {brightness_value} ({'ON' if brightness_value > 0 else 'OFF'})")
    print(f"Maximum brightness level: {max_brightness}")
    
    print("Enhanced PWM Backlight Controller started")
    print(f"Main button: GPIO {BUTTON_GPIO} (cycles: 0→1→3→3→0)")
    print(f"Power button: GPIO {POWER_BUTTON_GPIO} (toggle on/off)")
    print(f"Auto-dim: {auto_dim_timeout}s")
    print("Press Ctrl+C to exit")
    
    # Start auto-dim timer
    reset_auto_dim_timer()
    
    # Main loop
    try:
        while running:
            time.sleep(1)
            
            # In simulation mode, allow keyboard input for testing
            if not GPIO_AVAILABLE:
                time.sleep(10)  # Less frequent checks in simulation mode
                
    except KeyboardInterrupt:
        signal_handler(signal.SIGINT, None)

if __name__ == "__main__":
    main()
