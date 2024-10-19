#!/bin/bash

log() {
    echo -e "\e[1;32m$1\e[0m"
}

log "꧁IP꧂hello  hiSTORYans꧁IP꧂"


log "Install tool..."
sudo apt-get install wget lz4 aria2 pv -y

log "Stop node..."
sudo systemctl stop story
sudo systemctl stop story-geth

log "Download snapshot..."

log "Story data..."
cd $HOME
rm -f Story_snapshot.lz4
aria2c -x 16 -s 16 -k 1M https://story.josephtran.co/Story_snapshot.lz4

log "Geth data..."
#46Gb
cd $HOME
rm -f Geth_snapshot.lz4
aria2c -x 16 -s 16 -k 1M https://story.josephtran.co/Geth_snapshot.lz4

log "Backup priv_validator_state.json..."
cp $HOME/.story/story/data/priv_validator_state.json $HOME/.story/story/priv_validator_state.json.backup

log "Removing old data..."
rm -rf $HOME/.story/story/data
rm -rf $HOME/.story/geth/iliad/geth/chaindata

log "Decompress snapshot Story..."
sudo mkdir -p /root/.story/story/data
lz4 -d -c Story_snapshot.lz4 | pv | sudo tar xv -C ~/.story/story/ > /dev/null

log "Decompress snapshot Geth..."
sudo mkdir -p /root/.story/geth/iliad/geth/chaindata
lz4 -d -c Geth_snapshot.lz4 | pv | sudo tar xv -C ~/.story/geth/iliad/geth/ > /dev/null

log "Move priv_validator_state.json back..."
mv $HOME/.story/story/priv_validator_state.json.backup $HOME/.story/story/data/priv_validator_state.json

log "Restarting the story and story-geth services..."
sudo systemctl start story
sudo systemctl start story-geth


log "꧁IP꧂well done hiSTORYans, you did it꧁IP꧂"
