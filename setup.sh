#!/bin/bash

# Ensure the script is being run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root or with sudo"
    exit 1
fi

# Function to wait for apt locks to be released
wait_for_apt() {
    local max_attempts=60  # Maximum number of attempts (10 minutes total)
    local attempt=1

    echo "Waiting for apt locks to be released..."
    
    while [ $attempt -le $max_attempts ]; do
        if ! lsof /var/lib/dpkg/lock-frontend >/dev/null 2>&1 && \
           ! lsof /var/lib/apt/lists/lock >/dev/null 2>&1 && \
           ! lsof /var/lib/dpkg/lock >/dev/null 2>&1; then
            echo "Locks released, proceeding with installation..."
            return 0
        fi
        
        echo "Attempt $attempt/$max_attempts: Package system is locked. Waiting 10 seconds..."
        sleep 10
        attempt=$((attempt + 1))
    done

    echo "Error: Package system is still locked after $max_attempts attempts."
    echo "Please try the following:"
    echo "1. Wait for unattended-upgrades to complete"
    echo "2. Check running processes: ps aux | grep -i apt"
    echo "3. Verify system status: systemctl status unattended-upgrades"
    return 1
}

# Function to clean up existing NGINX installation
cleanup_nginx() {
    echo "Cleaning up existing NGINX installation..."
    systemctl stop nginx || true
    wait_for_apt && apt-get remove --purge nginx nginx-common nginx-full -y || true
    wait_for_apt && apt-get autoremove -y || true
    rm -rf /etc/nginx
    rm -rf /var/log/nginx
    rm -rf /var/www/html
    echo "Cleanup completed."
}

# Function to perform system updates
update_system() {
    echo "Updating system packages..."
    if wait_for_apt; then
        apt-get update
        apt-get upgrade -y
        echo "System update completed."
    else
        echo "Failed to acquire package system locks for system update."
        exit 1
    fi
}

# Function to verify NGINX installation
# verify_nginx() {
#     if nginx -v 2>/dev/null; then
#         echo "NGINX installed successfully."
#         return 0
#     else
#         echo "NGINX installation verification failed."
#         return 1
#     fi
# }

# Main installation function
install_nginx() {
    echo "Installing NGINX..."
    if wait_for_apt; then
        apt-get install nginx -y
        if [ $? -ne 0 ]; then
            echo "Error: Failed to install NGINX"
            return 1
        fi
    else
        echo "Failed to acquire package system locks for NGINX installation."
        return 1
    fi
    return 0
}

# Start execution
echo "Starting NGINX setup process..."

# First, clean up any existing installation
cleanup_nginx

# Update system
update_system

# Install NGINX
install_nginx

# if ! verify_nginx; then
#     echo "Installation failed. Exiting."
#     exit 1
# fi

# Enable NGINX to start on boot
echo "Enabling NGINX to start on boot..."
systemctl enable nginx

# Create necessary directories
echo "Creating necessary directories..."
mkdir -p /var/log/nginx
chmod 755 /var/log/nginx

# Create the NGINX configuration file
CONFIG_FILE="/etc/nginx/sites-available/learn.thesama.in"
echo "Creating NGINX config for learn.thesama.in..."
cat <<EOF > "$CONFIG_FILE"
server {
    listen 80;
    server_name learn.thesama.in;
    access_log /var/log/nginx/learn.thesama.in.access.log;
    error_log /var/log/nginx/learn.thesama.in.error.log;
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        # Add timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF

# Remove default site if it exists
rm -f /etc/nginx/sites-enabled/default

# Create symbolic link
ln -sf "$CONFIG_FILE" /etc/nginx/sites-enabled/

# Test configuration
echo "Testing NGINX configuration..."
nginx -t
if [ $? -ne 0 ]; then
    echo "Error: NGINX configuration test failed"
    exit 1
fi

# Check if the service on port 8000 is running
echo "Checking if the service on port 8000 is available..."
if ! curl -s http://127.0.0.1:8000 > /dev/null; then
    echo "Error: Service on port 8000 is not running. Please start the service and try again."
    exit 1
fi

# Check if port 80 is available
if netstat -tuln | grep ':80 '; then
    echo "Warning: Port 80 is already in use. Please check running services."
    netstat -tuln | grep ':80 '
    exit 1
fi

# Update /etc/hosts
if ! grep -q "127.0.0.1 learn.thesama.in" /etc/hosts; then
    echo "127.0.0.1 learn.thesama.in" >> /etc/hosts
    echo "Added learn.thesama.in to /etc/hosts"
fi

# Reload and Restart NGINX
echo "Reloading and Restarting NGINX..."
systemctl reload nginx
systemctl restart nginx

# Final verification
# if systemctl is-active nginx >/dev/null 2>&1; then
#     echo "NGINX is running successfully."
#     echo "Configuration completed successfully."
#     systemctl status nginx
# else
#     echo "Error: NGINX failed to start."
#     echo "Checking logs..."
#     journalctl -xeu nginx.service | tail -n 50
# fi
