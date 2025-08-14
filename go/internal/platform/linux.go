//go:build linux

package platform

import (
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"

	"selfspy/internal/types"
)

// linuxPlatform implements platform-specific operations for Linux
type linuxPlatform struct {
	keyboardChan chan<- *types.KeyEvent
	mouseChan    chan<- *types.MouseEvent
	stopChan     chan struct{}
}

func (p *linuxPlatform) CheckPermissions() (*types.Permissions, error) {
	permissions := &types.Permissions{}

	// Check if we can access X11 display
	if os.Getenv("DISPLAY") != "" {
		permissions.Accessibility = true
		permissions.InputMonitoring = true
	} else {
		// Check for Wayland
		if os.Getenv("WAYLAND_DISPLAY") != "" {
			// Wayland permissions are more restrictive
			permissions.Accessibility = false
			permissions.InputMonitoring = false
		}
	}

	// Screen recording is generally available on Linux
	permissions.ScreenRecording = true

	return permissions, nil
}

func (p *linuxPlatform) RequestPermissions() error {
	if os.Getenv("DISPLAY") == "" && os.Getenv("WAYLAND_DISPLAY") == "" {
		return fmt.Errorf("no display server detected")
	}

	if os.Getenv("WAYLAND_DISPLAY") != "" {
		fmt.Println("Wayland detected. Some monitoring features may be limited.")
		fmt.Println("Consider using X11 for full functionality.")
	}

	return nil
}

func (p *linuxPlatform) GetCurrentWindow() (*types.WindowInfo, error) {
	// Try xdotool first (X11)
	if window, err := p.getWindowInfoXdotool(); err == nil {
		return window, nil
	}

	// Try alternative methods
	if window, err := p.getWindowInfoWmctrl(); err == nil {
		return window, nil
	}

	// Fallback
	return &types.WindowInfo{
		Title:       "Unknown Window",
		Application: "Unknown Application",
		ProcessID:   0,
		X:           0,
		Y:           0,
		Width:       1920,
		Height:      1080,
		Timestamp:   time.Now(),
	}, nil
}

func (p *linuxPlatform) getWindowInfoXdotool() (*types.WindowInfo, error) {
	// Get active window ID
	cmd := exec.Command("xdotool", "getactivewindow")
	output, err := cmd.Output()
	if err != nil {
		return nil, err
	}

	windowID := strings.TrimSpace(string(output))

	// Get window title
	titleCmd := exec.Command("xdotool", "getwindowname", windowID)
	titleOutput, err := titleCmd.Output()
	if err != nil {
		return nil, err
	}
	title := strings.TrimSpace(string(titleOutput))

	// Get window geometry
	geomCmd := exec.Command("xdotool", "getwindowgeometry", windowID)
	geomOutput, err := geomCmd.Output()
	if err != nil {
		return nil, err
	}

	// Parse geometry (format: "Position: X,Y (screen: 0)" "Geometry: WxH")
	lines := strings.Split(string(geomOutput), "\n")
	var x, y, width, height int

	for _, line := range lines {
		if strings.Contains(line, "Position:") {
			parts := strings.Fields(line)
			if len(parts) >= 2 {
				coords := strings.Split(parts[1], ",")
				if len(coords) == 2 {
					x, _ = strconv.Atoi(coords[0])
					y, _ = strconv.Atoi(coords[1])
				}
			}
		} else if strings.Contains(line, "Geometry:") {
			parts := strings.Fields(line)
			if len(parts) >= 2 {
				dims := strings.Split(parts[1], "x")
				if len(dims) == 2 {
					width, _ = strconv.Atoi(dims[0])
					height, _ = strconv.Atoi(dims[1])
				}
			}
		}
	}

	// Get application name (process name)
	pidCmd := exec.Command("xdotool", "getwindowpid", windowID)
	pidOutput, err := pidCmd.Output()
	var processID int
	var application string

	if err == nil {
		processID, _ = strconv.Atoi(strings.TrimSpace(string(pidOutput)))
		
		// Get process name
		if processID > 0 {
			commPath := fmt.Sprintf("/proc/%d/comm", processID)
			if commData, err := os.ReadFile(commPath); err == nil {
				application = strings.TrimSpace(string(commData))
			}
		}
	}

	if application == "" {
		application = "Unknown Application"
	}

	return &types.WindowInfo{
		Title:       title,
		Application: application,
		ProcessID:   processID,
		X:           x,
		Y:           y,
		Width:       width,
		Height:      height,
		Timestamp:   time.Now(),
	}, nil
}

func (p *linuxPlatform) getWindowInfoWmctrl() (*types.WindowInfo, error) {
	cmd := exec.Command("wmctrl", "-a", "-v")
	output, err := cmd.Output()
	if err != nil {
		return nil, err
	}

	lines := strings.Split(string(output), "\n")
	for _, line := range lines {
		if strings.Contains(line, " * ") { // Active window marker
			parts := strings.Fields(line)
			if len(parts) >= 8 {
				title := strings.Join(parts[8:], " ")
				return &types.WindowInfo{
					Title:       title,
					Application: "Unknown Application",
					ProcessID:   0,
					X:           0,
					Y:           0,
					Width:       0,
					Height:      0,
					Timestamp:   time.Now(),
				}, nil
			}
		}
	}

	return nil, fmt.Errorf("no active window found")
}

func (p *linuxPlatform) StartKeyboardMonitoring(events chan<- *types.KeyEvent) error {
	p.keyboardChan = events
	p.stopChan = make(chan struct{})

	// Start keyboard monitoring in a goroutine
	go p.keyboardMonitorLoop()
	
	return nil
}

func (p *linuxPlatform) StartMouseMonitoring(events chan<- *types.MouseEvent) error {
	p.mouseChan = events
	if p.stopChan == nil {
		p.stopChan = make(chan struct{})
	}

	// Start mouse monitoring in a goroutine
	go p.mouseMonitorLoop()
	
	return nil
}

func (p *linuxPlatform) StopMonitoring() error {
	if p.stopChan != nil {
		close(p.stopChan)
	}
	return nil
}

func (p *linuxPlatform) keyboardMonitorLoop() {
	ticker := time.NewTicker(100 * time.Millisecond)
	defer ticker.Stop()

	for {
		select {
		case <-p.stopChan:
			return
		case <-ticker.C:
			// Placeholder: In practice, this would use xinput or libinput
			// to capture actual keyboard events
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

func (p *linuxPlatform) mouseMonitorLoop() {
	ticker := time.NewTicker(50 * time.Millisecond)
	defer ticker.Stop()

	for {
		select {
		case <-p.stopChan:
			return
		case <-ticker.C:
			// Placeholder: In practice, this would use xinput or libinput
			// to capture actual mouse events
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