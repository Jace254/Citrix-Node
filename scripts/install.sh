#!/bin/bash

# Check if the script is running with sudo
if [ "$EUID" -ne 0 ]; then
    echo "This script requires sudo privileges."
    exit 1
fi

# Check if nvm is installed
if ! command -v nvm &> /dev/null; then
    echo "nvm is not installed. Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
    # Activate nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
fi

# Install Node.js and npm using nvm
echo "-------> Installing Node.js and npm using nvm..."
nvm install node

# Check if pnpm is installed
if ! command -v pnpm &> /dev/null; then
    echo "pnpm is not installed. Installing pnpm..."
    npm install -g pnpm
fi

# Clone the repository
echo "-------> Cloning the repository"
git clone https://github.com/Jace254/Citrix-Node.git

# Move the cloned repository to the desired location
echo "-------> Moving the repository to /var/www/html/scripts/citrix-node"
mkdir /var/www/html/scripts
mv Citrix-Node /var/www/html/scripts/citrix-node
cd /var/www/html/scripts/citrix-node && pnpm install

# Give execute permission to the script and then add to /usr/local/bin
echo "-------> Adding get_logon_data to global scope"
chmod +x /var/www/html/scripts/citrix-node/get_logon_data.sh
cp /var/www/html/scripts/citrix-node/get_logon_data.sh /usr/local/bin/get_logon_data

# Clean up by deleting this script
echo "-------> Cleaning up"
rm "$0"

# Run the get_logon_data.sh script with the -h option
echo "-------> get_logon_data --help"
get_logon_data -h
