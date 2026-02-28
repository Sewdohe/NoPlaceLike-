#!/bin/bash

if pgrep -x "syncthing" > /dev/null; then
    echo '{"text": "󰓦", "tooltip": "Syncthing is running", "class": "running"}'
else
    echo '{"text": "󰓨", "tooltip": "Syncthing is not running", "class": "stopped"}'
fi
