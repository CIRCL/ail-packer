# Build Automated Machine Images for AIL
Build a virtual machine for AIL based on Ubuntu 18.04 server
(for VirtualBox or VMWare).

## Requirements

* [VirtualBox](https://www.virtualbox.org)
* [Packer](https://www.packer.io) from the Packer website
* *tree* -> sudo apt install tree (on deployment side)

## Usage

In the file *scripts/bootstrap.sh*, set the value of ``AIL_BASEURL`` according
to the IP address you will associate to your VM
(for example: http://172.16.100.100).

Launch the generation with the VirtualBox builder:

    $ packer build -only=virtualbox-iso ail.json

A VirtualBox image will be generated and stored in the folder
*output-virtualbox-iso*.

The sha1 and sha512 checksums of the generated VM will be stored in the files
*packer_virtualbox-iso_virtualbox-iso_sha1.checksum* and
*packer_virtualbox-iso_virtualbox-iso_sha512.checksum* respectively.

If you want to build an image for VMWare you will need to install it and
use the VMWare builder with the command:

    $ packer build -only=vmware-iso ail.json

You can also launch all builders in parallel.
