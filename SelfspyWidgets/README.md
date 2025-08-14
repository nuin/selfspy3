# SelfspyWidgets - Native macOS Desktop Widgets

Native Objective-C desktop widgets for displaying Selfspy activity data directly on your macOS desktop.

## Features

- **Always-on-top desktop widgets** that stay visible across all spaces
- **Draggable and repositionable** widgets with smooth animations
- **Real-time activity data** from your Selfspy monitoring
- **Multiple widget types**:
  - 📊 **Activity Summary**: Keystrokes, clicks, active time, productivity score
  - 🔧 **Terminal Activity**: Recent commands and terminal usage statistics  
  - 🏆 **Top Applications**: Most used apps with time tracking and progress bars
- **Native macOS integration** using Cocoa frameworks for optimal performance
- **Minimal resource usage** compared to Python-based alternatives

## Requirements

- macOS 10.12 or later
- Xcode command line tools
- Running Selfspy installation (for real data)

## Installation

### Quick Install

```bash
cd SelfspyWidgets
./build.sh
```

### Manual Build

```bash
# Build the application
make

# Or build optimized release version
make release

# Install system-wide (optional)
sudo make install
```

## Usage

### Running the Widgets

```bash
# Run from build directory
./SelfspyWidgets

# Or if installed system-wide
SelfspyWidgets
```

### Widget Controls

- **Drag to move**: Click and drag any widget to reposition
- **Always on top**: Widgets stay visible across all applications and spaces
- **Auto-refresh**: Data updates automatically every few seconds
- **Quit**: Use Cmd+Q or right-click → Quit

### Build Options

```bash
make            # Standard build
make debug      # Debug build with symbols
make release    # Optimized release build
make clean      # Clean build artifacts
make install    # Install to /usr/local/bin
make uninstall  # Remove from system
make run        # Build and run in one step
```

## Architecture

### Core Components

- **SelfspyWidgetApp**: Main application controller and window management
- **SelfspyWidget**: Base widget class with common functionality
- **ActivitySummaryWidget**: Daily activity statistics and productivity metrics
- **TerminalWidget**: Terminal command history and usage patterns
- **TopAppsWidget**: Application usage tracking with visual progress bars

### Data Integration

Currently uses mock data for demonstration. To integrate with real Selfspy data:

1. Link against Selfspy's SQLite database
2. Implement async data fetching to avoid blocking the UI
3. Add database connection management and error handling

### Technical Details

- **Language**: Objective-C with ARC (Automatic Reference Counting)
- **Frameworks**: Cocoa, Foundation, AppKit
- **Architecture**: MVC pattern with delegate-based event handling
- **Memory Management**: Automatic reference counting for leak-free operation
- **Threading**: Main thread UI with background data fetching

## Customization

### Adding New Widget Types

1. Create new widget class inheriting from `SelfspyWidget`
2. Implement required methods: `initWithPosition:`, `fetchData`, `drawContent:`
3. Add to the widget creation in `SelfspyWidgetApp.m`

### Styling and Appearance

- Modify drawing code in each widget's `drawContent:` method
- Adjust colors, fonts, and layouts as needed
- All widgets support transparency and custom backgrounds

## Development

### Project Structure

```
SelfspyWidgets/
├── main.m                    # Application entry point
├── SelfspyWidgetApp.[hm]     # Main app controller
├── SelfspyWidget.[hm]        # Base widget class
├── ActivitySummaryWidget.[hm] # Activity statistics widget
├── TerminalWidget.[hm]       # Terminal activity widget
├── TopAppsWidget.[hm]        # Top applications widget
├── Makefile                  # Build configuration
├── build.sh                  # Build script
└── README.md                 # This file
```

### Debugging

```bash
# Build with debug symbols
make debug

# Run with debugging
lldb ./SelfspyWidgets
```

## Integration with Python Selfspy

The native widgets can coexist with the Python PyObjC versions:

- **Python widgets**: `../desktop-app/simple_widget.py`
- **Advanced Python**: `../desktop-app/selfspy_desktop_advanced.py`
- **Native Objective-C**: `./SelfspyWidgets` (this project)

Choose the version that best fits your performance and customization needs.

## Performance

Native Objective-C version provides:
- **Lower memory usage** (~2-5MB vs 20-30MB for Python)
- **Better battery life** due to optimized drawing and reduced framework overhead
- **Smoother animations** with native Core Animation integration
- **Faster startup time** and more responsive UI

## Troubleshooting

### Build Issues

```bash
# Install Xcode command line tools if missing
xcode-select --install

# Clean and rebuild
make clean && make
```

### Runtime Issues

- Ensure Selfspy database is accessible and readable
- Check Console.app for any crash logs or error messages
- Verify macOS version compatibility (10.12+)

### Permission Issues

If widgets don't appear or behave incorrectly:
- Check System Preferences → Security & Privacy → Privacy → Accessibility
- Ensure the application has necessary permissions for window management

## License

Part of the Selfspy project. See main project license for details.