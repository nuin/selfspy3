# Selfspy 🔍

A modern Python tool for monitoring and analyzing your computer activity with beautiful visualizations and terminal command analytics.

## Features ✨

Selfspy continuously monitors and analyzes:
- **Keystrokes** (encrypted for security)
- **Mouse movements and clicks**
- **Active window titles and processes**
- **Terminal command execution** with project context
- **Activity periods and patterns**

### What's New 🆕
- 🎨 **Rich visualizations** with charts and graphs
- 🔧 **Terminal command analytics** - track your development workflow  
- 📊 **Enhanced statistics** with productivity insights
- 🖥️ **Live dashboard** with real-time monitoring
- 🍎 **Native macOS integration** with proper permissions handling
- 🪟 **Desktop widgets** - beautiful always-on-top activity widgets

## Quick Start 🚀

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/selfspy3.git
cd selfspy3

# Quick automatic installation (detects uv/pip automatically)
python3 install.py
```

**Alternative installation methods:**

**Using uv (recommended for development):**
```bash
# Basic installation
uv sync

# macOS with full functionality
uv sync --extra macos

# Development setup
uv sync --group dev --extra macos
```

**Using pip:**
```bash
# Manual installation - basic
pip3 install -r requirements.txt
pip3 install -e .

# Manual installation - macOS with full functionality
pip3 install -r requirements-macos.txt
pip3 install -e .

# Development setup
python3 install.py --dev
```

### Basic Usage

Start monitoring your activity:
```bash
selfspy start
```

View beautiful statistics:
```bash
# Enhanced visualizations
selfviz enhanced

# Activity timeline
selfviz timeline --days 7

# Live dashboard
selfviz live
```

Analyze your terminal workflow:
```bash
# Command frequency analysis
selfterminal commands --days 7

# Project-based analysis
selfterminal projects

# Development workflow patterns
selfterminal workflow
```

Check permissions (macOS):
```bash
selfspy check-permissions
```

Launch desktop widgets (macOS):
```bash
cd desktop-app
python3 launch_widgets.py developer  # Activity + Terminal + Apps
python3 launch_widgets.py minimal     # Just activity summary
```

## Requirements 📋

- **Python 3.10+**
- **macOS** (full support), Linux (basic support), Windows (limited)
- **Accessibility permissions** (macOS only)

## Installation Guide 📖

For detailed installation instructions, troubleshooting, and platform-specific setup, see [INSTALL.md](INSTALL.md).

## Commands Reference 📚

### Core Commands
- `selfspy start` - Start activity monitoring
- `selfspy check-permissions` - Check macOS permissions
- `selfstats` - Basic statistics (legacy command)

### Enhanced Visualizations  
- `selfviz enhanced` - Rich statistics with charts
- `selfviz timeline` - Activity timeline view
- `selfviz live` - Real-time dashboard

### Terminal Analytics
- `selfterminal commands` - Command frequency analysis
- `selfterminal sessions` - Terminal session statistics  
- `selfterminal projects` - Project-based analysis
- `selfterminal workflow` - Development workflow patterns

### Desktop Widgets (macOS)
- `python3 desktop-app/launch_widgets.py minimal` - Activity summary widget
- `python3 desktop-app/launch_widgets.py developer` - Developer widget set
- `python3 desktop-app/launch_widgets.py full` - All widget types
- Right-click widgets for customization options

## Perfect For 💼

- **Developers** - Track coding patterns and terminal usage
- **Freelancers** - Monitor time and productivity
- **Researchers** - Analyze computer usage patterns
- **Personal Analytics** - Understand your digital habits

## Security & Privacy 🔒

- All keystroke data is **encrypted** using industry-standard encryption
- **Local storage only** - no data leaves your computer
- Password protection for sensitive data
- Option to disable text logging
- Configurable exclusions for sensitive applications

## Development 🛠️

```bash
# Set up development environment
python3 install.py --dev

# Run tests
pytest

# Code formatting
black src/ tests/
isort src/ tests/

# Linting
ruff check src/ tests/
mypy src/
```

## Platform Support 🖥️

**macOS** (Recommended)
- Full window tracking and accessibility features
- Native PyObjC integration
- Advanced permissions handling

**Linux**
- Basic activity tracking
- Terminal command analytics

**Windows**
- Limited support
- Basic functionality only

## Configuration ⚙️

Default configuration is stored in `~/.local/share/selfspy/` (Linux/macOS) or equivalent.

Customize the data directory:
```bash
selfspy start --data-dir /path/to/custom/dir
```

## Advanced Usage 🚀

For detailed usage examples, advanced configuration, and API documentation, see [ADVANCED_GUIDE.md](ADVANCED_GUIDE.md).

## Contributing 🤝

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Install development dependencies (`python3 install.py --dev`)
4. Make your changes
5. Run tests (`pytest`)
6. Format code (`black src/ tests/`)
7. Submit a pull request

## License 📄

GNU General Public License v3 (GPLv3) - see [LICENSE](LICENSE) for details.

## Architecture 🏗️

Built with modern Python practices:
- **Async/await** for performance
- **SQLAlchemy 2.0** for database operations
- **Rich** for beautiful CLI interfaces
- **Typer** for command-line framework
- **Pydantic** for configuration management

---

**Ready to understand your digital habits?** `python3 install.py` and `selfspy start`! 🚀