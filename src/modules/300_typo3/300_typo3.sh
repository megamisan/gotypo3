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

# function : 	download_file
# description : downloads a file
# parameter 1 : is authentication needed ?
# parameter 2 :	url of file to download
# parameter 3 : output file
# parameter 4 :	user for authentication
# parameter 5 :	password for authentication
download_file ()
{
	local if_auth="$1"
	local file_url="$2"
	local output_file="$3"
	local auth_usr="$4"
	local auth_pwd="$5"

	if [[ "$if_auth" -eq 1 ]]
	then
		wget --quiet							\
			 --user				"$auth_usr"		\
			 --password			"$auth_pwd"		\
			 --output-document	"$output_file"	\
			 "$file_url"
	else
		wget --quiet							\
			 --output-document	"$output_file"	\
			 "$file_url"
	fi
	return 0
}

# function :	inputbox
# description :	prints a question and stores the answer into variable
# parameter 1 :	question to ask
# parameter 2 :	variable in which the input will be stored
inputbox()
{
	whiptail --inputbox							\
			 --title "GoTYPO : Virtual Host"	\
			 "$1" 8 50 2> $tempfile
	eval $2=$(<$tempfile)
	rm $tempfile
	return 0
}

# function :	question
# description :	prints a yes/no question, returns 0 for yes, 1 for no
# parameter 1 :	question to ask
question()
{
	whiptail --title "GoTYPO : Virtual Host"	\
		 	 --yesno "$1"						\
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
	  exit 1'						\
	  INT TERM EXIT

# select TYPO3 version
whiptail --title "GoTYPO : TYPO3"						\
		 --radiolist "Select TYPO3 version to install :"\
		 --noitem										\
		 10 40 2										\
		 "4.3.4" 0										\
		 "4.4.1" 0										\
		 2>$tempfile
typo3_version=$(<$tempfile)
rm $tempfile
typo3_symlink="typo3-`echo $typo3_version | cut -d '.' -f '1 2'`"

# check if TYPO3 sources are installed. If not install them from sourceforge.
if [[ ! -h /var/local/typo3/$typo3_symlink ]] || \
   [[ `readlink /var/local/typo3/$typo3_symlink | cut -d '.' -f '3'` -lt `echo $typo3_version | cut -d '.' -f '3'` ]]
then
	whiptail --title "GoTYPO : TYPO3"										\
			 --infobox "GoTYPO is installing TYPO3 sources, please wait."	\
			 6 58
	mkdir -p /var/local/typo3/
	cd /var/local/typo3/
	wget "http://prdownloads.sourceforge.net/typo3/typo3_src-$typo3_version.tar.gz?download"
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
	((vhosts_count++))
done

i=0
until [[ $i -eq $vhosts_count ]]
do
	params="${params:-""} ${vhosts[$i]} 0"
	if [[ ${#vhosts[$i]} -gt $maxwidth ]]
	then
		maxwidth=${#vhosts[$i]}
	fi
	((i++))
done

height=$((vhosts_count + 7))

# select virtual hosts in which TYPO3 should be installed
whiptail --title "GoTYPO : TYPO3"							 \
		 --checklist "Select vhosts for TYPO3 installation :"\
		 --noitem											 \
		 $height $(($maxwidth + 12)) $vhosts_count			 \
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
	typo3_db=$vhost_user
	typo3_dbusr=$vhost_user
	typo3_dbpwd=`</dev/urandom tr -dc a-zA-Z0-9 | head -c 8`
	typo3_dbhost="localhost"
	typo3_adminpwd=`</dev/urandom tr -dc a-zA-Z0-9 | head -c 8`
	typo3_installtoolpwd=`</dev/urandom tr -dc a-zA-Z0-9 | head -c 8`
	typo3_installtoolpwd_md5=`echo -n $typo3_installtoolpwd | openssl dgst -md5`
	sql_query="CREATE DATABASE \`$typo3_db\`;
			   CREATE USER '$typo3_dbusr'@'localhost' IDENTIFIED BY '$typo3_dbpwd';
			   GRANT ALL PRIVILEGES ON \`$typo3_db\`.\0052 TO '$typo3_dbusr'@'localhost';
			   ALTER DATABASE \`$typo3_db\` DEFAULT CHARACTER SET utf8;
			   ALTER DATABASE \`$typo3_db\` DEFAULT COLLATE utf8_bin;"

	# create the database
	echo -e $sql_query | mysql --defaults-file=/etc/mysql/debian.cnf
	
	# dowload and unpack the dummy package from sourceforge
	cd $vhost_dir/httpdocs
	wget "http://prdownloads.sourceforge.net/typo3/dummy-$typo3_version.tar.gz?download"
	tar -xzf dummy-$typo3_version.tar.gz
	mv dummy-$typo3_version/* ./
	rmdir dummy-$typo3_version
	rm dummy-$typo3_version.tar.gz
	rm $vhost_dir/httpdocs/typo3_src
	ln -s /var/local/typo3/$typo3_symlink $vhost_dir/httpdocs/typo3_src
	
	# download the localconf.php and .htaccess files from GoTYPO server
	rm $vhost_dir/httpdocs/typo3conf/localconf.php
	download_file "$GOTYPO_IFAUTH"											\
				  "$GOTYPO_SRV/modules/dummy-$typo3_version/localconf.php"	\
				  "$vhost_dir/httpdocs/typo3conf/localconf.php"				\
				  "$GOTYPO_AUTHUSR"											\
				  "$GOTYPO_AUTHPWD"
				  
	download_file "$GOTYPO_IFAUTH"											\
				  "$GOTYPO_SRV/modules/dummy-$typo3_version/htaccess"		\
				  "$vhost_dir/httpdocs/.htaccess"							\
				  "$GOTYPO_AUTHUSR"											\
				  "$GOTYPO_AUTHPWD"

	# configure localconf.php
	sed -i 	-e "s/\${sitename}/$i/g"				\
			-e "s/\${typo3_db}/$typo3_db/g"			\
			-e "s/\${typo3_dbusr}/$typo3_dbusr/g"	\
			-e "s/\${typo3_dbpwd}/$typo3_dbpwd/g"	\
			-e "s/\${typo3_dbhost}/$typo3_dbhost/g"	\
			-e "s/\${typo3_key}/$typo3_key/g"		\
			$vhost_dir/httpdocs/typo3conf/localconf.php
	
	# update permissions
	chown -R $vhost_user:www-data *
	find $vhost_dir/httpdocs -type d -exec chmod 6775 {} \;
	find $vhost_dir/httpdocs -type f -exec chmod 0664 {} \;
	
	# configure a temporary host record and enable TYPO3 install tool
	echo "127.0.0.100 $i" >> /etc/hosts
	touch $vhost_dir/httpdocs/typo3conf/ENABLE_INSTALL_TOOL
	
	#
	# we use wget to simulate user interactions in the install tool
	#

	# use wget to compare database
	wget "http://$i/typo3/install/index.php?password=joh316&redirect_url=index.php%3FTYPO3_INSTALL[type]=about"	\
		 --output-document=/dev/null																			\
		 --cookies=on																							\
		 --save-cookies /tmp/wgetcookies																		\
		 --keep-session-cookies																					\
		 --referer="http://$i/"

	wget "http://$i/typo3/install/index.php?TYPO3_INSTALL[type]=database&TYPO3_INSTALL[database_type]=cmpFile|CURRENT_TABLES"	\
		 --output-document=/tmp/wgetget																							\
		 --cookies=on																											\
		 --save-cookies /tmp/wgetcookies																						\
		 --load-cookies /tmp/wgetcookies																						\
		 --keep-session-cookies																									\
		 --referer="http://$i/typo3/install/index.php?TYPO3_INSTALL[type]=database"

	# generate post data needed to select database changes
	echo -n "TYPO3_INSTALL[database_type]=cmpFile|CURRENT_TABLES" > /tmp/wgetpost

	for j in `grep "<input type=\"checkbox\".*name=\"" /tmp/wgetget`
	do
		case $j in
		name=*)
			echo -n "&" >> /tmp/wgetpost
			echo $j | cut -d \" -f 2 | tr -d "\n" >> /tmp/wgetpost
			echo -n "=" >> /tmp/wgetpost
			;;
		value=*)
			echo $j | cut -d \" -f 2 | tr -d "\n" >> /tmp/wgetpost
			;;
		esac
	done

	rm /tmp/wgetget
	wget_post=$(</tmp/wgetpost)
	rm /tmp/wgetpost

	# apply changes to the database
	wget "http://$i/typo3/install/index.php?TYPO3_INSTALL[type]=database"																\
		 --output-document=/dev/null																									\
		 --cookies=on																													\
		 --load-cookies /tmp/wgetcookies																								\
		 --keep-session-cookies																											\
		 --referer="http://$i/typo3/install/index.php?TYPO3_INSTALL[type]=database&TYPO3_INSTALL[database_type]=cmpFile|CURRENT_TABLES" \
		 --post-data $wget_post

	# generate post data to add admin user
	wget_post="TYPO3_INSTALL%5Bdatabase_type%5D=adminUser%7C"\
"&TYPO3_INSTALL%5Bdatabase_adminUser%5D%5Busername%5D=$vhost_user"\
"&TYPO3_INSTALL%5Bdatabase_adminUser%5D%5Bpassword%5D=$typo3_adminpwd"\
"&TYPO3_INSTALL%5Bdatabase_adminUser%5D%5Bpassword2%5D=$typo3_adminpwd"

	# add admin user
	wget "http://$i/typo3/install/index.php?TYPO3_INSTALL[type]=database"													\
		 --output-document=/dev/null																						\
		 --cookies=on																										\
		 --load-cookies /tmp/wgetcookies																					\
		 --keep-session-cookies																								\
		 --referer="http://$i/typo3/install/index.php?TYPO3_INSTALL[type]=database&TYPO3_INSTALL[database_type]=adminUser|" \
		 --post-data $wget_post

	rm /tmp/wgetcookies

	# update install tool password
	sed -i -e "s/bacb98acf97e0b6112b1d1b650b84971/$typo3_installtoolpwd_md5/g" \
		$vhost_dir/httpdocs/typo3conf/localconf.php

	# delete temporary host record and disable install tool
	rm $vhost_dir/httpdocs/typo3conf/ENABLE_INSTALL_TOOL
	sed -i -e "/127.0.0.100 $i/d" /etc/hosts
	
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
