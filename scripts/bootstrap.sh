#!/bin/bash -e

## Source of the vercomp function: https://stackoverflow.com/questions/4023830/how-to-compare-two-strings-in-dot-separated-version-format-in-bash
# vercomp () {
#     if [[ $1 == $2 ]]
#     then
#         return 0
#     fi
#     local IFS=.
#     local i ver1=($1) ver2=($2)
#     # fill empty fields in ver1 with zeros
#     for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
#     do
#         ver1[i]=0
#     done
#     for ((i=0; i<${#ver1[@]}; i++))
#     do
#         if [[ -z ${ver2[i]} ]]
#         then
#             # fill empty fields in ver2 with zeros
#             ver2[i]=0
#         fi
#         if ((10#${ver1[i]} > 10#${ver2[i]}))
#         then
#             return 1
#         fi
#         if ((10#${ver1[i]} < 10#${ver2[i]}))
#         then
#             return 2
#         fi
#     done
#     return 0
# }

AIL_BRANCH='master'

# Grub config (reverts network interface names to ethX)
GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"
DEFAULT_GRUB="/etc/default/grub"

# Ubuntu version
UBUNTU_VERSION="$(lsb_release -r -s)"

# Webserver configuration
PATH_TO_AIL='/home/ail/AIL-framework'
AIL_BASEURL=''
FQDN='localhost'

SECRET_KEY="$(openssl rand -hex 32)"

echo "Your current shell is ${SHELL}"

echo "--- Installing AIL… ---"

# echo "--- Configuring GRUB ---"
#
# for key in GRUB_CMDLINE_LINUX
# do
#     sudo sed -i "s/^\($key\)=.*/\1=\"$(eval echo \${$key})\"/" $DEFAULT_GRUB
# done
# sudo grub-mkconfig -o /boot/grub/grub.cfg

echo "--- Updating packages list ---"
sudo apt-get -qq update

echo "--- Install base packages ---"
sudo apt-get -y install curl net-tools gcc git make sudo vim zip python3-dev python3-pip python3-virtualenv virtualenvwrapper > /dev/null 2>&1

echo "--- Retrieving and setting up AIL ---"
cd ~ail
sudo -u ail git clone https://github.com/CIRCL/AIL-framework.git
cd ${PATH_TO_AIL}
## BROKEN Issue with sudo in sudo
sudo -u ail ./installing_deps.sh
cd var/www/
sudo -u ail ./update_thirdparty.sh

#sudo -u ail mkdir ~/.virtualenvs
#sudo -u ail ln -s ${PATH_TO_AIL}/venv ~/.virtualenvs/ail
#cd $PATH_TO_AIL
#sudo cp ${PATH_TO_AIL}/etc/rc.local /etc/
sudo usermod -a -G ail www-data
#sudo chmod g+rw ${PATH_TO_AIL}
#sudo -u ail git config core.filemode false

echo "--- Install nginx ---"
sudo apt-get -y install nginx

echo "--- Copying config files ---"
#sed -i "s/<CHANGE_ME>/ail/g" $PATH_TO_AIL/etc/nginx/sites-available/ail
#sed -i "s/<CHANGE_ME>/ail/g" $PATH_TO_AIL/etc/systemd/system/ail.service
#sed -i "s/<MY_VIRTUALENV_PATH>/.virtualenvs\/ail/g" $PATH_TO_AIL/etc/systemd/system/ail.service
#sed -e "0,/changeme/ s/changeme/${SECRET_KEY}/" $PATH_TO_AIL/ail/__init__.py > /tmp/__init__.py
#cat /tmp/__init__.py | sudo tee $PATH_TO_AIL/ail/__init__.py
#rm /tmp/__init__.py
#sudo cp $PATH_TO_AIL/etc/nginx/sites-available/ail /etc/nginx/sites-available/
#sudo cp $PATH_TO_AIL/etc/systemd/system/ail.service /etc/systemd/system/
#sudo ln -sf /etc/nginx/sites-available/ail /etc/nginx/sites-enabled/default
#sudo chgrp -R www-data ~ail
#sudo chmod -R g+rw ~ail
#sudo systemctl start ail
#sudo systemctl enable ail

echo "\e[32mAIL is ready\e[0m"
echo "Login and passwords for the AIL image are the following:"
#echo "Web interface (default network settings): $AIL_BASEURL"
echo "Shell/SSH: ail/ail"
