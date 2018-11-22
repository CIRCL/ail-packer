#!/usr/bin/env bash

# Timing creation
TIME_START=$(date +%s)

# Latest version of AIL, tags disabled as not maintained.
##VER=$(curl -s https://api.github.com/repos/CIRCL/AIL-framework/tags  |jq -r '.[0] | .name')
VER='master'
# Latest commit hash of AIL
LATEST_COMMIT=$(curl -s https://api.github.com/repos/CIRCL/AIL-framework/commits  |jq -r '.[0] | .sha')
# SHAsums to be computed
SHA_SUMS="1 256 384 512"

PACKER_NAME="ail"
PACKER_VM="AIL"
NAME="ail-packer"

# Update time-stamp and make sure file exists
touch /tmp/${PACKER_NAME}-latest.sha

# Configure your user and remote server
REMOTE=1
REL_USER="${PACKER_NAME}-release"
REL_SERVER="cpab"

# GPG Sign
GPG_ENABLED=0
GPG_KEY="0x9BE4AEE9"

# Enable debug for packer, omit -debug to disable
##PACKER_DEBUG="-debug"

# Enable logging for packer
export PACKER_LOG=1

# Make sure we have a current work directory
PWD=`pwd`

# Make sure log dir exists (-p quiets if exists)
mkdir -p ${PWD}/log

vm_description='AIL is a modular framework to analyse potential information leaks from unstructured data sources like pastes from Pastebin or similar services or unstructured data streams. AIL framework is flexible and can be extended to support other functionalities to mine or process sensitive information.'
vm_version='master'

# Place holder, this fn() should be used to anything signing related
function signify()
{
if [ -z "$1" ]; then
  echo "This function needs an arguments"
  exit 1
fi

}

function removeAll()
{
  # Remove files for next run
  rm -r output-virtualbox-iso
  rm -r output-vmware-iso
  rm *.checksum *.zip *.sha*
  rm ${PACKER_NAME}-deploy.json
  rm packer_virtualbox-iso_virtualbox-iso_sha1.checksum.asc
  rm packer_virtualbox-iso_virtualbox-iso_sha256.checksum.asc
  rm packer_virtualbox-iso_virtualbox-iso_sha384.checksum.asc
  rm packer_virtualbox-iso_virtualbox-iso_sha512.checksum.asc
  rm AIL_${VER}@${LATEST_COMMIT}-vmware.zip.asc
  rm /tmp/LICENSE-${PACKER_NAME}
}

# TODO: Make it more graceful if files do not exist
removeAll

# Fetching latest AIL-framework LICENSE
/usr/bin/wget -q -O /tmp/LICENSE-${PACKER_NAME} https://raw.githubusercontent.com/CIRCL/AIL-framework/master/LICENSE

# Check if latest build is still up to date, if not, roll and deploy new
if [ "${LATEST_COMMIT}" != "$(cat /tmp/${PACKER_NAME}-latest.sha)" ]; then

  echo "Current ${PACKER_VM} version is: ${VER}@${LATEST_COMMIT}"

  # Search and replace for vm_name and make sure we can easily identify the generated VMs
  cat ${PACKER_NAME}.json| sed "s|\"vm_name\": \"${PACKER_VM}_demo\"|\"vm_name\": \"${PACKER_VM}_${VER}@${LATEST_COMMIT}\"|" > ${PACKER_NAME}-deploy.json

  # Build virtualbox VM set
  PACKER_LOG_PATH="${PWD}/packerlog-vbox.txt"
  /usr/local/bin/packer build -var "vm_description=${vm_description}" -var "vm_version=${vm_version}" --on-error=ask -only=virtualbox-iso ail-deploy.json

  # Build vmware VM set
  PACKER_LOG_PATH="${PWD}/packerlog-vmware.txt"
  /usr/local/bin/packer build -var "vm_description=${vm_description}" -var "vm_version=${vm_version}" --on-error=ask -only=vmware-iso ail-deploy.json

  # ZIPup all the vmware stuff
  zip -r ${PACKER_VM}_${VER}@${LATEST_COMMIT}-vmware.zip  packer_vmware-iso_vmware-iso_sha1.checksum packer_vmware-iso_vmware-iso_sha512.checksum output-vmware-iso

  # Create a hashfile for the zip
  for SUMsize in `echo ${SHA_SUMS}`; do
    shasum -a ${SUMsize} *.zip > ${PACKER_VM}_${VER}@${LATEST_COMMIT}-vmware.zip.sha${SUMsize}
  done


  # Current file list of everything to gpg sign and transfer
  FILE_LIST="${PACKER_VM}_${VER}@${LATEST_COMMIT}-vmware.zip output-virtualbox-iso/${PACKER_VM}_${VER}@${LATEST_COMMIT}.ova packer_virtualbox-iso_virtualbox-iso_sha1.checksum packer_virtualbox-iso_virtualbox-iso_sha256.checksum packer_virtualbox-iso_virtualbox-iso_sha384.checksum packer_virtualbox-iso_virtualbox-iso_sha512.checksum ${PACKER_VM}_${VER}@${LATEST_COMMIT}-vmware.zip.sha1 ${PACKER_VM}_${VER}@${LATEST_COMMIT}-vmware.zip.sha256 ${PACKER_VM}_${VER}@${LATEST_COMMIT}-vmware.zip.sha384 ${PACKER_VM}_${VER}@${LATEST_COMMIT}-vmware.zip.sha512"

  # Create the latest AIL export directory
  ssh ${REL_USER}@${REL_SERVER} mkdir -p export/AIL_${VER}@${LATEST_COMMIT}
  ssh ${REL_USER}@${REL_SERVER} mkdir -p export/AIL_${VER}@${LATEST_COMMIT}/checksums

  # Create the latest AIL export directory
  ssh -i $HOME/.ssh/id_rsa_ail ${REL_USER}@${REL_SERVER} mkdir -p export/${PACKER_VM}_${VER}@${LATEST_COMMIT}

  # Sign and transfer files
  for FILE in ${FILE_LIST}; do
    gpg --armor --output ${FILE}.asc --detach-sig ${FILE}
    rsync -azv --progress -e "ssh -i $HOME/.ssh/id_rsa_ail" ${FILE} ${REL_USER}@${REL_SERVER}:export/${PACKER_VM}_${VER}@${LATEST_COMMIT}
    rsync -azv --progress -e "ssh -i $HOME/.ssh/id_rsa_ail" ${FILE}.asc ${REL_USER}@${REL_SERVER}:export/${PACKER_VM}_${VER}@${LATEST_COMMIT}
  done
  ssh -i $HOME/.ssh/id_rsa_ail ${REL_USER}@${REL_SERVER} rm export/latest
  ssh -i $HOME/.ssh/id_rsa_ail ${REL_USER}@${REL_SERVER} ln -s ${PACKER_VM}_${VER}@${LATEST_COMMIT} export/latest
  ssh -i $HOME/.ssh/id_rsa_ail ${REL_USER}@${REL_SERVER} chmod -R +r export
  ssh ${REL_USER}@${REL_SERVER} mv export/AIL_${VER}@${LATEST_COMMIT}/*.checksum* export/AIL_${VER}@${LATEST_COMMIT}/checksums
  ssh ${REL_USER}@${REL_SERVER} mv export/AIL_${VER}@${LATEST_COMMIT}/*-vmware.zip.sha* export/AIL_${VER}@${LATEST_COMMIT}/checksums

  ##ssh ${REL_USER}@${REL_SERVER} cd export ; tree -T "AIL VM Images" -H https://www.circl.lu/ail-images/ -o index.html

  echo ${LATEST_COMMIT} > /tmp/${PACKER_NAME}-latest.sha
else
  echo "Current AIL-framework version ${VER}@${LATEST_COMMIT} is up to date."
fi
