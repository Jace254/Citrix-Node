#!/bin/bash
LOGON_DURATION=0

show_help() {
  echo ""
  echo "Usage: $0 -c <client_id> -s <client_secret> -u <customer_id> [-l <logon_duration>]"
  echo ""
  echo "Options:"
  echo "  -c <client_id>        Specify the client ID."
  echo "  -s <client_secret>    Specify the client secret."
  echo "  -u <customer_id>      Specify the customer ID."
  echo "  -l <logon_duration>   Specify the logon duration period for the script."
  echo "                        Default is 0 seconds"
  echo "  -p <citrix_host>      Specify the HOST to use"
  echo ""
  echo "  -h, --help            Show this help message."
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

while getopts ":c:s:u:l:p:h" opt; do
  case $opt in
    c) CLIENT_ID="$OPTARG" ;;
    s) CLIENT_SECRET="$OPTARG" ;;
    u) CUSTOMER_ID="$OPTARG" ;;
    p) CITRIX_HOST="$OPTARG" ;;
    l) LOGON_DURATION="$OPTARG"
    if ! [[ "$LOGON_DURATION" =~ ^[0-9]+$ ]]; then
        echo "Error: logon_duration must be a number."
        exit 1
      fi
    ;;
    \?) echo "Invalid option: -$OPTARG" >&2; show_help exit 1 ;;
    :) echo "Option -$OPTARG requires an argument." >&2; show_help; exit 1 ;;
  esac
done

# Check for required arguments
if [ -z "$CLIENT_ID" ]; then
  echo "!!!!!! Please provide the client_id with the -c flag."
  show_help
  exit 1
fi

if [ -z "$CLIENT_SECRET" ]; then
  echo "!!!!!! Please provide the client_secret with the -s flag."
  show_help
  exit 1
fi

if [ -z "$CUSTOMER_ID" ]; then
  echo "!!!!!! Please provide the customer_id with the -u flag."
  show_help
  exit 1
fi


echo "-----> Client ID: ${CLIENT_ID}"
echo "-----> Client Secret: ${CLIENT_SECRET}"
echo "-----> Customer ID: ${CUSTOMER_ID}"
echo "-----> Citrix HOST: ${CITRIX_HOST}"

# Export all variables (lowercase for consistency)
export client_id="$CLIENT_ID" client_secret="$CLIENT_SECRET" customer_id="$CUSTOMER_ID" logon_duration="$LOGON_DURATION" citrix_host="$CITRIX_HOST"

# Run the script with exported variables
node "/var/www/html/scripts/citrix-node/src/logon_data.js"