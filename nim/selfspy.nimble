# Package

version       = "1.0.0"
author        = "Selfspy Team"
description   = "Modern activity monitoring in Nim - fast, efficient, cross-platform"
license       = "MIT"
srcDir        = "src"
bin           = @["selfspy", "selfstats", "selfviz"]

# Dependencies

requires "nim >= 2.0.0"
requires "chronicles >= 0.10.3"   # Structured logging
requires "argparse >= 4.0.1"      # Command line parsing
requires "json_serialization"     # JSON handling
requires "sqliter >= 0.1.0"       # SQLite database
requires "asyncdispatch2"          # Async I/O
requires "chronos"                 # High-performance async
requires "yaml >= 2.0.0"          # Configuration files
requires "tempfile"                # Temporary files
requires "zippy"                   # Compression

when defined(linux):
  requires "x11"                   # X11 bindings for Linux

when defined(macosx):
  # macOS frameworks will be linked directly via pragma
  discard

when defined(windows):
  # Windows APIs will be linked directly via pragma
  discard