# Makefile for Selfspy Platform Monitor NIF
# Compiles native extensions for cross-platform system monitoring

# Default target
all: priv/platform_monitor.so

# Detect the operating system
UNAME_S := $(shell uname -s)

# Common compiler flags
CFLAGS = -fPIC -O3 -std=c99 -finline-functions -Wall -Wmissing-prototypes
LDFLAGS = -shared

# Include directory for Erlang/Elixir headers
ERL_EI_INCLUDE_DIR ?= $(shell erl -eval 'io:format("~s", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/include"])])' -s init stop -noshell)
ERL_EI_LIBDIR ?= $(shell erl -eval 'io:format("~s", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/lib"])])' -s init stop -noshell)

# Platform-specific settings
ifeq ($(UNAME_S),Darwin)
    # macOS specific settings
    CFLAGS += -I$(ERL_EI_INCLUDE_DIR) -I/usr/local/include
    LDFLAGS += -framework Cocoa -framework ApplicationServices -framework CoreGraphics
    SOURCES = platform_monitor_nif.c darwin_monitor.c
    TARGET = priv/platform_monitor.so
    
    # macOS specific flags
    CFLAGS += -DDARWIN
    LDFLAGS += -undefined dynamic_lookup -dynamiclib
    
else ifeq ($(UNAME_S),Linux)
    # Linux specific settings
    CFLAGS += -I$(ERL_EI_INCLUDE_DIR) -I/usr/include/X11
    LDFLAGS += -lX11 -lXtst -lXext
    SOURCES = platform_monitor_nif.c linux_monitor.c
    TARGET = priv/platform_monitor.so
    
    # Linux specific flags
    CFLAGS += -DLINUX
    
else ifeq ($(OS),Windows_NT)
    # Windows specific settings (MinGW)
    CFLAGS += -I$(ERL_EI_INCLUDE_DIR) -DWIN32
    LDFLAGS += -luser32 -lkernel32 -lgdi32
    SOURCES = platform_monitor_nif.c windows_monitor.c
    TARGET = priv/platform_monitor.dll
    
else
    # Fallback for unknown platforms
    $(warning Unknown platform: $(UNAME_S))
    SOURCES = platform_monitor_nif.c fallback_monitor.c
    TARGET = priv/platform_monitor.so
    CFLAGS += -DFALLBACK
endif

# Object files
OBJECTS = $(SOURCES:.c=.o)

# Ensure priv directory exists
priv:
	@mkdir -p priv

# Main target
$(TARGET): priv $(OBJECTS)
	$(CC) $(OBJECTS) $(LDFLAGS) -o $(TARGET)

# Generic object file rule
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Clean build artifacts
clean:
	rm -f *.o
	rm -f priv/platform_monitor.*

# Install development dependencies (macOS)
deps-darwin:
	@echo "Installing macOS development dependencies..."
	@echo "Ensure Xcode Command Line Tools are installed: xcode-select --install"

# Install development dependencies (Linux)
deps-linux:
	@echo "Installing Linux development dependencies..."
	@echo "Ubuntu/Debian: sudo apt-get install libx11-dev libxtst-dev libxext-dev"
	@echo "CentOS/RHEL: sudo yum install libX11-devel libXtst-devel libXext-devel"

# Install development dependencies (Windows)
deps-windows:
	@echo "Installing Windows development dependencies..."
	@echo "Ensure MinGW-w64 is installed and in PATH"

# Development helpers
.PHONY: all clean deps-darwin deps-linux deps-windows priv

# Help target
help:
	@echo "Selfspy Platform Monitor NIF Build System"
	@echo ""
	@echo "Targets:"
	@echo "  all          - Build the NIF library for current platform"
	@echo "  clean        - Remove build artifacts"
	@echo "  deps-darwin  - Show macOS dependency installation instructions"
	@echo "  deps-linux   - Show Linux dependency installation instructions"
	@echo "  deps-windows - Show Windows dependency installation instructions"
	@echo "  help         - Show this help message"
	@echo ""
	@echo "Platform Detection:"
	@echo "  Current OS: $(UNAME_S)"
	@echo "  Target: $(TARGET)"
	@echo "  Sources: $(SOURCES)"
	@echo ""
	@echo "Compiler Settings:"
	@echo "  CFLAGS: $(CFLAGS)"
	@echo "  LDFLAGS: $(LDFLAGS)"