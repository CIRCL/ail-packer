#!/bin/bash -eu

# /!\ NOT Working, revise before deployment.
## Version deployed: 5.2.16
# NOT a Vagrant target
SSH_USER=${SSH_USERNAME:-vagrant}

if [[ $PACKER_BUILDER_TYPE =~ virtualbox ]]; then
    echo "==> Installing VirtualBox guest additions"
    # Assuming the following packages are installed
    apt-get install -y linux-headers-$(uname -r) build-essential perl
    apt-get install -y dkms virtualbox-guest-additions-iso virtualbox-guest-dkms

    VBOX_VERSION=$(cat /home/${SSH_USER}/.vbox_version)
    mount -o loop /usr/share/virtualbox/VBoxGuestAdditions.iso /mnt
    yes|sh /mnt/VBoxLinuxAdditions.run
    umount /mnt
    rm /home/${SSH_USER}/VBoxGuestAdditions_$VBOX_VERSION.iso
    rm /home/${SSH_USER}/.vbox_version

    if [[ $VBOX_VERSION = "4.3.10" ]]; then
        ln -s /opt/VBoxGuestAdditions-4.3.10/lib/VBoxGuestAdditions /usr/lib/VBoxGuestAdditions
    fi
    if [[ $VBOX_VERSION = "5.1.10" ]]; then
        rm /sbin/mount.vboxsf && ln -s /usr/lib/VBoxGuestAdditions/mount.vboxsf /sbin/mount.vboxsf
    fi
fi
