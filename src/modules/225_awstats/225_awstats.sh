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

exec 2>> /var/log/gotypo.log

#===============================================================================
# functions declaration
#===============================================================================

# function :     download_file
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
        wget --quiet                          \
             --user            "$auth_usr"    \
             --password        "$auth_pwd"    \
             --output-document "$output_file" \
             "$file_url"
    else
        wget --quiet                             \
             --output-document    "$output_file" \
             "$file_url"
    fi
    return 0
}

#===============================================================================
# variables declaration and initialization
#===============================================================================

tempfile="/tmp/gotypo_typo3_tmp"
vhosts=""
vhosts_count=0
vhosts_selected=""
params=""
width=
height=
maxwidth=29
awstats_aliases=""
awstats_password=""
awstats_user=""

#===============================================================================
# main script
#===============================================================================

trap 'echo "Error Encountered in $0"                                
      exit 1'                        \
      INT TERM EXIT

# create virtual hosts list
for i in `ls -1 /opt/ics/gotypo/report_* | cut -d _ -f 2`
do
    vhosts[$vhosts_count]=$i
    vhosts_count=$((vhosts_count+1))
done

i=0
until [[ $i -eq $vhosts_count ]]
do
    params="${params:-""} ${vhosts[$i]} 0"
    if [[ ${#vhosts[$i]} -gt $maxwidth ]]
    then
        maxwidth=${#vhosts[$i]}
    fi 
    i=$((i + 1))
done

height=$((vhosts_count + 7))

# select virtual hosts for which Awstats should be configured
whiptail --title "GoTYPO3 : Awstats"                             \
         --checklist "Select vhosts for Awstats configuration :" \
         --noitem                                                \
         $height $(($maxwidth + 12)) $vhosts_count               \
         $params 2>$tempfile
sed -i -e 's/"//g' $tempfile
vhosts_selected=$(<$tempfile)
rm $tempfile

# configure awstats for each selected virtual host
for i in $vhosts_selected
do
    awstats_user=`grep "System user" /opt/ics/gotypo/report_$i | \
                  cut -d ':' -f 2`
    awstats_password=`</dev/urandom tr -dc a-zA-Z0-9 | head -c 8`
    awstats_aliases=`grep ServerAlias /var/www/vhosts/$i/conf/host.conf | \
                     cut -d ' ' -f 2                                    | \
                     tr  '\n' ' '`

    mkdir -p /var/www/vhosts/$i/awstatsweb/data
    mkdir /var/www/vhosts/$i/awstatsweb/static

    download_file "$GOTYPO3_IFAUTH"                         \
                  "$GOTYPO3_SRV/modules/awstats_index"  \
                  "/var/www/vhosts/$i/awstatsweb/index.php" \
                  "$GOTYPO3_AUTHUSR"                        \
                  "$GOTYPO3_AUTHPWD"

    download_file "$GOTYPO3_IFAUTH"                        \
                  "$GOTYPO3_SRV/modules/awstats_menu"  \
                  "/var/www/vhosts/$i/awstatsweb/menu.php" \
                  "$GOTYPO3_AUTHUSR"                       \
                  "$GOTYPO3_AUTHPWD"

    download_file "$GOTYPO3_IFAUTH"                      \
                  "$GOTYPO3_SRV/modules/awstats.conf"    \
                  "/var/www/vhosts/$i/conf/awstats.conf" \
                  "$GOTYPO3_AUTHUSR"                     \
                  "$GOTYPO3_AUTHPWD"

    sed -i -e "s/\${DOMAIN}/$i/g" \
              /var/www/vhosts/$i/awstatsweb/index.php

    sed -i -e "s/\${DOMAIN}/$i/g" \
              /var/www/vhosts/$i/awstatsweb/menu.php

    sed -i -e "s/\${DOMAIN}/$i/g"                  \
		   -e "s/\${AWALIASES}/$awstats_aliases/g" \
		      /var/www/vhosts/$i/conf/awstats.conf

    ln -s /var/www/vhosts/$i/conf/awstats.conf /etc/awstats/awstats.$i.conf

    htpasswd -b -c /var/www/vhosts/$i/conf/htpasswd_awstats \
                   $awstats_user                            \
                   $awstats_password

    echo "Awstats user : $awstats_user" >> /opt/ics/gotypo/report_$i
    echo "Awstats password : $awstats_password" >> /opt/ics/gotypo/report_$i
done

trap - INT TERM EXIT

exit 0
