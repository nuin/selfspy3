//go:build darwin

package platform

import (
	"fmt"
	"os/exec"
	"strings"
	"time"

	"selfspy/internal/types"
)

// macOSPlatform implements platform-specific operations for macOS
type macOSPlatform struct {
	keyboardChan chan<- *types.KeyEvent
	mouseChan    chan<- *types.MouseEvent
	stopChan     chan struct{}
}

func (p *macOSPlatform) CheckPermissions() (*types.Permissions, error) {
	permissions := &types.Permissions{}

	// Check accessibility permissions using AppleScript
	accessibilityCmd := exec.Command("osascript", "-e", `
		tell application "System Events"
			try
				set frontApp to name of first process whose frontmost is true
				return "true"
			on error
				return "false"
			end try
		end tell
	`)
	
	if output, err := accessibilityCmd.Output(); err == nil {
		permissions.Accessibility = strings.TrimSpace(string(output)) == "true"
	}

	// Check input monitoring permissions (simplified check)
	// In practice, this would require more sophisticated detection
	permissions.InputMonitoring = permissions.Accessibility

	// Check screen recording permissions
	screenCmd := exec.Command("osascript", "-e", `
		tell application "System Events"
			try
				tell process "Finder" to get windows
				return "true"
			on error
				return "false"
			end try
		end tell
	`)
	
	if output, err := screenCmd.Output(); err == nil {
		permissions.ScreenRecording = strings.TrimSpace(string(output)) == "true"
	}

	return permissions, nil
}

func (p *macOSPlatform) RequestPermissions() error {
	// Open System Preferences to Privacy & Security
	cmd := exec.Command("open", "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to open accessibility preferences: %w", err)
	}

	fmt.Println("Please grant accessibility permissions in System Preferences")
	fmt.Println("Security & Privacy > Privacy > Accessibility")
	fmt.Println("Add and enable your terminal application")
	
	return nil
}

func (p *macOSPlatform) GetCurrentWindow() (*types.WindowInfo, error) {
	// Use AppleScript to get current window information
	cmd := exec.Command("osascript", "-e", `
		tell application "System Events"
			set frontApp to first process whose frontmost is true
			set frontAppName to name of frontApp
			try
				set frontWindow to first window of frontApp
				set windowTitle to name of frontWindow
				set windowPosition to position of frontWindow
				set windowSize to size of frontWindow
				return frontAppName & "|" & windowTitle & "|" & item 1 of windowPosition & "|" & item 2 of windowPosition & "|" & item 1 of windowSize & "|" & item 2 of windowSize
			on error
				return frontAppName & "|" & frontAppName & "|0|0|0|0"
			end try
		end tell
	`)

	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to get window info: %w", err)
	}

	parts := strings.Split(strings.TrimSpace(string(output)), "|")
	if len(parts) < 6 {
		return nil, fmt.Errorf("invalid window info format")
	}

	// Parse coordinates and dimensions (simplified)
	return &types.WindowInfo{
		Title:       parts[1],
		Application: parts[0],
		BundleID:    "", // Would require additional API calls
		ProcessID:   0,  // Would require additional API calls
		X:           0,  // Parse from parts[2]
		Y:           0,  // Parse from parts[3]
		Width:       0,  // Parse from parts[4]
		Height:      0,  // Parse from parts[5]
		Timestamp:   time.Now(),
	}, nil
}

func (p *macOSPlatform) StartKeyboardMonitoring(events chan<- *types.KeyEvent) error {
	p.keyboardChan = events
	p.stopChan = make(chan struct{})

	// Start keyboard monitoring in a goroutine
	go p.keyboardMonitorLoop()
	
	return nil
}

func (p *macOSPlatform) StartMouseMonitoring(events chan<- *types.MouseEvent) error {
	p.mouseChan = events
	if p.stopChan == nil {
		p.stopChan = make(chan struct{})
	}

	// Start mouse monitoring in a goroutine
	go p.mouseMonitorLoop()
	
	return nil
}

func (p *macOSPlatform) StopMonitoring() error {
	if p.stopChan != nil {
		close(p.stopChan)
	}
	return nil
}

func (p *macOSPlatform) keyboardMonitorLoop() {
	ticker := time.NewTicker(100 * time.Millisecond)
	defer ticker.Stop()

	for {
		select {
		case <-p.stopChan:
			return
		case <-ticker.C:
			// Placeholder: In practice, this would use CGEventTap or similar
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

func (p *macOSPlatform) mouseMonitorLoop() {
	ticker := time.NewTicker(50 * time.Millisecond)
	defer ticker.Stop()

	for {
		select {
		case <-p.stopChan:
			return
		case <-ticker.C:
			// Placeholder: In practice, this would use CGEventTap or similar
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