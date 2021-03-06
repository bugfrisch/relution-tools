#!/bin/bash -e

if [ ! $JQ_EXECUTABLE ]; then 
    JQ_EXECUTABLE="jq"
fi

while [[ $# > 1 ]]
do
key="$1"

case $key in
    --help)
    RU_HELP=true
    shift # past argument
    ;;
    -f|--file)
    RU_FILE="$2"
    shift # past argument
    ;;
    -e|--environment)
    RU_ENVIRONMENT_UUID="$2"
    shift # past argument
    ;;
    -r|--release_status)
    RU_RELEASE_STATUS="$2"
    shift # past argument
    ;;
    -h|--host)
    RU_HOST="$2"
    shift # past argument
    ;;
    -u|--user)
    RU_USER="$2"
    shift # past argument
    ;;
    -p|--password)
    RU_PASSWORD="$2"
    shift # past argument
    ;;
    -a|--api_key)
    RU_API_KEY="$2"
    shift # past argument
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done

echo ${RU_HELP}

if [ $RU_HELP ] ; then
    echo "  _____      _       _   _             "
    echo " |  __ \    | |     | | (_)            "
    echo " | |__) |___| |_   _| |_ _  ___  _ __  "
    echo " |  _  // _ \ | | | | __| |/ _ \| '_ \ "
    echo " | | \ \  __/ | |_| | |_| | (_) | | | |"
    echo " |_|  \_\___|_|\__,_|\__|_|\___/|_| |_|"
    echo ""
    echo "-f --file               Relative path of the artifact that you want to deploy to the Relution Enterprise App Store, relative to the workspace directory. This is typically an Apple iOS (.ipa) or Google Android (.apk) binary."
    echo "-h --host               The Relution base url to which the file should be deployed."
    echo "-r --release_status     The release status in which the file should be put."  
    echo "-e --environment        The development hub environment id."
    echo "-a --api_key          Relution API Token used for the authentication."    
fi

if [ $RU_RELEASE_STATUS ]; then 
    curl_args="?releaseStatus=$RU_RELEASE_STATUS"
else
    curl_args="?releaseStatus=DEVELOPMENT"
fi

if [ $RU_ENVIRONMENT_UUID ]; then 
    curl_args="${curl_args}&environmentUuid=$RU_ENVIRONMENT_UUID" 
fi

if [ ! $RU_FILE ]; then 
    echo "Use -f to pass the file path"
    exit 1
fi

if [ $RU_API_KEY ]; then
    curl_auth="-H X-User-Access-Token:${RU_API_KEY}"
else
    curl_auth="-u ${RU_USER}:${RU_PASSWORD}"
fi

echo "Uploading '$RU_FILE' to '$RU_HOST/relution/api/v1/apps$curl_args' ..."
response=$(curl $curl_auth -F app=@$PWD/$RU_FILE $RU_HOST/relution/api/v1/apps$curl_args)
echo $response | $JQ_EXECUTABLE '.message'
response_code=$(echo $response | $JQ_EXECUTABLE -r '.status')
if [[ $response_code == "0" ]]; then
    appuuid=$(echo $response | $JQ_EXECUTABLE -r '.results[0].uuid')
    echo "$RU_HOST/relution/portal/#/apps/$appuuid/information"
else
    echo "Upload failed!"
    exit 1
fi
