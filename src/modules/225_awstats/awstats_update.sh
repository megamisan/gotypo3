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
month=`date +"%-m"`
year=`date +"%Y"`

#===============================================================================
# main script
#===============================================================================

#===============================================================================
# functions declaration
#===============================================================================

# function :     previous_month
# description : remove one month to the month variable, adjusting year if 
#               necessary
previous_month()
{
	month=$((month - 1))
	if [ $month -eq 0 ]
	then
		month=12
		year=$((year - 1))
	fi
}

compute_year()
{
	local lastmonth=$((month - 1))
	if [ $month -eq 0 ]
	then
		lastmonth=12
		year=$((year - 1))
	fi
	month=$lastmonth
	lastmonth=$((lastmonth - 1))
	for (( ; $lastmonth ; lastmonth=$((lastmonth - 1)) ))
	do
		month="$lastmonth $month"
	done
}

if [ $# -gt 1 ]
then
	case $2 in
		lastday)
			if [ `date +%-d` -eq 1 ]
			then
				previous_month
			fi
		;;
		lastmonth)
			previous_month
		;;
		fullyear)
			compute_year
		;;
	esac
fi

if [ ! -d /var/www/vhosts/$1 ]
then
	echo "Error: domain $1 does not exists" 1>&2
	exit 1
fi

for mon in $month
do

	if [ $mon -lt 10 ]
	then
		mon=0$mon
	fi

	if [ ! -d /var/www/vhosts/$1/$staticpage/$year-$mon ]
	then
		mkdir /var/www/vhosts/$1/$staticpage/$year-$mon 
	fi

	$awstatsdir/awstats_buildstaticpages.pl -config=$1										\
											-update											\
											-dir=/var/www/vhosts/$1/$staticpage/$year-$mon	\
											-month=$mon										\
											-year=$year										\
											-awstatsprog=$awstatsdir/awstats.pl				\
											-lang=fr

	if [ ! -d /var/www/vhosts/$1/$staticpage/$year-$mon/icon ]
	then
		ln -s /usr/share/awstats/icon/ /var/www/vhosts/$1/$staticpage/$year-$mon/icon
	fi
done

exit 0
