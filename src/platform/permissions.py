"""
Platform-specific permission checking utilities
"""
import platform
from typing import Tuple

import structlog
from rich.console import Console

logger = structlog.get_logger()
console = Console()

def verify_permissions() -> Tuple[bool, str]:
    """Verify accessibility permissions with retry"""
    if platform.system() != 'Darwin':
        return True, "Non-macOS platform"
        
    try:
        # Import required frameworks
        import objc
        from ApplicationServices import AXIsProcessTrusted, AXAPIEnabled
        
        # Check both AXIsProcessTrusted and AXAPIEnabled
        trusted = AXIsProcessTrusted()
        enabled = AXAPIEnabled()
        
        if trusted and enabled:
            return True, "Granted"
        elif not trusted:
            return False, "Process not trusted"
        elif not enabled:
            return False, "Accessibility API not enabled"
        else:
            return False, "Unknown permission state"
            
    except Exception as e:
        logger.error("Permission check error", error=str(e))
        return False, f"Error checking permissions: {str(e)}" 