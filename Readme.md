# Selfspy - Comprehensive Activity Monitoring Suite

> **Modern, cross-platform computer activity monitoring with multiple implementation options**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python Support](https://img.shields.io/badge/Python-3.10+-blue.svg)](https://python.org)
[![Rust Support](https://img.shields.io/badge/Rust-1.70+-orange.svg)](https://rust-lang.org)
[![Elixir Support](https://img.shields.io/badge/Elixir-1.15+-purple.svg)](https://elixir-lang.org)

Selfspy is a comprehensive activity monitoring suite that tracks keyboard input, mouse activity, window changes, and terminal commands across multiple platforms. Choose from Python, Rust, or Phoenix implementations based on your needs.

## 🚀 Quick Start

### Choose Your Implementation

| Implementation | Best For | Key Features |
|----------------|----------|-------------|
| **[Python](python/)** | General use, scripting, research | Original implementation, mature ecosystem |
| **[Rust](rust/)** | Performance, system integration | Native GUI, low resource usage |
| **[Elixir/Phoenix](elixir/)** | Web dashboard, real-time analytics | LiveView interface, multi-user |
| **[Objective-C/macOS](objective-c/)** | macOS desktop integration | Native widgets, system notifications |

### One-Line Install

```bash
# Python (recommended for most users)
curl -sSL https://install.selfspy.dev/python | bash

# Or clone and choose your implementation
git clone https://github.com/selfspy/selfspy3.git
cd selfspy3

# Quick Python setup
cd python && python3 install.py
```

### Basic Usage

```bash
# Start monitoring (from Python directory)
cd python && selfspy start

# View enhanced statistics
selfviz enhanced

# Terminal analytics
selfterminal commands --days 7

# Check permissions (macOS)
selfspy check-permissions
```

## 📁 Project Structure

```
selfspy/
├── python/                       # 🐍 Python Implementation
│   ├── src/selfspy/              # Main Python package
│   ├── tests/                    # Python tests
│   ├── desktop-app/              # macOS desktop widgets
│   └── README.md                 # Python-specific guide
│
├── rust/                         # 🦀 Rust Implementation
│   ├── selfspy-core/             # Core library
│   ├── selfspy-gui/              # GUI application
│   ├── selfspy-cli/              # Command line tools
│   └── README.md                 # Rust-specific guide
│
├── elixir/                       # 🔥 Elixir/Phoenix Implementation
│   ├── lib/                      # Elixir source code
│   ├── assets/                   # Frontend assets
│   ├── priv/                     # Migrations and static files
│   └── README.md                 # Elixir-specific guide
│
├── objective-c/                  # 🍎 Objective-C/macOS Implementation
│   ├── SelfspyWidgets.xcodeproj/ # Xcode project
│   ├── SelfspyWidgets/           # Source code
│   ├── Scripts/                  # Build scripts
│   └── README.md                 # Objective-C guide
│
├── docs/                         # 📚 Documentation
│   ├── installation/             # Installation guides
│   ├── user-guides/              # User documentation
│   └── development/              # Developer guides
│
├── shared/                       # 🔧 Shared Resources
│   ├── scripts/                  # Development scripts
│   ├── schemas/                  # Database schemas
│   └── configs/                  # Configuration templates
│
└── tools/                        # 🛠️ Development Tools
    ├── docker/                   # Container configurations
    └── ci/                       # CI/CD configurations
```

## 🎯 Features

### Core Monitoring
- **Keystroke Tracking** - Encrypted text capture with activity analysis
- **Mouse Activity** - Click events, movement patterns, and usage statistics
- **Window Management** - Active application tracking and window metadata
- **Terminal Analytics** - Command history with git integration and project detection

### Security & Privacy
- **Encryption by Default** - All sensitive data encrypted at rest
- **Local Storage Only** - No cloud transmission, complete data ownership
- **Configurable Exclusions** - Exclude sensitive applications and windows
- **Permission Management** - Granular control over what gets monitored

### Multiple Interfaces
- **Command Line** - Full-featured CLI for all operations
- **Web Dashboard** - Real-time Phoenix LiveView interface
- **Native GUI** - Cross-platform Rust application with charts
- **Desktop Widgets** - macOS notification center integration

## 🚀 Development

### Quick Setup

```bash
# Setup development environment for all implementations
./shared/scripts/setup-dev-env-new.sh

# Use the development helper
./dev python uv run selfspy start       # Python
./dev rust cargo run --bin selfspy-gui  # Rust GUI  
./dev elixir mix phx.server             # Phoenix web
./dev objective-c make all              # macOS widgets
./dev test                              # All tests
./dev build                             # Build everything
```

### Development Helper

The `./dev` script provides easy access to all implementations:

```bash
./dev [language] [command]

# Examples:
./dev python uv run selfspy start
./dev rust cargo build --release
./dev elixir mix phx.server
./dev objective-c make all
./dev test                    # Run all tests
./dev build                   # Build all implementations
```

## 📖 Documentation

- **[Installation Guides](docs/installation/)** - Platform-specific setup
- **[User Guides](docs/user-guides/)** - How to use Selfspy effectively
- **[Development Docs](docs/development/)** - Contributing and architecture
- **[API Reference](docs/api-reference/)** - Programming interfaces

## 🤝 Contributing

1. Choose the implementation you want to work on
2. Read the language-specific README in that directory
3. Follow the development setup instructions
4. See [Contributing Guide](docs/development/contributing.md) for details

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

## 🔗 Links

- **Documentation**: [docs/](docs/)
- **Issues**: [GitHub Issues](https://github.com/selfspy/selfspy3/issues)
- **Discussions**: [GitHub Discussions](https://github.com/selfspy/selfspy3/discussions)

---

**Built with ❤️ by the Selfspy community**