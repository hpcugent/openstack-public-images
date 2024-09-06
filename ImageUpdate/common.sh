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
export STACK=$(echo "$HOSTNAME" | cut -d '.' -f 2)
case $STACK in
    munna | swirlix)
    ;;
    *)
    error "Unknown stack: $HOSTNAME"
    ;;
esac
function sourcerc(){
    # remove old openstack stuff
    while read -r varname; do unset "$varname"; done < <(env | grep ^OS_ | cut -d '=' -f1)
    source "${HOME}/${STACK}rc"
}
function sourceprojectrc(){
    if [[ ! -f projectrc ]];then
        error "projectrc not found!"
    fi
    # remove old openstack stuff
    while read -r varname; do unset "$varname"; done < <(env | grep ^OS_ | cut -d '=' -f1)
    source projectrc
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
