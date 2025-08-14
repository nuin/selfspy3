# Selfspy - Kotlin Implementation

A complete implementation of Selfspy in [Kotlin](https://kotlinlang.org/), showcasing modern JVM development with coroutines, null safety, and expressive syntax.

## Features

- **Coroutines**: Asynchronous programming with structured concurrency
- **Null Safety**: Compile-time null safety prevents runtime errors
- **Type Inference**: Concise code with powerful type system
- **Java Interop**: Seamless integration with Java ecosystem
- **Modern Syntax**: Expressive, readable code with functional programming features
- **Excellent Tooling**: First-class IDE support and debugging

## Requirements

- JDK 17 or later
- Kotlin 1.9.20+ (included via Gradle)
- Platform-specific permissions for activity monitoring

## Building and Running

### Using Gradle (Recommended)

```bash
# Build the application
./gradlew build

# Run directly with Gradle
./gradlew run --args='help'
./gradlew run --args='start'
./gradlew run --args='stats --days 7'

# Build fat JAR
./gradlew shadowJar

# Run the JAR
java -jar build/libs/selfspy-1.0.0-all.jar help
```

### Using JAR

```bash
# After building
java -jar build/libs/selfspy-1.0.0-all.jar start
java -jar build/libs/selfspy-1.0.0-all.jar stats --days 30 --json
java -jar build/libs/selfspy-1.0.0-all.jar export --format csv --output activity.csv
```

## Usage Examples

```bash
# Start monitoring
./gradlew run --args='start'
java -jar selfspy.jar start

# Start with privacy options
./gradlew run --args='start --no-text --debug'
java -jar selfspy.jar start --no-text --debug

# View statistics
./gradlew run --args='stats --days 7'
java -jar selfspy.jar stats --days 7 --json

# Export data
./gradlew run --args='export --format csv --output activity.csv'
java -jar selfspy.jar export --format sql --days 30

# Check system permissions
./gradlew run --args='check'
java -jar selfspy.jar check
```

## Implementation Highlights

- **Modern Architecture**: Clean separation with sealed classes and data classes
- **Coroutines**: Structured concurrency for efficient async operations
- **Null Safety**: Compile-time protection against null pointer exceptions
- **Type System**: Powerful type inference with explicit nullability
- **Error Handling**: Sealed exception hierarchy with proper error propagation
- **JSON Serialization**: Built-in kotlinx-serialization for data export
- **Database Integration**: JDBC with SQLite for local storage
- **Logging**: Structured logging with SLF4J and Logback
- **Testing**: JUnit 5 integration with coroutine testing support

## Project Structure

```
kotlin/
├── build.gradle.kts              # Build configuration
├── gradle.properties             # Gradle settings
├── gradlew                       # Gradle wrapper (Unix)
├── src/main/kotlin/com/selfspy/
│   └── SelfspyMain.kt           # Main application
├── src/main/resources/
│   └── logback.xml              # Logging configuration
└── README.md                    # This file
```

## Architecture

The Kotlin implementation demonstrates:

1. **Sealed Classes**: Type-safe command modeling with `Command` hierarchy
2. **Data Classes**: Immutable data structures with automatic methods
3. **Object Singletons**: Platform detection and configuration management
4. **Coroutines**: Structured concurrency for monitoring loop
5. **Extension Functions**: Utility functions for formatting and display
6. **Null Safety**: Optional types and safe calls throughout
7. **Exception Handling**: Custom exception hierarchy with sealed classes
8. **Functional Programming**: Higher-order functions and lambda expressions

## Dependencies

- **Kotlin Standard Library**: Core language features
- **Kotlinx Coroutines**: Asynchronous programming
- **Kotlinx Serialization**: JSON handling
- **Kotlinx CLI**: Command-line argument parsing
- **SQLite JDBC**: Database connectivity
- **SLF4J + Logback**: Structured logging
- **JUnit 5**: Testing framework

This implementation showcases Kotlin's strengths in building robust, maintainable JVM applications with modern language features and excellent interoperability with the Java ecosystem.