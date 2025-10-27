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

is-at-least() {
    local version_a="$1"
    local version_b="$2"

    # 将版本号转换为可比较的数字格式
    local IFS=.
    local a=($version_a)
    local b=($version_b)

    # 填充缺失的版本位为0
    while [[ ${#a[@]} -lt ${#b[@]} ]]; do
        a+=(0)
    done
    while [[ ${#b[@]} -lt ${#a[@]} ]]; do
        b+=(0)
    done

    # 逐位比较版本号
    for ((i=0; i<${#a[@]}; i++)); do
        if [[ ${a[i]} -lt ${b[i]} ]]; then
            return 1  # 版本a小于版本b
        elif [[ ${a[i]} -gt ${b[i]} ]]; then
            return 0  # 版本a大于版本b
        fi
    done

    return 0  # 版本相等
}

getSSID() {
    local wifi_port=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}')

    if [[ -z "$wifi_port" ]]; then
        ts "Not connected to Wi-Fi"
        return 1
    fi

    local osVersion=$(sw_vers -productVersion)
    ts "macOS version is '$osVersion'"

    # macOS 15.7 and later
    if is-at-least "$osVersion" "15.7"; then
        wirelessInterface=$(networksetup -listnetworkserviceorder | sed -En 's/^\(Hardware Port: (Wi-Fi|AirPort), Device: (en.)\)$/\2/p')
        preferredWirelessNetworks=$(networksetup -listpreferredwirelessnetworks "${wirelessInterface}")
        # 提取首选WiFi网络列表中的第一个SSID
        # 使用grep排除可能存在的标题行，兼容：
        # - macOS 26版本：输出包含"Preferred networks on en0:"标题
        # - macOS 15.7 版本：直接输出网络列表，无标题行
        # head -1 获取第一行，awk去除首尾空格确保格式整洁
        SSID=$(echo "$preferredWirelessNetworks" | grep -v "Preferred networks" | head -1 | awk '{$1=$1;print}')

    # macOS 15.6+
    elif is-at-least "$osVersion" "15.6"; then
        SSID=$(system_profiler SPAirPortDataType | awk '/Current Network Information:/ { getline; print substr($0, 13, (length($0) - 13)); exit }')

    # macOS 15.0+
    elif is-at-least "$osVersion" "15.0"; then
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
