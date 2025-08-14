# Improved Selfspy Project Structure

## Current Issues with Mixed Languages

The current structure still has languages mixed together and needs better separation:

- Xcode project mixed with other files
- Python and desktop app files scattered
- Build systems not clearly separated by language
- No clear language-based organization

## New Language-Based Structure

```
selfspy/
├── README.md                          # Main project overview
├── CONTRIBUTING.md                    # Contribution guidelines
├── LICENSE                            # Project license
├── .gitignore                         # Global gitignore
├── docker-compose.yml                 # Multi-service development
│
├── docs/                              # Centralized documentation
│   ├── README.md                      # Documentation index
│   ├── installation/                  # Installation guides
│   ├── user-guides/                   # User documentation
│   ├── development/                   # Developer documentation
│   ├── api/                           # API documentation
│   └── examples/                      # Usage examples
│
├── python/                            # Python implementation
│   ├── README.md                      # Python-specific documentation
│   ├── pyproject.toml                 # Python project configuration
│   ├── requirements.txt               # Python dependencies
│   ├── requirements-dev.txt           # Development dependencies
│   ├── requirements-macos.txt         # macOS-specific dependencies
│   ├── install.py                     # Python installer script
│   ├── src/                           # Python source code
│   │   └── selfspy/                   # Main package
│   ├── tests/                         # Python tests
│   ├── scripts/                       # Python utility scripts
│   └── desktop-app/                   # Python desktop application
│
├── rust/                              # Rust implementation
│   ├── README.md                      # Rust-specific documentation
│   ├── Cargo.toml                     # Rust workspace configuration
│   ├── Cargo.lock                     # Dependency lock file
│   ├── src/                           # Rust source (if single crate)
│   ├── crates/                        # Multiple Rust crates
│   │   ├── selfspy-core/              # Core library
│   │   ├── selfspy-gui/               # GUI application
│   │   ├── selfspy-cli/               # Command line interface
│   │   └── selfspy-daemon/            # Background daemon
│   ├── tests/                         # Integration tests
│   ├── benches/                       # Benchmarks
│   └── examples/                      # Rust examples
│
├── elixir/                            # Elixir/Phoenix implementation
│   ├── README.md                      # Elixir-specific documentation
│   ├── mix.exs                        # Elixir project configuration
│   ├── mix.lock                       # Dependency lock file
│   ├── config/                        # Phoenix configuration
│   ├── lib/                           # Elixir source code
│   ├── test/                          # Elixir tests
│   ├── assets/                        # Frontend assets
│   ├── priv/                          # Private files (migrations, etc.)
│   └── c_src/                         # C NIFs
│
├── objective-c/                       # Objective-C/macOS implementation
│   ├── README.md                      # Objective-C specific documentation
│   ├── SelfspyWidgets.xcodeproj/      # Xcode project
│   ├── SelfspyWidgets/                # Source code
│   │   ├── Sources/                   # Organized source files
│   │   │   ├── Core/                  # Core functionality
│   │   │   ├── Widgets/               # Widget implementations
│   │   │   ├── UI/                    # User interface
│   │   │   └── Utils/                 # Utilities
│   │   ├── Resources/                 # Assets and resources
│   │   └── Info.plist                 # App information
│   ├── Tests/                         # XCTest unit tests
│   ├── Scripts/                       # Build and deployment scripts
│   │   ├── build.sh                   # Build script
│   │   └── create_app_bundle.sh       # App bundling
│   └── Documentation/                 # Objective-C specific docs
│
├── shared/                            # Shared resources across languages
│   ├── schemas/                       # Database schemas
│   │   ├── sqlite/                    # SQLite schemas
│   │   ├── postgresql/                # PostgreSQL schemas
│   │   └── migrations/                # Migration scripts
│   ├── configs/                       # Configuration templates
│   │   ├── selfspy.toml.example       # Configuration example
│   │   └── logging.yaml               # Logging configuration
│   ├── data/                          # Sample data and fixtures
│   └── scripts/                       # Cross-language scripts
│       ├── setup-dev-env.sh           # Development setup
│       ├── run-tests.sh               # Test runner
│       ├── build-all.sh               # Build script
│       └── deploy.sh                  # Deployment script
│
├── tools/                             # Development and deployment tools
│   ├── docker/                        # Container configurations
│   │   ├── Dockerfile.python          # Python container
│   │   ├── Dockerfile.rust            # Rust container
│   │   ├── Dockerfile.elixir          # Elixir container
│   │   └── docker-compose.dev.yml     # Development compose
│   ├── ci/                            # CI/CD configurations
│   │   ├── github-actions/            # GitHub Actions workflows
│   │   ├── scripts/                   # CI scripts
│   │   └── templates/                 # CI templates
│   ├── deployment/                    # Deployment configurations
│   │   ├── kubernetes/                # K8s manifests
│   │   ├── systemd/                   # Systemd services
│   │   └── homebrew/                  # Homebrew formula
│   └── dev/                           # Development utilities
│       ├── lint-all.sh                # Linting script
│       ├── format-all.sh              # Code formatting
│       └── clean-all.sh               # Cleanup script
│
└── examples/                          # Usage examples by language
    ├── python/                        # Python examples
    ├── rust/                          # Rust examples
    ├── elixir/                        # Elixir examples
    ├── objective-c/                   # Objective-C examples
    └── integrations/                  # Cross-language integrations
```

## Key Improvements

### 1. Clear Language Separation
- Each language gets its own top-level directory
- Language-specific build tools and configurations
- No mixing of different language files
- Clear ownership and responsibility

### 2. Consistent Structure Within Languages
- Each language follows its ecosystem conventions
- Standard directories for source, tests, docs
- Language-specific tooling in proper locations

### 3. Proper Xcode Project Organization
- Xcode project moved to `objective-c/` directory
- Source code organized in logical subdirectories
- Build scripts properly located with the project
- Tests and documentation co-located

### 4. Shared Resources
- Common schemas and configurations in `shared/`
- Cross-language development tools
- Deployment and CI/CD configurations

### 5. Examples and Documentation
- Language-specific examples
- Clear documentation hierarchy
- Cross-references between implementations

## Migration Plan

### Phase 1: Create New Structure
1. Create new language-based directories
2. Move files to appropriate language folders
3. Update build configurations
4. Adjust import paths and references

### Phase 2: Update Documentation
1. Update all README files
2. Fix cross-references
3. Update installation guides
4. Revise development documentation

### Phase 3: Update Tooling
1. Modify build scripts for new paths
2. Update CI/CD configurations
3. Adjust development helper scripts
4. Update Docker configurations

### Phase 4: Testing and Validation
1. Test all build processes
2. Verify documentation accuracy
3. Ensure examples work
4. Validate cross-language compatibility

## Benefits

1. **Clear Ownership**: Each language implementation is self-contained
2. **Better Maintenance**: Easier to find and modify language-specific code
3. **Ecosystem Compliance**: Each language follows its conventions
4. **Scalability**: Easy to add new language implementations
5. **Developer Experience**: Clear entry points for each technology
6. **Professional Structure**: Industry-standard organization