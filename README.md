# Development Utilities

This repository contains various utilities and scripts to help with development tasks.

## Prerequisites

- Make

### Installing Make

#### macOS
```bash
# Using Homebrew
brew install make

# Or using Xcode Command Line Tools
xcode-select --install
```

#### Ubuntu
```bash
sudo apt-get update
sudo apt-get install make
```

## Quick Start

### Using Make Commands (Recommended)

The easiest way to manage the development environment is using the provided Make commands:

```bash
# Setup and start all services
make all

# Setup the development environment
make setup

# Start services
make up

# Stop all services
make down

# Reset the development environment
make reset

# Show available commands
make help
```
