#!/usr/bin/python3
"""
Enhanced Backlight control script for JDI DRM Enhanced Driver
Autor: N@Xs - Enhanced Edition 2025 - PWM FIXED VERSION

Features:
- Polling-based button control
- Auto-dimming for battery saving
- Multiple button support
- PWM brightness control (0-6 levels)
- Status monitoring
- FIXED: Uses real PWM backlight interface
"""

import RPi.GPIO as GPIO
import signal
import sys
import os
import time
import threading
import subprocess

# Configuration
BUTTON_PIN = 17
POWER_BUTTON_PIN = 27
DEBOUNCE_TIME = 0.3
POLL_INTERVAL = 0.1
AUTO_DIM_TIMEOUT = 300

# PWM Backlight configuration
BACKLIGHT_PATH = '/sys/class/backlight/jdi-backlight/brightness'
BACKLIGHT_MAX_PATH = '/sys/class/backlight/jdi-backlight/max_brightness'
BACKLIGHT_POWER_PATH = '/sys/class/backlight/jdi-backlight/bl_power'

class EnhancedBacklightController:
    def __init__(self):
        self.backlit_on = False
        self.brightness_level = 4  # Default level
        self.max_brightness = 6
        self.last_time = time.time()
        self.last_button_state = True
        self.last_power_button_state = True
        self.running = True
        self.last_activity = time.time()
        
        # Check if backlight control is available
        if not os.path.exists(BACKLIGHT_PATH):
            print(f"ERROR: PWM Backlight control not found at {BACKLIGHT_PATH}")
            print("Make sure jdi-backlight is configured")
            sys.exit(1)
            
        print("Enhanced Backlight Controller - N@Xs Edition PWM FIXED")
        print(f"PWM Backlight control: {BACKLIGHT_PATH}")
        
        # Initialize GPIO
        self.setup_gpio()
        
        # Get initial backlight state and max brightness
        self.get_current_state()
        self.get_max_brightness()
        
        # Start auto-dimming thread
        self.dimming_thread = threading.Thread(target=self.auto_dimming_worker, daemon=True)
        self.dimming_thread.start()
    
    def setup_gpio(self):
        """Setup GPIO pins for buttons"""
        try:
            GPIO.setwarnings(False)
            GPIO.setmode(GPIO.BCM)
            GPIO.setup(BUTTON_PIN, GPIO.IN, pull_up_down=GPIO.PUD_UP)
            
            # Setup optional power button
            if POWER_BUTTON_PIN != BUTTON_PIN:
                try:
                    GPIO.setup(POWER_BUTTON_PIN, GPIO.IN, pull_up_down=GPIO.PUD_UP)
                    print(f"Power button configured on GPIO {POWER_BUTTON_PIN}")
                except:
                    print(f"Power button GPIO {POWER_BUTTON_PIN} not available")
            
            print(f"Main button GPIO {BUTTON_PIN} configured successfully")
        except Exception as e:
            print(f"GPIO setup failed: {e}")
            sys.exit(1)
    
    def get_max_brightness(self):
        """Get maximum brightness level"""
        try:
            with open(BACKLIGHT_MAX_PATH, 'r') as f:
                self.max_brightness = int(f.read().strip())
            print(f"Maximum brightness level: {self.max_brightness}")
        except Exception as e:
            print(f"Could not read max brightness: {e}")
            self.max_brightness = 6  # Default fallback
    
    def get_current_state(self):
        """Get current backlight state from PWM system"""
        try:
            with open(BACKLIGHT_PATH, 'r') as f:
                self.brightness_level = int(f.read().strip())
                self.backlit_on = self.brightness_level > 0
            print(f"Current brightness level: {self.brightness_level} ({'ON' if self.backlit_on else 'OFF'})")
        except Exception as e:
            print(f"Could not read current brightness: {e}")
            self.brightness_level = 4
            self.backlit_on = True
    
    def set_backlight(self, state):
        """Set backlight state using PWM brightness control"""
        try:
            if state:
                # Turn on: use default level or last level if it was > 0
                new_level = self.brightness_level if self.brightness_level > 0 else 4
            else:
                # Turn off: set to 0
                new_level = 0
            
            # Write to PWM brightness control
            with open(BACKLIGHT_PATH, 'w') as f:
                f.write(str(new_level))
            
            # Update internal state
            self.brightness_level = new_level
            self.backlit_on = new_level > 0
            self.last_activity = time.time()
            
            print(f"PWM Backlight: {'ON' if state else 'OFF'} (level {new_level})")
                
        except PermissionError:
            print("Permission denied - run with appropriate permissions")
        except Exception as e:
            print(f"Failed to set backlight: {e}")
    
    def cycle_brightness(self):
        """Cycle through brightness levels: OFF -> 1 -> 3 -> 6 -> OFF"""
        try:
            if self.brightness_level == 0:
                new_level = 1  # Turn on to minimum
            elif self.brightness_level == 1:
                new_level = 3  # Medium
            elif self.brightness_level == 3:
                new_level = 6  # Maximum
            else:
                new_level = 0  # Turn off
            
            with open(BACKLIGHT_PATH, 'w') as f:
                f.write(str(new_level))
            
            self.brightness_level = new_level
            self.backlit_on = new_level > 0
            self.last_activity = time.time()
            
            status = f"Level {new_level}" if new_level > 0 else "OFF"
            print(f"Brightness cycled to: {status}")
            
        except Exception as e:
            print(f"Failed to cycle brightness: {e}")
    
    def auto_dimming_worker(self):
        """Worker thread for auto-dimming"""
        while self.running:
            try:
                current_time = time.time()
                time_since_activity = current_time - self.last_activity
                
                # Auto-dim if backlight is on and no activity
                if (self.backlit_on and time_since_activity > AUTO_DIM_TIMEOUT):
                    print(f"Auto-dimming after {AUTO_DIM_TIMEOUT}s of inactivity")
                    self.set_backlight(False)
                
                time.sleep(5)  # Check every 5 seconds
            except Exception as e:
                print(f"Auto-dimming error: {e}")
                time.sleep(1)
    
    def check_buttons(self):
        """Check all button states and handle presses"""
        try:
            current_time = time.time()
            
            # Main backlight button
            current_button_state = GPIO.input(BUTTON_PIN)
            if self.last_button_state and not current_button_state:
                if current_time - self.last_time >= DEBOUNCE_TIME:
                    self.last_time = current_time
                    self.last_activity = current_time
                    
                    # Cycle through brightness levels
                    self.cycle_brightness()
            
            self.last_button_state = current_button_state
            
            # Optional power button (simple on/off)
            if POWER_BUTTON_PIN != BUTTON_PIN:
                try:
                    current_power_state = GPIO.input(POWER_BUTTON_PIN)
                    if self.last_power_button_state and not current_power_state:
                        if current_time - self.last_time >= DEBOUNCE_TIME:
                            self.last_time = current_time
                            self.last_activity = current_time
                            # Simple toggle for power button
                            self.set_backlight(not self.backlit_on)
                            
                    self.last_power_button_state = current_power_state
                except:
                    pass
            
        except Exception as e:
            print(f"Error checking buttons: {e}")
    
    def show_status(self):
        """Show current status"""
        print("=" * 50)
        print("Enhanced PWM Backlight Controller Status")
        print("=" * 50)
        print(f"Current brightness: {self.brightness_level}/{self.max_brightness}")
        print(f"Backlight: {'ON' if self.backlit_on else 'OFF'}")
        print(f"Auto-dim timeout: {AUTO_DIM_TIMEOUT}s")
        print(f"Last activity: {time.time() - self.last_activity:.1f}s ago")
        
        try:
            with open(BACKLIGHT_POWER_PATH, 'r') as f:
                power_state = f.read().strip()
            print(f"Power state: {'Normal' if power_state == '0' else 'Suspended'}")
        except:
            print("Power state: Unknown")
        
        print(f"Button behavior: Cycle levels (0→1→3→6→0)")
        print("=" * 50)
    
    def signal_handler(self, sig, frame):
        """Clean shutdown handler"""
        print("\nShutting down Enhanced Backlight Controller...")
        self.running = False
        self.show_status()
        GPIO.cleanup()
        sys.exit(0)
    
    def run(self):
        """Main run loop with polling"""
        signal.signal(signal.SIGINT, self.signal_handler)
        signal.signal(signal.SIGTERM, self.signal_handler)
        
        print("Enhanced PWM Backlight Controller started")
        print(f"Main button: GPIO {BUTTON_PIN} (cycles: 0→1→3→6→0)")
        if POWER_BUTTON_PIN != BUTTON_PIN:
            print(f"Power button: GPIO {POWER_BUTTON_PIN} (toggle on/off)")
        print(f"Auto-dim: {AUTO_DIM_TIMEOUT}s")
        print("Press Ctrl+C to exit")
        
        try:
            while self.running:
                self.check_buttons()
                time.sleep(POLL_INTERVAL)
                
        except KeyboardInterrupt:
            print("Keyboard interrupt received")
        finally:
            GPIO.cleanup()

if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == 'status':
        try:
            controller = EnhancedBacklightController()
            controller.show_status()
            GPIO.cleanup()
            sys.exit(0)
        except Exception as e:
            print(f"Status error: {e}")
            sys.exit(1)
    
    try:
        controller = EnhancedBacklightController()
        controller.run()
    except Exception as e:
        print(f"Fatal error: {e}")
        GPIO.cleanup()
        sys.exit(1)
