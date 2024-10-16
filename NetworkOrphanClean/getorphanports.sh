#!/bin/bash
set -euf -o pipefail
function help(){
    cat <<"EOF" 
Usage: ./getdeadports.sh <flags> <id>
Flags:
-s              Show port details
-h              For when you're confused.
-t              Cache time
-o              Show only ports that are DOWN but have an IP that matches an existing VM.
-p              The project to inspect
EOF
exit 0
}


# shellcheck source=getvmofport.sh
source getvmofport.sh

SHOW=false
showOffVMs=false
OPTSTRING=":shot:p:"
while getopts "${OPTSTRING}" opt; do
  case ${opt} in
    s)
      SHOW=true
      ;;
    h)
      help
      ;;
    t)
      export CACHETIME=${OPTARG}
      ;;
    o)
      showOffVMs=true
      ;;
    p)
      export _PROJECT=${OPTARG}
      ;;
    *)
      echo "Unknown flag"
      help
      ;;
  esac
done
# shellcheck source=common.sh
source common.sh
getPorts
deadPorts=()
offVMs=0
for ID in $IDs; do
 if [[ "$( getProperty "$ID" "status" )" != "ACTIVE" && "$(getProperty "$ID" "security_group_ids")" != "[]" ]]; then
  vms="$(getVMsOfPort "$ID")"
  if [ $showOffVMs == false ] && [ "$vms" != "[]" ];then (( offVMs += 1));fi
  if [ $showOffVMs == true ] && [ "$vms" != "[]" ];then
      deadPorts+=("$ID")
  elif [ $showOffVMs == false ] && [ "$vms" == "[]" ];then
      deadPorts+=("$ID")
  fi
 fi
done

for port in "${deadPorts[@]}";do
  if [[ $SHOW == true ]];then
  openstack port show -c description -c fixed_ips -c id -c security_group_ids -c status -c tags -c updated_at "$port"
    if [[ $showOffVMs == true ]];then
        vms="$(getVMsOfPort "$port")"
        if [ "$vms" != "[]" ];then
            echo "Attached VM(s): $vms"
        fi
    fi
  else
    secgroup_ids="$(getProperty "$port" 'security_group_ids' )"
    echo "port: $port"
    echo "security groups: $secgroup_ids"
    echo "-------------"
  fi
done
# If interactive shell
if [[ -t 0 ]]
then
    if [ $showOffVMs == false ]; then
    echo "$offVMs not shown due to IP matches with existing VMs. Use -o to show these VMs."
    fi
    if [[ $IS_CACHED == true ]];then
    echo "This result is cached!"
    fi
fi