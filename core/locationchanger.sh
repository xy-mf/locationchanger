#!/bin/bash

# This script changes network location based on the name of Wi-Fi network.

exec 2>&1 >> $HOME/Library/Logs/LocationChanger.log

sleep 3

ts() {
    date +"[%Y-%m-%d %H:%M] $*"
}

ID=`whoami`
ts "I am '$ID'"

SSID=""
NEW_LOCATION=""

getSSID() {
    local wifi_port=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}')

    if [[ -z "$wifi_port" ]]; then
        ts "Not connected to Wi-Fi"
        return 1
    fi

    local mac_version=$(sw_vers -productVersion | cut -d '.' -f 1)
    ts "macOS version is '$mac_version'"

    if [[ "$mac_version" -ge 15 ]]; then
        SSID=$(ipconfig getsummary "$wifi_port" | awk -F ' SSID : ' '/ SSID : / {print $2}')
    else
        SSID=$(networksetup -getairportnetwork "$wifi_port" | awk '{print $NF}')
    fi
}

getSSID
if [ -z "$SSID" ]; then
    ts "Failed to retrieve SSID"
    exit 1
fi
ts "Connected to '$SSID'"

getNewLocation(){
    local NEW_SSID
    local E_SSID

    local LOCATION_NAMES=$(networksetup -listlocations)
    local CONFIG_FILE="$HOME/.locations/locations.conf"

    ts "Probing '$CONFIG_FILE'"

    # check config file is exist and update SSID
    if [ -f $CONFIG_FILE ]; then
        ts "Reading to '$CONFIG_FILE'"
        # escape special characters
        E_SSID=`echo "$SSID" | sed 's/[.[\*^$]/\\\\&/g'`
        NEW_SSID=`grep "^$E_SSID=" $CONFIG_FILE | cut -d = -f 2`
        if [ "$NEW_SSID" != "" ]; then
            ts "Will switch the location to '$NEW_SSID' (configuration file)"
            SSID=$NEW_SSID
        else
            ts "Will switch the location to '$SSID'"
        fi
    fi


    E_SSID=`echo "$SSID" | sed 's/[.[\*^$]/\\\\&/g'`
    if echo "$LOCATION_NAMES" | grep -q "^$E_SSID$"; then
        NEW_LOCATION="$SSID"
    else
        if echo "$LOCATION_NAMES" | grep -q "^Automatic$"; then
            NEW_LOCATION=Automatic
            ts "Location '$SSID' was not found. Will default to 'Automatic'"
        else
            ts "Location '$SSID' was not found. The following locations are available: $LOCATION_NAMES"
            exit 1
        fi
    fi
}

changeLocation() {
    local CURRENT_LOCATION=$(networksetup -getcurrentlocation)

    if [ -z "$NEW_LOCATION" ]; then
        ts "Error: NEW_LOCATION is empty"
        return 1
    fi

    if [ "$NEW_LOCATION" == "$CURRENT_LOCATION" ]; then
        ts "Already at '$NEW_LOCATION'"
        return 0
    fi

    ts "Changing location to '$NEW_LOCATION'"
    scselect "$NEW_LOCATION"
    local SCRIPT="$HOME/.locations/$NEW_LOCATION"
    if [ -f "$SCRIPT" ]; then
        ts "Running script '$SCRIPT'"
        "$SCRIPT"
    fi
}

getNewLocation

if [ -n "$NEW_LOCATION" ]; then
    changeLocation
else
    ts "Failed to get a new location, exiting."
    exit 1
fi
