#!/bin/bash

set -e

# Function to log messages
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check if a command exists
command_exists() {
  command -v "$1" &> /dev/null
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

# Create COFFEEZ_ROOT directory if it doesn't exist
if [[ ! -d "$COFFEEZ_ROOT" ]]; then
  log "🔧 Creating COFFEEZ_ROOT directory at $COFFEEZ_ROOT..."
  mkdir -p "$COFFEEZ_ROOT"
  log "✅ Created COFFEEZ_ROOT directory"
else
  log "✅ COFFEEZ_ROOT directory already exists at $COFFEEZ_ROOT"
fi

# Clone repositories
clone_repo "creators-studio"
clone_repo "creators-studio-api"
clone_repo "db-migrations"
clone_repo "kafka-consumer"

# Check and install services only if they don't exist
if ! command_exists clickhouse; then
  log "🔧 Installing ClickHouse..."
  brew install --cask clickhouse || brew install --no-quarantine clickhouse
  CLICKHOUSE_PATH=$(which clickhouse)
  if [[ -n "$CLICKHOUSE_PATH" ]]; then
    log "🔧 Removing quarantine attribute from ClickHouse binary..."
    if xattr -d com.apple.quarantine "$CLICKHOUSE_PATH" 2>/dev/null; then
      log "✅ Quarantine attribute removed from ClickHouse binary."
    else
      log "⚠️  No quarantine attribute found on ClickHouse binary."
    fi
    log "✅ ClickHouse installed at $CLICKHOUSE_PATH"
  else
    log "❌ ClickHouse installation failed. Please check Homebrew output."
  fi
else
  log "✅ ClickHouse already installed at $(which clickhouse)"
fi

if [[ ! -d "/opt/kafka" ]]; then
  log "🔧 Installing Kafka..."
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

if ! command_exists mysql; then
  log "🔧 Installing MySQL..."
  brew install mysql
  log "✅ MySQL installed."
else
  log "✅ MySQL already installed at $(which mysql)"
fi

if ! command_exists redis-server; then
  log "🔧 Installing Redis..."
  brew install redis
  log "✅ Redis installed."
else
  log "✅ Redis already installed at $(which redis-server)"
fi

if ! command_exists node; then
  log "🔧 Installing Node.js and npm..."
  brew install node
  log "✅ Node.js and npm installed."
else
  log "✅ Node.js already installed at $(which node)"
  log "✅ npm already installed at $(which npm)"
fi

# Create logs directory
log "🔧 Creating logs directory..."
mkdir -p "$COFFEEZ_ROOT/logs"

log "🔧 Setup complete! Please restart your terminal or run: source ~/.zprofile"