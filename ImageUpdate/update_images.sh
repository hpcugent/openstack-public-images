#!/bin/bash
source ./common.sh
set -euf -o pipefail
function send_help(){
    cat <<"EOF"
Usage: ./update_images <flags>
Flags:
-f <json_file>  Json file of images to update, default "images.json"
-y              Don't ask for confirmation for each image
-t              Testing mode. Exports TEST=true to ./update_generic.sh so that images are not uploaded.
-d <dir>        Temporary directory for storage
-h              For when you're confused.
Function:
The script will read a json file and pass the values to update_generic.sh to download, modify and then upload OS images to openstack.
EOF
exit 0
}
OPTSTRING=":ythf:d:"
TMP_DIR=${TMP_DIR:=$(pwd)}
while getopts "${OPTSTRING}" opt; do
  case ${opt} in
    y)
      YES=true
      ;;
    t)
      export TEST=true
      ;;
    f)
      PARAM=${OPTARG}
      ;;
    d)
      export TEMPDIR=${OPTARG}
      ;;
    h)
      send_help
      ;;
    *)
      warn "Unknown flag"
      send_help
      ;;
  esac
done
IMG_JSON=${PARAM:="images.json"}
# Check for invalid json file
if jq -e "$IMG_JSON" >/dev/null 2>&1; then
    echo "invalid json file!"
    exit 1
fi
# distro, version_name,version_number
function update_image(){
  ./update_generic.sh
}
images=()
images_size=0
for i in $(seq 0 $(($(jq 'length' "$IMG_JSON")-1))); do
    unset DISTRO VERSION_NAME VERSION_NUMBER
    DISTRO="$(jq -r ".[$i].distro" "$IMG_JSON")"
    VERSION_NAME="$(jq -r ".[$i].version_name" "$IMG_JSON")"
    VERSION_NUMBER="$(jq -r ".[$i].version_number" "$IMG_JSON")"
    export DISTRO VERSION_NAME VERSION_NUMBER
    _has_url="$(jq -r ".[$i] | has(\"url\")" "$IMG_JSON")"
    if [ "$_has_url" == "true" ];then
      URL="$(jq -r ".[$i].url" "$IMG_JSON" | envsubst )"
    else
      URL="$(jq -r ".$DISTRO" urls.json | envsubst )"
    fi
    if [ -z "$URL" ]; then error "No URL found for $DISTRO"; fi
    export URL

    getConfirmation "Update \"${DISTRO^} $VERSION_NUMBER ($VERSION_NAME)\"?" "Updating \"${DISTRO^} $VERSION_NUMBER ($VERSION_NAME)\""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        images+=("DISTRO=$DISTRO VERSION_NAME=$VERSION_NAME VERSION_NUMBER=$VERSION_NUMBER URL=$URL ./update_generic.sh 2>&1 | tee ${DISTRO}_${VERSION_NUMBER}_update.log")
        image_size=$(DISTRO=$DISTRO VERSION_NAME=$VERSION_NAME VERSION_NUMBER=$VERSION_NUMBER URL=$URL ./update_generic.sh -s)
        ((images_size+=image_size))
    fi
done
JOBS=4
HUMAN_BUFFER=5G
BUFFER="$(numfmt --from=iec $HUMAN_BUFFER)"
AVAILABLE_SIZE="$(df --output=avail -B 1 "$TMP_DIR" | tail -n1)"
MIN_SIZE=$((images_size+BUFFER))

echo "TEMPDIR: ${TMP_DIR}"
if [[ $AVAILABLE_SIZE -lt $MIN_SIZE ]];then
  HUMAN_AVAILABLE="$(df -h --output=avail "$TMP_DIR" | tail -n1))"
  HUMAN_NEED="$(numfmt --to=iec $MIN_SIZE)" 
  error "Not enough space in $TMP_DIR !, Need: ${HUMAN_NEED}, Available: ${HUMAN_AVAILABLE}}"
fi
parallel --jobs "$JOBS" --keep-order --bar --eta ::: "${images[@]}"
