#!/bin/bash

# Load environment variables
set -a
source .env
set +a

# Validate argument
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 [up|down]"
  exit 1
fi

ACTION="$1"

# Function: Start a new Terminal tab with command
start_in_new_tab() {
  local CMD="$1"
  osascript -e "tell application \"Terminal\" to do script \"${CMD//\"/\\\"}\""
}

if [[ "$ACTION" == "up" ]]; then

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
    echo "✅ Starting Zookeeper via Terminal tab..."
    start_in_new_tab "echo 'Starting Zookeeper...'; \"$KAFKA_INSTALL_PATH/bin/zookeeper-server-start.sh\" \"$KAFKA_INSTALL_PATH/config/zookeeper.properties\""
    sleep 5

    echo "✅ Starting Kafka via Terminal tab..."
    start_in_new_tab "echo 'Starting Kafka...'; \"$KAFKA_INSTALL_PATH/bin/kafka-server-start.sh\" \"$KAFKA_INSTALL_PATH/config/server.properties\""
    sleep 5
  fi

  # Start MySQL
  echo "✅ Starting MySQL..."
  brew services start mysql
  sleep 5

  # Start Kafka Consumer
  echo "📦 Starting Kafka Consumer..."
  start_in_new_tab "cd \"$COFFEEZ_ROOT/kafka-consumer\" && npm install && npm run local"
  sleep 2

  # DB Migrations
  echo "🧾 Running DB Migrations..."
  start_in_new_tab "cd \"$COFFEEZ_ROOT/db-migrations\" && npm install && npm run migrate:up && npm run mate:up"
  sleep 2

  # Creators Studio API
  echo "🚀 Starting Creators Studio API..."
  start_in_new_tab "cd \"$COFFEEZ_ROOT/creators-studio-api\" && npm install && npm run local"
  sleep 2

  # Creators Studio Frontend App
  echo "🎨 Starting Creators Studio App..."
  start_in_new_tab "cd \"$COFFEEZ_ROOT/creators-studio\" && npm install && npm run dev"

  echo "🎉 All services are being started in new terminal tabs."

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

  echo "🛑 Stopping Kafka..."
  brew services stop kafka

  echo "🛑 Stopping Zookeeper..."
  brew services stop zookeeper

  echo "✅ All services have been stopped."

else
  echo "❌ Invalid argument: $ACTION"
  echo "Usage: $0 [up|down]"
  exit 1
fi
