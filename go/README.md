# Selfspy - Go Implementation

Modern activity monitoring in Go - practical and widely used for system tools with excellent concurrency support, strong standard library, and cross-platform compatibility.

## Features

- **Excellent Concurrency**: Built-in goroutines and channels for efficient monitoring
- **Strong Standard Library**: Comprehensive APIs for system interaction
- **Cross-platform Compatibility**: Native support for macOS, Linux, and Windows
- **Fast Compilation**: Quick build times for rapid development
- **Robust Error Handling**: Go's explicit error handling patterns
- **Static Typing**: Compile-time type safety
- **Memory Efficient**: Garbage collected with excellent performance

## Installation

### Prerequisites

- Go 1.21 or later
- Platform-specific requirements:
  - **macOS**: Accessibility permissions
  - **Linux**: X11 or Wayland display server
  - **Windows**: Generally works out of the box

### Building

```bash
# Clone and build
cd go/
go mod download
go build -o selfspy ./cmd/selfspy

# Or install globally
go install ./cmd/selfspy
```

### Development

```bash
# Run tests
go test ./...

# Run with race detection
go run -race ./cmd/selfspy start

# Build for all platforms
GOOS=darwin GOARCH=amd64 go build -o selfspy-darwin ./cmd/selfspy
GOOS=linux GOARCH=amd64 go build -o selfspy-linux ./cmd/selfspy
GOOS=windows GOARCH=amd64 go build -o selfspy-windows.exe ./cmd/selfspy
```

## Usage

### Start Monitoring

```bash
# Basic monitoring
./selfspy start

# Privacy mode (no text capture)
./selfspy start --no-text

# Debug mode
./selfspy start --debug
```

### View Statistics

```bash
# Show last 7 days
./selfspy stats

# Show last 30 days
./selfspy stats --days 30

# JSON output
./selfspy stats --json
```

### Check Permissions

```bash
./selfspy check
```

### Export Data

```bash
# Export as JSON
./selfspy export --format json --output data.json

# Export as CSV
./selfspy export --format csv --days 14
```

## Architecture

### Project Structure

```
go/
├── cmd/selfspy/           # Main application entry point
├── internal/
│   ├── config/           # Configuration management
│   ├── monitor/          # Core monitoring orchestration
│   ├── platform/         # Platform-specific implementations
│   ├── stats/            # Statistics and analytics
│   ├── storage/          # Database operations
│   └── types/            # Shared type definitions
├── go.mod                # Go module definition
└── README.md             # This file
```

### Key Components

- **Command Line Interface**: Built with Cobra for robust CLI handling
- **Configuration**: Viper-based configuration with environment variable support
- **Platform Abstraction**: Interface-based design for cross-platform support
- **Concurrency**: Goroutines and channels for efficient event processing
- **Storage**: SQLite with proper connection pooling
- **Error Handling**: Comprehensive error handling with context

## Configuration

Configuration can be set via:

1. Configuration file (`~/.local/share/selfspy/config.yaml`)
2. Environment variables (prefix: `SELFSPY_`)
3. Command line flags

Example configuration:

```yaml
capture_text: true
capture_mouse: true
capture_windows: true
update_interval_ms: 100
encryption_enabled: true
debug: false
privacy_mode: false
exclude_applications:
  - "Password Manager"
  - "Secure App"
max_database_size_mb: 500
```

## Platform Support

### macOS

- Uses AppleScript for window detection
- Requires Accessibility permissions
- Optional Screen Recording permissions for enhanced features
- Native Cocoa API integration (placeholder implementations)

### Linux

- Supports both X11 and Wayland
- Uses `xdotool` and `wmctrl` for window management
- Input monitoring via xinput/libinput
- Graceful degradation on Wayland

### Windows

- Uses Win32 API for window detection
- Low-level keyboard/mouse hooks
- Process information via Windows APIs
- Generally works without additional permissions

## Security

- All sensitive data encrypted using industry-standard encryption
- Local storage only - no network transmission
- Configurable application exclusions
- Privacy mode for restricted environments
- Optional text capture disabling

## Performance

- Goroutine-based concurrent processing
- Efficient memory usage with garbage collection
- Configurable update intervals
- Database connection pooling
- Minimal CPU overhead during monitoring

## Development

### Adding New Features

1. Define types in `internal/types/`
2. Implement platform-specific code in `internal/platform/`
3. Add business logic to appropriate internal packages
4. Update CLI commands in `cmd/selfspy/`
5. Add tests and documentation

### Platform-Specific Development

Each platform implementation follows the `platform.Interface`:

```go
type Interface interface {
    CheckPermissions() (*types.Permissions, error)
    RequestPermissions() error
    GetCurrentWindow() (*types.WindowInfo, error)
    StartKeyboardMonitoring(chan<- *types.KeyEvent) error
    StartMouseMonitoring(chan<- *types.MouseEvent) error
    StopMonitoring() error
}
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see the parent repository for full license text.