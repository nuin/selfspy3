package platform

import (
	"os"
	"os/user"
	"runtime"

	"selfspy/internal/types"
)

// Interface defines the platform-specific operations
type Interface interface {
	CheckPermissions() (*types.Permissions, error)
	RequestPermissions() error
	GetCurrentWindow() (*types.WindowInfo, error)
	StartKeyboardMonitoring(chan<- *types.KeyEvent) error
	StartMouseMonitoring(chan<- *types.MouseEvent) error
	StopMonitoring() error
}

// GetCurrent returns the platform-specific implementation
func GetCurrent() Interface {
	switch runtime.GOOS {
	case "darwin":
		return &macOSPlatform{}
	case "linux":
		return &linuxPlatform{}
	case "windows":
		return &windowsPlatform{}
	default:
		return &fallbackPlatform{}
	}
}

// CheckPermissions checks system permissions across platforms
func CheckPermissions() (*types.Permissions, error) {
	return GetCurrent().CheckPermissions()
}

// RequestPermissions requests necessary system permissions
func RequestPermissions() error {
	return GetCurrent().RequestPermissions()
}

// GetSystemInfo returns system information
func GetSystemInfo() *types.SystemInfo {
	hostname, _ := os.Hostname()
	currentUser, _ := user.Current()
	
	return &types.SystemInfo{
		Platform:     runtime.GOOS,
		Architecture: runtime.GOARCH,
		GoVersion:    runtime.Version(),
		Hostname:     hostname,
		Username:     currentUser.Username,
	}
}

// fallbackPlatform provides basic implementations for unsupported platforms
type fallbackPlatform struct{}

func (p *fallbackPlatform) CheckPermissions() (*types.Permissions, error) {
	return &types.Permissions{
		Accessibility:   true,
		InputMonitoring: true,
		ScreenRecording: false,
	}, nil
}

func (p *fallbackPlatform) RequestPermissions() error {
	return nil
}

func (p *fallbackPlatform) GetCurrentWindow() (*types.WindowInfo, error) {
	return &types.WindowInfo{
		Title:       "Unknown Window",
		Application: "Unknown Application",
		BundleID:    "",
		ProcessID:   0,
		X:           0,
		Y:           0,
		Width:       1920,
		Height:      1080,
	}, nil
}

func (p *fallbackPlatform) StartKeyboardMonitoring(events chan<- *types.KeyEvent) error {
	// Placeholder implementation
	return nil
}

func (p *fallbackPlatform) StartMouseMonitoring(events chan<- *types.MouseEvent) error {
	// Placeholder implementation
	return nil
}

func (p *fallbackPlatform) StopMonitoring() error {
	return nil
}