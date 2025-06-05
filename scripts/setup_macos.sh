#!/bin/bash

set -e

# Function to log messages
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "🔧 Updating Homebrew..."
brew update

log "🔧 Installing ClickHouse..."
if ! command -v clickhouse &> /dev/null; then
  brew install --cask clickhouse || brew install --no-quarantine clickhouse
  CLICKHOUSE_PATH=$(which clickhouse)
  if [[ -n "$CLICKHOUSE_PATH" ]]; then
    log "🔧 Removing quarantine attribute from ClickHouse binary..."
    xattr -d com.apple.quarantine "$CLICKHOUSE_PATH"
    log "✅ ClickHouse installed at $CLICKHOUSE_PATH"
  else
    log "❌ ClickHouse installation failed. Please check Homebrew output."
  fi
else
  log "✅ ClickHouse already installed at $(which clickhouse)"
fi

log "🔧 Installing Kafka..."
if [[ ! -d "/opt/kafka" ]]; then
  log "🔧 Downloading Kafka 3.5.1..."
  curl -O https://archive.apache.org/dist/kafka/3.5.1/kafka_2.13-3.5.1.tgz
  log "🔧 Extracting Kafka..."
  tar -xzf kafka_2.13-3.5.1.tgz
  sudo mv kafka_2.13-3.5.1 /opt/kafka-3.5.1
  sudo ln -s /opt/kafka-3.5.1 /opt/kafka
  if ! grep -q 'export PATH="/opt/kafka/bin:$PATH"' ~/.zprofile; then
    echo 'export PATH="/opt/kafka/bin:$PATH"' >> ~/.zprofile
    log "🔧 Added Kafka to PATH in ~/.zprofile"
  fi
  rm kafka_2.13-3.5.1.tgz
  log "✅ Kafka installed at /opt/kafka"
else
  log "✅ Kafka already installed at /opt/kafka"
fi

log "🔧 Installing MySQL..."
if ! command -v mysql &> /dev/null; then
  brew install mysql
  log "✅ MySQL installed."
else
  log "✅ MySQL already installed at $(which mysql)"
fi

log "🔧 Installing Redis..."
if ! command -v redis-server &> /dev/null; then
  brew install redis
  log "✅ Redis installed."
else
  log "✅ Redis already installed at $(which redis-server)"
fi

log "🔧 Installing Node.js and npm..."
if ! command -v node &> /dev/null; then
  brew install node
  log "✅ Node.js and npm installed."
else
  log "✅ Node.js already installed at $(which node)"
  log "✅ npm already installed at $(which npm)"
fi

log "🔧 Creating logs directory..."
mkdir -p "$HOME/Go/src/github.com/coffeezHQ/logs"

log "🔧 Setup complete! Please restart your terminal or run: source ~/.zprofile" 