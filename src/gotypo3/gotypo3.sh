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

if [[ -f /var/log/gotypo.log ]]
then
    rm /var/log/gotypo.log
fi
exec 2>> /var/log/gotypo.log

#===============================================================================
# functions declaration
#===============================================================================

# function :     download_content
# description : downloads the content a file
# parameter 1 : is authentication needed ?
# parameter 2 :    url of file to download
# parameter 3 :    user for authentication
# parameter 4 :    password for authentication
download_content ()
{
    local if_auth="$1"
    local file_url="$2"
    local auth_usr="$3"
    local auth_pwd="$4"

    if [[ "$if_auth" -eq 1 ]]
    then
        local file_content=`wget --quiet                        \
                                 --user             "$auth_usr" \
                                 --password         "$auth_pwd" \
                                 --output-document  -           \
                                 "$file_url"`
    else
        local file_content=`wget --quiet                \
                                 --output-document  -   \
                                 "$file_url"`
    fi

    echo "$file_content"
    return 0
}

# function :    setlock
# description : creates lockfile
setlock ()
{
    if [[ -e "$lockfile" ]]
    then
        echo "GoTYPO3 already running with PID `cat "$lockfile"`"
        return 1
    else
        echo $$ > "$lockfile"
        return 0
    fi
}

# function :    unsetlock
# description : deletes lockfile
unsetlock ()
{
    if [[ -e "$lockfile" ]]
    then
        rm "$lockfile"
    fi
    return 0
}


#===============================================================================
# variables declaration and initialization
#===============================================================================

list_url=${list_url:-"$GOTYPO3_SRV/modules_list.txt"}
mods_url=${mods_url:-"$GOTYPO3_SRV/modules/"}
mods_path=${mods_path:-"/opt/ics/gotypo/modules/"}
lockfile=${lockfile:-"/tmp/gotypo_lock"}
tempfile=${tempfile:-"/tmp/gotypo_temp"}
mods_count=0
height=0
width=0
maxwidth=0
params=""

#===============================================================================
# main script
#===============================================================================

# create lockfile and set trap
setlock
trap 'echo "Error Encountered in $0"
      unsetlock
      exit 1'                       \
      INT TERM EXIT

# create modules directory
if ! [[ -d $mods_path ]]
then
    mkdir -p $mods_path
fi

# download list of available modules
mods_available=`download_content "$GOTYPO3_IFAUTH" "$list_url" "$GOTYPO3_AUTHUSR" "$GOTYPO3_AUTHPWD"`

OIFS=$IFS
IFS='
'
for i in $mods_available
do
    modules[$mods_count]=$i
    mods_count=$((mods_count+1))
done
IFS=$OIFS

i=0
until [[ $i -eq $mods_count ]]
do
    params="${params:-""} `echo ${modules[$i]} | cut --delimiter        ':'      \
                                                     --output-delimiter ' '      \
                                                     --fields           '2 3'` 0 "
    if [[ ${#modules[$i]} -gt $maxwidth ]]
    then
        maxwidth=${#modules[$i]}
    fi
    i=$((i+1))
done

height=$((mods_count + 7))

# ask user to select modules
eval "whiptail --title \"Gotypo\"                                    \
               --checklist \"Select modules to execute:\"            \
               $height $(($maxwidth + 10)) $mods_count               \
               `echo $params | tr '*' '\"' | tr '_' ' '`" 2>$tempfile
mods_selected=$(<$tempfile)
rm $tempfile

# generate list of modules to download
touch $tempfile
for i in $mods_selected
do
    for j in ${modules[@]}
    do
        if [ `echo -n $i | tr -d '"'` = `echo -n $j | cut -d ':' -f '2'` ]
        then
            echo $j | cut --delimiter ':'                    \
                          --fields '1 2'                     \
                          --output-delimiter='_' >> $tempfile
        fi
    done
done

sort -o $tempfile $tempfile
mods_list=$(<$tempfile)
rm $tempfile

# download and execute selected modules
for i in $mods_list
do
    download_content $GOTYPO3_IFAUTH                     \
                     "$mods_url$i.sh"                   \
                     $GOTYPO3_AUTHUSR                    \
                     $GOTYPO3_AUTHPWD > "$mods_path$i.sh"
    chmod u+x "$mods_path$i.sh"
done

for i in $mods_list
do
    $mods_path$i.sh
done

# remove lockfile and reset trap
unsetlock
trap - INT TERM EXIT

# exit without errors
echo "GoTYPO3 execution successful"
exit 0
