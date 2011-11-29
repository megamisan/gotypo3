#!/bin/bash
#===============================================================================
#    © Copyright 2010 In Cité Solution
#
#    This file is part of GoTYPO3.
#
#    GoTYPO3 is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    GoTYPO3 is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with GoTYPO3.  If not, see <http://www.gnu.org/licenses/>.
#===============================================================================

#===============================================================================
# bash options and logs
#===============================================================================

set -o nounset
set -o errexit

#===============================================================================
# variables declaration and initialization
#===============================================================================

script_path=`dirname $0`
install_path=""
server_url=""

#===============================================================================
# main script
#===============================================================================

if [[ $script_path == '.' ]]
then
    script_path=`pwd`
fi
cd $script_path

# ask where to install GoTYPO3
clear
echo "Enter path to the directory where GoTYPO3 should be installed, this directory will be overwritten if it already exists:"
read install_path

if [[ -d $install_path ]]
then
    rm -R $install_path
    mkdir $install_path
else
    mkdir -p $install_path
fi

# ask the server url
clear
echo "Enter the URL (without leading http://) from where GoTYPO3 will be accessed:"
read server_url

# install base scripts
cp ./src/gotypo3/* $install_path
cp ./src/modules/modules_list.txt $install_path

server_url=${server_url//\//\\\/}
sed -i -e "s/no-server-url/$server_url/g" $install_path/launcher.sh

# install modules
mkdir $install_path/modules

# 100_debian-lenny
cp ./src/modules/100_debian-lenny/* $install_path/modules

# 200_vhost
cp ./src/modules/200_vhost/200_vhost.sh $install_path/modules
cd ./src/modules/200_vhost/vhost_skeleton
tar -czf /tmp/vhost_skeleton.tgz ./
mv /tmp/vhost_skeleton.tgz $install_path/modules
cd $script_path

# 225_awstats
cp ./src/modules/225_awstats/* $install_path/modules

# 250_ftp-users
cp ./src/modules/250_ftp-users/* $install_path/modules

# 300_typo3
cp -R ./src/modules/300_typo3/* $install_path/modules

clear
echo "Installation successful"

exit 0
