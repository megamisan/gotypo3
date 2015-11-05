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
        wget --quiet                          \
             --user            "$auth_usr"    \
             --password        "$auth_pwd"    \
             --output-document "$output_file" \
             "$file_url"
    else
        wget --quiet                          \
             --output-document "$output_file" \
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
             --title "GoTYPO3 : Virtual Host" \
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
    whiptail --title "GoTYPO3 : Virtual Host" \
              --yesno "$1"                   \
              11 22
}

#===============================================================================
# variables declaration and initialization
#===============================================================================

tempfile="/tmp/gotypo_typo3_tmp"
typo3_version=""
typo3_symlink=""
vhosts=""
vhosts_count=0
vhosts_selected=""
params=""
width=
height=
maxwidth=29
vhost_user=""
vhost_dir=""
typo3_key=""
typo3_db=""
typo3_dbusr=""
typo3_dbpwd=""
typo3_dbhost=""
typo3_adminpwd=""
typo3_installtoolpwd=""
typo3_installtoolpwd_md5=""
sql_query=""
wget_post=""

#===============================================================================
# main script
#===============================================================================

trap 'echo "Error Encountered in $0"                                
      exit 1'                        \
      INT TERM EXIT

# select TYPO3 version
whiptail --title "GoTYPO3 : TYPO3"                        \
         --radiolist "Select TYPO3 version to install :" \
         --noitem                                        \
         10 40 2                                         \
         "6.2" 0                                         \
         "7.5" 0                                         \
         2>$tempfile
typo3_version=$(<$tempfile)
rm $tempfile
typo3_symlink="typo3-`echo $typo3_version | cut -d '.' -f '1 2'`"

# check if TYPO3 sources are installed. If not install them from sourceforge.
if [[ ! -h /var/local/typo3/$typo3_symlink ]] || \
   [[ `readlink /var/local/typo3/$typo3_symlink | cut -d '.' -f '3'` -lt `echo $typo3_version | cut -d '.' -f '3'` ]]
then
    whiptail --title "GoTYPO3 : TYPO3"                                     \
             --infobox "GoTYPO3 is installing TYPO3 sources, please wait." \
             7 58
    mkdir -p /var/local/typo3/
    cd /var/local/typo3/
    wget -O "typo3_src-$typo3_version.tar.gz" \
         "http://prdownloads.sourceforge.net/typo3/typo3_src-$typo3_version.tar.gz?download"
    tar -xzf typo3_src-$typo3_version.tar.gz
    rm typo3_src-$typo3_version.tar.gz
    if [[ -h /var/local/typo3/$typo3_symlink ]]
    then
        rm /var/local/typo3/$typo3_symlink
    fi
    ln -s /var/local/typo3/typo3_src-$typo3_version /var/local/typo3/$typo3_symlink
fi

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
    i=$((i+1))
done

HEIGHT=$((vhosts_count + 7))
TERM_HEIGHT=25
if [[ $HEIGHT -gt $TERM_HEIGHT ]]
then
	HEIGHT=$TERM_HEIGHT
fi

# select virtual hosts in which TYPO3 should be installed
whiptail --title "GoTYPO3 : TYPO3"                             \
         --checklist "Select vhosts for TYPO3 installation :" \
         --noitem                                             \
         $HEIGHT $(($maxwidth + 12)) $((HEIGHT - 7))          \
         $params 2>$tempfile
sed -i -e 's/"//g' $tempfile
vhosts_selected=$(<$tempfile)
rm $tempfile

for i in $vhosts_selected
do
    # initialize variables fo the current virtual host
    vhost_dir=`grep "Directory" "/opt/ics/gotypo/report_$i" | cut -d : -f 2 | tr -d [:space:]`
    vhost_user=`grep "System user" "/opt/ics/gotypo/report_$i" | cut -d : -f 2 | tr -d [:space:]`
    typo3_key=`</dev/urandom tr -dc a-f0-9 | head -c 96`
    typo3_db=`echo $vhost_user | cut -c 1-16`
    typo3_dbusr=$typo3_db
    typo3_dbpwd=`</dev/urandom tr -dc a-zA-Z0-9 | head -c 8`
    typo3_dbhost="localhost"
    typo3_adminpwd=`</dev/urandom tr -dc a-zA-Z0-9 | head -c 8`
    typo3_installtoolpwd=`</dev/urandom tr -dc a-zA-Z0-9 | head -c 8`
    typo3_installtoolpwd_md5=`echo -n $typo3_installtoolpwd | openssl dgst -md5`
    sql_query="CREATE DATABASE \`$typo3_db\` COLLATE utf8_unicode_ci;
               CREATE USER '$typo3_dbusr'@'localhost' IDENTIFIED BY '$typo3_dbpwd';
               GRANT ALL PRIVILEGES ON \`$typo3_db\`.\0052 TO '$typo3_dbusr'@'localhost';"

    # create the database
    echo -e $sql_query | mysql --defaults-file=/etc/mysql/debian.cnf
    
    cd $vhost_dir/httpdocs
    ln -s /var/local/typo3/$typo3_symlink $vhost_dir/httpdocs/typo3_src

    # update permissions
    chown -R $vhost_user:www-data *
    find $vhost_dir/httpdocs -type d -exec chmod 6775 \{\} \;
    find $vhost_dir/httpdocs -type f -exec chmod 0664 \{\} \;

    # update report
    echo "Database : $typo3_db" >> /opt/ics/gotypo/report_$i
    echo "Database user : $typo3_dbusr" >> /opt/ics/gotypo/report_$i
    echo "Database user password : $typo3_dbpwd" >> /opt/ics/gotypo/report_$i
    echo "TYPO3 admin : $vhost_user" >> /opt/ics/gotypo/report_$i
    echo "TYPO3 admin password : $typo3_adminpwd" >> /opt/ics/gotypo/report_$i
    echo "TYPO3 install tool password : $typo3_installtoolpwd" >> /opt/ics/gotypo/report_$i
done

trap - INT TERM EXIT

exit 0
