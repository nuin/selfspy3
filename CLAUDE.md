# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Selfspy is a modern Python daemon for monitoring and analyzing computer activity. It continuously monitors:
- Keystrokes (encrypted for security)
- Mouse movements and clicks
- Active window titles and processes
- Activity periods

The project uses modern Python (3.10+) with async/await patterns and SQLAlchemy 2.0.

## Development Commands

### Setup and Installation
```bash
# Install dependencies (use uv)
uv sync --group dev

# Install with macOS extras for full functionality
uv sync --group dev --extra macos

# Alternative pip installation
uv pip install .
```

### Running the Application
```bash
# Start monitoring (will guide through permission setup on macOS)
uv run selfspy start

# Start monitoring with custom data directory
uv run selfspy start --data-dir /path/to/data

# Start monitoring without text logging
uv run selfspy start --no-text

# Skip permission checks (for testing, may fail)
uv run selfspy start --force

# View statistics
uv run selfstats

# Check macOS permissions manually
uv run selfspy check-permissions
```

### Development and Testing
```bash
# Run tests
uv run pytest

# Run with coverage (default from pytest.ini)
uv run pytest --cov=src

# Run a single test file
uv run pytest tests/test_models.py

# Linting and formatting
uv run black src/ tests/
uv run isort src/ tests/
uv run ruff check src/ tests/
uv run mypy src/

# Pre-commit hooks
uv run pre-commit run --all-files
```

## Architecture Overview

### Core Components

**Entry Points (`src/cli.py` and `src/stats.py`)**
- Uses Typer for modern CLI interface with Rich output
- Main commands: `start` (monitoring), `stats` (analysis), `check-permissions`
- Handles async event loops and signal handling

**Activity Monitor (`src/activity_monitor.py`)**
- Central orchestrator using async patterns
- Manages platform-specific trackers (keyboard, mouse, window)
- Maintains live dashboard during monitoring
- Buffers keystrokes before storage to reduce I/O

**Data Layer**
- `src/models.py`: SQLAlchemy 2.0 models with modern mapped_column syntax
- `src/activity_store.py`: Database operations with async session management
- `src/encryption.py`: Handles keystroke encryption using cryptography library

**Platform Abstraction (`src/platform/`)**
- `base.py`: Abstract interfaces for cross-platform support
- `darwin.py`: macOS-specific implementations using PyObjC
- `fallback.py`: Basic implementations for other platforms
- Platform detection and graceful degradation

### Key Design Patterns

- **Async/Await**: All I/O operations use asyncio for better performance
- **Dependency Injection**: Settings and stores passed to components
- **Platform Abstraction**: Interface-based design allows platform-specific implementations
- **Encryption by Default**: All keystroke data encrypted unless explicitly disabled
- **Modern Python**: Uses type hints, dataclasses, and modern SQLAlchemy patterns

### Database Schema

Uses SQLAlchemy 2.0 with declarative base and relationships:
- `Process`: Application information with macOS bundle IDs
- `Window`: Window metadata including geometry and screen info
- `Keys`: Encrypted keystroke data with counts
- `Click`: Mouse events with coordinates and movement tracking

All tables include timestamp mixins and proper indexing for performance.

### Configuration (`src/config.py`)

Uses Pydantic Settings for type-safe configuration:
- Environment variable support with `SELFSPY_` prefix
- Path validation and automatic directory creation
- Platform-specific settings for macOS features
- Privacy and security controls

## macOS Integration

The project has extensive macOS support requiring:
- Accessibility permissions for window tracking
- Optional Screen Recording permissions for screenshots
- PyObjC frameworks for native API access
- Bundle ID tracking for better app identification

Use `uv sync --group dev --extra macos` for full macOS functionality.

## Security Considerations

- All keystroke data encrypted by default using industry-standard cryptography
- Configurable exclusions for sensitive applications
- Privacy mode available for restricted logging
- Local storage only - no network transmission
- Secure password handling via keyring integration

## Testing and Code Quality

- Uses pytest with async support and coverage reporting
- Code formatting with Black and import sorting with isort
- Type checking with mypy
- Linting with ruff
- Pre-commit hooks for code quality enforcement

The codebase follows modern Python conventions with comprehensive type hints and documentation.