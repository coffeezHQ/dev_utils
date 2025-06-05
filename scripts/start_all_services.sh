#!/bin/bash

# Source environment variables
if [[ -f .env ]]; then
  source .env
else
  echo "Error: .env file not found"
  exit 1
fi

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="macos"
  SERVICE_CMD="brew services"
  SETUP_SCRIPT="scripts/setup_macos.sh"
elif [[ -f /etc/lsb-release ]] && grep -q "Ubuntu" /etc/lsb-release; then
  OS="ubuntu"
  SERVICE_CMD="sudo systemctl"
  SETUP_SCRIPT="scripts/setup_ubuntu.sh"
else
  echo "Error: Unsupported operating system"
  exit 1
fi

# Function to log messages with timestamps
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check if a service is running
check_service() {
  local service_name=$1
  local pattern=$2
  if pgrep -f "$pattern" > /dev/null; then
    log "✅ $service_name is running"
    return 0
  else
    log "❌ $service_name is not running"
    return 1
  fi
}

# Function to start MySQL
start_mysql() {
  log "Starting MySQL..."
  if [[ "$OS" == "macos" ]]; then
    brew services start mysql
  else
    $SERVICE_CMD start mysql
  fi
  sleep 2
  check_service "MySQL" "mysqld"
}

# Function to start Kafka and Zookeeper
start_kafka() {
  log "Starting Kafka and Zookeeper..."
  "$KAFKA_INSTALL_PATH/bin/zookeeper-server-start.sh" -daemon "$KAFKA_INSTALL_PATH/config/zookeeper.properties"
  sleep 2
  "$KAFKA_INSTALL_PATH/bin/kafka-server-start.sh" -daemon "$KAFKA_INSTALL_PATH/config/server.properties"
  sleep 2
  check_service "Zookeeper" "zookeeper"
  check_service "Kafka" "kafka"
}

# Function to start ClickHouse
start_clickhouse() {
  log "Starting ClickHouse..."
  if [[ "$OS" == "macos" ]]; then
    brew services start clickhouse
  else
    $SERVICE_CMD start clickhouse-server
  fi
  sleep 2
  check_service "ClickHouse" "clickhouse"
}

# Function to start all services
start_all_services() {
  # Create logs directory if it doesn't exist
  mkdir -p "$COFFEEZ_ROOT/logs"

  # Start infrastructure services
  start_mysql
  start_kafka
  start_clickhouse

  # Start Kafka Consumer
  log "Starting Kafka Consumer..."
  (cd "$COFFEEZ_ROOT/kafka-consumer" && npm install && npm run local) > "$COFFEEZ_ROOT/logs/kafka-consumer.log" 2>&1 &
  sleep 2

  # Run DB Migrations
  log "Running DB Migrations..."
  (cd "$COFFEEZ_ROOT/db-migrations" && npm install && npm run migrate:up && npm run mate:up) > "$COFFEEZ_ROOT/logs/db-migrations.log" 2>&1 &
  sleep 2

  # Start Creators Studio API
  log "Starting Creators Studio API..."
  (cd "$COFFEEZ_ROOT/creators-studio-api" && npm install && npm run local) > "$COFFEEZ_ROOT/logs/creators-studio-api.log" 2>&1 &
  sleep 2

  # Start Creators Studio Frontend
  log "Starting Creators Studio App..."
  (cd "$COFFEEZ_ROOT/creators-studio" && npm install && npm run dev) > "$COFFEEZ_ROOT/logs/creators-studio.log" 2>&1 &

  log "All services have been started"
  log "To view logs:"
  echo "  tail -f $COFFEEZ_ROOT/logs/kafka-consumer.log"
  echo "  tail -f $COFFEEZ_ROOT/logs/db-migrations.log"
  echo "  tail -f $COFFEEZ_ROOT/logs/creators-studio-api.log"
  echo "  tail -f $COFFEEZ_ROOT/logs/creators-studio.log"
}

# Function to stop all services
stop_all_services() {
  log "Stopping all services..."

  # Stop project services
  pkill -f "npm run dev"
  pkill -f "creaters-studio-api"
  pkill -f "db-migrations"
  pkill -f "kafka-consumer"

  # Stop infrastructure services
  if [[ "$OS" == "macos" ]]; then
    brew services stop clickhouse
    "$KAFKA_INSTALL_PATH/bin/kafka-server-stop.sh"
    "$KAFKA_INSTALL_PATH/bin/zookeeper-server-stop.sh"
    brew services stop mysql
  else
    $SERVICE_CMD stop clickhouse-server
    "$KAFKA_INSTALL_PATH/bin/kafka-server-stop.sh"
    "$KAFKA_INSTALL_PATH/bin/zookeeper-server-stop.sh"
    $SERVICE_CMD stop mysql
  fi

  log "All services have been stopped"
}

# Function to pull latest code from a repository
pull_latest_code() {
  local repo=$1
  local repo_path="$COFFEEZ_ROOT/$repo"
  
  if [[ ! -d "$repo_path" ]]; then
    log "❌ Repository $repo not found at $repo_path"
    return 1
  fi

  log "📥 Pulling latest code for $repo..."
  if (cd "$repo_path" && git pull); then
    log "✅ Successfully pulled latest code for $repo"
    return 0
  else
    log "❌ Failed to pull latest code for $repo"
    return 1
  fi
}

# Function to check logs for errors
check_logs() {
  local log_dir="$COFFEEZ_ROOT/logs"
  local error_count=0

  if [[ ! -d "$log_dir" ]]; then
    log "❌ Log directory not found at $log_dir"
    return 1
  fi

  log "🔍 Checking logs for errors..."
  
  for log_file in "$log_dir"/*.log; do
    if [[ -f "$log_file" ]]; then
      local filename=$(basename "$log_file")
      log "Checking $filename..."
      
      # Check last 50 lines for errors
      if tail -n 50 "$log_file" | grep -i "error\|exception\|fail" > /dev/null; then
        log "❌ Found errors in $filename:"
        tail -n 50 "$log_file" | grep -i "error\|exception\|fail" | while read -r line; do
          echo "  $line"
        done
        ((error_count++))
      else
        log "✅ No errors found in $filename"
      fi
    fi
  done

  if [[ $error_count -eq 0 ]]; then
    log "✅ No errors found in any logs"
    return 0
  else
    log "❌ Found errors in $error_count log files"
    return 1
  fi
}

# Main script
ACTION=${1:-start}

if [[ "$ACTION" == "start" ]]; then
  start_all_services
elif [[ "$ACTION" == "stop" ]]; then
  stop_all_services
elif [[ "$ACTION" == "reset" ]]; then
  log "🔄 Resetting project services and pulling latest code..."
  
  # Stop only project services
  log "🛑 Stopping project services..."
  pkill -f "npm run dev"
  pkill -f "creaters-studio-api"
  pkill -f "db-migrations"
  pkill -f "kafka-consumer"
  log "✅ Stopped project services"

  # Clear logs
  if [[ -d "$COFFEEZ_ROOT/logs" ]]; then
    rm -f "$COFFEEZ_ROOT/logs"/*.log
    log "🧹 Cleared all logs"
  fi

  # Pull latest code from all repos
  pull_failed=0
  for repo in "creators-studio" "creators-studio-api" "db-migrations" "kafka-consumer"; do
    if ! pull_latest_code "$repo"; then
      pull_failed=1
    fi
  done

  if [[ $pull_failed -eq 1 ]]; then
    log "⚠️  Some repositories failed to update. Continuing with restart..."
  fi

  # Start project services
  log "🚀 Starting project services..."
  
  # Start Kafka Consumer
  log "📦 Starting Kafka Consumer..."
  (cd "$COFFEEZ_ROOT/kafka-consumer" && npm install && npm run local) > "$COFFEEZ_ROOT/logs/kafka-consumer.log" 2>&1 &
  sleep 2

  # Run DB Migrations
  log "🧾 Running DB Migrations..."
  (cd "$COFFEEZ_ROOT/db-migrations" && npm install && npm run migrate:up && npm run mate:up) > "$COFFEEZ_ROOT/logs/db-migrations.log" 2>&1 &
  sleep 2

  # Start Creators Studio API
  log "🚀 Starting Creators Studio API..."
  (cd "$COFFEEZ_ROOT/creators-studio-api" && npm install && npm run local) > "$COFFEEZ_ROOT/logs/creators-studio-api.log" 2>&1 &
  sleep 2

  # Start Creators Studio Frontend
  log "🎨 Starting Creators Studio App..."
  (cd "$COFFEEZ_ROOT/creators-studio" && npm install && npm run dev) > "$COFFEEZ_ROOT/logs/creators-studio.log" 2>&1 &

  log "🎉 All project services have been reset and restarted"
  log "To view logs:"
  echo "  tail -f $COFFEEZ_ROOT/logs/kafka-consumer.log"
  echo "  tail -f $COFFEEZ_ROOT/logs/db-migrations.log"
  echo "  tail -f $COFFEEZ_ROOT/logs/creators-studio-api.log"
  echo "  tail -f $COFFEEZ_ROOT/logs/creators-studio.log"
elif [[ "$ACTION" == "logs" ]]; then
  check_logs
elif [[ "$ACTION" == "setup" ]]; then
  log "🔧 Running setup script for $OS..."
  if [[ -f "$SETUP_SCRIPT" ]]; then
    bash "$SETUP_SCRIPT"
  else
    log "❌ Setup script not found: $SETUP_SCRIPT"
    exit 1
  fi
else
  echo "Usage: $0 [start|stop|reset|logs|setup]"
  exit 1
fi
