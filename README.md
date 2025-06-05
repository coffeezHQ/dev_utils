# Dev Utils

A collection of utility scripts for development environment setup and management.

## Prerequisites

- macOS (tested on macOS 22.3.0)
- Homebrew
- Node.js (v18 or later)
- Docker Desktop
- Go (v1.21 or later)

## Quick Start

1. Clone this repository:
```bash
git clone git@github.com:coffeezhq/dev_utils.git
cd dev_utils
```

2. Run the setup script:
```bash
./scripts/setup.sh
```

This will:
- Install required Homebrew packages
- Set up required directories
- Clone all necessary repositories
- Install dependencies
- Start all required services

## Available Commands

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

## Directory Structure

```
dev_utils/
├── scripts/
│   ├── setup.sh
│   └── start_all_services.sh
├── logs/
│   ├── kafka-consumer.log
│   ├── db-migrations.log
│   ├── creators-studio-api.log
│   └── creators-studio.log
└── README.md
```

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

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

