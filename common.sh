#!/bin/bash
set -ef -o pipefail
YES=false
#Colors
ERROR=$(tput setaf 1)
NORMAL=$(tput sgr0)
SUCCESS=$(tput setaf 2)
WARN=$(tput setaf 6)
function error(){
    local MESSAGE=${1:="An error occuERROR!"}
    printf "%s\n" "${ERROR}${MESSAGE}${NORMAL}"
    exit 1
}
function success(){
    printf "%s\n" "${SUCCESS}${1}${NORMAL}"
}
function warn(){
    printf "%s\n" "${WARN}${1}${NORMAL}"
}
function sourcerc(){
    STACK=$(echo "$HOSTNAME" | cut -d '.' -f 2)
    case $STACK in
        munna | swirlix)
        ;;
        *)
        error "Unknown stack: $HOSTNAME"
        ;;
    esac
    source "$HOME/${STACK}rc"
}
function getConfirmation(){
    REPLY="n"
    if [ $YES == false ]; then
        warn "$1"
        read -p "(y/n): " -r
        echo
    else
        warn "$2"
        echo
        REPLY="y"
    fi
    export REPLY
}