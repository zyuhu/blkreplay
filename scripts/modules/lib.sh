#!/usr/bin/env bash
# Copyright 2010-2012 Thomas Schoebel-Theuer /  1&1 Internet AG
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

if (( !noecho )); then
    echo "Sourcing lib.sh"
fi

# this may be later overridden by distros / install scripts / etc

# $sript_dir is assumed to be already set by the caller
base_dir="$(cd "$script_dir/.."; pwd)"
bin_dir="$base_dir/src"
module_dir="$script_dir/modules"
download_dir="$base_dir/downloads"
mkdir -p "$download_dir" || exit -1

[ -x $bin_dir/bins.exe ] || \
    (cd $base_dir && ./configure && make) ||\
    { echo "Could not make binaries. Sorry." ; exit -1; }

#####################################################################

# helper for prevention of script failures due to missing tools

function check_installed
{
    check_list="$1"
    for i in $check_list; do
	if ! which $i >/dev/null 2>&1; then
	    echo "Sorry, program '$i' is not installed."
	    exit -1
	fi
    done
}

check_always_list="basename dirname which pwd mkdir rmdir rm cat ls sort ssh scp nice"
check_installed "$check_always_list"

#####################################################################

# helper for sourcing other config files (may reside in parents of cwd)

function source_config
{
    name="$1"
    setup_dir=$(pwd)
    limit=0
    until [ -r $setup_dir/$name.conf ]; do
	setup_dir="$(cd $setup_dir/..; pwd)"
	(( limit++ > 20 )) && { echo "No parent dir found for (potential) config file $name.conf."; return 1; }
    done
    setup=$setup_dir/$name.conf
    echo "Sourcing config file $setup"
    shopt -u nullglob
    source $setup || exit $?
    return 0
}



#####################################################################

# abstracting access to remote hosts

function remote
{
    host="$1"
    shift
    (( verbose_script > 1 )) && echo "remote $host: $@"
    ssh root@"$host" "$@"
}

function remote_all
{
    host_all="$1"
    shift
    (( verbose_script > 1 )) && echo "remote_all: $@"
    for host in $host_all; do
	remote "$host" "$@" || return $?
    done
    return 0
}

function remote_all_noreturn
{
    host_all="$1"
    shift
    (( verbose_script > 1 )) && echo "remote_all: $@"
    for host in $host_all; do
	remote "$host" "$@"
    done
}

#####################################################################

# generate copyright header on stdout

function echo_copyright
{
    name="$1"
    copyright="${2:-Thomas Schoebel-Theuer /  1&1 Internet AG}"

    # Notice: the following GNU all-permissive license applies to the
    # generated DATA file only, and does not change the GPL of this script.
    #
    echo "Copyright $copyright"
    echo ""
    if [ -n "$name" ]; then
	echo "This file was automatically generated from '$name'"
	echo "converted by $(whoami)@$(hostname) $(date)"
	echo ""
    fi
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
}
