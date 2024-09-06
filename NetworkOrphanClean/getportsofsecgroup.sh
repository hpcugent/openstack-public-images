#!/bin/bash
set -euf -o pipefail
function send_help(){
    cat <<"EOF"
Usage: ./tracksecgroup.sh <flags> <id>
Flags:
-s              Show port details
-h              For when you're confused.
-c              Show deletion command
-t              Cache time
-p              Project to inspect
EOF
exit 0
}

# Set to true if deletion commands should be shown
SHOW_COMMAND=false
SHOW=false
OPTSTRING=":shct:p:"
while getopts "${OPTSTRING}" opt; do
  case ${opt} in
    s)
      SHOW=true
      ;;
    h)
      send_help
      ;;
    c)
      SHOW_COMMAND=true
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
if [ -z "$1" ];then
  echo "Missing parameter: secgroup ID"
  send_help
fi
sec_group=$1
# shellcheck source=common.sh
source common.sh
usedPorts=()

getPorts
for ID in $IDs; do
if grep -q "$sec_group" "ports/${ID}.json"; then
  usedPorts+=("$ID")
fi
done


for port in "${usedPorts[@]}";do
  if [[ $SHOW == true ]];then
    openstack port show -c admin_state_up -c description -c fixed_ips -c id -c mac_address -c network_id -c security_group_ids -c status -c tags -c updated_at "$port"
  else
    echo "$port"
  fi
done

if [[ $SHOW_COMMAND == true ]];then
  for port in "${usedPorts[@]}";do
   echo "openstack port ${PROJECT[*]} unset --security-group $sec_group $port"
  done 
fi

if [[ $IS_CACHED == true ]];then
  echo "This result is cached!"
fi