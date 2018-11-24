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

# Ubuntu version
UBUNTU_VERSION="$(lsb_release -r -s)"

# Webserver configuration
PATH_TO_AIL='/home/ail/AIL-framework'
AIL_BASEURL=''
FQDN='localhost'

SECRET_KEY="$(openssl rand -hex 32)"

echo "Your current shell is ${SHELL}"

echo "--- Installing AIL… ---"

echo "--- Updating packages list ---"
apt-get -qq update

echo "--- Install base packages ---"
apt-get -y install curl net-tools gcc git make sudo vim zip python3-dev python3-pip python3-virtualenv virtualenvwrapper redis-tools tmux > /dev/null 2>&1

echo "--- Retrieving and setting up AIL ---"
cd ~ail
sudo -u ail git clone https://github.com/CIRCL/AIL-framework.git
sudo -u ail git clone https://github.com/CIRCL/pystemon.git
sed -i -e 's/  queue: no/  queue: yes/g' pystemon/pystemon.yaml
sed -i -e 's/  save-all: no/  save-all: yes/g' pystemon/pystemon.yaml

cd ${PATH_TO_AIL}
sudo -H -u ail ./installing_deps.sh
./AILENV/bin/pip install pyyaml
# Enabling pystemon intergration
sed -i -e 's/pystemonpath = \/home\/pystemon\/pystemon\//pystemonpath = \/home\/ail\/pystemon\//g' bin/packages/config.cfg

./crawler_hidden_services_install.sh -y

echo "--- Installing rc.local ---"
# With initd:
if [ ! -e /etc/rc.local ]
then
    echo '#!/bin/sh -e' | sudo tee -a /etc/rc.local
    echo 'exit 0' | sudo tee -a /etc/rc.local
    chmod u+x /etc/rc.local
fi

sed -i -e '$i \sudo -u ail bash /home/ail/AIL-framework/bin/LAUNCH.sh -l \n' /etc/rc.local
sed -i -e '$i \sudo -u ail bash /home/ail/AIL-framework/bin/LAUNCH.sh -f \n' /etc/rc.local

#sudo -u ail mkdir ~/.virtualenvs
#sudo -u ail ln -s ${PATH_TO_AIL}/venv ~/.virtualenvs/ail
#cd $PATH_TO_AIL
#sudo cp ${PATH_TO_AIL}/etc/rc.local /etc/
usermod -a -G ail www-data
#sudo chmod g+rw ${PATH_TO_AIL}
#sudo -u ail git config core.filemode false

echo "--- Install nginx --- (TODO)"
##apt-get -y install nginx

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
