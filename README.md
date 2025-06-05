# Dev Utils

A collection of utility scripts for development environment setup and management.

## Prerequisites

- macOS (tested on macOS 22.3.0) or Ubuntu (tested on Ubuntu 22.04 LTS)
- Homebrew (for macOS)
- Node.js (v18 or later)
- Docker Desktop
- Go (v1.21 or later)

## Quick Start

1. Clone this repository:
```bash
git clone git@github.com:coffeezhq/dev_utils.git
cd dev_utils
```

2. Create a `.env` file with the following content:
```bash
KAFKA_INSTALL_PATH=/opt/kafka
COFFEEZ_ROOT=$HOME/Go/src/github.com/coffeezHQ
```

3. Run the setup script:
```bash
./scripts/start_all_services.sh setup
```

4. Start all services:
```bash
./scripts/start_all_services.sh start
```

## Available Commands

### Setup Environment
```bash
./scripts/start_all_services.sh setup
```
This command will:
- Create the COFFEEZ_ROOT directory if it doesn't exist
- Clone all required repositories if they don't exist
- Install required services only if they're not already installed
- Set up necessary environment variables

### Start All Services
```bash
./scripts/start_all_services.sh start
```
This command will:
- Start MySQL
- Start Kafka and Zookeeper
- Start ClickHouse
- Start Kafka Consumer
- Run DB Migrations
- Start Creators Studio API
- Start Creators Studio Frontend

### Stop All Services
```bash
./scripts/start_all_services.sh stop
```
This command will:
- Stop all running services
- Clean up any remaining processes

### Reset Project Services
```bash
./scripts/start_all_services.sh reset
```
This command will:
- Stop only project services (Kafka Consumer, DB Migrations, Creators Studio API, and Frontend)
- Clear all logs
- Pull latest code from all repositories
- Restart project services with latest code
- Install/update dependencies

Note: This command does not affect infrastructure services (MySQL, Kafka, Zookeeper, ClickHouse).

### Check Service Logs
```bash
./scripts/start_all_services.sh logs
```
This command will:
- Show logs for all running services
- Highlight any errors in red
- Show the last 50 lines of each log file

## Troubleshooting

### Common Issues

1. **Permission Denied**
   - Make sure you have execute permissions on the scripts:
   ```bash
   chmod +x scripts/*.sh
   ```

2. **Port Already in Use**
   - Check if any services are already running:
   ```bash
   lsof -i :<port_number>
   ```
   - Stop the conflicting process or use a different port

3. **Service Not Starting**
   - Check the logs in the `logs/` directory
   - Ensure all dependencies are installed
   - Verify that required ports are available

### Log Files

All service logs are stored in the `logs/` directory:
- `kafka-consumer.log`: Kafka consumer service logs
- `db-migrations.log`: Database migration logs
- `creators-studio-api.log`: API service logs
- `creators-studio.log`: Frontend application logs
