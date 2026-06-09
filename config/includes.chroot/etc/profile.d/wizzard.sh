#!/bin/bash

# ANSI Color Codes
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Check if the setup script exists and hasn't been deleted yet
if [ -f /usr/local/bin/setup.sh ]; then
# Explicitly start the Red ANSI sequence (\e[31m), print all text, then clear it (\e[0m)
echo -e "\e[31m========================================\n           WELCOME TO TABIAN OS\n========================================\n\nYour base system is installed, but needs to be finalized.\nPlease connect an Ethernet cable and run the following command:\n\n   sudo setup.sh\n\n========================================\e[0m"
fi
