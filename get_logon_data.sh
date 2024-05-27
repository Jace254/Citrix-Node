#!/bin/bash

show_help() {
  echo ""
  echo "Usage: $0 -c <client_id> -s <client_secret> -u <customer_id>"
  echo ""
  echo "Options:"
  echo "  -c <client_id>        Specify the client ID."
  echo "  -l <client_secret>    Specify the client secret."
  echo "  -u <customer_id>      Specify the customer ID."
  echo "  -h, --help            Show this help message and exit."
  echo ""
}

for arg in "$@"; do
  case $arg in
    -h|--help)
      show_help
      exit 0
      ;;
  esac
done

while getopts ":c:s:u:h" opt; do
  case $opt in
    c) CLIENT_ID="$OPTARG" ;;
    s) CLIENT_SECRET="$OPTARG" ;;
    u) CUSTOMER_ID="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
    :) echo "Option -$OPTARG requires an argument." >&2; show_help; exit 1 ;;
  esac
done

# Check for required arguments
if [ -z "$CLIENT_ID" ]; then
  echo "!!!!!! Please provide the client_id with the -c flag."
  echo "Usage: $0 -c <client_id> -s <client_secret> -u <customer_id>"
  exit 1
fi

if [ -z "$CLIENT_SECRET" ]; then
  echo "!!!!!! Please provide the client_secret with the -s flag."
  echo "Usage: $0 -c <client_id> -s <client_secret> -u <customer_id>"
  exit 1
fi

if [ -z "$CUSTOMER_ID" ]; then
  echo "!!!!!! Please provide the customer_id with the -u flag."
  echo "Usage: $0 -c <client_id> -s <client_secret> -u <customer_id>"
  exit 1
fi

echo "-----> Client ID: ${CLIENT_ID}"
echo "-----> Client Secret: ${CLIENT_SECRET}"
echo "-----> Customer ID: ${CUSTOMER_ID}"

# Export all variables (lowercase for consistency)
export client_id="$CLIENT_ID" client_secret="$CLIENT_SECRET" customer_id="$CUSTOMER_ID"

# Run the script with exported variables
node ./src/index.js