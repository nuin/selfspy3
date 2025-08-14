# Selfspy Phoenix Implementation 🔍

A modern web-based activity monitoring application built with Phoenix LiveView for real-time monitoring and analytics.

## 🚀 Features

### Core Functionality
- **Real-time Activity Monitoring**: Live tracking of keystrokes, mouse clicks, and window changes
- **Interactive Dashboard**: Modern Phoenix LiveView interface with real-time updates
- **Activity Analytics**: Comprehensive statistics and visualizations with Chart.js
- **Secure Data Storage**: Encrypted keystroke data with PostgreSQL backend
- **Terminal Tracking**: Command history analysis with git integration and project detection

### Technology Stack
- **Backend**: Elixir/Phoenix with GenServer-based monitoring architecture
- **Frontend**: Phoenix LiveView with TailwindCSS and Chart.js
- **Database**: PostgreSQL with Ecto schemas
- **Real-time**: Phoenix PubSub for live updates
- **Security**: Built-in encryption for sensitive keystroke data

## 📋 Prerequisites

- Elixir 1.15+ and Phoenix 1.8+
- PostgreSQL 13+
- Node.js 18+ (for asset compilation)

## 🛠️ Installation

### Quick Setup

```bash
# Clone and navigate to the Phoenix project
cd selfspy-phoenix/selfspy_web

# Install dependencies
mix deps.get
npm install --prefix assets

# Setup database
mix ecto.create
mix ecto.migrate

# Start the Phoenix server
mix phx.server
```

### Development Mode

```bash
# Start PostgreSQL (macOS with Homebrew)
brew services start postgresql

# Run in development with live reload
mix phx.server

# Access the dashboard at http://localhost:4000
```

## 🏗️ Architecture

### Core Components

**GenServer Architecture**
- `ActivityMonitor`: Main orchestrator for all monitoring activities
- `KeyboardMonitor`: Platform-specific keyboard event capture
- `MouseMonitor`: Mouse click and movement tracking
- `WindowMonitor`: Active window detection and metadata
- `TerminalMonitor`: Shell command history analysis

**Phoenix LiveView Dashboard**
- Real-time activity statistics and charts
- Live monitoring controls (start/stop)
- Interactive data visualizations
- Responsive design with dark mode support

**Data Layer**
- Ecto schemas for all activity data types
- Encrypted keystroke storage for privacy
- Optimized database indexes for performance
- Comprehensive migration system

### Database Schema

```elixir
# Core activity tracking tables
- processes: Application/process metadata
- windows: Window properties and geometry
- keystrokes: Encrypted keystroke data with counts
- clicks: Mouse events with coordinates and deltas
- terminal_sessions: Shell session metadata
- terminal_commands: Individual commands with context
```

### Real-time Features

**Phoenix PubSub Integration**
- Live status updates across all connected clients
- Real-time activity statistics broadcast
- Immediate UI updates on monitoring state changes

**Chart.js Integration**
- Interactive activity timeline charts
- Live data updates without page refresh
- Responsive design for all screen sizes

## 🎨 User Interface

### Dashboard Features
- **Activity Cards**: Real-time keystroke, click, and window statistics
- **Live Charts**: Activity timeline with multiple data series
- **Status Indicators**: Visual monitoring state with animations
- **Control Buttons**: Start/stop monitoring with immediate feedback

### Modern Design
- TailwindCSS for responsive styling
- Dark mode support with system preference detection
- Smooth animations and transitions
- Mobile-friendly responsive layout

## 🔒 Security & Privacy

### Data Protection
- **Keystroke Encryption**: All text data encrypted using industry-standard cryptography
- **Local Storage**: No cloud transmission, all data stored locally
- **Configurable Exclusions**: Ability to exclude sensitive applications
- **Privacy Controls**: Granular settings for what data to collect

### Platform Integration
- **macOS Support**: Native accessibility API integration
- **Cross-platform**: Designed for extensibility to Linux and Windows
- **Permission Management**: Proper handling of system permissions

## 🚀 Demo Mode

The application includes a comprehensive demo mode for testing without real system monitoring:

```elixir
# Enable demo mode in config
config :selfspy_web, demo_mode: true
```

Demo features:
- Simulated keyboard and mouse events
- Fake window changes with realistic data
- Sample terminal commands with git context
- Live chart updates with generated data

## 📊 Monitoring Capabilities

### Keystroke Tracking
- Encrypted text capture with key counts
- Special key detection (Enter, Tab, etc.)
- Modifier key combinations (Cmd, Ctrl, Alt)
- Application context for all keystrokes

### Mouse Activity
- Click events with precise coordinates
- Button type detection (left, right, middle, scroll)
- Movement delta tracking
- Pressure sensitivity support

### Window Management
- Active window detection and metadata
- Window geometry and screen information
- Process association and bundle ID tracking
- Real-time window change notifications

### Terminal Analytics
- Command history parsing for multiple shells (bash, zsh, fish)
- Git branch and project type detection
- Working directory context
- Command categorization and exit code tracking

## 🔧 Configuration

### Environment Variables
```bash
# Database configuration
DATABASE_URL=postgresql://user:pass@localhost/selfspy_web

# Demo mode (optional)
DEMO_MODE=true

# Monitoring settings
FLUSH_INTERVAL_SECONDS=5
IDLE_TIMEOUT_SECONDS=300
```

### Runtime Configuration
```elixir
# In config/runtime.exs
config :selfspy_web,
  demo_mode: System.get_env("DEMO_MODE", "false") == "true",
  flush_interval: String.to_integer(System.get_env("FLUSH_INTERVAL_SECONDS", "5")),
  idle_timeout: String.to_integer(System.get_env("IDLE_TIMEOUT_SECONDS", "300"))
```

## 🧪 Development

### Running Tests
```bash
# Run all tests
mix test

# Run tests with coverage
mix test --cover

# Run specific test file
mix test test/selfspy_web/monitor/activity_monitor_test.exs
```

### Code Quality
```bash
# Format code
mix format

# Run static analysis
mix credo

# Type checking
mix dialyzer
```

### Live Development
```bash
# Start with live reload
mix phx.server

# Interactive Elixir session
iex -S mix phx.server
```

## 🚢 Deployment

### Production Setup
```bash
# Set environment to production
export MIX_ENV=prod

# Compile assets
mix assets.deploy

# Create release
mix release

# Run the release
_build/prod/rel/selfspy_web/bin/selfspy_web start
```

### Docker Deployment
```dockerfile
# Dockerfile example
FROM elixir:1.15-alpine
WORKDIR /app
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
COPY . .
RUN mix compile
CMD ["mix", "phx.server"]
```

## 📈 Performance

### Optimizations
- **Buffered Writes**: Activity data batched for efficient database writes
- **Indexed Queries**: Optimized database indexes for fast analytics
- **Memory Management**: Efficient GenServer state management
- **Real-time Updates**: Phoenix PubSub for minimal latency

### Monitoring
- Built-in telemetry for all monitoring operations
- Phoenix LiveDashboard integration
- Memory and process monitoring
- Performance metrics collection

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is part of the Selfspy ecosystem and follows the same open-source licensing.

## 🔗 Related Projects

- **Selfspy Python**: Original Python implementation with extensive platform support
- **Selfspy Rust**: High-performance Rust implementation with GUI
- **Selfspy Desktop**: Cross-platform desktop application

## 🎯 Roadmap

- [ ] Settings and configuration UI completion
- [ ] Platform-specific NIFs for native monitoring
- [ ] Advanced analytics and reporting features
- [ ] Export functionality for data portability
- [ ] Mobile responsive enhancements
- [ ] Plugin system for extensibility

---

**Built with ❤️ using Phoenix LiveView and Elixir**