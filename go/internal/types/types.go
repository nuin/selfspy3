package types

import (
	"time"
)

// WindowInfo represents information about a window
type WindowInfo struct {
	Title       string    `json:"title" db:"title"`
	Application string    `json:"application" db:"application"`
	BundleID    string    `json:"bundle_id" db:"bundle_id"`
	ProcessID   int       `json:"process_id" db:"process_id"`
	X           int       `json:"x" db:"x"`
	Y           int       `json:"y" db:"y"`
	Width       int       `json:"width" db:"width"`
	Height      int       `json:"height" db:"height"`
	Timestamp   time.Time `json:"timestamp" db:"timestamp"`
}

// KeyEvent represents a keyboard event
type KeyEvent struct {
	Key         string    `json:"key" db:"key"`
	Application string    `json:"application" db:"application"`
	ProcessID   int       `json:"process_id" db:"process_id"`
	Count       int       `json:"count" db:"count"`
	Encrypted   bool      `json:"encrypted" db:"encrypted"`
	Timestamp   time.Time `json:"timestamp" db:"timestamp"`
}

// MouseEvent represents a mouse event
type MouseEvent struct {
	X          int       `json:"x" db:"x"`
	Y          int       `json:"y" db:"y"`
	Button     int       `json:"button" db:"button"`
	EventType  string    `json:"event_type" db:"event_type"`
	ProcessID  int       `json:"process_id" db:"process_id"`
	Timestamp  time.Time `json:"timestamp" db:"timestamp"`
}

// Process represents a running process/application
type Process struct {
	ID        int       `json:"id" db:"id"`
	Name      string    `json:"name" db:"name"`
	BundleID  string    `json:"bundle_id" db:"bundle_id"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
}

// ActivityStats represents aggregated activity statistics
type ActivityStats struct {
	Keystrokes        uint64     `json:"keystrokes"`
	Clicks            uint64     `json:"clicks"`
	WindowChanges     uint64     `json:"window_changes"`
	ActiveTimeSeconds uint64     `json:"active_time_seconds"`
	TopApps           []AppUsage `json:"top_apps"`
	DateRange         struct {
		Start time.Time `json:"start"`
		End   time.Time `json:"end"`
	} `json:"date_range"`
}

// AppUsage represents application usage statistics
type AppUsage struct {
	Name       string  `json:"name"`
	Percentage float64 `json:"percentage"`
	Duration   uint64  `json:"duration_seconds"`
	Events     uint64  `json:"events"`
}

// SystemInfo contains system information
type SystemInfo struct {
	Platform     string `json:"platform"`
	Architecture string `json:"architecture"`
	GoVersion    string `json:"go_version"`
	Hostname     string `json:"hostname"`
	Username     string `json:"username"`
}

// Permissions represents system permissions status
type Permissions struct {
	Accessibility    bool `json:"accessibility"`
	InputMonitoring  bool `json:"input_monitoring"`
	ScreenRecording  bool `json:"screen_recording"`
}

// HasAllPermissions returns true if all required permissions are granted
func (p *Permissions) HasAllPermissions() bool {
	return p.Accessibility && p.InputMonitoring
}

// ExportFormat represents different export formats
type ExportFormat string

const (
	ExportFormatJSON ExportFormat = "json"
	ExportFormatCSV  ExportFormat = "csv"
	ExportFormatSQL  ExportFormat = "sql"
)

// MonitorState represents the current state of monitoring
type MonitorState int

const (
	MonitorStateStopped MonitorState = iota
	MonitorStateStarting
	MonitorStateRunning
	MonitorStateStopping
)

func (s MonitorState) String() string {
	switch s {
	case MonitorStateStopped:
		return "stopped"
	case MonitorStateStarting:
		return "starting"
	case MonitorStateRunning:
		return "running"
	case MonitorStateStopping:
		return "stopping"
	default:
		return "unknown"
	}
}