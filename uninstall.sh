#!/bin/bash

INSTALL_DIR=/usr/local/bin
SCRIPT_PATH=$INSTALL_DIR/locationchanger
LAUNCH_AGENTS_DIR=$HOME/Library/LaunchAgents
PLIST_PATH=$LAUNCH_AGENTS_DIR/LocationChanger.plist
CONFIG_DIR=$HOME/.locations

sudo -v

launchctl unload -w $PLIST_PATH
sudo rm $PLIST_PATH

sudo rm $SCRIPT_PATH

rm $HOME/Library/Logs/LocationChanger.log

rm -rf $CONFIG_DIR