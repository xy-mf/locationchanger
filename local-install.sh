#!/bin/bash

INSTALL_DIR=/usr/local/bin
SCRIPT_PATH=$INSTALL_DIR/locationchanger
LAUNCH_AGENTS_DIR=$HOME/Library/LaunchAgents
PLIST_PATH=$LAUNCH_AGENTS_DIR/LocationChanger.plist
CONFIG_DIR=$HOME/.locations

sudo -v

mkdir -p $CONFIG_DIR
cp ./core/locations.conf.sample $CONFIG_DIR/locations.conf

sudo mkdir -p $INSTALL_DIR
sudo cp ./core/locationchanger.sh $SCRIPT_PATH
sudo chmod +x $SCRIPT_PATH

mkdir -p $LAUNCH_AGENTS_DIR
cp ./core/LocationChanger.plist $PLIST_PATH
launchctl load -w $PLIST_PATH

