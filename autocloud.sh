#!/usr/bin/env sh

# Declarations of names and ids of records.
declare -a RECORD_NAMES=("exemple.com" "www.exemple.com")
AUTH_EMAIL="youremail@gmail.com"
AUTH_KEY="000000000000000000000000000000"
ZONE_NAME="zone.com"
IP_FILE="/tmp/CloudFlare_IP" 
PROXIED=true


# Cheking that data was provided
if [ "$AUTH_KEY" = "Your_authorization_key" ] || [ "$AUTH_KEY" = "" ]; then
    echo "Missing Cloudflare API Key."
    exit 2
fi
if [ "$AUTH_EMAIL" = "Your_email_adress_in_cloudflare_services" ] || [ "$AUTH_EMAIL" = "" ]; then
    echo "Missing email address, used to create Cloudflare account."
    exit 2
fi
if [ ${#RECORD_NAMES[@]} = 0 ] || [ ${RECORD_NAMES[0]} = "Your_name_1" ] ; then
    echo "Missing hostname, you should provide at least one name."
    exit 2
fi
if [ "$ZONE_NAME" = "Your_zone_name" ] || [ "$ZONE_NAME" = "" ]; then
    echo "Missing zone name."
    exit 2
fi


# Obtaing zone ID
ZONE_ID="f8f2721bdc0fb6cfb9ae4a61b3d1e37e"

if [ "$ZONE_ID" = "" ]; then
    printf 'Something went wrong in line: %s \n' "${BASH_LINENO[i]}";
    echo $(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$NAME_OF_RECORD" -H "X-Auth-Email: $AUTH_EMAIL" -H "X-Auth-Key: $AUTH_KEY" -H "Content-Type: application/json")
    exit 2
fi


# Checking that file exists
if [ -f $IP_FILE ]; then
    IP_FROM_FILE=$(cat $IP_FILE)
else
    IP_FROM_FILE=""
    echo "No file with old IP, dont worry script will still work, and create that file for you :)"
fi


# Get the current public IP address
ACTUAL_IP="51.210.83.53"


# Otherwise, your Internet provider changed your public IP again.
# Loop for all our records.
for i in ${!RECORD_NAMES[@]}; do

    NAME_OF_RECORD=${RECORD_NAMES[$i]}
    # Getting ID of record
    ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$NAME_OF_RECORD" -H "X-Auth-Email: $AUTH_EMAIL" -H "X-Auth-Key: $AUTH_KEY" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1)
    # Creating record with the new public IP address for Cloudflare using API v4
    RECORD=$(
        cat <<EOF
	{ "type": "A",
  	"name": "$NAME_OF_RECORD",
  	"content": "$ACTUAL_IP",
  	"ttl": 180,
  	"proxied": $PROXIED }
EOF
    )

    RESPONSE=$(curl --silent "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$ID" \
        -X PUT \
        -H "Content-Type: application/json" \
        -H "X-Auth-Email: $AUTH_EMAIL" \
        -H "X-Auth-Key: $AUTH_KEY" \
        -d "$RECORD")

    if [ "$(echo $RESPONSE | grep "\"success\":true")" != "" ]; then
        # Saves new IP to file.
        echo $ACTUAL_IP >$IP_FILE
        echo "$NAME_OF_RECORD IP address updated successful"
    else
        printf 'Something went wrong in line: %s \n' "${BASH_LINENO[i]}";
        echo "Response: $RESPONSE"
    fi

done