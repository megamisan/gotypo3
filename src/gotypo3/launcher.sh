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

# load configuration if exists
if [[ -e /opt/ics/gotypo/conf.local ]]
then
    source /opt/ics/gotypo/conf.local
fi

export GOTYPO3_IFAUTH=${GOTYPO3_IFAUTH:-0}
export GOTYPO3_AUTHUSR=${GOTYPO3_AUTHUSR:-"no-user-defined"}
export GOTYPO3_AUTHPWD=${GOTYPO3_AUTHPWD:-"no-password-defined"}
export GOTYPO3_SRV=${GOTYPO3_SRV:-"http://gotypo.in-cite.net"}

#===============================================================================
# main script
#===============================================================================

wget $GOTYPO3_SRV/gotypo3.sh -O /tmp/gotypo3.sh
chmod u+x /tmp/gotypo3.sh
/tmp/gotypo3.sh
rm /tmp/gotypo3.sh
