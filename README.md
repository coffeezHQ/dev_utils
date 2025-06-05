# Development Utilities

This repository contains various utilities and scripts to help with development tasks.

## Prerequisites

- Go 1.21 or later
- Docker and Docker Compose
- Make (for using Make commands)

## Quick Start

### Using Make Commands (Recommended)

The easiest way to manage the development environment is using the provided Make commands:

```bash
# Setup and start all services
make all

# Setup the development environment
make setup

# Start services in detached mode
make up

# Stop all services
make down

# Reset the development environment
make reset

# Show available commands
make help
```
