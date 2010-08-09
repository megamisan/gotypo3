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

# function :     configure_proftpd
# description : configures proftpd database and configuration files
configure_proftpd ()
{
    local proftpd_dbpwd=`</dev/urandom tr -dc a-zA-Z0-9 | head -c 8`

    local sql_query="DROP DATABASE IF EXISTS \`ftpserver\`;"
    echo -e $sql_query | mysql --defaults-file=/etc/mysql/debian.cnf

    local sql_query="DROP USER 'proftpd'@'localhost';"
    echo $sql_query | mysql --defaults-file=/etc/mysql/debian.cnf -f
    
    local sql_query="CREATE DATABASE \`ftpserver\`;
                     CREATE USER 'proftpd'@'localhost' IDENTIFIED BY '$proftpd_dbpwd';
                     GRANT SELECT ON \`ftpserver\`.\0052 TO 'proftpd'@'localhost';
                     ALTER DATABASE \`ftpserver\` DEFAULT CHARACTER SET utf8;
                     ALTER DATABASE \`ftpserver\` DEFAULT COLLATE utf8_bin;"
    echo -e $sql_query | mysql --defaults-file=/etc/mysql/debian.cnf

    local sql_query="UPDATE user SET Create_view_priv = 'Y',
                                     Show_view_priv = 'Y',
                                     Create_routine_priv = 'Y',
                                     Alter_routine_priv = 'Y',
                                     Create_user_priv = 'Y'
                     WHERE User = 'debian-sys-maint'; 
                     FLUSH PRIVILEGES;"
    echo $sql_query | mysql --defaults-file=/etc/mysql/debian.cnf 'mysql'


    download_file "$GOTYPO3_IFAUTH"                         \
                  "$GOTYPO3_SRV/modules/proftpd_schema.sql" \
                  "/tmp/proftpd_schema.sql"                \
                  "$GOTYPO3_AUTHUSR"                        \
                  "$GOTYPO3_AUTHPWD"
    mysql --defaults-file=/etc/mysql/debian.cnf \
          ftpserver                             \
          < /tmp/proftpd_schema.sql
    rm /tmp/proftpd_schema.sql
    
    local sql_query="INSERT INTO users_plain
                     VALUES ( 'www-data',
                               NULL,
                               33,
                               33,
                               '/var/www/vhosts',
                               1 );"
    echo $sql_query | mysql --defaults-file=/etc/mysql/debian.cnf ftpserver
    
    local sql_query="INSERT INTO groups_sys
                     VALUES ( 'www-data', 33 );"
    echo $sql_query | mysql --defaults-file=/etc/mysql/debian.cnf ftpserver

    if [[ -f /etc/proftpd/proftpd.conf ]]
    then
        rm /etc/proftpd/proftpd.conf
    fi
    download_file "$GOTYPO3_IFAUTH"                           \
                  "$GOTYPO3_SRV/modules/proftpd_proftpd.conf" \
                  "/etc/proftpd/proftpd.conf"                \
                  "$GOTYPO3_AUTHUSR"                          \
                  "$GOTYPO3_AUTHPWD"

    if [[ -f /etc/proftpd/modules.conf ]]
    then
        rm /etc/proftpd/modules.conf
    fi
    download_file "$GOTYPO3_IFAUTH"                           \
                  "$GOTYPO3_SRV/modules/proftpd_modules.conf" \
                  "/etc/proftpd/modules.conf"                \
                  "$GOTYPO3_AUTHUSR"                          \
                  "$GOTYPO3_AUTHPWD"

    if [[ -f /etc/proftpd/sql.conf ]]
    then
        rm /etc/proftpd/sql.conf
    fi
    download_file "$GOTYPO3_IFAUTH"                       \
                  "$GOTYPO3_SRV/modules/proftpd_sql.conf" \
                  "/etc/proftpd/sql.conf"                \
                  "$GOTYPO3_AUTHUSR"                      \
                  "$GOTYPO3_AUTHPWD"

    chmod 640 /etc/proftpd/sql.conf
    sed -i -e "s/\${proftpd_dbpwd}/$proftpd_dbpwd/g" \
        /etc/proftpd/sql.conf

    /etc/init.d/proftpd restart

    return 0
}

#===============================================================================
# variables declaration and initialization
#===============================================================================

tempfile="/tmp/gotypo_debian-lenny_tmp"
pkgs_list="apache2
           aspell
           awstats
           catdoc
           gdebi-core
           imagemagick
           libapache2-mod-php5
           locales-all
           makepasswd
           mysql-admin
           mysql-client
           mysql-query-browser
           mysql-server
           ntp
           php5-cli
           php5-curl
           php5-gd
           php5-gmp
           php5-mysql
           php5-tidy
           php5-xcache
           php5-xsl
           postfix
           ppthtml
           proftpd
           proftpd-mod-mysql
           pwgen
           unrtf
           unzip
           xauth
           xlhtml
           xpdf-utils"
pkgs_missing=""
proftpd_missing=""
pkgs_status="OK"
logrot_status="OK"
proftpd_status="OK"
proftpd_list="modules.conf proftpd.conf sql.conf"

#===============================================================================
# main script
#===============================================================================

trap 'echo "Error Encountered in $0"                                
      exit 1'                        \
      INT TERM EXIT

while true
do
    # generate packages report
    pkgs_status="OK"
    for i in $pkgs_list
    do
        if ! dpkg -s $i &>/dev/null
        then
            if [[ $pkgs_status = "OK" ]]
            then
                pkgs_status="KO"
                pkgs_missing="$i"
            else
                pkgs_missing="$pkgs_missing $i"
            fi
        fi
    done

    # generate logrotate configuration report
    logrot_status="OK"
    if [[ ! -f /etc/logrotate.d/vhosts ]]
    then
        logrot_status="KO"
    fi
    
    # generate proftpd configuration report
    proftpd_status="OK"
    for i in $proftpd_list
    do
        if ! grep -s "###GoTYPO3" /etc/proftpd/$i
        then
            proftpd_status="KO"
        fi
    done
    if [[ "$pkgs_status" == "OK" ]]
    then
        if ! echo "exit" | mysql --defaults-file=/etc/mysql/debian.cnf ftpserver
        then
            proftpd_status="KO"
        fi
    fi

    # select a report
    whiptail --title "GoTYPO3 : Debian Lenny" \
             --menu "Reports :"              \
             10 30 3                         \
             packages "[$pkgs_status]"       \
             logrotate "[$logrot_status]"    \
             proftpd "[$proftpd_status]"     \
             2>$tempfile || break
    report_selected=$(<$tempfile)
    rm $tempfile

    case $report_selected in
    "packages")
        if [[ "$pkgs_status" = "OK" ]]
        then
            whiptail --title  "GoTYPO3 : Debian Lenny"             \
                     --msgbox "All needed packages are installed" \
                     10 30
        else
            whiptail --title "GoTYPO3 : Debian Lenny"                        \
                     --yesno "`echo -e "Those packages are not installed :" \
                                      "\n"                                  \
                                      "\n$pkgs_missing"                     \
                                      "\n"                                  \
                                      "\nInstall them ?"`"                  \
                     22 45                                                  \
                     && {
                            apt-get update
                            apt-get -y install $pkgs_missing
                            dpkg-reconfigure locales
                            a2dissite default
                            a2enmod rewrite
                            /etc/init.d/apache2 reload
                        } || true
        fi
        ;;
    "logrotate")
        if [[ "$logrot_status" = "OK" ]]
        then
            whiptail --title  "GoTYPO3 : Debian Lenny"                          \
                     --msgbox "Logrotate configuration file \"vhosts\" exists" \
                     10 30
        else
            whiptail --title "GoTYPO3 : Debian Lenny"                                 \
                     --yesno "`echo -e "Logrotate configuration file does not exist" \
                                      "\n"                                           \
                                      "\nCreate it ?"`"                              \
                     10 30                                                           \
                     &&    download_file "$GOTYPO3_IFAUTH"                         \
                                      "$GOTYPO3_SRV/modules/logrotate_vhosts.conf" \
                                      "/etc/logrotate.d/vhosts"                   \
                                      "$GOTYPO3_AUTHUSR"                           \
                                      "$GOTYPO3_AUTHPWD" || true
        fi
        ;;
    "proftpd")
        if [[ "$proftpd_status" = "OK" ]]
        then
            whiptail --title  "GoTYPO3 : Debian Lenny"           \
                     --msgbox "proftpd is correctly configured" \
                     10 30
        else
            whiptail --title "GoTYPO3 : Debian Lenny"                           \
                     --yesno "`echo -e "proftpd is not correctly configured."  \
                                      "\n"                                     \
                                      "\nApply default GoTYPO3 configuration ?" \
                                      "\n"                                     \
                                      "\nIMPORTANT : This will drop ftpserver" \
                                      "mysql database and proftpd mysql user " \
                                      "if they exist, and overwrite proftpd "  \
                                      "configuration files"`"                  \
                     15 45                                                     \
                     && configure_proftpd || true
        fi
        ;;
    *)
    
        ;;
    esac
done

trap - INT TERM EXIT

exit 0
