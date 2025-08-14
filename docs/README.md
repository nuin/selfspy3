# Selfspy Documentation

Welcome to the comprehensive documentation for Selfspy, a cross-platform activity monitoring suite.

## 📚 Documentation Index

### Getting Started
- **[Installation Guides](installation/)** - Platform and implementation-specific setup
- **[Quick Start](user-guides/basic-usage.md)** - Get up and running in minutes
- **[Choosing an Implementation](user-guides/choosing-implementation.md)** - Python vs Rust vs Phoenix vs macOS Widgets

### User Guides
- **[Basic Usage](user-guides/basic-usage.md)** - Essential commands and workflows
- **[Advanced Features](user-guides/advanced-features.md)** - Power user capabilities
- **[Privacy & Security](user-guides/privacy-security.md)** - Data protection and configuration
- **[Troubleshooting](user-guides/troubleshooting.md)** - Common issues and solutions

### Installation
- **[Python Installation](installation/python.md)** - Original implementation setup
- **[Rust Installation](installation/rust.md)** - High-performance native GUI
- **[Phoenix Installation](installation/phoenix.md)** - Web-based dashboard
- **[macOS Widgets Installation](installation/macos-widgets.md)** - Desktop widgets

### Development
- **[Architecture Overview](development/architecture.md)** - System design and components
- **[Contributing Guide](development/contributing.md)** - How to contribute to the project
- **[API Reference](development/api-reference.md)** - Programming interfaces
- **[Building from Source](development/building.md)** - Development environment setup

### Examples
- **[Basic Monitoring](examples/basic-monitoring.md)** - Simple usage examples
- **[Custom Analytics](examples/custom-analytics.md)** - Data analysis scripts
- **[Integration Examples](examples/integration-examples.md)** - Third-party integrations
- **[API Usage](examples/api-usage.md)** - Programming with Selfspy

## 🎯 Quick Navigation

### By Use Case

**Personal Productivity**
- [Basic Usage Guide](user-guides/basic-usage.md)
- [Python Installation](installation/python.md)
- [Desktop Widgets](installation/macos-widgets.md)

**Development Teams**  
- [Phoenix Web Dashboard](installation/phoenix.md)
- [Team Analytics](user-guides/advanced-features.md#team-analytics)
- [API Integration](examples/api-usage.md)

**Research & Analytics**
- [Data Export](user-guides/advanced-features.md#data-export)
- [Custom Analytics](examples/custom-analytics.md)
- [API Reference](development/api-reference.md)

**System Administration**
- [Rust Implementation](installation/rust.md)
- [Service Deployment](development/building.md#deployment)
- [Security Configuration](user-guides/privacy-security.md)

### By Platform

**macOS Users**
- [Python Installation](installation/python.md) (Recommended)
- [Desktop Widgets](installation/macos-widgets.md)
- [Permissions Setup](user-guides/troubleshooting.md#macos-permissions)

**Linux Users**
- [Python Installation](installation/python.md)
- [Rust Installation](installation/rust.md)
- [Phoenix Installation](installation/phoenix.md)

**Windows Users**
- [Rust Installation](installation/rust.md) (Recommended)
- [Python Installation](installation/python.md)

### By Technical Level

**Beginners**
- [Quick Start](user-guides/basic-usage.md)
- [Python Installation](installation/python.md)
- [Troubleshooting](user-guides/troubleshooting.md)

**Intermediate**
- [Advanced Features](user-guides/advanced-features.md)
- [Phoenix Dashboard](installation/phoenix.md)
- [Configuration](user-guides/privacy-security.md)

**Advanced**
- [API Reference](development/api-reference.md)
- [Contributing](development/contributing.md)
- [Architecture](development/architecture.md)

## 🔧 Implementation Comparison

| Feature | Python | Rust | Phoenix | macOS Widgets |
|---------|--------|------|---------|---------------|
| **Best For** | General use | Performance | Web dashboard | Desktop integration |
| **Resource Usage** | Moderate | Low | Moderate | Low |
| **Setup Complexity** | Easy | Moderate | Advanced | Easy |
| **Cross-Platform** | ✅ Full | ✅ Full | ✅ Full | ❌ macOS only |
| **GUI** | CLI + Widgets | Native GUI | Web interface | Desktop widgets |
| **Multi-User** | ❌ | ❌ | ✅ | ❌ |
| **Real-Time** | ❌ | ✅ | ✅ | ✅ |
| **Customization** | ✅ High | ✅ Moderate | ✅ High | ✅ Moderate |

## 📖 Documentation Standards

### Writing Guidelines

- **Clear and Concise**: Use simple language and avoid jargon
- **Example-Driven**: Provide practical examples for all features
- **Cross-Referenced**: Link between related documentation
- **Platform-Specific**: Include platform-specific instructions where needed

### Code Examples

All code examples should be:
- **Working**: Tested and functional
- **Commented**: Explain non-obvious parts
- **Complete**: Include necessary imports and setup
- **Safe**: Use best practices for security and privacy

### Screenshots

When including screenshots:
- Use consistent themes and settings
- Highlight relevant UI elements
- Include captions with context
- Provide alternative text descriptions

## 🤝 Contributing to Documentation

We welcome documentation improvements! See our [Contributing Guide](development/contributing.md) for:

- Writing style guidelines
- Documentation review process
- Building docs locally
- Submitting improvements

## 📞 Getting Help

- **GitHub Issues**: [Bug reports and feature requests](https://github.com/selfspy/selfspy3/issues)
- **GitHub Discussions**: [Questions and community support](https://github.com/selfspy/selfspy3/discussions)
- **Security Issues**: [security@selfspy.dev](mailto:security@selfspy.dev)

## 🔗 External Resources

- **Project Website**: [selfspy.dev](https://selfspy.dev)
- **GitHub Repository**: [github.com/selfspy/selfspy3](https://github.com/selfspy/selfspy3)
- **Release Notes**: [Changelog](https://github.com/selfspy/selfspy3/releases)

---

**Documentation Last Updated**: {{ current_date }}
**Selfspy Version**: {{ current_version }}