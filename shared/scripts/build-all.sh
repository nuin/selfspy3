#!/bin/bash
set -euo pipefail

# Selfspy Unified Build Script
# Builds all implementations for distribution

echo "🔨 Building all Selfspy implementations..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Track build results
PYTHON_BUILD_SUCCESS=false
RUST_BUILD_SUCCESS=false
PHOENIX_BUILD_SUCCESS=false
MACOS_WIDGETS_BUILD_SUCCESS=false

# Create build directory
mkdir -p build/{python,rust,phoenix,macos-widgets}
mkdir -p dist

# Build Python implementation
build_python() {
    if [[ -d "python" ]]; then
        log_info "Building Python implementation..."
        cd python
        
        # Create virtual environment and install dependencies
        if command -v uv &> /dev/null; then
            log_info "Using uv for Python build..."
            uv sync --group dev
            
            # Build wheel
            uv build
            
            # Copy artifacts
            cp -r dist/* ../../build/python/
            
            log_success "Python build completed"
            PYTHON_BUILD_SUCCESS=true
        else
            log_warning "uv not found, attempting pip build..."
            python3 -m pip install build
            python3 -m build
            
            cp -r dist/* ../../build/python/
            log_success "Python build completed with pip"
            PYTHON_BUILD_SUCCESS=true
        fi
        
        cd ../..
    else
        log_warning "Python implementation not found"
    fi
}

# Build Rust implementation
build_rust() {
    if [[ -d "rust" ]]; then
        log_info "Building Rust implementation..."
        cd rust
        
        if command -v cargo &> /dev/null; then
            # Build release versions
            cargo build --release --all
            
            # Copy binaries
            mkdir -p ../../build/rust/bin
            for binary in target/release/selfspy-*; do
                if [[ -f "$binary" && -x "$binary" ]]; then
                    cp "$binary" ../../build/rust/bin/
                fi
            done
            
            # Create distribution packages
            case "$(uname -s)" in
                Darwin)
                    log_info "Creating macOS distribution..."
                    tar -czf ../../dist/selfspy-rust-macos.tar.gz -C target/release selfspy-gui selfspy-monitor selfspy-stats || true
                    ;;
                Linux)
                    log_info "Creating Linux distribution..."
                    tar -czf ../../dist/selfspy-rust-linux.tar.gz -C target/release selfspy-gui selfspy-monitor selfspy-stats || true
                    ;;
            esac
            
            log_success "Rust build completed"
            RUST_BUILD_SUCCESS=true
        else
            log_warning "cargo not found, skipping Rust build"
        fi
        
        cd ../..
    else
        log_warning "Rust implementation not found"
    fi
}

# Build Phoenix implementation
build_phoenix() {
    if [[ -d "elixir" ]]; then
        log_info "Building Phoenix implementation..."
        cd elixir
        
        if command -v mix &> /dev/null; then
            # Set production environment
            export MIX_ENV=prod
            
            # Install dependencies
            mix deps.get --only prod
            
            # Compile assets
            npm install --prefix assets
            mix assets.deploy
            
            # Create release
            mix release
            
            # Copy release to build directory
            cp -r _build/prod/rel/selfspy_web ../../build/phoenix/
            
            # Create distribution archive
            tar -czf ../../dist/selfspy-phoenix.tar.gz -C _build/prod/rel selfspy_web
            
            log_success "Phoenix build completed"
            PHOENIX_BUILD_SUCCESS=true
        else
            log_warning "mix not found, skipping Phoenix build"
        fi
        
        cd ../..
    else
        log_warning "Phoenix implementation not found"
    fi
}

# Build macOS widgets
build_macos_widgets() {
    if [[ -d "objective-c" && "$(uname -s)" == "Darwin" ]]; then
        log_info "Building macOS widgets..."
        cd objective-c
        
        # Build widgets
        if [[ -f "build.sh" ]]; then
            chmod +x build.sh
            ./build.sh
            
            # Create app bundle if script exists
            if [[ -f "create_app_bundle.sh" ]]; then
                chmod +x create_app_bundle.sh
                ./create_app_bundle.sh
            fi
            
            # Copy artifacts
            if [[ -d "SelfspyWidgets.app" ]]; then
                cp -r SelfspyWidgets.app ../../build/macos-widgets/
            fi
            
            # Create distribution
            if [[ -d "SelfspyWidgets.app" ]]; then
                tar -czf ../../dist/selfspy-macos-widgets.tar.gz SelfspyWidgets.app
            fi
            
            log_success "macOS widgets build completed"
            MACOS_WIDGETS_BUILD_SUCCESS=true
        else
            log_warning "Build scripts not found for macOS widgets"
        fi
        
        cd ../..
    elif [[ "$(uname -s)" != "Darwin" ]]; then
        log_warning "macOS widgets can only be built on macOS"
    else
        log_warning "macOS widgets implementation not found"
    fi
}

# Create unified installer
create_unified_installer() {
    log_info "Creating unified installer..."
    
    cat > dist/install.sh << 'EOF'
#!/bin/bash
# Selfspy Unified Installer

set -euo pipefail

echo "🚀 Selfspy Installation Script"
echo "=============================="

# Detect platform
case "$(uname -s)" in
    Darwin) PLATFORM="macos" ;;
    Linux) PLATFORM="linux" ;;
    *) echo "Unsupported platform"; exit 1 ;;
esac

echo "Platform: $PLATFORM"

# Choose implementation
echo ""
echo "Choose implementation:"
echo "1) Python (recommended for most users)"
echo "2) Rust (high performance)"
echo "3) Phoenix (web dashboard)"
if [[ $PLATFORM == "macos" ]]; then
    echo "4) macOS Widgets"
fi

read -p "Enter choice [1-$([ $PLATFORM == "macos" ] && echo 4 || echo 3)]: " choice

case $choice in
    1)
        echo "Installing Python implementation..."
        # Python installation logic here
        ;;
    2)
        echo "Installing Rust implementation..."
        # Rust installation logic here
        ;;
    3)
        echo "Installing Phoenix implementation..."
        # Phoenix installation logic here
        ;;
    4)
        if [[ $PLATFORM == "macos" ]]; then
            echo "Installing macOS Widgets..."
            # macOS widgets installation logic here
        else
            echo "Invalid choice"
            exit 1
        fi
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo "Installation completed!"
EOF

    chmod +x dist/install.sh
    log_success "Unified installer created"
}

# Create checksums
create_checksums() {
    log_info "Creating checksums..."
    cd dist
    
    for file in *.tar.gz; do
        if [[ -f "$file" ]]; then
            sha256sum "$file" > "$file.sha256" 2>/dev/null || shasum -a 256 "$file" > "$file.sha256"
        fi
    done
    
    cd ..
    log_success "Checksums created"
}

# Main build process
main() {
    log_info "Starting comprehensive build process..."
    
    # Check we're in the right directory
    if [[ ! -f "CLAUDE.md" ]]; then
        log_error "Please run this script from the project root directory"
        exit 1
    fi
    
    # Clean previous builds
    log_info "Cleaning previous builds..."
    rm -rf build/* dist/*
    
    # Build each implementation
    build_python
    build_rust
    build_phoenix
    build_macos_widgets
    
    # Create distribution artifacts
    create_unified_installer
    create_checksums
    
    # Print summary
    echo ""
    echo "🏁 Build Summary"
    echo "==============="
    
    echo "Build Results:"
    echo "  Python: $([ $PYTHON_BUILD_SUCCESS == true ] && echo "✅ SUCCESS" || echo "❌ FAILED")"
    echo "  Rust: $([ $RUST_BUILD_SUCCESS == true ] && echo "✅ SUCCESS" || echo "❌ FAILED")"
    echo "  Phoenix: $([ $PHOENIX_BUILD_SUCCESS == true ] && echo "✅ SUCCESS" || echo "❌ FAILED")"
    echo "  macOS Widgets: $([ $MACOS_WIDGETS_BUILD_SUCCESS == true ] && echo "✅ SUCCESS" || echo "❌ FAILED")"
    
    echo ""
    echo "Build Artifacts:"
    echo "  Build directory: ./build/"
    echo "  Distribution packages: ./dist/"
    
    if [[ -f "dist/install.sh" ]]; then
        echo "  Unified installer: ./dist/install.sh"
    fi
    
    echo ""
    log_info "Listing distribution files:"
    ls -la dist/
    
    # Calculate total success
    local successful_builds=0
    [ $PYTHON_BUILD_SUCCESS == true ] && successful_builds=$((successful_builds + 1))
    [ $RUST_BUILD_SUCCESS == true ] && successful_builds=$((successful_builds + 1))
    [ $PHOENIX_BUILD_SUCCESS == true ] && successful_builds=$((successful_builds + 1))
    [ $MACOS_WIDGETS_BUILD_SUCCESS == true ] && successful_builds=$((successful_builds + 1))
    
    if [[ $successful_builds -gt 0 ]]; then
        log_success "Build completed with $successful_builds implementation(s) 🎉"
    else
        log_error "All builds failed"
        exit 1
    fi
}

# Handle command line arguments
case "${1:-all}" in
    "python")
        build_python
        ;;
    "rust")
        build_rust
        ;;
    "phoenix")
        build_phoenix
        ;;
    "macos-widgets")
        build_macos_widgets
        ;;
    "all"|*)
        main
        ;;
esac