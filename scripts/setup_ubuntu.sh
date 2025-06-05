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

# Check if Kafka is already installed
if [ ! -d "$KAFKA_INSTALL_PATH" ]; then
    log "📦 Installing Kafka..."
    # Download and install Kafka
    KAFKA_VERSION="3.6.1"
    KAFKA_DOWNLOAD_URL="https://archive.apache.org/dist/kafka/$KAFKA_VERSION/kafka_2.13-$KAFKA_VERSION.tgz"
    
    # Create directory for Kafka
    sudo mkdir -p "$KAFKA_INSTALL_PATH"
    
    # Download and extract Kafka
    log "📥 Downloading Kafka from $KAFKA_DOWNLOAD_URL..."
    curl -L "$KAFKA_DOWNLOAD_URL" -o kafka.tgz
    if [ $? -ne 0 ]; then
        log "❌ Failed to download Kafka"
        exit 1
    fi
    
    # Verify the downloaded file is a valid gzip archive
    if ! file kafka.tgz | grep -q "gzip compressed data"; then
        log "❌ Downloaded file is not a valid gzip archive"
        log "File type: $(file kafka.tgz)"
        exit 1
    fi
    
    log "📦 Extracting Kafka..."
    sudo tar -xzf kafka.tgz -C "$KAFKA_INSTALL_PATH" --strip-components=1
    if [ $? -ne 0 ]; then
        log "❌ Failed to extract Kafka"
        exit 1
    fi
    
    # Clean up
    rm kafka.tgz
    
    # Set permissions
    sudo chown -R $USER:$USER "$KAFKA_INSTALL_PATH"
    
    # Add Kafka to PATH
    echo "export PATH=\$PATH:$KAFKA_INSTALL_PATH/bin" >> ~/.bashrc
    source ~/.bashrc
    
    log "✅ Kafka installed successfully at $KAFKA_INSTALL_PATH"
else
    log "✅ Kafka is already installed at $KAFKA_INSTALL_PATH"
fi

# Create logs directory
log "📁 Creating logs directory..."
mkdir -p "$COFFEEZ_ROOT/logs"

log "🔧 Setup complete! Please restart your terminal or run: source ~/.bashrc"