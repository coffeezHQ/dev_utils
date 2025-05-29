#!/bin/bash

# Load environment variables
set -a
source .env
set +a

# Validate argument
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 [up|down|install]"
  exit 1
fi

ACTION="$1"

# Function: Start a new Terminal tab with command
start_in_new_tab() {
  local CMD="$1"
  osascript -e "tell application \"Terminal\" to do script \"${CMD//\"/\\\"}\""
}

if [[ "$ACTION" == "install" ]]; then
  echo "🔧 Installing dependencies..."

  # Install ClickHouse
  if ! command -v clickhouse &> /dev/null; then
    echo "➡️  Installing ClickHouse via Homebrew (no quarantine)..."
    brew install --cask clickhouse || brew install --no-quarantine clickhouse
    CLICKHOUSE_PATH=$(which clickhouse)
    if [[ -n "$CLICKHOUSE_PATH" ]]; then
      echo "➡️  Removing quarantine attribute from ClickHouse binary..."
      xattr -d com.apple.quarantine "$CLICKHOUSE_PATH"
      echo "✅ ClickHouse installed at $CLICKHOUSE_PATH"
    else
      echo "❌ ClickHouse installation failed. Please check Homebrew output."
    fi
  else
    echo "✅ ClickHouse already installed at $(which clickhouse)"
  fi

  # Install Kafka
  if [[ ! -d "/opt/kafka" ]]; then
    echo "➡️  Downloading Kafka 3.5.1..."
    curl -O https://archive.apache.org/dist/kafka/3.5.1/kafka_2.13-3.5.1.tgz
    echo "➡️  (Optional) Verifying integrity..."
    shasum -a 512 kafka_2.13-3.5.1.tgz
    echo "➡️  Extracting Kafka..."
    tar -xzf kafka_2.13-3.5.1.tgz
    sudo mv kafka_2.13-3.5.1 /opt/kafka-3.5.1
    sudo ln -s /opt/kafka-3.5.1 /opt/kafka
    echo 'export PATH="/opt/kafka/bin:$PATH"' >> ~/.zprofile
    source ~/.zprofile
    echo "✅ Kafka installed at /opt/kafka"
  else
    echo "✅ Kafka already installed at /opt/kafka"
  fi

  # Install MySQL
  if ! command -v mysql &> /dev/null; then
    echo "➡️  Installing MySQL via Homebrew..."
    brew install mysql
    echo "✅ MySQL installed."
  else
    echo "✅ MySQL already installed at $(which mysql)"
  fi

  # Install Redis
  if ! command -v redis-server &> /dev/null; then
    echo "➡️  Installing Redis via Homebrew..."
    brew install redis
    echo "✅ Redis installed."
  else
    echo "✅ Redis already installed at $(which redis-server)"
  fi

  # Install Node.js and npm
  if ! command -v node &> /dev/null; then
    echo "➡️  Installing Node.js (includes npm) via Homebrew..."
    brew install node
    echo "✅ Node.js and npm installed."
  else
    echo "✅ Node.js already installed at $(which node)"
    echo "✅ npm already installed at $(which npm)"
  fi

  echo "🔧 Installation complete. Please restart your terminal or run: source ~/.zprofile"
  exit 0

elif [[ "$ACTION" == "up" ]]; then
  mkdir -p "$COFFEEZ_ROOT/logs"
  chmod 775 "$COFFEEZ_ROOT/logs"

  # Check Kafka path or fallback to brew
  if [[ -z "$KAFKA_INSTALL_PATH" ]]; then
    if brew list | grep -q kafka; then
      echo "✅ Homebrew Kafka detected. Starting via brew services..."
      brew services start zookeeper
      sleep 5
      brew services start kafka
      sleep 5
    else
      echo "❌ KAFKA_INSTALL_PATH not set and Kafka not installed via Homebrew."
      exit 1
    fi
  else
    echo "✅ Starting Zookeeper in background... (logs: $COFFEEZ_ROOT/logs/zookeeper.log)"
    ("$KAFKA_INSTALL_PATH/bin/zookeeper-server-start.sh" "$KAFKA_INSTALL_PATH/config/zookeeper.properties") > "$COFFEEZ_ROOT/logs/zookeeper.log" 2>&1 &
    sleep 5

    echo "✅ Starting Kafka in background... (logs: $COFFEEZ_ROOT/logs/kafka.log)"
    ("$KAFKA_INSTALL_PATH/bin/kafka-server-start.sh" "$KAFKA_INSTALL_PATH/config/server.properties") > "$COFFEEZ_ROOT/logs/kafka.log" 2>&1 &
    sleep 5
  fi

  # Start MySQL
  echo "✅ Starting MySQL..."
  brew services start mysql
  sleep 5

  # Start ClickHouse
  echo "✅ Starting ClickHouse... (logs: $COFFEEZ_ROOT/logs/clickhouse.log)"
  (clickhouse server) > "$COFFEEZ_ROOT/logs/clickhouse.log" 2>&1 &
  sleep 5

  # Start Kafka Consumer
  echo "📦 Starting Kafka Consumer... (logs: $COFFEEZ_ROOT/logs/kafka-consumer.log)"
  (cd "$COFFEEZ_ROOT/kafka-consumer" && npm install && npm run local) > "$COFFEEZ_ROOT/logs/kafka-consumer.log" 2>&1 &
  sleep 2

  # DB Migrations
  echo "🧾 Running DB Migrations... (logs: $COFFEEZ_ROOT/logs/db-migrations.log)"
  (cd "$COFFEEZ_ROOT/db-migrations" && npm install && npm run migrate:up && npm run mate:up) > "$COFFEEZ_ROOT/logs/db-migrations.log" 2>&1 &
  sleep 2

  # Creators Studio API
  echo "🚀 Starting Creators Studio API... (logs: $COFFEEZ_ROOT/logs/creators-studio-api.log)"
  (cd "$COFFEEZ_ROOT/creators-studio-api" && npm install && npm run local) > "$COFFEEZ_ROOT/logs/creators-studio-api.log" 2>&1 &
  sleep 2

  # Creators Studio Frontend App
  echo "🎨 Starting Creators Studio App... (logs: $COFFEEZ_ROOT/logs/creators-studio.log)"
  (cd "$COFFEEZ_ROOT/creators-studio" && npm install && npm run dev) > "$COFFEEZ_ROOT/logs/creators-studio.log" 2>&1 &

  echo "🎉 All services are being started in the background."
  echo "To view logs:"
  echo "  tail -f $COFFEEZ_ROOT/logs/kafka-consumer.log"
  echo "  tail -f $COFFEEZ_ROOT/logs/db-migrations.log"
  echo "  tail -f $COFFEEZ_ROOT/logs/creators-studio-api.log"
  echo "  tail -f $COFFEEZ_ROOT/logs/creators-studio.log"
  echo "  tail -f $COFFEEZ_ROOT/logs/zookeeper.log"
  echo "  tail -f $COFFEEZ_ROOT/logs/kafka.log"
  echo "  tail -f $COFFEEZ_ROOT/logs/clickhouse.log"

elif [[ "$ACTION" == "down" ]]; then

  echo "🛑 Stopping all services..."

  echo "🛑 Killing Creators Studio App..."
  pkill -f "npm run dev"

  echo "🛑 Killing Creators Studio API..."
  pkill -f "creaters-studio-api"

  echo "🛑 Killing DB Migrations..."
  pkill -f "db-migrations"

  echo "🛑 Killing Kafka Consumer..."
  pkill -f "kafka-consumer"

  echo "🛑 Stopping MySQL..."
  brew services stop mysql

  # Stop Kafka and Zookeeper based on how they were started
  if [[ -z "$KAFKA_INSTALL_PATH" ]]; then
    echo "🛑 Stopping Kafka via Homebrew..."
    brew services stop kafka
    echo "🛑 Stopping Zookeeper via Homebrew..."
    brew services stop zookeeper
  else
    echo "🛑 Stopping Kafka via stop script..."
    "$KAFKA_INSTALL_PATH/bin/kafka-server-stop.sh"
    echo "🛑 Stopping Zookeeper via stop script..."
    "$KAFKA_INSTALL_PATH/bin/zookeeper-server-stop.sh"
  fi

  echo "🛑 Stopping ClickHouse..."
  pkill -f "clickhouse"

  echo "🧹 Clearing all logs..."
  rm -f "$COFFEEZ_ROOT/logs"/*.log

  echo "✅ All services have been stopped."

else
  echo "❌ Invalid argument: $ACTION"
  echo "Usage: $0 [up|down|install]"
  exit 1
fi
