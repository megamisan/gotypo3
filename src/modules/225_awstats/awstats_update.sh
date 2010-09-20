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

exec 2>> /var/log/awstats_update.log

#===============================================================================
# variables declaration and initialization
#===============================================================================

awstatsdir="/usr/lib/cgi-bin"
staticpage="awstatsweb/static"
month=`date +"%m"`
year=`date +"%Y"`

#===============================================================================
# main script
#===============================================================================

if [ ! -d /var/www/vhosts/$1 ]
then
	echo "Error: domain $1 does not exists" 1>&2
	exit 1
fi

if [ ! -d /var/www/vhosts/$1/$staticpage/$year-$month ]
then
	mkdir /var/www/vhosts/$1/$staticpage/$year-$month 
fi

$awstatsdir/awstats_buildstaticpages.pl -config=$1											\
										-update												\
										-dir=/var/www/vhosts/$1/$staticpage/$year-$month	\
										-month=$month										\
										-year=$year											\
										-awstatsprog=$awstatsdir/awstats.pl					\
										-lang=fr

if [ ! -d /var/www/vhosts/$1/$staticpage/$year-$month/icon ]
then
	ln -s /usr/share/awstats/icon/ /var/www/vhosts/$1/$staticpage/$year-$month/icon
fi

exit 0
