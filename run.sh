#!/usr/bin/env bash

# Bitwarden CLI Vault Export Script
# Author: https://github.com/0neTX/Bitwarden_Export

# Constant and global variables
BITWARDENCLI_APPDATA_DIR="${BITWARDENCLI_APPDATA_DIR:-"$(pwd)"}"
params_validated=0
Yellow='\033[0;33m'  # Yellow
IYellow='\033[0;93m' # Yellow
IGreen='\033[0;92m'  # Green
Cyan='\033[0;36m'    # Cyan
UCyan='\033[4;36m'   # Cyan
UWhite='\033[4;37m'  # White
Blue='\033[0;34m'    # Blue

#Set Vaultwarden own server.
# To obtain your organization_id value, open a terminal and type:
#   bw login #(follow the prompts);
if [[ -z "${BW_URL_SERVER}" ]]; then
    echo -e -n "$Cyan" # set text = yellow
    echo -e "\nInfo: BW_URL_SERVER enviroment not provided."

    echo -n "$(date '+%F %T') If you have your own Bitwarden or Vaulwarden server, set in the environment variable BW_URL_SERVER its url address. "
    echo -n "$(date '+%F %T') Example: https://skynet-vw.server.com"
    echo
else
    bw_url_server="${BW_URL_SERVER}"
fi

#Set Bitwarden session authentication.
# To obtain your organization_id value, open a terminal and type:
#   bw login #(follow the prompts);
if [[ -z "${BW_CLIENTID}" ]]; then

    echo -e "\n$(date '+%F %T') ${IYellow}ERROR: BW_CLIENTID enviroment variable not provided, exiting..."

    echo -n "$(date '+%F %T') Your Bitwarden Personal API Key can be obtain in:"
    echo -n "$(date '+%F %T') https://bitwarden.com/help/personal-api-key/"
    params_validated=-1
else
    if test -f "${BW_CLIENTID}"; then
        client_id=$(<"${BW_CLIENTID}")
    else
        client_id="${BW_CLIENTID}"
    fi

fi


if [[ -z "${BW_CLIENTSECRET}" ]]; then

    echo -e "\n$(date '+%F %T') ${IYellow}ERROR: BW_CLIENTSECRET enviroment variable not provided, exiting..."

    echo -n "$(date '+%F %T') Your Bitwarden Personal API Key can be obtain in:"
    echo -n "$(date '+%F %T') https://bitwarden.com/help/personal-api-key/"
    params_validated=-1
else
    if test -f "${BW_CLIENTSECRET}"; then
        client_secret=$(<"${BW_CLIENTSECRET}")
    else
        client_secret="${BW_CLIENTSECRET}"
    fi

fi


if [[ -z "${BW_PASSWORD}" ]]; then

    echo -e "\n$(date '+%F %T') ${IYellow}ERROR: BW_PASSWORD enviroment variable not provided, exiting..."

    params_validated=-1
else

    if test -f "${BW_PASSWORD}"; then
        bw_password=$(<"${BW_PASSWORD}")
    else
        bw_password="${BW_PASSWORD}"
    fi
fi

# Check if required parameters has beed proviced.
if [[ $params_validated != 0 ]]; then
    echo -e "\n$(date '+%F %T') ${IYellow}One or more required environment variables have not been set."
    echo -e "${IYellow}Please check the required environment variables:"
    echo -e "${IYellow}BW_CLIENTID,BW_CLIENTSECRET,BW_PASSWORD"
    exit 1
fi

npm install -g @bitwarden/cli

if [[ $bw_url_server != "" && $bw_url_server != *"bitwarden.com" ]]; then
    echo "$(date '+%F %T') Setting custom server..."
    bw config server "$bw_url_server" --nointeraction
    echo
fi

BW_CLIENTID=$client_id
BW_CLIENTSECRET=$client_secret
#Login user if not already authenticated
if [[ $(bw status | jq -r .status) == "unauthenticated" ]]; then
    echo "$(date '+%F %T') Performing login..."
    bw login --apikey --method 0 --quiet --nointeraction
fi
if [[ $(bw status | jq -r .status) == "unauthenticated" ]]; then
    echo -e "\n$(date '+%F %T') ${IYellow}ERROR: Failed to login."
    echo
    exit 1
fi

#Unlock the vault
echo "$(date '+%F %T') Unlocking the vault..." 
session_key=$(bw unlock "$bw_password" --raw)
#Verify that unlock succeeded

if [[ $session_key == "" ]] ||  [[ " $session_key"  == "0" ]]; then
    echo -e "\n$(date '+%F %T') ${IYellow}ERROR: Failed to unlock vault with BW_PASSWORD."
    exit 1
else
    echo "$(date '+%F %T') Vault unlocked."
fi
#Export the session key as an env variable (needed by BW CLI)
export BW_SESSION="$session_key"

bw export --format json --output "$(pwd)/password.json"

zip --password "$bw_password" "$EXPORT_FILE" password.json
