#!/bin/bash
set -euf -o pipefail


source common.sh
function getVMsOfPort(){
    portID=$1
    portIPs="$( getProperty "$portID" "fixed_ips[].ip_address" )"

    ipRegex=""
    for ip in $portIPs;do
        ipRegex="${ipRegex}|${ip}"
    done
    # cut first |
    ipRegex="${ipRegex:1}"

    openstack server list "${PROJECT[@]}" --ip "$ipRegex" -f json
}

if [ "$0" == "${BASH_SOURCE[0]}" ]; then
    function send_help(){
cat <<"EOF"
Usage: ./getvmofport.sh <flags> <id>
Flags:
-h              For when you're confused.
-t              Cache time
-p              The project to inspect
EOF
    exit 0
    }
    OPTSTRING=":ht:p:"
    while getopts "${OPTSTRING}" opt; do
    case ${opt} in
        h)
        send_help
        ;;
        t)
        export CACHETIME=${OPTARG}
        ;;
        p)
        export _PROJECT=${OPTARG}
        ;;
        *)
        echo "Unknown flag"
        send_help
        ;;
    esac
    done
    shift $((OPTIND-1))
    getVMsOfPort "$1"
fi

