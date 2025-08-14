//go:build windows

package platform

import (
	"fmt"
	"os/exec"
	"strconv"
	"strings"
	"syscall"
	"time"
	"unsafe"

	"selfspy/internal/types"
)

// Windows API constants
const (
	GW_HWNDNEXT = 2
	GWL_STYLE   = -16
	WS_VISIBLE  = 0x10000000
)

var (
	user32           = syscall.NewLazyDLL("user32.dll")
	kernel32         = syscall.NewLazyDLL("kernel32.dll")
	getForegroundWindow = user32.NewProc("GetForegroundWindow")
	getWindowTextW   = user32.NewProc("GetWindowTextW")
	getWindowTextLengthW = user32.NewProc("GetWindowTextLengthW")
	getWindowThreadProcessId = user32.NewProc("GetWindowThreadProcessId")
	getWindowRect    = user32.NewProc("GetWindowRect")
)

// RECT represents a Windows rectangle
type RECT struct {
	Left, Top, Right, Bottom int32
}

// windowsPlatform implements platform-specific operations for Windows
type windowsPlatform struct {
	keyboardChan chan<- *types.KeyEvent
	mouseChan    chan<- *types.MouseEvent
	stopChan     chan struct{}
}

func (p *windowsPlatform) CheckPermissions() (*types.Permissions, error) {
	permissions := &types.Permissions{
		Accessibility:   true, // Generally available on Windows
		InputMonitoring: true, // Generally available on Windows
		ScreenRecording: true, // Generally available on Windows
	}

	// Check if we can get the foreground window
	hwnd, _, _ := getForegroundWindow.Call()
	if hwnd == 0 {
		permissions.Accessibility = false
	}

	return permissions, nil
}

func (p *windowsPlatform) RequestPermissions() error {
	// On Windows, most permissions are available by default
	// However, some antivirus software might block input monitoring
	fmt.Println("Windows permissions are generally available by default.")
	fmt.Println("If monitoring doesn't work, check your antivirus settings.")
	return nil
}

func (p *windowsPlatform) GetCurrentWindow() (*types.WindowInfo, error) {
	// Get foreground window handle
	hwnd, _, _ := getForegroundWindow.Call()
	if hwnd == 0 {
		return nil, fmt.Errorf("no foreground window")
	}

	// Get window title
	titleLength, _, _ := getWindowTextLengthW.Call(hwnd)
	if titleLength == 0 {
		return nil, fmt.Errorf("unable to get window title length")
	}

	titleBuffer := make([]uint16, titleLength+1)
	getWindowTextW.Call(hwnd, uintptr(unsafe.Pointer(&titleBuffer[0])), uintptr(titleLength+1))
	title := syscall.UTF16ToString(titleBuffer)

	// Get process ID
	var processID uint32
	getWindowThreadProcessId.Call(hwnd, uintptr(unsafe.Pointer(&processID)))

	// Get window rectangle
	var rect RECT
	getWindowRect.Call(hwnd, uintptr(unsafe.Pointer(&rect)))

	// Get process name
	application := p.getProcessName(int(processID))

	return &types.WindowInfo{
		Title:       title,
		Application: application,
		ProcessID:   int(processID),
		X:           int(rect.Left),
		Y:           int(rect.Top),
		Width:       int(rect.Right - rect.Left),
		Height:      int(rect.Bottom - rect.Top),
		Timestamp:   time.Now(),
	}, nil
}

func (p *windowsPlatform) getProcessName(processID int) string {
	// Use tasklist command to get process name
	cmd := exec.Command("tasklist", "/FI", fmt.Sprintf("PID eq %d", processID), "/FO", "CSV", "/NH")
	output, err := cmd.Output()
	if err != nil {
		return "Unknown Application"
	}

	lines := strings.Split(string(output), "\n")
	if len(lines) > 0 {
		fields := strings.Split(lines[0], ",")
		if len(fields) > 0 {
			// Remove quotes from process name
			processName := strings.Trim(fields[0], "\"")
			return processName
		}
	}

	return "Unknown Application"
}

func (p *windowsPlatform) StartKeyboardMonitoring(events chan<- *types.KeyEvent) error {
	p.keyboardChan = events
	p.stopChan = make(chan struct{})

	// Start keyboard monitoring in a goroutine
	go p.keyboardMonitorLoop()
	
	return nil
}

func (p *windowsPlatform) StartMouseMonitoring(events chan<- *types.MouseEvent) error {
	p.mouseChan = events
	if p.stopChan == nil {
		p.stopChan = make(chan struct{})
	}

	// Start mouse monitoring in a goroutine
	go p.mouseMonitorLoop()
	
	return nil
}

func (p *windowsPlatform) StopMonitoring() error {
	if p.stopChan != nil {
		close(p.stopChan)
	}
	return nil
}

func (p *windowsPlatform) keyboardMonitorLoop() {
	ticker := time.NewTicker(100 * time.Millisecond)
	defer ticker.Stop()

	for {
		select {
		case <-p.stopChan:
			return
		case <-ticker.C:
			// Placeholder: In practice, this would use SetWindowsHookEx
			// with WH_KEYBOARD_LL to capture actual keyboard events
			if p.keyboardChan != nil {
				select {
				case p.keyboardChan <- &types.KeyEvent{
					Key:         "sample",
					Application: "sample",
					ProcessID:   0,
					Count:       1,
					Encrypted:   true,
					Timestamp:   time.Now(),
				}:
				default:
					// Channel full, skip
				}
			}
		}
	}
}

func (p *windowsPlatform) mouseMonitorLoop() {
	ticker := time.NewTicker(50 * time.Millisecond)
	defer ticker.Stop()

	for {
		select {
		case <-p.stopChan:
			return
		case <-ticker.C:
			// Placeholder: In practice, this would use SetWindowsHookEx
			// with WH_MOUSE_LL to capture actual mouse events
			if p.mouseChan != nil {
				select {
				case p.mouseChan <- &types.MouseEvent{
					X:         100,
					Y:         100,
					Button:    1,
					EventType: "click",
					ProcessID: 0,
					Timestamp: time.Now(),
				}:
				default:
					// Channel full, skip
				}
			}
		}
	}
}