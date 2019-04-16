#!/bin/bash
function ask()	# this function borrowed from "Advanced BASH Scripting Guide"
				# (a free book) by Mendel Cooper
{
	echo -n "$@" '[y/[n]] ' ; read ans
	case "$ans" in
		y*|Y*) return 0 ;;
		*) return 1 ;;
	esac
}

for i in $(ls -1 *.pcap | sed 's/\.pcap//'); do
	if [ -e "${i}_tStreams" ]; then
		if ( grep -q $i DONE ); then
			echo -n "$i.pcap "
		else
			echo ;echo "=-=-=-=-=-=";ls -lL $i.pcap
			tail -3 ${i}_tStreams/*streams.ls-1
			ls -lLtr ${i}_tStreams/ | tail -3
			# $verif not yet (really) used
			verif=$(ls -1tr ${i}_tStreams/ | tail -2|grep -v streams)
			echo \$verif: $verif
			echo "Probably DONE?"
			ask
			if [ "$?" == 0 ]
				then echo $i.pcap >> DONE
			fi
		fi
	else
		echo -n "NPy: $i.pcap "
	fi
done
echo; echo "NPy="NOT processed yet" (if any)"
echo "=-=-=-=-=-="
# vim: set tabstop=4 expandtab:
