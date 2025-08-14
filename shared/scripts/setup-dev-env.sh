#!/bin/bash
set -euo pipefail

# Selfspy Development Environment Setup
# Sets up development environment for all implementations

echo "🔧 Setting up Selfspy development environment..."

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
if [[ ! -f "PROJECT_STRUCTURE.md" ]]; then
    log_error "Please run this script from the project root directory"
    exit 1
fi

# Create necessary directories
log_info "Creating development directories..."
mkdir -p {build,dist,tmp}
log_success "Directories created"

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
            brew install git postgresql pkg-config
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
                    curl
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
                    curl
            elif command -v pacman &> /dev/null; then
                log_info "Using pacman package manager..."
                sudo pacman -Syu --noconfirm \
                    base-devel \
                    git \
                    pkg-config \
                    libx11 \
                    libxtst \
                    libxext \
                    postgresql \
                    curl
            else
                log_warning "Unknown package manager. Please install dependencies manually:"
                log_info "  - build-essential or equivalent"
                log_info "  - git, pkg-config, curl"
                log_info "  - X11 development headers"
                log_info "  - PostgreSQL"
            fi
            log_success "Linux dependencies installed"
            ;;
            
        windows)
            log_info "Setting up Windows dependencies..."
            log_warning "Windows setup requires manual installation of:"
            log_info "  - Visual Studio Build Tools or MinGW"
            log_info "  - Git for Windows"
            log_info "  - PostgreSQL"
            log_info "Please install these manually and re-run this script"
            ;;
            
        *)
            log_warning "Unknown platform. Please install dependencies manually"
            ;;
    esac
}

# Python environment setup
setup_python() {
    log_info "Setting up Python environment..."
    
    cd implementations/python
    
    # Check for Python 3.10+
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
        log_info "Found Python $PYTHON_VERSION"
        
        if python3 -c "import sys; exit(0 if sys.version_info >= (3, 10) else 1)"; then
            log_success "Python version is compatible"
        else
            log_error "Python 3.10+ is required"
            cd ../..
            return 1
        fi
    else
        log_error "Python 3 not found"
        cd ../..
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
    cd ../..
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
    cargo install cargo-audit cargo-tarpaulin
    
    # Build Rust implementation
    cd implementations/rust
    log_info "Building Rust implementation..."
    cargo build
    log_success "Rust environment ready"
    cd ../..
}

# Elixir/Phoenix environment setup
setup_phoenix() {
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
    
    # Check for Node.js (required for Phoenix assets)
    if ! command -v node &> /dev/null; then
        log_warning "Node.js not found. Installing..."
        case $PLATFORM in
            macos)
                brew install node
                ;;
            linux)
                curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
                sudo apt-get install -y nodejs
                ;;
            *)
                log_warning "Please install Node.js manually"
                return 1
                ;;
        esac
    fi
    
    # Setup Phoenix application
    cd implementations/phoenix
    log_info "Installing Elixir dependencies..."
    mix deps.get
    
    log_info "Installing Node.js dependencies..."
    npm install --prefix assets
    
    log_info "Setting up database..."
    mix ecto.create 2>/dev/null || log_warning "Database might already exist"
    mix ecto.migrate
    
    log_success "Phoenix environment ready"
    cd ../..
}

# Main setup process
main() {
    log_info "Starting Selfspy development environment setup..."
    
    # Install platform dependencies
    setup_platform_dependencies
    
    # Setup each implementation based on availability and user choice
    if [[ -d "implementations/python" ]]; then
        if setup_python; then
            log_success "Python implementation ready"
        else
            log_warning "Python setup failed"
        fi
    fi
    
    if [[ -d "implementations/rust" ]]; then
        if setup_rust; then
            log_success "Rust implementation ready"
        else
            log_warning "Rust setup failed"
        fi
    fi
    
    if [[ -d "implementations/phoenix" ]]; then
        if setup_phoenix; then
            log_success "Phoenix implementation ready"
        else
            log_warning "Phoenix setup failed"
        fi
    fi
    
    # Create unified development commands
    log_info "Creating development shortcuts..."
    cat > dev << 'EOF'
#!/bin/bash
# Selfspy Development Helper

case "$1" in
    "python")
        cd implementations/python
        exec "${@:2}"
        ;;
    "rust")
        cd implementations/rust
        exec "${@:2}"
        ;;
    "phoenix")
        cd implementations/phoenix
        exec "${@:2}"
        ;;
    "test")
        echo "Running all tests..."
        ./shared/scripts/run-tests.sh
        ;;
    "build")
        echo "Building all implementations..."
        ./shared/scripts/build-all.sh
        ;;
    *)
        echo "Usage: ./dev [python|rust|phoenix|test|build] [command...]"
        echo "Examples:"
        echo "  ./dev python uv run selfspy start"
        echo "  ./dev rust cargo run --bin selfspy-gui"
        echo "  ./dev phoenix mix phx.server"
        echo "  ./dev test"
        echo "  ./dev build"
        ;;
esac
EOF
    chmod +x dev
    
    log_success "Development environment setup complete!"
    
    echo ""
    log_info "🚀 Quick start commands:"
    echo "  ./dev python uv run selfspy start    # Python monitoring"
    echo "  ./dev rust cargo run --bin selfspy-gui  # Rust GUI"
    echo "  ./dev phoenix mix phx.server         # Phoenix web interface"
    echo "  ./dev test                           # Run all tests"
    echo "  ./dev build                          # Build all implementations"
    echo ""
    log_info "📚 Next steps:"
    echo "  - Review docs/README.md for documentation"
    echo "  - Check implementations/*/README.md for specific guides"
    echo "  - Run ./dev test to verify everything works"
}

# Run main function
main "$@"