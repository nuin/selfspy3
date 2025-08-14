#!/bin/bash
set -euo pipefail

# Selfspy Unified Test Runner
# Runs tests for all implementations

echo "🧪 Running Selfspy test suite..."

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

# Track test results
PYTHON_TESTS_PASSED=false
RUST_TESTS_PASSED=false
PHOENIX_TESTS_PASSED=false
TOTAL_TESTS=0
PASSED_TESTS=0

# Python tests
run_python_tests() {
    if [[ -d "python" ]]; then
        log_info "Running Python tests..."
        cd python
        
        if command -v uv &> /dev/null; then
            if uv run pytest --tb=short; then
                log_success "Python tests passed"
                PYTHON_TESTS_PASSED=true
                PASSED_TESTS=$((PASSED_TESTS + 1))
            else
                log_error "Python tests failed"
            fi
        elif command -v pytest &> /dev/null; then
            if pytest --tb=short; then
                log_success "Python tests passed"
                PYTHON_TESTS_PASSED=true
                PASSED_TESTS=$((PASSED_TESTS + 1))
            else
                log_error "Python tests failed"
            fi
        else
            log_warning "pytest not found, skipping Python tests"
        fi
        
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        cd ../..
    else
        log_warning "Python implementation not found"
    fi
}

# Rust tests
run_rust_tests() {
    if [[ -d "rust" ]]; then
        log_info "Running Rust tests..."
        cd rust
        
        if command -v cargo &> /dev/null; then
            if cargo test --all; then
                log_success "Rust tests passed"
                RUST_TESTS_PASSED=true
                PASSED_TESTS=$((PASSED_TESTS + 1))
            else
                log_error "Rust tests failed"
            fi
        else
            log_warning "cargo not found, skipping Rust tests"
        fi
        
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        cd ../..
    else
        log_warning "Rust implementation not found"
    fi
}

# Phoenix tests
run_phoenix_tests() {
    if [[ -d "elixir" ]]; then
        log_info "Running Phoenix tests..."
        cd elixir
        
        if command -v mix &> /dev/null; then
            # Set test environment
            export MIX_ENV=test
            
            # Ensure test database exists
            mix ecto.create -q 2>/dev/null || true
            mix ecto.migrate -q
            
            if mix test; then
                log_success "Phoenix tests passed"
                PHOENIX_TESTS_PASSED=true
                PASSED_TESTS=$((PASSED_TESTS + 1))
            else
                log_error "Phoenix tests failed"
            fi
        else
            log_warning "mix not found, skipping Phoenix tests"
        fi
        
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        cd ../..
    else
        log_warning "Phoenix implementation not found"
    fi
}

# Code quality checks
run_quality_checks() {
    log_info "Running code quality checks..."
    
    # Python quality checks
    if [[ -d "python" && $PYTHON_TESTS_PASSED == true ]]; then
        cd python
        log_info "Python code quality..."
        
        if command -v uv &> /dev/null; then
            # Format check
            if uv run black --check src/ tests/ 2>/dev/null; then
                log_success "Python formatting OK"
            else
                log_warning "Python formatting issues found"
            fi
            
            # Import sorting check
            if uv run isort --check-only src/ tests/ 2>/dev/null; then
                log_success "Python import sorting OK"
            else
                log_warning "Python import sorting issues found"
            fi
            
            # Linting
            if uv run ruff check src/ tests/ 2>/dev/null; then
                log_success "Python linting OK"
            else
                log_warning "Python linting issues found"
            fi
        fi
        cd ../..
    fi
    
    # Rust quality checks
    if [[ -d "rust" && $RUST_TESTS_PASSED == true ]]; then
        cd rust
        log_info "Rust code quality..."
        
        if command -v cargo &> /dev/null; then
            # Format check
            if cargo fmt --check 2>/dev/null; then
                log_success "Rust formatting OK"
            else
                log_warning "Rust formatting issues found"
            fi
            
            # Linting
            if cargo clippy --all-targets --all-features -- -D warnings 2>/dev/null; then
                log_success "Rust linting OK"
            else
                log_warning "Rust linting issues found"
            fi
        fi
        cd ../..
    fi
    
    # Phoenix quality checks
    if [[ -d "elixir" && $PHOENIX_TESTS_PASSED == true ]]; then
        cd elixir
        log_info "Phoenix code quality..."
        
        if command -v mix &> /dev/null; then
            # Format check
            if mix format --check-formatted 2>/dev/null; then
                log_success "Elixir formatting OK"
            else
                log_warning "Elixir formatting issues found"
            fi
            
            # Credo linting (if available)
            if mix credo --strict 2>/dev/null; then
                log_success "Elixir linting OK"
            else
                log_warning "Elixir linting issues found (or credo not installed)"
            fi
        fi
        cd ../..
    fi
}

# Integration tests
run_integration_tests() {
    log_info "Running integration tests..."
    
    # Test that basic commands work (if implementations are built)
    if [[ -d "python" ]]; then
        cd python
        if command -v uv &> /dev/null; then
            if uv run python -c "import src.selfspy; print('Python import OK')"; then
                log_success "Python integration OK"
            else
                log_warning "Python integration issues"
            fi
        fi
        cd ../..
    fi
    
    if [[ -d "rust" ]]; then
        cd rust
        if command -v cargo &> /dev/null; then
            if cargo check --all; then
                log_success "Rust integration OK"
            else
                log_warning "Rust integration issues"
            fi
        fi
        cd ../..
    fi
    
    if [[ -d "elixir" ]]; then
        cd elixir
        if command -v mix &> /dev/null; then
            if mix compile; then
                log_success "Phoenix integration OK"
            else
                log_warning "Phoenix integration issues"
            fi
        fi
        cd ../..
    fi
}

# Main test execution
main() {
    log_info "Starting comprehensive test suite..."
    
    # Change to project root if needed
    if [[ ! -f "CLAUDE.md" ]]; then
        log_error "Please run this script from the project root directory"
        exit 1
    fi
    
    # Run implementation tests
    run_python_tests
    run_rust_tests
    run_phoenix_tests
    
    # Run quality checks
    run_quality_checks
    
    # Run integration tests
    run_integration_tests
    
    # Print summary
    echo ""
    echo "🏁 Test Summary"
    echo "==============="
    
    if [[ $TOTAL_TESTS -eq 0 ]]; then
        log_warning "No test suites found"
        exit 1
    fi
    
    echo "Test suites run: $TOTAL_TESTS"
    echo "Test suites passed: $PASSED_TESTS"
    echo "Test suites failed: $((TOTAL_TESTS - PASSED_TESTS))"
    
    echo ""
    echo "Implementation Results:"
    [[ -d "python" ]] && echo "  Python: $([ $PYTHON_TESTS_PASSED == true ] && echo "✅ PASSED" || echo "❌ FAILED")"
    [[ -d "rust" ]] && echo "  Rust: $([ $RUST_TESTS_PASSED == true ] && echo "✅ PASSED" || echo "❌ FAILED")"
    [[ -d "elixir" ]] && echo "  Phoenix: $([ $PHOENIX_TESTS_PASSED == true ] && echo "✅ PASSED" || echo "❌ FAILED")"
    
    echo ""
    if [[ $PASSED_TESTS -eq $TOTAL_TESTS ]]; then
        log_success "All tests passed! 🎉"
        exit 0
    else
        log_error "Some tests failed"
        exit 1
    fi
}

# Handle command line arguments
case "${1:-all}" in
    "python")
        run_python_tests
        ;;
    "rust")
        run_rust_tests
        ;;
    "phoenix")
        run_phoenix_tests
        ;;
    "quality")
        run_quality_checks
        ;;
    "integration")
        run_integration_tests
        ;;
    "all"|*)
        main
        ;;
esac