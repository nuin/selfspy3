# Selfspy Installation Guide

Selfspy is a modern Python application for monitoring and analyzing computer activity. This guide covers multiple installation methods to suit different needs.

## Quick Installation

### Prerequisites

- **Python 3.10 or higher** (required)
- **pip** (Python package installer)
- **Git** (for cloning the repository)

### Check Python Version

```bash
python3 --version
# or
python --version
```

If you don't have Python 3.10+, install it from [python.org](https://www.python.org/downloads/) or use your system's package manager.

## Installation Methods

### Method 1: Automatic Installation (Recommended)

Clone the repository and run the installation script. It will automatically detect if you have `uv` or `pip` and use the appropriate method:

```bash
git clone https://github.com/yourusername/selfspy3.git
cd selfspy3
python3 install.py
```

The script will automatically:
- Check Python version compatibility
- Detect if you have `uv` or `pip` available
- Detect your operating system
- Install appropriate dependencies
- Set up the application

**For development:**
```bash
python3 install.py --dev
```

### Method 2: Using uv (Recommended for Development)

If you have `uv` installed, you can use it for faster dependency management:

```bash
git clone https://github.com/yourusername/selfspy3.git
cd selfspy3

# Basic installation
uv sync

# macOS with full functionality
uv sync --extra macos

# Development installation
uv sync --group dev --extra macos  # macOS
uv sync --group dev                 # Other platforms
```

### Method 3: Manual pip Installation

#### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/selfspy3.git
cd selfspy3
```

#### 2. Install Dependencies

Choose the appropriate requirements file for your system:

**For all platforms:**
```bash
pip3 install -r requirements.txt
```

**For macOS (recommended for full functionality):**
```bash
pip3 install -r requirements-macos.txt
```

**For development:**
```bash
pip3 install -r requirements-dev.txt
```

#### 3. Install Selfspy

```bash
pip3 install -e .
```

### Method 3: Virtual Environment (Recommended for Development)

```bash
# Clone repository
git clone https://github.com/yourusername/selfspy3.git
cd selfspy3

# Create virtual environment
python3 -m venv selfspy-env

# Activate virtual environment
# On macOS/Linux:
source selfspy-env/bin/activate
# On Windows:
# selfspy-env\Scripts\activate

# Install dependencies
pip install -r requirements.txt  # or requirements-macos.txt on macOS

# Install selfspy
pip install -e .
```

## Platform-Specific Setup

### macOS Setup

macOS requires special permissions for activity monitoring:

1. **Install with macOS support:**
   ```bash
   pip3 install -r requirements-macos.txt
   pip3 install -e .
   ```

2. **Check permissions:**
   ```bash
   selfspy check-permissions
   ```

3. **Grant permissions manually:**
   - Open **System Settings** → **Privacy & Security** → **Privacy**
   - Click **Accessibility** and add your terminal application
   - If using screen recording features, also add to **Screen Recording**

### Linux Setup

```bash
# Install dependencies
pip3 install -r requirements.txt
pip3 install -e .

# You may need additional system packages
sudo apt-get install python3-dev  # Ubuntu/Debian
# or
sudo yum install python3-devel    # RedHat/CentOS
```

### Windows Setup

```bash
# Use Command Prompt or PowerShell
pip install -r requirements.txt
pip install -e .
```

**Note:** Windows support is limited. Some features may not work as expected.

## Development Setup

For contributors and developers:

```bash
# Clone and enter directory
git clone https://github.com/yourusername/selfspy3.git
cd selfspy3

# Install development dependencies
python3 install.py --dev

# Or manually:
pip3 install -r requirements-dev.txt
pip3 install -e .

# Set up pre-commit hooks
pre-commit install
```

## Verification

After installation, verify everything works:

```bash
# Check installation
selfspy --help

# Check permissions (macOS only)
selfspy check-permissions

# Run tests (development setup)
pytest
```

## Troubleshooting

### Common Issues

**1. Python Version Error**
```
Error: Python 3.10 or higher is required
```
**Solution:** Upgrade Python or use `python3.10` specifically.

**2. Permission Denied (macOS)**
```
Error: AXIsProcessTrusted
```
**Solution:** 
- Run `selfspy check-permissions`
- Grant Accessibility permissions in System Settings
- Restart your terminal

**3. Import Error**
```
ModuleNotFoundError: No module named 'src'
```
**Solution:** Make sure you installed with `pip install -e .`

**4. PyObjC Installation Error (macOS)**
```
Error: Failed building wheel for pyobjc-framework-Quartz
```
**Solution:**
- Install Xcode Command Line Tools: `xcode-select --install`
- Try: `pip install --upgrade pip setuptools wheel`

### Getting Help

1. **Check the logs:** Selfspy creates logs in your data directory
2. **Run with debug:** `selfspy start --debug`
3. **Check permissions:** `selfspy check-permissions` (macOS)
4. **GitHub Issues:** Report bugs at [repository issues page]

## Uninstallation

To remove Selfspy:

```bash
# Uninstall the package
pip3 uninstall selfspy

# Remove data directory (optional)
rm -rf ~/.local/share/selfspy  # Linux/macOS
# or check: selfspy --help  # for data directory location
```

## Next Steps

After successful installation:

1. **Start monitoring:** `selfspy start`
2. **View statistics:** `selfviz enhanced`
3. **Terminal analytics:** `selfterminal commands`
4. **Read the documentation:** Check `ADVANCED_GUIDE.md` for detailed usage

## Dependencies

### Core Dependencies
- SQLAlchemy 2.0+ (database)
- Rich (CLI interface)
- Typer (command-line framework)
- Pynput (input monitoring)
- Cryptography (data encryption)

### macOS Dependencies
- PyObjC frameworks (native macOS APIs)

### Development Dependencies
- pytest (testing)
- black (code formatting)
- ruff (linting)
- mypy (type checking)