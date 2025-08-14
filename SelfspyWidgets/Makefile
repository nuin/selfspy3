# Makefile for SelfspyWidgets
# Native macOS desktop widgets for Selfspy

CC = clang
FRAMEWORKS = -framework Cocoa -framework Foundation
CFLAGS = -Wall -Wextra -std=c99 -fobjc-arc

# Legacy version
LEGACY_SOURCES = main.m SelfspyWidgetApp.m SelfspyWidget.m ActivitySummaryWidget.m TerminalWidget.m TopAppsWidget.m
LEGACY_TARGET = SelfspyWidgets

# Modern version
MODERN_SOURCES = modern_main.m ModernSelfspyApp.m ModernSelfspyWidget.m SimpleModernActivityWidget.m
MODERN_TARGET = ModernSelfspyWidgets

INSTALL_DIR = /usr/local/bin

# Default target - build modern version
all: $(MODERN_TARGET)

# Build modern version
modern: $(MODERN_TARGET)

# Build legacy version
legacy: $(LEGACY_TARGET)

# Build the modern application
$(MODERN_TARGET): $(MODERN_SOURCES)
	$(CC) $(CFLAGS) $(FRAMEWORKS) -o $(MODERN_TARGET) $(MODERN_SOURCES)

# Build the legacy application
$(LEGACY_TARGET): $(LEGACY_SOURCES)
	$(CC) $(CFLAGS) $(FRAMEWORKS) -o $(LEGACY_TARGET) $(LEGACY_SOURCES)

# Clean build artifacts
clean:
	rm -f $(MODERN_TARGET) $(LEGACY_TARGET)

# Install to system path
install: $(MODERN_TARGET)
	sudo cp $(MODERN_TARGET) $(INSTALL_DIR)/
	sudo chmod +x $(INSTALL_DIR)/$(MODERN_TARGET)

# Uninstall from system
uninstall:
	sudo rm -f $(INSTALL_DIR)/$(MODERN_TARGET)

# Run the modern application
run: $(MODERN_TARGET)
	./$(MODERN_TARGET)

# Run legacy application
run-legacy: $(LEGACY_TARGET)
	./$(LEGACY_TARGET)

# Debug build with symbols
debug: CFLAGS += -g -DDEBUG
debug: $(MODERN_TARGET)

# Release build with optimization
release: CFLAGS += -O2 -DNDEBUG
release: $(MODERN_TARGET)

.PHONY: all modern legacy clean install uninstall run run-legacy debug release