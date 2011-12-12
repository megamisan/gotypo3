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


#===============================================================================
# variables declaration and initialization
#===============================================================================

sys_user=""
sys_user_selected=""
sys_user_home=""
sys_user_uid=
sys_user_gid=
ftp_user_name=""
ftp_user_home=""
ftp_user_passwd=""
sql_query=""
params=""
counter=0
width_max=33
tempfile="/tmp/gotypo_ftp-users_tmp"
line_num=
OLDIFS=""

#===============================================================================
# main script
#===============================================================================

trap 'echo "Error Encountered in $0"                                
      exit 1'                        \
      INT TERM EXIT

while true
do
    # generate system users list
    params=""
    OLDIFS=$IFS
    IFS="
"
    for i in $(</etc/passwd)
    do
        if [[ `echo $i | cut -d : -f 3` -gt 999 ]]
        then
            sys_user=`echo $i | cut -d : -f 1`
            counter=$((counter+1))
            params="${params:-""} $sys_user 0"
        fi
    done
    IFS=$OLDIFS
	
	HEIGHT=$((counter + 7))
	TERM_HEIGHT=25
	if [[ $HEIGHT -gt $TERM_HEIGHT ]]
	then
		HEIGHT=$TERM_HEIGHT
	fi

    # select system user
    whiptail --title "GoTYPO3 : FTP users"                                    \
             --radiolist "Select the system user whose rights will be used :" \
             --noitem                                                         \
             $HEIGHT 54 $((HEIGHT - 7))                                       \
             $params 2>$tempfile || break
    sys_user_selected=$(<$tempfile)
    rm $tempfile

    line_num=`cut -d : -f 1 /etc/passwd | grep $sys_user_selected -nx | cut -d : -f 1`
    sys_user_home=`awk 'FNR == '$line_num'' /etc/passwd | cut -d : -f 6`
    sys_user_uid=`awk 'FNR == '$line_num'' /etc/passwd | cut -d : -f 3`
    sys_user_gid=`awk 'FNR == '$line_num'' /etc/passwd | cut -d : -f 4`

    # select ftp user name
    whiptail --title "GoTYPO3 : FTP users" \
             --inputbox "FTP user name :" \
             8 26 $sys_user_selected      \
             2>$tempfile || break
    ftp_user_name=$(<$tempfile)
    rm $tempfile

    # select ftp user home
    if [[ `echo -n "$sys_user_home" | wc -m` -gt $width_max ]]
    then
        width_max=`echo -n "$sys_user_home" | wc -m`
    fi

    whiptail --title "GoTYPO3 : FTP users"                   \
             --inputbox "Home directory for the FTP user :" \
             8 $((width_max + 8)) $sys_user_home            \
             2>$tempfile || break
    ftp_user_home=$(<$tempfile)
    rm $tempfile

    # select ftp user password

    whiptail --title "GoTYPO3 : FTP users"                      \
             --inputbox "FTP user password :"                  \
             8 26 `</dev/urandom tr -dc a-zA-Z0-9 | head -c 8` \
             2>$tempfile || break
    ftp_user_passwd=$(<$tempfile)
    rm $tempfile

    # generate SQL query and execute it

    sql_query="INSERT INTO users_plain
               VALUES ( '$ftp_user_name',
                        '$ftp_user_passwd',
                        $sys_user_uid,
                        $sys_user_gid,
                        '$ftp_user_home',
                        1 );"
    echo $sql_query | mysql --defaults-file=/etc/mysql/debian.cnf ftpserver

    whiptail --title "GoTYPO3 : FTP users"     \
             --yesno "Add another FTP user ?" \
             11 22 || break
done

trap - INT TERM EXIT

exit 0
