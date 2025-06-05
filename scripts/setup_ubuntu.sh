#!/bin/bash

set -e

# Function to log messages
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "🔧 Updating package lists..."
sudo apt-get update

log "🔧 Installing prerequisites (curl, git, lsb-release)..."
sudo apt-get install -y curl git lsb-release

log "🔧 Installing MySQL Server..."
sudo apt-get install -y mysql-server

log "🔧 Installing ClickHouse Server..."
if ! command -v clickhouse-server &> /dev/null; then
  sudo apt-get install -y clickhouse-server clickhouse-client
else
  log "✅ ClickHouse already installed."
fi

log "🔧 Installing Node.js (LTS) and npm..."
if ! command -v node &> /dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt-get install -y nodejs
else
  log "✅ Node.js already installed."
fi

log "🔧 Installing unzip (for Kafka extraction)..."
sudo apt-get install -y unzip

log "🔧 Installing Java (required for Kafka)..."
sudo apt-get install -y default-jre

KAFKA_VERSION="3.5.1"
KAFKA_SCALA_VERSION="2.13"
KAFKA_DIR="/opt/kafka"
KAFKA_TGZ="kafka_${KAFKA_SCALA_VERSION}-${KAFKA_VERSION}.tgz"
KAFKA_URL="https://archive.apache.org/dist/kafka/${KAFKA_VERSION}/${KAFKA_TGZ}"

if [[ ! -d "$KAFKA_DIR" ]]; then
  log "🔧 Downloading Kafka..."
  curl -O "$KAFKA_URL"
  log "🔧 Extracting Kafka..."
  sudo tar -xzf "$KAFKA_TGZ" -C /opt/
  sudo mv "/opt/kafka_${KAFKA_SCALA_VERSION}-${KAFKA_VERSION}" "$KAFKA_DIR"
  rm "$KAFKA_TGZ"
  log "✅ Kafka installed at $KAFKA_DIR"
else
  log "✅ Kafka already installed at $KAFKA_DIR"
fi

if ! grep -q 'export PATH="/opt/kafka/bin:$PATH"' ~/.bashrc; then
  echo 'export PATH="/opt/kafka/bin:$PATH"' >> ~/.bashrc
  log "🔧 Added Kafka to PATH in ~/.bashrc"
fi

log "🔧 Ensuring permissions for Kafka directory..."
sudo chown -R $USER:$USER "$KAFKA_DIR"

log "🔧 Creating logs directory..."
mkdir -p "$HOME/Go/src/github.com/coffeezHQ/logs"

log "🔧 Setup complete! Please restart your terminal or run: source ~/.bashrc" 