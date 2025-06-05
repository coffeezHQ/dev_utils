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

# Start all services
make start

# Start services in detached mode
make up

# Stop all services
make down

# Reset the development environment
make reset

# Show available commands
make help
```

### Manual Setup

If you prefer to run scripts directly:

1. First, run the appropriate setup script for your OS:
   ```bash
   # For macOS
   ./scripts/setup_mac.sh

   # For Ubuntu
   ./scripts/setup_ubuntu.sh
   ```

2. Start all services:
   ```bash
   ./scripts/all_services.sh
   ```

3. To start services in detached mode:
   ```bash
   ./scripts/all_services.sh --detached
   ```

4. To stop all services:
   ```bash
   ./scripts/all_services.sh --stop
   ```

5. To reset the environment:
   ```bash
   ./scripts/all_services.sh --reset
   ```

## Available Scripts

### `scripts/all_services.sh`

This script manages all development services. It can:
- Start all services
- Start services in detached mode
- Stop all services
- Reset the environment

Usage:
```bash
./scripts/all_services.sh [--detached|--stop|--reset]
```

### `scripts/setup_mac.sh`

Sets up the development environment on macOS. This script:
- Installs required dependencies
- Sets up necessary configurations
- Creates required directories

### `scripts/setup_ubuntu.sh`

Sets up the development environment on Ubuntu. This script:
- Installs required dependencies
- Sets up necessary configurations
- Creates required directories

## Directory Structure

```
.
├── scripts/
│   ├── all_services.sh
│   ├── setup_mac.sh
│   └── setup_ubuntu.sh
├── Makefile
└── README.md
```

## Troubleshooting

If you encounter any issues:

1. Check if all prerequisites are installed
2. Ensure you have the necessary permissions
3. Try resetting the environment using `make reset` or `./scripts/all_services.sh --reset`
4. Check the logs in the `logs` directory for any error messages

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request
