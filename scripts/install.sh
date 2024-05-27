#!/bin/bash

# Check if the script is running with sudo
if [ "$EUID" -ne 0 ]; then
    echo "This script requires sudo privileges."
    exit 1
fi

# Clone the repository
echo "-------> Cloning the repository"
git clone https://github.com/Jace254/Citrix-Node.git

# Move the cloned repository to the desired location
echo "-------> Moving the repository to /var/www/html/scripts/citrix-node"
mv Citrix-Node /var/www/html/scripts/citrix-node

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