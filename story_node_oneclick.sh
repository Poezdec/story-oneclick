#!/bin/bash

# Function for outputting steps
log() {
    echo -e "\e[1;32m$1\e[0m"
}

log "꧁IP꧂hello  hiSTORYans꧁IP꧂"

# Step 0: Ask for node moniker at the beginning
read -p "Enter the name of your node (moniker): " MONIKER

# Step 1: Dependency installation, including pv
log "Updating the package lists and installing required tools..."
sudo apt update && sudo apt-get update && sudo apt install curl git wget htop tmux build-essential jq make lz4 tree gcc unzip pv -y

# Step 2: Creating required directories
log "Creating directories to store Geth and Story binaries..."
mkdir -p $HOME/.story/geth/bin $HOME/.story/story/bin

# Step 3: Downloading and Installing Geth
log "Downloading and installing Geth binary..."
wget https://storage.crouton.digital/testnet/story/bin/geth
chmod +x geth
mv geth $HOME/.story/geth/bin/
$HOME/.story/geth/bin/geth version

# Step 4: Downloading and Installing Story
log "Downloading and installing Story binary..."
wget https://storage.crouton.digital/testnet/story/bin/story
chmod +x story
mv story $HOME/.story/story/bin/
$HOME/.story/story/bin/story version

# Step 5: Ensure binaries are in expected directories
log "Ensuring binaries are correctly placed..."
sudo tree $HOME/.story

# Step 6: Add Geth and Story binaries to PATH
log "Adding Geth and Story binaries to PATH..."
echo 'export PATH="$HOME/.story/geth/bin:$HOME/.story/story/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Принудительно обновляем PATH для текущей сессии
export PATH="$HOME/.story/geth/bin:$HOME/.story/story/bin:$PATH"

# Step 7: Setting up Geth as a systemd service
log "Setting up Geth as a systemd service..."
sudo tee /etc/systemd/system/story-geth.service > /dev/null <<EOF
[Unit]
Description=ETH Node
After=network.target

[Service]
User=$USER
Type=simple
WorkingDirectory=$HOME/.story/geth
ExecStart=$(which geth) --iliad --syncmode full
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

log "Reloading systemd, enabling and starting Geth service..."
sudo systemctl daemon-reload && sudo systemctl enable story-geth && sudo systemctl restart story-geth

# Step 8: Check if Story binary exists
log "Checking for Story binary..."
if ! [ -f "$HOME/.story/story/bin/story" ]; then
    log "Story binary not found, please check installation."
    exit 1
else
    log "Story binary found."
fi

# Step 9: Initialize Story node with your moniker
log "Initializing Story node..."
if $HOME/.story/story/bin/story init --network iliad --moniker "$MONIKER"; then
    log "Node initialized successfully with moniker $MONIKER"
else
    log "Failed to initialize node. Please check the Story binary installation."
    exit 1
fi

# Step 10: Download addrbook
log "Downloading addrbook..."
mkdir -p $HOME/.story/story/config
wget -O $HOME/.story/story/config/addrbook.json https://storage.crouton.digital/testnet/story/files/addrbook.json

# Step 11: Setting up Story as a systemd service
log "Setting up Story as a systemd service..."
sudo tee /etc/systemd/system/story.service > /dev/null <<EOF
[Unit]
Description=Story Protocol Node
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/.story/story
Type=simple
ExecStart=$(which story) run
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

log "Reloading systemd, enabling and starting Story service..."
sudo systemctl daemon-reload && sudo systemctl enable story && sudo systemctl restart story

# Step 12: Recovering Snapshot
log "Recovering snapshot..."
sudo systemctl stop story story-geth

log "Backing up priv_validator_state.json..."
cp $HOME/.story/story/data/priv_validator_state.json $HOME/.story/story/priv_validator_state.json.backup

log "Removing old data..."
rm -rf $HOME/.story/story/data
rm -rf $HOME/.story/geth/iliad/geth/chaindata

log "Downloading the latest snapshot with resume capability..."
wget -c https://storage.crouton.digital/testnet/story/snapshots/story_latest.tar.lz4 -O $HOME/story_latest.tar.lz4 --show-progress

log "Extracting the snapshot and showing progress..."
pv $HOME/story_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.story

log "Restoring priv_validator_state.json..."
mv $HOME/.story/story/priv_validator_state.json.backup $HOME/.story/story/data/priv_validator_state.json

log "Restarting the story and story-geth services..."
sudo systemctl start story-geth
sudo systemctl start story

log "꧁IP꧂well done hiSTORYans, you did it꧁IP꧂"

log "Follow Story logs..."
sudo journalctl -u story -f
