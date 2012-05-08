#!/bin/bash
# Copyright 2010-2012 Thomas Schoebel-Theuer, sponsored by 1&1 Internet AG
#
# Email: tst@1und1.de
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

#####################################################################

#
# Convert binary blktrace(8) data to internal format
# suitable as input for blkreplay.
#
# Usage: /path/to/script blktrace-binary-logfile
#
# The output format of this script is called .load.gz
# and is later used by blkreplay as input.
#
# TST 2010-01-26

filename="$1"

if ! [ -f "$filename.blktrace.0" ]; then
    echo "Input file $filename.blktrace.0 does not exist"
    exit -1
fi

{
    # Notice: the following GNU all-permissive license applies to the
    # generated DATA file only, and does not change the GPL of this script.
    #
    echo "Copyright Thomas Schoebel-Theuer, sponsored by 1&1 Internet AG"
    echo ""
    echo "This file was automatically generated from '$filename.blktrace.*'"
    echo "converted by $(whoami)@$(hostname) $(date)"
    echo ""
    echo "PLEASE DO NOT EDIT this file without renaming, even if legally"
    echo "allowed by the following GNU all-permissive license:"
    echo ""
    echo "Copying and distribution of this file, with or without modification,"
    echo "are permitted in any medium without royalty provided the copyright"
    echo "notice and this notice are preserved.  This file is offered as-is,"
    echo "without any warranty."
    echo ""
    echo "PLEASE name any derivatives of this file DIFFERENTLY, in order to"
    echo "avoid confusion. Additionally, PLEASE add a pointer to the original."
    echo ""
    echo "PLEASE means: failing to do so may damage your reputation."
    echo ""
    echo "Why? Because people EXPECT that 'things' remain the same, otherwise"
    echo "they may accuse you of winding them up."
    echo ""
    echo "Notice: damaged reputation can be harder than prison. I have warned you."
    echo ""
    echo "In practice: although I don't put a 'hard' requirement on you,"
    echo "PLEASE just copy/rename this file before doing"
    echo "any modifications, and include a pointer to the original."
    echo ""
    echo "Additionally, it is best practice to name your data files such that"
    echo "other people can easily grasp what is inside."
    echo ""
    echo "#################################################################"
    echo "start ; sector; length ; op ;  replay_delay=0 ; replay_duration=0"
    
    blkparse -v -i "$filename" -f '%2a ; %6T.%9t ; %12S ; %4n ; %3d ; 0.0 ; 0.0\n' |\
	sed 's/^ Q/ D/' |\
	sed 's/ WB/  W/' |\
	sed 's/ WS /  W /' |\
	sed 's/  \([RW]\)/\1/' |\
	grep "^ D" |\
	cut -d';' -f2-
} | gzip -9 > "$filename.load.gz"

