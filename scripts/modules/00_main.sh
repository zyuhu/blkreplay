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

function remote
{
    host="$1"
    shift
    ssh root@"$host" "$@"
}

function remote_all
{
    for host in $replay_hosts_unique; do
	remote "$host" "$@" || exit $?
    done
}

#####################################################################

function main_prepare
{
    replay_count=0
    replay_host_list="$(eval echo "$replay_host_list")"
    replay_device_list="$(eval echo "$replay_device_list")"
    input_file_list="$(eval echo "$input_file_list")"
    if [ -z "$replay_host_list" ]; then
	echo "variable replay_host_list is undefined"
	exit -1
    fi
    if echo $replay_host_list | grep -q ":"; then
	for i in $replay_host_list; do
	    host=$(echo $i | cut -d: -f1)
	    device=$(echo $i | cut -d: -f2)
	    replay_host[$replay_count]=$host
	    replay_device[$replay_count]=$device
	    replay_max=$replay_count
	    (( replay_count++ ))
	done
    else
	if [ -z "$replay_device_list" ]; then
	    echo "variable replay_device_list is undefined"
	    exit -1
	fi
	for host in $replay_host_list; do
	    for device in $replay_device_list; do
		replay_host[$replay_count]=$host
		replay_device[$replay_count]=$device
		replay_max=$replay_count
		(( replay_count++ ))
	    done
	done
    fi
    if [ -z "$input_file_list" ]; then
	echo "variable input_file_list is undefined"
	exit -1
    fi
    replay_hosts_unique="$(for i in $(eval echo {0..$replay_max}); do echo "${replay_host[$i]}"; done | sort -u)"
    j=0
    for i in $input_file_list; do
	input_file[$j]=$i
	(( j++ ))
    done
    echo "List of hosts / devices / input files / output files:"
    j=0
    for i in $(eval echo {0..$replay_max}); do
	[ -z "${input_file[$j]}" ] && j=0
	input_file[$i]="${input_file[$j]}"
	devname="$(echo ${replay_device[$i]} | sed 's/[\/]\?dev[\/]\?//'| sed 's/\//./g' | sed 's/\.\././g')"
	output_file[$i]="${output_label:-TEST}$sub_prefix.${replay_host[$i]}.$devname.$(basename ${input_file[$i]} | sed 's/\.\(load\|gz\)//g').replay.gz"
	echo " $i: ${replay_host[$i]} ${replay_device[$i]} $(basename ${input_file[$i]}) ${output_file[$i]}"
	(( j++ ))
    done
    echo ""
}

function main_setup
{
    echo $FUNCNAME
    buffer_cmd="(buffer -m 16m 2>/dev/null || cat)"
    for host in $replay_hosts_unique; do
	echo "Copying executables to $host..."
	rsync -avP $base_dir/../src/blkreplay.{i686,x86_64} root@$host:
    done
}

function main_run
{
    echo $FUNCNAME
    start="${replay_start:-0}"
    len="${replay_duration:-3600}"
    delta="${replay_delta:-0}"
    for i in $(eval echo {0..$replay_max}); do
	mode_dev="${replay_device[$i]}"
	case "$vmode" in
	    *-verify)
            mode_dev="!$mode_dev"
	    ;;
	esac
	case "$vmode" in
	    with-conflicts*)
	    mode_dev="$mode_dev"
	    ;;
	    with-drop*)
	    mode_dev="?$mode_dev"
	    ;;
	    with-ordering*)
	    mode_dev="??$mode_dev"
	    ;;
	    with-verify*)
	    mode_dev="???$mode_dev"
	    ;;
	    with-final-verify*)
	    mode_dev="????$mode_dev"
	    ;;
	    with-paranoia*)
	    mode_dev="?????$mode_dev"
	    ;;
	    *)
	    echo "Warning: no vmode is set. Falling back to 'with-conflicts'."
	    mode_dev="$mode_dev"
	    ;;
	esac
	limits="$start $(( start + len))"
	[ -n "$replay_out_start" ] && limits="$start=$replay_out_start $(( start + len))"
	blkreplay="./blkreplay.\$(uname -m) $mode_dev ${speedup:-1.0} $limits"
	#echo "$blkreplay"
	cmd="$buffer_cmd | nice gunzip -f | $buffer_cmd | $blkreplay | $buffer_cmd 2>&1 | nice gzip | $buffer_cmd"
	echo "Starting blkreplay on ${replay_host[$i]} device $mode_dev"
	#echo "$cmd"
	remote "${replay_host[$i]}" "$cmd" < "${input_file[$i]}" > "${output_file[$i]}" &
	(( start += delta ))
    done
    echo "$(date) Waiting for termination........"
    wait
    echo "$(date) Done."
}

function main_cleanup
{
    echo $FUNCNAME
}

function main_finish
{
    echo $FUNCNAME
    if (( !omit_tmp_cleanup )); then
	echo "Cleaning all remote /tmp/ directories..."
	remote_all "rm -rf /tmp/blkreplay.*"
    fi
}

# Notice: this is the _only_ place where these lists are to be assigned.
# In modules, the lists must be _extended_ only (prepend / append)

prepare_list="main_prepare"
setup_list="main_setup"
run_list="main_run"
cleanup_list="main_cleanup"
finish_list="main_finish"


function main
{
    ok=1
    for script in $prepare_list; do
	if (( ok )); then
	    echo "calling $script"
	    $script || ok=0
	fi
    done
    for script in $setup_list; do
	if (( ok )); then
	    echo "calling $script"
	    $script || ok=0
	fi
    done
    for script in $run_list; do
	if (( ok )); then
	    echo "calling $script"
	    $script || ok=0
	fi
    done
    for script in $cleanup_list; do
	echo "calling $script"
	$script
    done
    for script in $finish_list; do
	echo "calling $script"
	$script
    done
    return $(( !ok ))
}