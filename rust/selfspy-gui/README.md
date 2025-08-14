# Selfspy GUI 🖥️

A comprehensive graphical interface for Selfspy built with Rust and egui, featuring everything you need to monitor, analyze, and visualize your computer activity.

## Features ✨

### 📊 Live Dashboard
- **Real-time metrics** - Keystrokes, clicks, windows, processes
- **Activity indicators** - Live activity level bars and status
- **Current session info** - Active applications and timing
- **Quick actions** - Start/stop monitoring, export data

### 📈 Advanced Statistics
- **Multiple time periods** - Today, week, month, year, all-time
- **Detailed breakdowns** - Productivity analysis, app usage, patterns
- **Trend analysis** - Compare periods and track improvements
- **Focus metrics** - Concentration levels and distraction tracking

### 📉 Interactive Charts
- **Activity over time** - Multi-line charts with keystrokes, clicks, active time
- **Application usage** - Bar charts showing time spent per app
- **Productivity trends** - Track productivity, focus, and efficiency scores
- **Hourly patterns** - Heatmaps and activity distribution

### ⚙️ Comprehensive Settings
- **Privacy controls** - Encryption settings, excluded applications
- **Data management** - Export, import, backup, and cleanup
- **Performance tuning** - Buffer sizes, update frequencies
- **System integration** - Auto-start, tray icon, notifications

### 🎯 System Integration
- **System tray** - Monitor and control from the system tray
- **Notifications** - Activity alerts and status updates
- **Auto-start** - Launch with system startup
- **Minimize to tray** - Keep running in background

## Installation 🚀

### Prerequisites
- Rust 1.75+ (install via [rustup](https://rustup.rs/))
- Platform-specific requirements:
  - **macOS**: Xcode Command Line Tools, Accessibility permissions
  - **Linux**: X11 development libraries, GTK3
  - **Windows**: Visual Studio Build Tools

### Building from Source

```bash
# Clone the repository
git checkout rust-implementation
cd selfspy-rs

# Build the GUI application
cargo build --release --package selfspy-gui

# Run the GUI
./target/release/selfspy-gui
```

### Running

```bash
# Direct execution
./target/release/selfspy-gui

# Or through cargo
cargo run --package selfspy-gui --release
```

## Usage Guide 📖

### Getting Started

1. **Launch the application**
   ```bash
   ./target/release/selfspy-gui
   ```

2. **Configure settings**
   - Go to Settings tab
   - Set up encryption password (recommended)
   - Configure excluded applications
   - Adjust data directory if needed

3. **Start monitoring**
   - Click the "▶ Start" button in the top bar
   - Grant necessary permissions on macOS/Linux
   - Monitor the dashboard for live activity

4. **View your data**
   - **Dashboard**: Real-time overview and current session
   - **Statistics**: Detailed breakdowns and comparisons
   - **Charts**: Visual trends and patterns

### Dashboard Overview

The dashboard provides a real-time view of your activity:

- **Metric Cards**: Live counters for keystrokes, clicks, windows, processes
- **Activity Status**: Current monitoring state and active application
- **Activity Level**: Real-time activity intensity bar
- **Timeline**: 24-hour activity visualization
- **Quick Actions**: Fast access to common operations

### Statistics Analysis

Comprehensive statistics with multiple views:

- **Time Periods**: Filter by today, week, month, year, or all-time
- **Overview**: High-level metrics with trends and averages
- **Detailed View**: Deep dive into productivity patterns
- **App Usage**: Top applications by time and activity
- **Comparisons**: Period-over-period analysis

### Interactive Charts

Rich visualizations for data exploration:

- **Activity Timeline**: Multi-metric line charts over time
- **Application Breakdown**: Bar charts of app usage
- **Productivity Trends**: Track focus and efficiency scores
- **Heatmaps**: Weekly activity patterns by hour

### Settings & Configuration

Complete control over monitoring behavior:

**General Settings:**
- Data directory location
- Flush interval timing
- Idle timeout configuration

**Privacy & Security:**
- Keystroke encryption with password protection
- Excluded applications list
- Privacy mode options

**Data Management:**
- Export data to various formats
- Import existing data
- Backup and restore functionality
- Database maintenance

**Advanced Options:**
- Performance tuning parameters
- System integration settings
- Logging and debug options

## Architecture 🏗️

### Component Structure

```
selfspy-gui/
├── src/
│   ├── main.rs          # Application entry point
│   ├── app.rs           # Main application state and logic
│   ├── dashboard.rs     # Live dashboard implementation
│   ├── statistics.rs    # Statistics analysis and display
│   ├── charts.rs        # Interactive charts with egui_plot
│   ├── settings.rs      # Configuration and preferences
│   └── system_tray.rs   # System tray integration
└── Cargo.toml          # Dependencies and build config
```

### Key Dependencies

- **eframe/egui**: Immediate mode GUI framework
- **egui_plot**: Charts and plotting functionality
- **tray-icon**: System tray integration
- **selfspy-core**: Shared monitoring and database logic
- **tokio**: Async runtime for background operations

### Performance Characteristics

- **Memory Usage**: ~25-40MB (including GUI framework)
- **CPU Usage**: <1% when idle, 2-3% during active monitoring
- **Startup Time**: ~200-500ms (including GUI initialization)
- **Responsiveness**: 60 FPS UI with 1-second data refresh rate

## Platform Support 🖥️

### macOS
- **Native look and feel** with proper macOS integration
- **Accessibility permissions** handling
- **Menu bar integration** with native system tray
- **App bundle support** for distribution

### Linux
- **X11 and Wayland** support through winit
- **GTK3 integration** for native dialogs
- **Desktop file** for application launcher
- **Packaging support** for various distributions

### Windows
- **Native Windows APIs** for system integration
- **Windows 10/11** modern styling
- **MSI installer** support for easy distribution
- **Windows Store** compatibility

## Development 🔧

### Building for Development

```bash
# Debug build with faster compilation
cargo build --package selfspy-gui

# Run with debug logging
RUST_LOG=debug cargo run --package selfspy-gui

# Run tests
cargo test --package selfspy-gui
```

### Adding Features

The modular architecture makes it easy to extend:

1. **New Dashboard Widgets**: Add to `dashboard.rs`
2. **Additional Charts**: Extend `charts.rs` with new plot types
3. **Settings Options**: Add to `settings.rs` with UI and persistence
4. **System Integration**: Enhance `system_tray.rs` with platform features

### Performance Optimization

- **Data Refresh**: Configurable update intervals for different UI components
- **Chart Rendering**: Efficient plotting with egui_plot optimizations
- **Memory Management**: Bounded data structures for long-running sessions
- **Background Processing**: Async operations to maintain UI responsiveness

## Troubleshooting 🔧

### Common Issues

**Permission Errors (macOS)**
```bash
# Check and grant Accessibility permissions
./target/release/selfspy-gui
# Go to System Preferences > Security & Privacy > Privacy > Accessibility
```

**Missing Dependencies (Linux)**
```bash
# Ubuntu/Debian
sudo apt install build-essential libgtk-3-dev libx11-dev

# Fedora/RHEL
sudo dnf install gtk3-devel libX11-devel
```

**Performance Issues**
- Increase flush interval in Settings
- Reduce chart time ranges for large datasets
- Check available disk space for database

### Debug Mode

```bash
# Enable debug logging
RUST_LOG=selfspy_gui=debug cargo run --package selfspy-gui

# Verbose egui debugging
RUST_LOG=egui=debug,selfspy_gui=debug cargo run --package selfspy-gui
```

## Contributing 🤝

We welcome contributions! Areas for improvement:

- **Additional chart types** (pie charts, scatter plots, etc.)
- **Export formats** (PDF reports, CSV exports, etc.)
- **Themes and customization** (dark/light themes, color schemes)
- **Performance optimizations** (data streaming, efficient rendering)
- **Platform-specific features** (native integrations, platform APIs)

## License 📄

GPL-3.0-or-later (same as original Selfspy)

## Acknowledgments 🙏

Built with:
- [egui](https://github.com/emilk/egui) - Immediate mode GUI framework
- [eframe](https://github.com/emilk/egui/tree/master/crates/eframe) - Cross-platform GUI application framework
- [egui_plot](https://github.com/emilk/egui/tree/master/crates/egui_plot) - Plotting library for egui