#!/bin/bash

INSTALL_DIR=/usr/local/bin
SCRIPT_PATH=$INSTALL_DIR/locationchanger
LAUNCH_AGENTS_DIR=$HOME/Library/LaunchAgents
PLIST_PATH=$LAUNCH_AGENTS_DIR/LocationChanger.plist
CONFIG_DIR=$HOME/.locations

RAW_SCRIPT_URL="https://github.com/xy-mf/locationchanger/raw/master/core"

sudo -v

mkdir -p $CONFIG_DIR
curl -L $RAW_SCRIPT_URL/locations.conf.sample -o $CONFIG_DIR/locations.conf

sudo mkdir -p $INSTALL_DIR
sudo curl -L $RAW_SCRIPT_URL/core/locationchanger.sh -o $SCRIPT_PATH
sudo chmod +x $SCRIPT_PATH

mkdir -p $LAUNCH_AGENTS_DIR
curl -L $RAW_SCRIPT_URL/core/LocationChanger.plist -o $PLIST_PATH
launchctl load -w $PLIST_PATH

