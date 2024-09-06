#!/bin/bash
source ./common.sh
set -euf -o pipefail
IMAGE=${1}
_FLAVOR=${TESTFLAVOR:=3}
VMNAME="${IMAGE}-test"
# Timeout in seconds
TIMEOUT=300
sourceprojectrc
function vmIsActive() {
    if [ "$(openstack server show "${VM_ID}" -f json | jq -r '.status')" == "ACTIVE" ]; then
        return 1
    fi
    return 0
}
VM_ID=""
function catchExit(){
    if [[ "$VM_ID" == "" ]];then
        error "Error creating server for $IMAGE"
    fi
}
if [[ "$IMAGE" =~ "Windows" ]];then
    warn "skipped $IMAGE: Can't test Windows"
    exit 0
fi
if [ $STACK == "swirlix" ];then
  PROJECT="VSC_12348"
  NETWORK="VSC_12348_vm"
else
  PROJECT="VSC_00001"
  NETWORK="VSC_00001_vm"
fi
trap catchExit ERR 
SEC_GROUP="$(openstack security group list -f json | jq -r '.[] | select(.Name == "default") | .ID')"
VM_ID="$(openstack server create --flavor "${_FLAVOR}" --image "${IMAGE}" \
  --security-group "$SEC_GROUP" "${VMNAME}" --network "$NETWORK" -f json | jq -r '.id')"
set -e
SECONDS=0
while vmIsActive && [ $SECONDS -lt $TIMEOUT ] ; do
 sleep 5
done
if [ $SECONDS -gt $TIMEOUT ] && vmIsActive ; then
    openstack server delete "${VM_ID}"
    error "$VM_ID Did not become available within $SECONDS seconds".
fi
trap - ERR
set +e
test_exit=1
SECONDS=0
while [[ $test_exit != 0 ]] && [[ $SECONDS -lt 100 ]];do
    openstack console log show "${VM_ID}" | grep -q -e 'BEGIN SSH HOST KEY KEYS' -e 'cloud-init'
    test_exit=$?
    sleep 5
done
set -e
openstack server delete "${VM_ID}"
if [[ $test_exit != 0 ]];then
    error "$IMAGE failed!"
fi

success "$IMAGE validated."