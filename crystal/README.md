# Crystal Selfspy - Modern Activity Monitoring

A high-performance activity monitoring system written in Crystal, featuring cross-platform support, real-time monitoring, and rich visualizations.

## 🚀 Features

- **Cross-Platform Support**: Works on macOS, Linux, and Windows
- **Real-Time Monitoring**: Tracks keystrokes, mouse activity, and window changes
- **SQLite Database**: Efficient local storage with proper indexing
- **Encryption**: Secure keystroke data encryption
- **Rich Visualizations**: ASCII charts, dashboards, and enhanced statistics
- **Multiple Export Formats**: JSON, CSV, and SQL export capabilities
- **Fiber-Based Concurrency**: Lightweight, efficient monitoring using Crystal fibers
- **Privacy Controls**: Configurable privacy settings and exclusions

## 📦 Installation

### Prerequisites

- Crystal 1.17+ installed
- SQLite3 development libraries

### Building from Source

```bash
# Clone the repository (if not already done)
cd crystal/

# Install dependencies
shards install

# Build all executables
crystal build src/selfspy.cr -o bin/selfspy
crystal build src/selfstats.cr -o bin/selfstats
crystal build src/selfviz.cr -o bin/selfviz

# Or build with optimization
crystal build --release src/selfspy.cr -o bin/selfspy
crystal build --release src/selfstats.cr -o bin/selfstats
crystal build --release src/selfviz.cr -o bin/selfviz
```

## 🎯 Quick Start

### 1. Check System Permissions

```bash
./bin/selfspy check
```

This will verify that your system has the necessary permissions for activity monitoring.

### 2. Start Monitoring

```bash
./bin/selfspy start
```

To start monitoring in the background:

```bash
./bin/selfspy start --daemon
```

### 3. View Statistics

```bash
# Basic statistics
./bin/selfstats

# Enhanced visualizations
./bin/selfviz enhanced

# Live dashboard
./bin/selfviz dashboard
```

## 📊 Usage Examples

### Statistics Commands

```bash
# View last 7 days of activity
./bin/selfstats stats --days 7

# Show detailed statistics with app usage
./bin/selfstats stats --days 30 --detailed --apps

# Export statistics to JSON
./bin/selfstats stats --days 7 --format json --export stats.json

# View top applications
./bin/selfstats apps --days 14 --limit 5

# Live statistics monitoring
./bin/selfstats live
```

### Visualization Commands

```bash
# Enhanced activity analysis
./bin/selfviz enhanced --days 7

# Activity timeline
./bin/selfviz timeline --days 1 --granularity hour

# Activity heatmap
./bin/selfviz heatmap --days 30 --type activity

# Real-time dashboard
./bin/selfviz dashboard
```

### Export Commands

```bash
# Export to JSON
./bin/selfspy export --format json --days 30 --output data.json

# Export to CSV
./bin/selfspy export --format csv --days 7 --output data.csv

# Export to SQL
./bin/selfspy export --format sql --days 14 --output backup.sql
```

## ⚙️ Configuration

Configuration is stored in `~/Library/Application Support/selfspy/config.yaml` (macOS) or `~/.config/selfspy/config.yaml` (Linux).

### Sample Configuration

```yaml
database:
  path: "~/Library/Application Support/selfspy/selfspy.db"
  backup_interval: 168  # hours

monitoring:
  capture_text: true
  capture_mouse: true
  capture_windows: true
  buffer_size: 100

encryption:
  enabled: true
  algorithm: "AES-256-GCM"
  key_derivation: "PBKDF2"

privacy:
  private_mode: false
  excluded_apps: []
  password_protection: true
```

## 🏗️ Architecture

### Core Components

- **`src/selfspy.cr`** - Main application entry point with CLI interface
- **`src/monitor.cr`** - Activity monitoring coordinator using Crystal fibers
- **`src/storage.cr`** - SQLite database operations and data management
- **`src/platform.cr`** - Cross-platform abstraction layer
- **`src/config.cr`** - Configuration management and validation
- **`src/selfstats.cr`** - Statistics application with multiple output formats
- **`src/selfviz.cr`** - Enhanced visualization tools and dashboards

### Database Schema

```sql
-- Sessions table
CREATE TABLE sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  start_time INTEGER NOT NULL,
  end_time INTEGER
);

-- Windows table
CREATE TABLE windows (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  app_name TEXT NOT NULL,
  bundle_id TEXT,
  pid INTEGER NOT NULL,
  first_seen INTEGER NOT NULL,
  last_seen INTEGER NOT NULL
);

-- Keystrokes table
CREATE TABLE keystrokes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  timestamp INTEGER NOT NULL,
  key_data TEXT NOT NULL,
  modifiers TEXT,
  window_id INTEGER,
  encrypted INTEGER DEFAULT 0,
  FOREIGN KEY (window_id) REFERENCES windows (id)
);

-- Mouse events table
CREATE TABLE mouse_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  timestamp INTEGER NOT NULL,
  event_type TEXT NOT NULL,
  x INTEGER NOT NULL,
  y INTEGER NOT NULL,
  button TEXT,
  window_id INTEGER,
  FOREIGN KEY (window_id) REFERENCES windows (id)
);
```

## 🔒 Security & Privacy

### Encryption

- All keystroke data is encrypted by default using AES-256-GCM
- Encryption keys are derived using PBKDF2 with secure salt generation
- Sensitive data is never stored in plain text

### Privacy Controls

- **Private Mode**: Disable all data collection temporarily
- **App Exclusions**: Exclude specific applications from monitoring
- **Password Protection**: Automatic detection and exclusion of password fields
- **Local Storage**: All data remains on your local machine

### Permission Requirements

- **macOS**: Accessibility permissions required for window and input monitoring
- **Linux**: May require adding user to `input` group for keyboard/mouse access
- **Windows**: Generally works without additional permissions

## 🎨 Visualization Features

### Enhanced Statistics
- Colored ASCII charts and progress bars
- Activity overview with visual indicators
- Productivity metrics and scoring
- Application usage analysis with rankings

### Timeline Views
- Hourly, daily, and weekly activity timelines
- Interactive time-based visualizations
- Pattern recognition and trend analysis

### Live Dashboard
- Real-time activity monitoring
- Live statistics updates every 2 seconds
- System performance metrics
- Monitoring status indicators

## 🔧 Development

### Project Structure

```
crystal/
├── src/
│   ├── selfspy.cr      # Main application
│   ├── monitor.cr      # Activity monitoring
│   ├── storage.cr      # Database operations
│   ├── platform.cr     # Platform abstraction
│   ├── config.cr       # Configuration
│   ├── selfstats.cr    # Statistics tool
│   └── selfviz.cr      # Visualization tool
├── bin/                # Built executables
├── shard.yml          # Crystal dependencies
└── README.md          # This file
```

### Dependencies

- `crystal-db` - Database abstraction layer
- `crystal-sqlite3` - SQLite3 driver for Crystal

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📈 Performance

- **Memory Usage**: ~5-10MB RAM during monitoring
- **CPU Usage**: <1% CPU on modern systems
- **Storage**: ~1MB per day of typical usage
- **Startup Time**: <100ms cold start

## 🐛 Troubleshooting

### Common Issues

**Permission Denied (macOS)**
```bash
# Grant accessibility permissions in System Preferences
./bin/selfspy check
```

**Database Locked**
```bash
# Stop any running instances
./bin/selfspy stop
```

**Build Errors**
```bash
# Update Crystal and dependencies
shards update
crystal build src/selfspy.cr
```

### Logs

Logs are written to standard output with different levels:
- `INFO`: General information
- `WARN`: Warnings and non-critical issues
- `ERROR`: Critical errors requiring attention
- `DEBUG`: Detailed debugging information

## 📄 License

This implementation follows the same license as the main Selfspy project.

## 🤝 Acknowledgments

- Built with the Crystal programming language
- Inspired by the original Python Selfspy implementation
- Uses SQLite for reliable local data storage