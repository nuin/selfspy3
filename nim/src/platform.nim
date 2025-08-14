## Platform-specific implementations for activity monitoring
## Provides cross-platform abstractions for system APIs

import std/[times, json, asyncdispatch]
import chronicles

type
  WindowInfo* = object
    title*: string
    application*: string
    bundleId*: string  # macOS/iOS
    processId*: int
    x*, y*, width*, height*: int
    screen*: int
    
  KeyEvent* = object
    key*: string
    timestamp*: DateTime
    application*: string
    
  MouseEvent* = object
    x*, y*: int
    button*: int  # 1=left, 2=right, 3=middle
    eventType*: string  # click, move, scroll
    timestamp*: DateTime
    
  PermissionStatus* = object
    accessibility*: bool
    screenRecording*: bool
    inputMonitoring*: bool
    hasAllPermissions*: bool

# Platform-specific includes
when defined(macosx):
  {.passL: "-framework ApplicationServices".}
  {.passL: "-framework Carbon".}
  {.passL: "-framework CoreGraphics".}
  {.passL: "-framework Foundation".}
  
  include platform/macos

elif defined(linux):
  {.passL: "-lX11".}
  {.passL: "-lXtst".}
  {.passL: "-lXext".}
  
  include platform/linux

elif defined(windows):
  {.passL: "-luser32".}
  {.passL: "-lkernel32".}
  {.passL: "-lshell32".}
  
  include platform/windows

else:
  include platform/fallback

proc getCurrentWindow*(): Future[WindowInfo] {.async.} =
  """Get information about the currently active window."""
  when defined(macosx):
    result = await getMacOSActiveWindow()
  elif defined(linux):
    result = await getLinuxActiveWindow()
  elif defined(windows):
    result = await getWindowsActiveWindow()
  else:
    result = WindowInfo(
      title: "Unknown",
      application: "Unknown",
      processId: 0
    )

proc startKeyboardMonitoring*(callback: proc(event: KeyEvent): Future[void]) {.async.} =
  """Start monitoring keyboard input."""
  info "Starting keyboard monitoring"
  when defined(macosx):
    await startMacOSKeyboardMonitoring(callback)
  elif defined(linux):
    await startLinuxKeyboardMonitoring(callback)
  elif defined(windows):
    await startWindowsKeyboardMonitoring(callback)
  else:
    warn "Keyboard monitoring not implemented for this platform"

proc startMouseMonitoring*(callback: proc(event: MouseEvent): Future[void]) {.async.} =
  """Start monitoring mouse input."""
  info "Starting mouse monitoring"
  when defined(macosx):
    await startMacOSMouseMonitoring(callback)
  elif defined(linux):
    await startLinuxMouseMonitoring(callback)
  elif defined(windows):
    await startWindowsMouseMonitoring(callback)
  else:
    warn "Mouse monitoring not implemented for this platform"

proc checkPermissions*(): PermissionStatus =
  """Check if required permissions are granted."""
  when defined(macosx):
    result = checkMacOSPermissions()
  elif defined(linux):
    result = checkLinuxPermissions()
  elif defined(windows):
    result = checkWindowsPermissions()
  else:
    result = PermissionStatus(
      accessibility: true,
      screenRecording: true,
      inputMonitoring: true,
      hasAllPermissions: true
    )

proc requestPermissions*(): Future[bool] {.async.} =
  """Request necessary permissions from the system."""
  info "Requesting system permissions"
  when defined(macosx):
    result = await requestMacOSPermissions()
  elif defined(linux):
    result = await requestLinuxPermissions()
  elif defined(windows):
    result = await requestWindowsPermissions()
  else:
    result = true

proc getSystemInfo*(): JsonNode =
  """Get system information for debugging."""
  result = %*{
    "platform": system.hostOS,
    "architecture": system.hostCPU,
    "timestamp": now().format("yyyy-MM-dd'T'HH:mm:ss'Z'")
  }
  
  when defined(macosx):
    result["macos"] = getMacOSSystemInfo()
  elif defined(linux):
    result["linux"] = getLinuxSystemInfo()
  elif defined(windows):
    result["windows"] = getWindowsSystemInfo()