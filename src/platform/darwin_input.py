"""
Enhanced macOS input tracking implementation with proper event handling
"""
import asyncio
import threading
from datetime import datetime
import structlog
from typing import Callable, Optional

import Foundation
import AppKit
import Quartz
from pynput.keyboard import Key, KeyCode

from .input_tracker import InputTracker
from .permissions import verify_permissions

logger = structlog.get_logger()


class MacOSInputTracker(InputTracker):
    """Track keyboard and mouse input using native macOS APIs"""
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.event_tap = None
        self.run_loop = None
        self.run_loop_thread = None
        
    def start(self):
        """Start input tracking using CGEventTap"""
        super().start()
        
        # Verify permissions before creating event tap
        has_permission, msg = verify_permissions()
        if not has_permission:
            logger.error("Permission denied", reason=msg)
            return False
            
        try:
            # Create event tap for keyboard and mouse events
            mask = (
                Quartz.CGEventMaskBit(Quartz.kCGEventKeyDown) |
                Quartz.CGEventMaskBit(Quartz.kCGEventLeftMouseDown) |
                Quartz.CGEventMaskBit(Quartz.kCGEventRightMouseDown) |
                Quartz.CGEventMaskBit(Quartz.kCGEventScrollWheel)
            )
            
            # Create event tap in the current thread
            self.event_tap = Quartz.CGEventTapCreate(
                Quartz.kCGSessionEventTap,
                Quartz.kCGHeadInsertEventTap,
                Quartz.kCGEventTapOptionDefault,
                mask,
                self._event_callback,
                None
            )
            
            if not self.event_tap:
                logger.error("Failed to create event tap")
                return False
                
            # Enable the event tap
            Quartz.CGEventTapEnable(self.event_tap, True)
            
            # Create run loop source
            run_loop_source = Quartz.CGEventTapCreateRunLoopSource(
                None, self.event_tap, 0
            )
            
            # Start run loop in a separate thread
            def run_loop_thread():
                try:
                    self.run_loop = Quartz.CFRunLoopGetCurrent()
                    Quartz.CFRunLoopAddSource(
                        self.run_loop,
                        run_loop_source,
                        Quartz.kCFRunLoopCommonModes
                    )
                    logger.info("Starting CFRunLoop")
                    Quartz.CFRunLoopRun()
                except Exception as e:
                    logger.error("Run loop error", error=str(e))
            
            self.run_loop_thread = threading.Thread(target=run_loop_thread)
            self.run_loop_thread.daemon = True
            self.run_loop_thread.start()
            
            logger.info("MacOS input tracking started")
            return True
            
        except Exception as e:
            logger.error("Failed to initialize input tracking", error=str(e))
            return False
            
    def stop(self):
        """Stop input tracking"""
        super().stop()
        if self.run_loop:
            Quartz.CFRunLoopStop(self.run_loop)
        if self.event_tap:
            Quartz.CGEventTapEnable(self.event_tap, False)
        if self.run_loop_thread and self.run_loop_thread.is_alive():
            self.run_loop_thread.join(timeout=1.0)
        
    def _event_callback(self, proxy, event_type, event, refcon):
        """Handle input events from CGEventTap"""
        try:
            if event_type == Quartz.kCGEventKeyDown and self.on_key_press:
                keycode = Quartz.CGEventGetIntegerValueField(
                    event, Quartz.kCGKeyboardEventKeycode
                )
                # Convert keycode to pynput Key
                key = KeyCode.from_vk(keycode)
                self.on_key_press(key)
                
            elif event_type == Quartz.kCGEventLeftMouseDown and self.on_mouse_click:
                point = Quartz.CGEventGetLocation(event)
                self.on_mouse_click(int(point.x), int(point.y), 'left', True)
                
            elif event_type == Quartz.kCGEventRightMouseDown and self.on_mouse_click:
                point = Quartz.CGEventGetLocation(event)
                self.on_mouse_click(int(point.x), int(point.y), 'right', True)
                
            elif event_type == Quartz.kCGEventScrollWheel and self.on_scroll:
                dy = Quartz.CGEventGetIntegerValueField(
                    event, Quartz.kCGScrollWheelEventDeltaAxis1
                )
                dx = Quartz.CGEventGetIntegerValueField(
                    event, Quartz.kCGScrollWheelEventDeltaAxis2
                )
                point = Quartz.CGEventGetLocation(event)
                self.on_scroll(int(point.x), int(point.y), dx, dy)
                
        except Exception as e:
            logger.error("Event callback error", error=str(e))
            
        # Always return event to allow it to propagate
        return event
        
    def _keycode_to_key(self, keycode: int):
        """Convert macOS keycode to pynput key"""
        try:
            # Get character from keycode
            keyboard = AppKit.NSEvent.keyboardLayout()
            if not keyboard:
                return None
                
            # Get characters for keycode
            chars = keyboard.keyStringForKeyCode_modifierFlags_(keycode, 0)
            if chars and len(chars) > 0:
                return Key.from_char(chars[0])
            return None
            
        except Exception:
            return None
            