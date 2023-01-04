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

export BLUE='\033[1;94m'
export GREEN='\033[1;92m'
export RED='\033[1;91m'
export RESETCOLOR='\033[1;00m'

if [ -n "$1" ]; then
    tail_n=$1
else
    tail_n=3
fi
echo \$tail_n: $tail_n


for i in $(ls -1 *.pcap | sed 's/\.pcap//'); do
	if [ -e "${i}_tStreams" ]; then
		if ( grep -q $i DONE ); then
			echo -n "$i.pcap "
		else
			echo ;echo "=-=-=-=-=-=";ls -lL $i.pcap
			tail -$tail_n ${i}_tStreams/*streams.ls-1
			ls -lLtr ${i}_tStreams/ | tail -$tail_n
			# $verif not yet (really) used
			verif=$(ls -1tr ${i}_tStreams/ | tail -2|grep -v streams)
			echo \$verif: $verif
			echo "Probably DONE?"
			ask
			if [ "$?" == 0 ]
				then echo $i.pcap >> DONE; echo
			fi
		fi
	else
		echo -e -n "$RED $i.pcap $RESETCOLOR"
	fi
done
echo; echo -e "Legend: $RED dump_....pcap $RESETCOLOR NOT processed yet (if any)."
echo "=-=-=-=-=-="
# vim: set tabstop=4 expandtab:
