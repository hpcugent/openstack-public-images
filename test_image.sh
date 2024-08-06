#!/bin/bash
source ./common.sh
set -euf -o pipefail
IMAGE=${1}
VMNAME="${IMAGE}-test"
# Timeout in seconds
TIMEOUT=300
sourcerc
function vmIsActive() {
    if [ "$(openstack server show "${VM_ID}" -f json | jq -r '.status')" == "ACTIVE" ]; then
        return 1
    fi
    return 0
}
SEC_GROUP="$(openstack security group list --project admin -f json | jq -r '.[] | select(.Name == "default") | .ID')"
VM_ID="$(openstack server create --flavor 1 --image "${IMAGE}" \
  --security-group "$SEC_GROUP" "${VMNAME}" --network "public" -f json | jq -r '.id')"
set -e
SECONDS=0
while vmIsActive && [ $SECONDS -lt $TIMEOUT ] ; do
 sleep 5
done
if [ $SECONDS -gt $TIMEOUT ] && vmIsActive ; then
    openstack server delete "${VM_ID}"
    error "VM_ID Did not become available within $SECONDS seconds".
fi
sleep 20
test_exit=1
set +e
test_comm="$(openstack console log show "${VM_ID}" | grep 'Cloud-init target')"
$test_comm
test_exit=$?
set +e
openstack server delete "${VM_ID}"
if [[ $test_exit != 0 ]];then
    error "ssh failed!"
fi

success "$IMAGE validated."