#!/bin/bash
source ./common.sh
set -euf -o pipefail
# shellcheck source=./common.sh
function traperr(){
    rm -f "${IMAGE_RELEASE}.img"
    error "$1"
}
trap 'error on $LINENO' 1 2 3 6
case $DISTRO in
    centos | alma )
    _OS_DISTRO="centos"
    ;;
    ubuntu | debian | rocky | cirros)
    _OS_DISTRO=$DISTRO
    ;;
    *)
    error "Unknown distro: \"$DISTRO\""
    ;;
esac
IMAGE_RELEASE="${DISTRO^}-${VERSION_NUMBER}"
if [ "$DISTRO" == "alma" ];then IMAGE_RELEASE="AlmaLinux-${VERSION_NUMBER}";fi
## 
# Load stackrc, set the OS_DISTRO property, create the new imag eand replace it with the old one + archive old one.
##
function upload_image() {
    STACK=$(echo "$HOSTNAME" | cut -d '.' -f 2)
    case $STACK in
        munna | swirlix)
        ;;
        *)
        echo "Unknown stack: $HOSTNAME"
        exit 1
        ;;
    esac
    # No os property for cirros
    _OS_PROPERTY=$([[ $DISTRO != 'cirros' ]] && echo " --property OS_DISTRO=$_OS_DISTRO" || echo "");
    #common.sh
    sourcerc
    set +e
    OLD_ID="$(openstack image show "${IMAGE_RELEASE}" -f json | jq '.id' -r)"
    set -e
    openstack image create "${IMAGE_RELEASE}" --file "${IMAGE_RELEASE}.img" --disk-format qcow2 --container-format bare --public --property hw_vif_multiqueue_enabled=true"$_OS_PROPERTY" --property hw_qemu_guest_agent='yes'
    # Archive old image *after* image create succeeds. Allow failure if not found
    if [ -n "$OLD_ID" ]; then
     openstack image set --name "${IMAGE_RELEASE}-$(date +%F-%H%M%S)" --deactivate "${OLD_ID}"
    else
     warn "OLD ID not found."
    fi
    rm "${IMAGE_RELEASE}.img"
    success "uploaded image"
}
##
# Install chrony and python on debian & rhel-like
##
function install_packages(){
    #Apt
    APT_COMMAND='apt install python3-distro chrony -y && apt clean all'
    #Yum
    DNF_COMMAND='dnf -y install python3 python3-distro chrony'
    case $_OS_DISTRO in
        ubuntu |debian)
        INSTALL_COMMAND="$APT_COMMAND"
        ;;
        centos | rocky)
        INSTALL_COMMAND="$DNF_COMMAND"
        ;;
        *)
        error "unknown distro $DISTRO"
    esac
    virt-customize -x -v -a "${IMAGE_RELEASE}.img" --run-command "$INSTALL_COMMAND" --selinux-relabel
    success "installed packages"
}
##
# Configure chrony to use ugent ntp
##
function configure_crony(){
    CHRONY_FILE='/etc/chrony.conf'
    # Ubuntu puts chrony config elsewhere
    if [ "$_OS_DISTRO" == "ubuntu" ] || [ "$_OS_DISTRO" == "debian" ]; then
        CHRONY_FILE='/etc/chrony/chrony.conf'
    fi
    virt-customize -a "${IMAGE_RELEASE}.img" --run-command "sed -i '1s/^/pool ntp.ugent.be iburst\n/' ${CHRONY_FILE}" --selinux-relabel
    virt-customize -a "${IMAGE_RELEASE}.img" --run-command 'ln -sfn /usr/share/zoneinfo/Europe/Brussels /etc/localtime' --selinux-relabel
    success "configured chrony"
}
function download_iso(){
    wget "${URL}" -O "${IMAGE_RELEASE}.img"
    success "Downloaded ${IMAGE_RELEASE}.img"
}

export LIBGUESTFS_BACKEND=direct

download_iso
if [[ $DISTRO != "cirros" ]]; then
# Generic
virt-customize -a "${IMAGE_RELEASE}.img" --update --selinux-relabel
# Packages
install_packages
# Time stuff
configure_crony
fi
if [ "${TEST:=false}" == true ];then success "test complete"; exit 0;fi
upload_image
