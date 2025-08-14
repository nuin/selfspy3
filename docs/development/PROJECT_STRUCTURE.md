# Selfspy Project Structure Reorganization

## Current Issues

1. **Multiple Root-Level Implementations**: Python, Rust, Elixir/Phoenix, and macOS widgets all mixed at root level
2. **Inconsistent Documentation**: Multiple README files with overlapping content
3. **Build System Fragmentation**: Different build tools and configs scattered throughout
4. **Unclear Entry Points**: Hard to understand what's the "main" implementation
5. **Configuration Duplication**: Multiple config systems not clearly separated

## Proposed New Structure

```
selfspy/
├── README.md                          # Main project overview
├── CONTRIBUTING.md                    # Development guidelines
├── LICENSE                            # Project license
├── .gitignore                         # Global gitignore
├── docker-compose.yml                 # Multi-service development
│
├── docs/                              # Centralized documentation
│   ├── README.md                      # Documentation index
│   ├── installation/                  # Installation guides
│   │   ├── python.md
│   │   ├── rust.md
│   │   ├── phoenix.md
│   │   └── macos-widgets.md
│   ├── user-guides/                   # User documentation
│   │   ├── basic-usage.md
│   │   ├── advanced-features.md
│   │   └── troubleshooting.md
│   ├── development/                   # Developer docs
│   │   ├── architecture.md
│   │   ├── contributing.md
│   │   └── api-reference.md
│   └── examples/                      # Usage examples
│
├── implementations/                   # All language implementations
│   ├── python/                        # Original Python implementation
│   │   ├── README.md                  # Python-specific docs
│   │   ├── pyproject.toml
│   │   ├── requirements.txt
│   │   ├── requirements-dev.txt
│   │   ├── requirements-macos.txt
│   │   ├── src/selfspy/               # Main package
│   │   ├── tests/
│   │   ├── scripts/                   # Utility scripts
│   │   │   └── install.py
│   │   └── desktop-app/               # Desktop widget application
│   │
│   ├── rust/                          # Rust implementation
│   │   ├── README.md
│   │   ├── Cargo.toml                 # Workspace manifest
│   │   ├── Cargo.lock
│   │   ├── selfspy-core/              # Core library
│   │   ├── selfspy-cli/               # Command line interface
│   │   ├── selfspy-gui/               # GUI application
│   │   ├── selfspy-monitor/           # Background monitor
│   │   └── selfspy-stats/             # Statistics tools
│   │
│   ├── phoenix/                       # Elixir/Phoenix web implementation
│   │   ├── README.md
│   │   ├── mix.exs
│   │   ├── mix.lock
│   │   ├── config/
│   │   ├── lib/
│   │   ├── assets/
│   │   ├── priv/
│   │   ├── test/
│   │   └── c_src/                     # Native extensions
│   │
│   └── macos-widgets/                 # macOS-specific widgets
│       ├── README.md
│       ├── SelfspyWidgets.xcodeproj/
│       ├── Sources/                   # Organized source files
│       ├── Resources/
│       ├── Scripts/                   # Build scripts
│       └── Documentation/
│
├── shared/                            # Shared resources
│   ├── schemas/                       # Database schemas
│   │   ├── sqlite.sql
│   │   ├── postgresql.sql
│   │   └── migrations/
│   ├── configs/                       # Configuration templates
│   │   ├── selfspy.toml.example
│   │   ├── logging.yaml
│   │   └── systemd/
│   └── scripts/                       # Cross-platform scripts
│       ├── setup-dev-env.sh
│       ├── run-tests.sh
│       └── build-all.sh
│
├── tools/                             # Development and deployment tools
│   ├── docker/                        # Container configurations
│   │   ├── Dockerfile.python
│   │   ├── Dockerfile.rust
│   │   ├── Dockerfile.phoenix
│   │   └── docker-compose.dev.yml
│   ├── ci/                            # CI/CD configurations
│   │   ├── github-actions/
│   │   └── scripts/
│   └── deployment/                    # Deployment configurations
│       ├── kubernetes/
│       ├── systemd/
│       └── homebrew/
│
└── examples/                          # Usage examples and demos
    ├── basic-monitoring/
    ├── custom-analytics/
    ├── integration-examples/
    └── api-usage/
```

## Implementation Plan

### Phase 1: Create New Structure
1. Create new directory layout
2. Move Python implementation to `implementations/python/`
3. Move Rust implementation to `implementations/rust/`
4. Move Phoenix implementation to `implementations/phoenix/`
5. Move macOS widgets to `implementations/macos-widgets/`

### Phase 2: Consolidate Documentation
1. Merge all README files into organized docs
2. Create unified installation guide
3. Standardize development documentation
4. Add cross-references between implementations

### Phase 3: Standardize Build Systems
1. Create unified development environment setup
2. Standardize configuration across implementations
3. Create shared CI/CD pipeline
4. Add cross-implementation testing

### Phase 4: Improve Developer Experience
1. Add development containers
2. Create unified CLI for all implementations
3. Add integration testing suite
4. Improve debugging and monitoring tools

## Benefits

1. **Clear Separation**: Each implementation has its own space
2. **Unified Documentation**: Single source of truth for docs
3. **Better Onboarding**: Clear entry points for different use cases
4. **Consistent Development**: Standardized tools and processes
5. **Easier Maintenance**: Logical organization makes updates easier
6. **Cross-Implementation Sharing**: Common resources in shared directory

## Migration Strategy

- Keep all current functionality working during migration
- Use symlinks temporarily to maintain compatibility
- Update all build scripts and CI/CD
- Add deprecation notices for old paths
- Complete migration in stages to minimize disruption