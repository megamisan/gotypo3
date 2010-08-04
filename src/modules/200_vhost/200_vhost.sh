#!/bin/bash
#===============================================================================
#    © Copyright 2010 In Cité Solution
#
#    This file is part of GoTYPO.
#
#    GoTYPO is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    GoTYPO is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with GoTYPO.  If not, see <http://www.gnu.org/licenses/>.
#===============================================================================

#===============================================================================
# bash options and logs
#===============================================================================

set -o nounset
set -o errexit

exec 2>> /var/log/gotypo.log

#===============================================================================
# functions declaration
#===============================================================================

# function :    download_file
# description : downloads a file
# parameter 1 : is authentication needed ?
# parameter 2 : url of file to download
# parameter 3 : output file
# parameter 4 : user for authentication
# parameter 5 : password for authentication
download_file ()
{
    local if_auth="$1"
    local file_url="$2"
    local output_file="$3"
    local auth_usr="$4"
    local auth_pwd="$5"

    if [[ "$if_auth" -eq 1 ]]
    then
        wget --quiet                           \
             --user             "$auth_usr"    \
             --password         "$auth_pwd"    \
             --output-document  "$output_file" \
             "$file_url"
    else
        wget --quiet                             \
             --output-document    "$output_file" \
             "$file_url"
    fi
    return 0
}

# function :    inputbox
# description : prints a question and stores the answer into variable
# parameter 1 : question to ask
# parameter 2 : variable in which the input will be stored
inputbox()
{
    whiptail --inputbox                      \
             --title "GoTYPO : Virtual Host" \
             "$1" 8 50 2> $tempfile
    eval $2=$(<$tempfile)
    rm $tempfile
    return 0
}

# function :    question
# description : prints a yes/no question, returns 0 for yes, 1 for no
# parameter 1 : question to ask
question()
{
    whiptail --title "GoTYPO : Virtual Host" \
              --yesno "$1"                   \
              11 22
}

#===============================================================================
# variables declaration and initialization
#===============================================================================

tempfile="/tmp/gotypo_vhost_tmp"
if_alias=0
if_addvhost=0
alias=""
aliases=""
vhost_fqdn=""
vhost_usr=""
counter=1

#===============================================================================
# main script
#===============================================================================

trap 'echo "Error Encountered in $0"                                
      exit 1'                        \
      INT TERM EXIT

while true
do
    # get Virtual Host FQN
    inputbox "FQDN for the Virtual Host : " "vhost_fqdn"

    # get system user username
    if [[ `echo $vhost_fqdn | cut --delimiter '.' --fields '1'` == www ]]
    then
        vhost_usr=`echo $vhost_fqdn | cut --delimiter '.' --fields '2'`
    else
        vhost_usr=`echo $vhost_fqdn | cut --delimiter '.' --fields '1'`
    fi

    if cut -d : -f 1 /etc/passwd | grep $vhost_usr 
    then
        while cut -d : -f 1 /etc/passwd | grep "$vhost_usr"-"$counter"
        do
            ((counter++))
        done
        vhost_usr="$vhost_usr"-"$counter"
    fi

    # get aliases for the Virtual Host
    question "Add an alias ?" && if_alias=1 || true
    aliases=""
    
    if [[ $if_alias -eq 1 ]]
    then
        inputbox "Alias to add :" "alias"
        aliases="ServerAlias $alias"
        question "Add another alias ?" || if_alias=0
    fi
        
    while [[ $if_alias -eq 1 ]]
    do
        inputbox "Alias to add :" "alias"
        aliases=$aliases'\n'"ServerAlias $alias"
        question "Add another alias ?" || if_alias=0
    done

    # download and decompress the Virtual Host skeleton
    download_file "$GOTYPO_IFAUTH"                         \
                  "$GOTYPO_SRV/modules/vhost_skeleton.tgz" \
                  "/tmp/vhost_skeleton.tgz"                \
                  "$GOTYPO_AUTHUSR"                        \
                  "$GOTYPO_AUTHPWD"
    mkdir --parents /var/www/vhosts/$vhost_fqdn
    cd /var/www/vhosts/$vhost_fqdn
    tar -xzf /tmp/vhost_skeleton.tgz
    rm /tmp/vhost_skeleton.tgz

    # configure the skeleton
    if [[ -z $aliases ]]
    then
        sed -i -e "s/\${vhost_fqdn}/$vhost_fqdn/g"     \
               -e "/\${aliases}/d"                     \
            /var/www/vhosts/$vhost_fqdn/conf/host.conf
    else
        sed -i -e "s/\${vhost_fqdn}/$vhost_fqdn/g"     \
               -e "s/\${aliases}/$aliases/g"           \
            /var/www/vhosts/$vhost_fqdn/conf/host.conf
    fi
    ln -s /var/www/vhosts/$vhost_fqdn/conf/host.conf \
          /etc/apache2/sites-available/$vhost_fqdn

    # add system user and set permissions
    adduser --quiet                            \
            --disabled-password                \
            --ingroup www-data                 \
            --home /var/www/vhosts/$vhost_fqdn \
            --no-create-home                   \
            --gecos ,,,                        \
            $vhost_usr
    chown -R root:root /var/www/vhosts/$vhost_fqdn/*
    chown -R $vhost_usr:www-data /var/www/vhosts/$vhost_fqdn/httpdocs
    chown -R $vhost_usr:www-data /var/www/vhosts/$vhost_fqdn/errors
    chown -R $vhost_usr:www-data /var/www/vhosts/$vhost_fqdn/srcclient
    find /var/www/vhosts/$vhost_fqdn -type d -exec chmod 6775 {} \;
    find /var/www/vhosts/$vhost_fqdn -type f -exec chmod 0664 {} \;

    # create a report and fill it
    touch /opt/ics/gotypo/report_$vhost_fqdn
    chmod 600 /opt/ics/gotypo/report_$vhost_fqdn

    echo "---GoTYPO report for $vhost_fqdn---" >> /opt/ics/gotypo/report_$vhost_fqdn
    echo "---DO NOT EDIT---" >> /opt/ics/gotypo/report_$vhost_fqdn
    echo "Directory : /var/www/vhosts/$vhost_fqdn" >> /opt/ics/gotypo/report_$vhost_fqdn
    echo "System user : $vhost_usr" >> /opt/ics/gotypo/report_$vhost_fqdn
    
    a2ensite $vhost_fqdn
    /etc/init.d/apache2 reload
    
    question "Add another Virtual Host ?" || break
done

trap - INT TERM EXIT

exit 0
