#!/bin/bash
set -euo pipefail

# Selfspy Development Environment Setup (New Structure)
# Sets up development environment for all language implementations

echo "🔧 Setting up Selfspy development environment (new structure)..."

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

# Detect platform
detect_platform() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        Linux) echo "linux" ;;
        CYGWIN*|MINGW*|MSYS*) echo "windows" ;;
        *) echo "unknown" ;;
    esac
}

PLATFORM=$(detect_platform)
log_info "Platform detected: $PLATFORM"

# Check if running from project root
if [[ ! -f "IMPROVED_STRUCTURE.md" ]]; then
    log_error "Please run this script from the project root directory"
    exit 1
fi

# Platform-specific setup
setup_platform_dependencies() {
    case $PLATFORM in
        macos)
            log_info "Setting up macOS dependencies..."
            
            # Check for Xcode Command Line Tools
            if ! xcode-select -p &> /dev/null; then
                log_warning "Xcode Command Line Tools not found. Installing..."
                xcode-select --install
                log_info "Please complete Xcode Command Line Tools installation and re-run this script"
                exit 1
            fi
            
            # Check for Homebrew
            if ! command -v brew &> /dev/null; then
                log_warning "Homebrew not found. Installing..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            
            # Install common development dependencies
            log_info "Installing development dependencies with Homebrew..."
            brew update
            brew install git postgresql pkg-config node
            log_success "macOS dependencies installed"
            ;;
            
        linux)
            log_info "Setting up Linux dependencies..."
            
            # Detect package manager and install dependencies
            if command -v apt-get &> /dev/null; then
                log_info "Using apt package manager..."
                sudo apt-get update
                sudo apt-get install -y \
                    build-essential \
                    git \
                    pkg-config \
                    libx11-dev \
                    libxtst-dev \
                    libxext-dev \
                    postgresql \
                    postgresql-contrib \
                    curl \
                    nodejs \
                    npm
            elif command -v yum &> /dev/null; then
                log_info "Using yum package manager..."
                sudo yum groupinstall -y "Development Tools"
                sudo yum install -y \
                    git \
                    pkgconfig \
                    libX11-devel \
                    libXtst-devel \
                    libXext-devel \
                    postgresql \
                    postgresql-server \
                    curl \
                    nodejs \
                    npm
            else
                log_warning "Unknown package manager. Please install dependencies manually"
            fi
            log_success "Linux dependencies installed"
            ;;
            
        *)
            log_warning "Platform-specific setup not available for $PLATFORM"
            ;;
    esac
}

# Python environment setup
setup_python() {
    log_info "Setting up Python environment..."
    
    if [[ -d "python" ]]; then
        cd python
        
        # Check for Python 3.10+
        if command -v python3 &> /dev/null; then
            PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
            log_info "Found Python $PYTHON_VERSION"
            
            if python3 -c "import sys; exit(0 if sys.version_info >= (3, 10) else 1)"; then
                log_success "Python version is compatible"
            else
                log_error "Python 3.10+ is required"
                cd ..
                return 1
            fi
        else
            log_error "Python 3 not found"
            cd ..
            return 1
        fi
        
        # Install uv if available, otherwise use pip
        if command -v uv &> /dev/null; then
            log_info "Using uv for Python dependency management..."
            uv sync --group dev --extra macos
        else
            log_info "Using pip for Python dependency management..."
            if [[ $PLATFORM == "macos" ]]; then
                pip3 install -r requirements-macos.txt
            else
                pip3 install -r requirements.txt
            fi
            pip3 install -r requirements-dev.txt
            pip3 install -e .
        fi
        
        log_success "Python environment ready"
        cd ..
    else
        log_warning "Python implementation not found"
    fi
}

# Rust environment setup
setup_rust() {
    log_info "Setting up Rust environment..."
    
    # Check for Rust
    if ! command -v rustc &> /dev/null; then
        log_warning "Rust not found. Installing..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi
    
    # Update Rust to latest stable
    log_info "Updating Rust toolchain..."
    rustup update stable
    
    # Install additional tools
    log_info "Installing Rust development tools..."
    rustup component add clippy rustfmt
    cargo install cargo-audit cargo-tarpaulin || log_warning "Failed to install some Rust tools"
    
    # Build Rust implementation
    if [[ -d "rust" ]]; then
        cd rust
        log_info "Building Rust implementation..."
        cargo build
        log_success "Rust environment ready"
        cd ..
    else
        log_warning "Rust implementation not found"
    fi
}

# Elixir/Phoenix environment setup
setup_elixir() {
    log_info "Setting up Elixir/Phoenix environment..."
    
    # Check for Elixir
    if ! command -v elixir &> /dev/null; then
        log_warning "Elixir not found. Installing..."
        case $PLATFORM in
            macos)
                brew install elixir
                ;;
            linux)
                if command -v apt-get &> /dev/null; then
                    wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb
                    sudo dpkg -i erlang-solutions_2.0_all.deb
                    sudo apt-get update
                    sudo apt-get install -y esl-erlang elixir
                    rm erlang-solutions_2.0_all.deb
                else
                    log_warning "Please install Elixir manually"
                    return 1
                fi
                ;;
            *)
                log_warning "Please install Elixir manually"
                return 1
                ;;
        esac
    fi
    
    # Setup Phoenix application
    if [[ -d "elixir" ]]; then
        cd elixir
        log_info "Installing Elixir dependencies..."
        mix deps.get
        
        log_info "Installing Node.js dependencies..."
        npm install --prefix assets
        
        log_info "Setting up database..."
        mix ecto.create 2>/dev/null || log_warning "Database might already exist"
        mix ecto.migrate
        
        log_success "Elixir/Phoenix environment ready"
        cd ..
    else
        log_warning "Elixir implementation not found"
    fi
}

# Objective-C/macOS setup
setup_objective_c() {
    if [[ $PLATFORM == "macos" && -d "objective-c" ]]; then
        log_info "Setting up Objective-C/macOS environment..."
        
        cd objective-c
        
        # Check if we can build
        if [[ -f "Makefile" ]]; then
            log_info "Building Objective-C widgets..."
            make clean || true
            make all
            log_success "Objective-C environment ready"
        else
            log_warning "Makefile not found in objective-c directory"
        fi
        
        cd ..
    elif [[ $PLATFORM != "macos" ]]; then
        log_warning "Objective-C implementation requires macOS"
    else
        log_warning "Objective-C implementation not found"
    fi
}

# Create unified development helper
create_dev_helper() {
    log_info "Creating development helper script..."
    
    cat > dev << 'EOF'
#!/bin/bash
# Selfspy Development Helper (New Structure)

case "$1" in
    "python")
        cd python
        exec "${@:2}"
        ;;
    "rust")
        cd rust
        exec "${@:2}"
        ;;
    "elixir"|"phoenix")
        cd elixir
        exec "${@:2}"
        ;;
    "objective-c"|"objc"|"macos")
        cd objective-c
        exec "${@:2}"
        ;;
    "test")
        echo "Running all tests..."
        ./shared/scripts/run-tests-new.sh
        ;;
    "build")
        echo "Building all implementations..."
        ./shared/scripts/build-all-new.sh
        ;;
    "docs")
        echo "Opening documentation..."
        open docs/README.md 2>/dev/null || echo "See docs/README.md"
        ;;
    *)
        echo "Selfspy Development Helper"
        echo "========================="
        echo ""
        echo "Usage: ./dev [language|command] [args...]"
        echo ""
        echo "Languages:"
        echo "  python                    - Switch to Python implementation"
        echo "  rust                      - Switch to Rust implementation"
        echo "  elixir|phoenix           - Switch to Elixir/Phoenix implementation"
        echo "  objective-c|objc|macos   - Switch to Objective-C implementation"
        echo ""
        echo "Commands:"
        echo "  test                     - Run all tests"
        echo "  build                    - Build all implementations"
        echo "  docs                     - Open documentation"
        echo ""
        echo "Examples:"
        echo "  ./dev python uv run selfspy start"
        echo "  ./dev rust cargo run --bin selfspy-gui"
        echo "  ./dev elixir mix phx.server"
        echo "  ./dev objective-c make all"
        echo "  ./dev test"
        echo "  ./dev build"
        ;;
esac
EOF
    chmod +x dev
    log_success "Development helper created: ./dev"
}

# Main setup process
main() {
    log_info "Starting Selfspy development environment setup..."
    
    # Install platform dependencies
    setup_platform_dependencies
    
    # Setup each implementation
    setup_python
    setup_rust
    setup_elixir
    setup_objective_c
    
    # Create development helper
    create_dev_helper
    
    log_success "Development environment setup complete!"
    
    echo ""
    log_info "🚀 Quick start commands:"
    echo "  ./dev python uv run selfspy start      # Python monitoring"
    echo "  ./dev rust cargo run --bin selfspy-gui # Rust GUI"
    echo "  ./dev elixir mix phx.server            # Phoenix web interface"
    echo "  ./dev objective-c make all             # macOS widgets"
    echo "  ./dev test                             # Run all tests"
    echo "  ./dev build                            # Build all implementations"
    echo ""
    log_info "📚 Next steps:"
    echo "  - Review docs/README.md for documentation"
    echo "  - Check language-specific README files"
    echo "  - Run ./dev test to verify everything works"
    echo "  - Explore ./dev [language] for specific commands"
}

# Run main function
main "$@"