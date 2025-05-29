#!/bin/bash

# Load environment variables
set -a
source .env
set +a

# Validate required variables
if [[ -z "$KAFKA_INSTALL_PATH" ]]; then
  # Check if Homebrew Kafka is installed
  if brew list | grep -q kafka; then
    echo "✅ Homebrew Kafka found. Using brew services to start Zookeeper and Kafka..."
    brew services start zookeeper
    sleep 5
    brew services start kafka
    sleep 5
    KAFKA_STARTED_WITH_BREW=true
  else
    echo "❌ Neither KAFKA_INSTALL_PATH is set nor Homebrew Kafka is installed. Please install Kafka or set KAFKA_INSTALL_PATH in .env."
    exit 1
  fi
else
  if [[ -z "$COFFEEZ_ROOT" ]]; then
    echo "❌ Required environment variable (COFFEEZ_ROOT) not set in .env"
    exit 1
  fi
  echo "✅ Starting Zookeeper..."
  osascript <<EOF
tell application "Terminal"
    do script "echo 'Starting Zookeeper...'; \"$KAFKA_INSTALL_PATH/bin/zookeeper-server-start.sh\" \"$KAFKA_INSTALL_PATH/config/zookeeper.properties\""
end tell
EOF
  sleep 5
  echo "✅ Starting Kafka..."
  osascript <<EOF
tell application "Terminal"
    do script "echo 'Starting Kafka...'; \"$KAFKA_INSTALL_PATH/bin/kafka-server-start.sh\" \"$KAFKA_INSTALL_PATH/config/server.properties\""
end tell
EOF
  sleep 5
fi

echo "✅ Starting MySQL..."
brew services start mysql

sleep 5

echo "🧾 Opening Kafka Consumer..."
osascript <<EOF
tell application "Terminal"
    do script "cd \"$COFFEEZ_ROOT/kafka-consumer\" && npm install && npm run local"
end tell
EOF

sleep 2

echo "🧾 Running DB Migrations..."
osascript <<EOF
tell application "Terminal"
    do script "cd \"$COFFEEZ_ROOT/db-migrations\" && npm install && npm run migrate:up && npm run mate:up"
end tell
EOF

sleep 2

echo "🧾 Running Creators Studio API..."
osascript <<EOF
tell application "Terminal"
    do script "cd \"$COFFEEZ_ROOT/creaters-studio-api\" && npm install && npm run local"
end tell
EOF

sleep 2

echo "🧾 Running Creators Studio App..."
osascript <<EOF
tell application "Terminal"
    do script "cd \"$COFFEEZ_ROOT/creaters-studio\" && npm install && npm run dev"
end tell
EOF

echo "🎉 All services are being started..."

# Argument parsing
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 [up|down]"
  exit 1
fi

ACTION=$1

if [[ "$ACTION" == "up" ]]; then
  # ... existing up logic ...
  # (move all current service start logic here)

elif [[ "$ACTION" == "down" ]]; then
  echo "🛑 Stopping Creators Studio App..."
  pkill -f "npm run dev"
  echo "🛑 Stopping Creators Studio API..."
  pkill -f "creaters-studio-api"
  echo "🛑 Stopping DB Migrations..."
  pkill -f "db-migrations"
  echo "🛑 Stopping Kafka Consumer..."
  pkill -f "kafka-consumer"
  echo "🛑 Stopping MySQL..."
  brew services stop mysql
  echo "🛑 Stopping Kafka..."
  brew services stop kafka
  echo "🛑 Stopping Zookeeper..."
  brew services stop zookeeper
  echo "🛑 All services have been stopped."
else
  echo "Invalid argument: $ACTION"
  echo "Usage: $0 [up|down]"
  exit 1
fi
