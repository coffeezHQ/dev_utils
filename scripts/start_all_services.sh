#!/bin/bash

# Load environment variables
set -a
source .env
set +a

# Validate required variables
if [[ -z "$KAFKA_INSTALL_PATH" || -z "$COFFEEZ_ROOT" ]]; then
  echo "❌ Required environment variables (KAFKA_INSTALL_PATH, COFFEEZ_ROOT) not set in .env"
  exit 1
fi

echo "✅ Starting Zookeeper..."
"$KAFKA_INSTALL_PATH/bin/zookeeper-server-start.sh" "$KAFKA_INSTALL_PATH/config/zookeeper.properties" &

sleep 5

echo "✅ Starting Kafka..."
"$KAFKA_INSTALL_PATH/bin/kafka-server-start.sh" "$KAFKA_INSTALL_PATH/config/server.properties" &

sleep 5

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
    do script "cd \"$COFFEEZ_ROOT/db_migrations\" && npm install && npm run migrate:up && npm run mate:up"
end tell
EOF

sleep 2

echo "🧾 Running Creators Studio API..."
osascript <<EOF
tell application "Terminal"
    do script "cd \"$COFFEEZ_ROOT/creaters_studio_api\" && npm install && npm run local"
end tell
EOF

sleep 2

echo "🧾 Running Creators Studio App..."
osascript <<EOF
tell application "Terminal"
    do script "cd \"$COFFEEZ_ROOT/creaters_studio\" && npm install && npm run dev"
end tell
EOF

echo "🎉 All services are being started..."
