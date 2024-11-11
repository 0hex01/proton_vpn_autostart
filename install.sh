#!/bin/bash

# Get the directory of the script
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Define paths
INSTALL_TAR="$SCRIPT_DIR/install.tar.gz"
VPN_FOLDER_PATH="$SCRIPT_DIR/vpn"
VPN_BIN_PATH="$VPN_FOLDER_PATH/bin/"
DEST_BIN_PATH="/usr/local/bin/"
DEST_VPN_PATH="/home/user/scripts/vpn/"

# Check if the install.tar.gz file exists
if [ ! -f "$INSTALL_TAR" ]; then
    echo "Error: $INSTALL_TAR not found."
    exit 1
fi

# Unzip the install.tar.gz file
echo "Unzipping $INSTALL_TAR..."
tar -xzf "$INSTALL_TAR" -C "$SCRIPT_DIR"

# Check if the /vpn/ folder exists after extraction
if [ ! -d "$VPN_FOLDER_PATH" ]; then
    echo "Error: $VPN_FOLDER_PATH not found."
    exit 1
fi

# Copy the entire /vpn folder to /home/user/scripts/
echo "Copying $VPN_FOLDER_PATH to $DEST_VPN_PATH..."
sudo mkdir -p "$DEST_VPN_PATH"
sudo cp -r "$VPN_FOLDER_PATH"/* "$DEST_VPN_PATH"

# Copy files from /vpn/bin/ to /usr/local/bin/
echo "Copying files from $VPN_BIN_PATH to $DEST_BIN_PATH..."
sudo cp -r "$VPN_BIN_PATH"* "$DEST_BIN_PATH"

# Set the file to run at boot automatically
SELECTED_FILE="ovpn"

# Validate if the selected file exists
if [ ! -f "$DEST_BIN_PATH/$SELECTED_FILE" ]; then
    echo "Error: $DEST_BIN_PATH/$SELECTED_FILE not found."
    exit 1
fi

# Get the name of the selected file (without the path)
SERVICE_NAME=$(basename "$SELECTED_FILE")

# Create a systemd service file
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"

echo "Creating systemd service for $SELECTED_FILE..."

# Write the service file content
sudo bash -c "cat > $SERVICE_FILE <<EOF
[Unit]
Description=Run $SELECTED_FILE at boot
After=network.target

[Service]
ExecStart=$DEST_BIN_PATH/$SELECTED_FILE
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF"

# Reload systemd to apply changes
sudo systemctl daemon-reload

# Enable the service to start on boot
sudo systemctl enable $SERVICE_NAME.service

# Start the service immediately
sudo systemctl start $SERVICE_NAME.service

# Display the service status
sudo systemctl status $SERVICE_NAME.service
