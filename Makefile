.PHONY: all setup start up down reset

# Default target
all: setup start

# Setup the development environment
setup:
	@echo "Setting up development environment..."
	@if [ "$(shell uname)" = "Darwin" ]; then \
		./scripts/setup_macos.sh; \
	else \
		./scripts/setup_ubuntu.sh; \
	fi

# Start all services
up:
	@echo "Starting all services..."
	@./scripts/all_services.sh start

# Stop all services
down:
	@echo "Stopping all services..."
	@./scripts/all_services.sh stop

# Reset the development environment
reset:
	@echo "Resetting development environment..."
	@./scripts/all_services.sh reset

# Help command
help:
	@echo "Available commands:"
	@echo "  make all    - Setup and start all services"
	@echo "  make setup  - Setup the development environment"
	@echo "  make start  - Start all services"
	@echo "  make up     - Start services in detached mode"
	@echo "  make down   - Stop all services"
	@echo "  make reset  - Reset the development environment"
	@echo "  make help   - Show this help message" 
