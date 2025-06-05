#!/bin/bash

set -e

# Function to log messages
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to clone repository if it doesn't exist
clone_repo() {
  local repo=$1
  local repo_path="$COFFEEZ_ROOT/$repo"
  
  if [[ ! -d "$repo_path" ]]; then
    log "🔧 Cloning $repo repository..."
    git clone "git@github.com:coffeezHQ/$repo.git" "$repo_path"
    log "✅ Cloned $repo repository"
  else
    log "✅ Repository $repo already exists at $repo_path"
  fi
}

# Check if COFFEEZ_ROOT is set, if not set a default value
if [ -z "$COFFEEZ_ROOT" ]; then
  COFFEEZ_ROOT="./"
  log "⚠️  COFFEEZ_ROOT not set, using default: $COFFEEZ_ROOT"
fi

# Create COFFEEZ_ROOT directory if it doesn't exist
if [ ! -d "$COFFEEZ_ROOT" ]; then
  log "🔧 Creating COFFEEZ_ROOT directory at $COFFEEZ_ROOT"
  mkdir -p "$COFFEEZ_ROOT"
fi

# Clone repositories
clone_repo "creators-studio"
clone_repo "creators-studio-api"
clone_repo "db-migrations"
clone_repo "kafka-consumer"

# Install required packages
log "📦 Installing required packages..."
sudo apt-get update

# Install curl if not present
if ! command_exists curl; then
  log "📦 Installing curl..."
  sudo apt-get install -y curl
else
  log "✅ curl already installed"
fi

# Install git if not present
if ! command_exists git; then
  log "📦 Installing git..."
  sudo apt-get install -y git
else
  log "✅ git already installed"
fi

# Install lsb-release if not present
if ! command_exists lsb-release; then
  log "📦 Installing lsb-release..."
  sudo apt-get install -y lsb-release
else
  log "✅ lsb-release already installed"
fi

# Install MySQL if not present
if ! command_exists mysql; then
  log "📦 Installing MySQL Server..."
  sudo apt-get install -y mysql-server
else
  log "✅ MySQL already installed"
fi

# Install ClickHouse if not present
if ! command_exists clickhouse-server; then
  log "📦 Installing ClickHouse Server..."
  sudo apt-get install -y clickhouse-server clickhouse-client
else
  log "✅ ClickHouse already installed"
fi

# Install Node.js if not present
if ! command_exists node; then
  log "📦 Installing Node.js (LTS) and npm..."
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt-get install -y nodejs
else
  log "✅ Node.js already installed"
fi

# Install unzip if not present
if ! command_exists unzip; then
  log "📦 Installing unzip..."
  sudo apt-get install -y unzip
else
  log "✅ unzip already installed"
fi

# Install Java if not present
if ! command_exists java; then
  log "📦 Installing Java (required for Kafka)..."
  sudo apt-get install -y default-jre
else
  log "✅ Java already installed"
fi

KAFKA_VERSION="3.6.1"
KAFKA_SCALA_VERSION="2.13"
KAFKA_DIR="/opt/kafka"
KAFKA_TGZ="kafka_${KAFKA_SCALA_VERSION}-${KAFKA_VERSION}.tgz"
KAFKA_URL="https://downloads.apache.org/kafka/${KAFKA_VERSION}/${KAFKA_TGZ}"

if [[ ! -d "$KAFKA_DIR" ]]; then
  log "📦 Installing Kafka..."
  curl -L "$KAFKA_URL" -o kafka.tgz
  sudo mkdir -p "$KAFKA_DIR"
  sudo tar -xzf kafka.tgz -C "$KAFKA_DIR" --strip-components=1
  rm kafka.tgz
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

# Create logs directory
log "📁 Creating logs directory..."
mkdir -p "$COFFEEZ_ROOT/logs"

log "🔧 Setup complete! Please restart your terminal or run: source ~/.bashrc"