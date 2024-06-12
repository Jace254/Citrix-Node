#!/bin/bash

sudo apt update
# Check if nvm is installed for the zabbix user
if [ ! -d "/home/zabbix/.nvm" ]; then
    echo "nvm is not installed for the zabbix user. Installing nvm..."
    sudo -u zabbix bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash'
fi

# Activate nvm for the zabbix user
export NVM_DIR="/home/zabbix/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Install Node.js and npm using nvm for the zabbix user
echo "-------> Installing Node.js and npm using nvm for the zabbix user..."
sudo -u zabbix apt install nodejs
sudo -u zabbix bash -c 'nvm install node'

# Check if pnpm is installed for the zabbix user
if ! sudo -u zabbix bash -c 'command -v pnpm &> /dev/null'; then
    echo "pnpm is not installed for the zabbix user. Installing pnpm..."
    sudo -u zabbix bash -c 'npm install -g pnpm'
fi

# Clone the repository
echo "-------> Cloning the repository"
sudo -u zabbix bash -c 'git clone https://github.com/Jace254/Citrix-Node.git'

# Move the cloned repository to the desired location
echo "-------> Moving the repository to /var/www/html/scripts/citrix-node"
sudo -u zabbix bash -c 'mkdir -p /var/www/html/scripts'
sudo -u zabbix bash -c 'mv Citrix-Node /var/www/html/scripts/citrix-node'
cd /var/www/html/scripts/citrix-node && sudo -u zabbix bash -c 'pnpm install'

# Give execute permission to the script and then add to /usr/local/bin
echo "-------> Adding get_logon_data to global scope"
sudo -u zabbix bash -c 'chmod +x /var/www/html/scripts/citrix-node/get_logon_data.sh'
sudo cp /var/www/html/scripts/citrix-node/get_logon_data.sh /usr/local/bin/get_logon_data

# Check if /usr/lib/zabbix/externalscripts path exists
if [ ! -d "/usr/lib/zabbix/externalscripts" ]; then
    echo "Creating /usr/lib/zabbix/externalscripts directory..."
    mkdir -p /usr/lib/zabbix/externalscripts
fi

# Copy the script to /usr/lib/zabbix/externalscripts if the path exists
if [ -d "/usr/lib/zabbix/externalscripts" ]; then
    echo "Copying get_logon_data script to /usr/lib/zabbix/externalscripts/citrix.sh"
    cp /var/www/html/scripts/citrix-node/get_logon_data.sh /usr/lib/zabbix/externalscripts/citrix.sh
else
    echo "Failed to copy get_logon_data script. /usr/lib/zabbix/externalscripts directory does not exist."
fi

# Clean up by deleting this script
echo "-------> Cleaning up"
rm "$0"

# Run the get_logon_data.sh script with the -h option
echo "-------> get_logon_data --help"
sudo -u zabbix bash -c 'get_logon_data -h'
