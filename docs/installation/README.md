# Installation Guides

Choose your Selfspy implementation based on your needs and platform.

## Quick Decision Guide

### 🐍 Python Implementation
**Best for**: General use, research, scripting, mature ecosystem
- ✅ Most mature and feature-complete
- ✅ Extensive documentation and examples
- ✅ Rich command-line tools and visualizations
- ✅ Desktop widgets for macOS
- [Install Python Version](python.md)

### 🦀 Rust Implementation  
**Best for**: Performance, system integration, native applications
- ✅ Low resource usage and high performance
- ✅ Native cross-platform GUI application
- ✅ System tray integration
- ✅ Fast startup and processing
- [Install Rust Version](rust.md)

### 🔥 Phoenix Implementation
**Best for**: Web dashboards, team monitoring, real-time analytics
- ✅ Web-based interface accessible from anywhere
- ✅ Real-time updates with Phoenix LiveView
- ✅ Multi-user support and team features
- ✅ Modern responsive design
- [Install Phoenix Version](phoenix.md)

### 🍎 macOS Widgets
**Best for**: macOS desktop integration, always-visible monitoring
- ✅ Native macOS desktop widgets
- ✅ Always-on-top activity displays
- ✅ Minimal resource usage
- ❌ macOS only
- [Install macOS Widgets](macos-widgets.md)

## Platform Support Matrix

| Platform | Python | Rust | Phoenix | macOS Widgets |
|----------|--------|------|---------|---------------|
| **macOS** | ✅ Full | ✅ Full | ✅ Full | ✅ Native |
| **Linux** | ✅ Full | ✅ Full | ✅ Full | ❌ |
| **Windows** | ⚠️ Basic | ✅ Full | ✅ Full | ❌ |

## Installation Methods

### One-Line Installers (Coming Soon)

```bash
# Python (most users)
curl -sSL https://install.selfspy.dev/python | bash

# Rust (performance users)  
curl -sSL https://install.selfspy.dev/rust | bash

# Phoenix (web dashboard)
curl -sSL https://install.selfspy.dev/phoenix | bash
```

### Manual Installation

1. **Choose your implementation** from the links above
2. **Follow the specific installation guide** for your chosen implementation
3. **Complete platform-specific setup** (permissions, dependencies)
4. **Verify installation** with provided test commands

## Common Prerequisites

### All Platforms
- **Git**: For cloning the repository
- **Basic development tools**: Compilers and build tools for your platform

### macOS
- **Xcode Command Line Tools**: `xcode-select --install`
- **Homebrew** (recommended): For package management
- **Accessibility permissions**: Required for full monitoring

### Linux
- **Development packages**: `build-essential` (Ubuntu) or equivalent
- **System libraries**: X11 development headers
- **Package manager**: `apt`, `yum`, `pacman`, etc.

### Windows
- **Visual Studio Build Tools** or **MinGW**: For Rust compilation
- **Python 3.10+**: For Python implementation
- **PowerShell 5.0+**: For running setup scripts

## Post-Installation

After installing any implementation:

1. **Verify installation**: Run the provided test commands
2. **Configure permissions**: Follow platform-specific permission setup
3. **Review privacy settings**: Configure data collection preferences
4. **Start monitoring**: Begin tracking your activity
5. **Explore features**: Try different commands and interfaces

## Getting Help

If you encounter issues:

1. **Check the troubleshooting guide** for your implementation
2. **Review common issues** in [Troubleshooting](../user-guides/troubleshooting.md)
3. **Search existing issues** on [GitHub](https://github.com/selfspy/selfspy3/issues)
4. **Ask for help** in [GitHub Discussions](https://github.com/selfspy/selfspy3/discussions)

## Multiple Implementations

You can install multiple implementations side-by-side:

- **Different data directories**: Use `--data-dir` to separate data
- **Different ports**: Phoenix can run on custom ports
- **Coordinated monitoring**: Only run one monitor at a time per data directory

Example:
```bash
# Python for daily use
selfspy start --data-dir ~/.selfspy/python

# Phoenix for web dashboard (different data)
cd implementations/phoenix
mix phx.server --data-dir ~/.selfspy/phoenix
```