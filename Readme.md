# Selfspy

A modern Python tool for monitoring and analyzing your computer activity.

## Description

Selfspy is a daemon that continuously monitors and stores what you are doing on your computer. This includes:
- Keystrokes (encrypted)
- Mouse movements and clicks
- Active window titles and processes
- Activity periods

Perfect for:
- Personal analytics
- Time tracking
- Activity monitoring
- Productivity analysis

## Requirements

- Python 3.10+
- MacOS 10.15+

## Installation

```bash
# Using Poetry
poetry install

# Or using pip
pip install .
```

## Usage

Start monitoring:
```bash
poetry run selfspy
```

View statistics:
```bash
poetry run selfstats
```

## Configuration

Default configuration is stored in `~/.selfspy/`. You can customize the location using:
```bash
poetry run selfspy --data-dir=/path/to/dir
```

## Security

- All keystroke data is encrypted using industry-standard encryption
- Password protection for sensitive data
- Local storage only - no data leaves your computer
- Option to disable text logging

## Contributing

1. Fork the repository
2. Create your feature branch
3. Install development dependencies: `poetry install --with dev`
4. Make your changes
5. Run tests: `poetry run pytest`
6. Submit a pull request

## License

GNU General Public License v3 (GPLv3)