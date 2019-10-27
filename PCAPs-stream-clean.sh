#!/bin/bash
#
# PCAPs-stream-clean.sh -- segregate out all streams with less than 2 packets,
#							and keep only streams holding 3 or more packets.
#							Needed, because those small streams slow down
#							horribly my tshark-streams.sh.
#

function ask()	# this function borrowed from "Advanced BASH Scripting Guide"
				# (a free book) by Mendel Cooper
{
	echo -n "$@" '[y/[n]] ' ; read ans
	case "$ans" in
		y*|Y*) return 0 ;;
		*) return 1 ;;
	esac
}

PCAPs=$1
echo \$PCAPs: $PCAPs
read NOOP
PCAPs_tr=$(ls -1 $1 | tr '\012' ' ')
echo \$PCAPs_tr: $PCAPs_tr
read NOOP
echo "ls -1 \$PCAPs|sed 's/\.pcap//'"
echo "ls -1 $PCAPs|sed 's/\.pcap//'"
ls -1 $PCAPs|sed 's/\.pcap//'
read NOOP
for i in $(ls -1 $PCAPs|sed 's/\.pcap//'); do
    TMP="$(mktemp -d "/tmp/$i.$$.XXXXXXXX")"
    ls -ld $TMP
    ls -l $TMP
    read NOOP
    ls -l $i.pcap
	tshark -r $i.pcap -T fields -e frame.number -e tcp.stream \
		> $TMP/${i}_fr_no_stream_list
	# debug 6 lines
	echo "ls -l $TMP/${i}_fr_no_stream_list"
	ls -l $TMP/${i}_fr_no_stream_list
	head $TMP/${i}_fr_no_stream_list
	tail $TMP/${i}_fr_no_stream_list
	echo "(ls -l $TMP/${i}_fr_no_stream_list)"
    read NOOP
	tshark -r $i.pcap -T fields -e frame.number -e tcp.stream \
		| awk '{ print $2 }' > $TMP/${i}_streams_list
	# debug 6 lines
	echo "ls -l $TMP/${i}_streams_list"
	ls -l $TMP/${i}_streams_list
	head $TMP/${i}_streams_list
	tail $TMP/${i}_streams_list
	echo "(ls -l $TMP/${i}_streams_list)"
    read NOOP
	# Now sort that \${i}_streams_list
	str_num_tail_1=$(tail -1 $TMP/${i}_streams_list|sed 's/\012//')
	echo -n $str_num_tail_1|wc -c
	str_num_max_len=$(echo -n $str_num_tail_1|wc -c)
	echo \$str_num_max_len: $str_num_max_len
    read NOOP
	str_num_len=1
	echo \$str_num_len: $str_num_len
	search_str='[0-9]'
	echo "\$search_str: $search_str"
	echo "$search_str"
    read NOOP
	> $TMP/${i}_streams_list_sort
	while [ "$str_num_len" -le "$str_num_max_len" ]; do
		#for str in $(<$TMP/${i}_streams_list); do
		grep "^$search_str\>" $TMP/${i}_streams_list | sort -u \
			>> $TMP/${i}_streams_list_sort
		#debug 5 lines
		ls -l $TMP/${i}_streams_list_sort
		head $TMP/${i}_streams_list_sort
		tail $TMP/${i}_streams_list_sort
		echo "(ls -l $TMP/${i}_streams_list_sort)"
        read NOOP
		#done
		let str_num_len+=1
		echo \$str_num_len: $str_num_len
		echo "echo \${search_str}[0-9]"
    	read NOOP
		search_str=$(echo ${search_str}[0-9])
		echo \$search_str: $search_str
    	read NOOP
	done
    read NOOP
	> $TMP/${i}_fr_no_stream_list_sort
	for stream in $(cat $TMP/${i}_streams_list_sort); do
		# debug
		#echo \$stream: $stream; ls -l $TMP/${i}_fr_no_stream_list
		grep "\<$stream$" $TMP/${i}_fr_no_stream_list \
			>> $TMP/${i}_fr_no_stream_list_sort
		#read NOOP
	done; 
	# debug 6 lines
	echo "ls -l $TMP/${i}_fr_no_stream_list_sort"
	ls -l $TMP/${i}_fr_no_stream_list_sort
	head $TMP/${i}_fr_no_stream_list_sort
	tail $TMP/${i}_fr_no_stream_list_sort
	echo "(ls -l $TMP/${i}_streams_list_sort)"
    read NOOP
	if [ -e "${i}_str_fr_list" ]; then
		mv -iv ${i}_str_fr_list ${i}_str_fr_list.$(date +%s)
	fi
cat > ${i}_str_fr_list <<EOF
# These packets all belong to streams that have no more than 2 packets each
# When removed from their PCAP, easier the work.
EOF
	for stream in $(<$TMP/${i}_streams_list_sort); do
		echo \"$stream\"
		cat $TMP/${i}_fr_no_stream_list_sort | awk '{ print $2 }' | grep "^$stream\>"
    	read NOOP
		str_cnt=$(cat $TMP/${i}_fr_no_stream_list_sort | awk '{ print $2 }' | grep "^$stream\>"|wc -l)
		echo \$str_cnt: $str_cnt
    	read NOOP
		if [ "$str_cnt" -le "2" ]; then
			str_fr=$(cat $TMP/${i}_fr_no_stream_list_sort | grep "[[:space:]]$stream\>" | awk '{ print $1 }')
			echo \$str_fr: $str_fr
			echo $str_fr >> ${i}_str_fr_list
		fi
	done
	echo "Done:"
    ls -l $i.pcap
    read NOOP
    trap "rm -rf $TMP/" EXIT INT TERM
    export TMP
    rm -rf $TMP/
done
ls -l $TMP
read NOOP
trap "rm -rf $TMP/" EXIT INT TERM

# vim: set tabstop=4 expandtab:
