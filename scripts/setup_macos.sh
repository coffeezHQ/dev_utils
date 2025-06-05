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

# Function to clone a repository if it doesn't exist
clone_repo() {
    local repo_name=$1
    local repo_path="$COFFEEZ_ROOT/$repo_name"
    
    if [ ! -d "$repo_path" ]; then
        log "📦 Cloning $repo_name repository..."
        git clone "https://github.com/coffeezHQ/$repo_name.git" "$repo_path"
    else
        log "✅ $repo_name repository already exists."
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

# Check if Homebrew is installed
if ! command_exists brew; then
  log "📦 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  log "✅ Homebrew already installed"
fi

# Install required packages
log "📦 Installing required packages..."

# Install curl if not present
if ! command_exists curl; then
  log "📦 Installing curl..."
  brew install curl
else
  log "✅ curl already installed"
fi

# Install git if not present
if ! command_exists git; then
  log "📦 Installing git..."
  brew install git
else
  log "✅ git already installed"
fi

# Install MySQL if not present
if ! command_exists mysql; then
  log "📦 Installing MySQL..."
  brew install mysql
else
  log "✅ MySQL already installed at $(which mysql)"
fi

# Install ClickHouse if not present
if ! command_exists clickhouse; then
  log "📦 Installing ClickHouse..."
  brew install clickhouse
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

# Install Node.js if not present
if ! command_exists node; then
  log "📦 Installing Node.js..."
  brew install node@18
else
  log "✅ Node.js already installed at $(which node)"
  log "✅ npm already installed at $(which npm)"
fi

# Install unzip if not present
if ! command_exists unzip; then
  log "📦 Installing unzip..."
  brew install unzip
else
  log "✅ unzip already installed"
fi

# Install Java if not present
if ! command_exists java; then
  log "📦 Installing Java..."
  brew install openjdk@17
else
  log "✅ Java already installed"
fi

# Check if Kafka is already installed
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

# Create logs directory
log "🔧 Creating logs directory..."
mkdir -p "$COFFEEZ_ROOT/logs"

log "🔧 Setup complete! Please restart your terminal or run: source ~/.zprofile"