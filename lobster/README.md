# Selfspy - Lobster Implementation

A complete implementation of Selfspy in [Lobster](http://strlen.com/lobster/), a simple, statically typed language with automatic memory management and excellent performance.

## Features

- **Simple Syntax**: Clean, readable code with strong typing
- **Memory Safety**: Automatic memory management without garbage collection overhead
- **Performance**: Excellent runtime performance characteristics
- **Concurrent**: Built-in support for concurrent programming patterns
- **Cross-platform**: Works on Windows, macOS, and Linux

## Requirements

- [Lobster compiler](http://strlen.com/lobster/) installed
- Platform-specific permissions for activity monitoring

## Building

```bash
# Check if Lobster is available
lobster --version

# Run directly (no compilation needed)
lobster selfspy.lobster help
```

## Usage

```bash
# Start monitoring
lobster selfspy.lobster start

# Start with privacy options
lobster selfspy.lobster start --no-text --debug

# View statistics
lobster selfspy.lobster stats --days 7

# Export data
lobster selfspy.lobster export --format csv --output activity.csv

# Check system permissions
lobster selfspy.lobster check
```

## Implementation Highlights

- **Static Typing**: Strong type system with automatic inference
- **Memory Management**: Automatic memory management without GC pauses
- **Pattern Matching**: Clean command parsing with switch expressions
- **Error Handling**: Simple, effective error handling with fatal() calls
- **Platform Abstraction**: Cross-platform code with runtime detection
- **Concurrent Programming**: Built-in support for cooperative multitasking

## Architecture

The Lobster implementation showcases:

1. **Struct-based Data Modeling**: Clean data structures with explicit types
2. **Functional Programming**: Functional approach to data processing
3. **Pattern Matching**: Extensive use of switch expressions for control flow
4. **Memory Efficiency**: Automatic memory management without overhead
5. **Performance**: Compiled performance with interpreted flexibility

This implementation demonstrates Lobster's suitability for system programming while maintaining simplicity and performance.