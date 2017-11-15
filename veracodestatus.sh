#!/bin/bash
APP_ID=your_app_id
API_USERNAME="username"
API_PASSWORD="password"
PRESCAN_SLEEP_TIME=300
SCAN_SLEEP_TIME=300


# Validate HTTP response
function validate_response {
        local response="$1"

        # Check if response is XML
        if ! [[ "$response" =~ (\<\?xml version=\"1\.0\" encoding=\"UTF-8\"\?\>) ]]; then
                echo "[-] Response body is not XML format at `date`"
                echo "$response"
                #exit 1
        fi

        # Check for an error element
        if [[ "$response" =~ (<error>[a-zA-Z0-9 \.]+</error>) ]]; then
                local error=$(echo $response | sed -n 's/.*<error>\(.*\)<\/error>.*/\1/p')
                echo "[-] Error: $error"
                exit 1
        fi
}

# Poll scan status
function pollscan {
        echo "[+] Polling scan status every $SCAN_SLEEP_TIME seconds"
        local is_scanning=true
        while $is_scanning; do
                sleep $SCAN_SLEEP_TIME

                local build_info_response=`curl --silent --compressed -u "$API_USERNAME:$API_PASSWORD" https://analysiscenter.veracode.com/api/5.0/getdynamicstatus.do -F "app_id=$APP_ID"`
                validate_response "$build_info_response"
                if [[ "$build_info_response" =~ (<scan_status>Results Ready</scan_status>) ]]; then
                        is_scanning=false
                        echo -e "\n[+] Scan complete"
                else
                        echo -n -e "\n[+] `date` Scan still in Process"
                fi
        done
}

echo "Init - `date`"

pollscan

echo "Complete - `date`"

exit 0
