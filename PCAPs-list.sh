#!/bin/bash
#
# this one is still only an idea

function ask()	# this function borrowed from "Advanced BASH Scripting Guide"
				# (a free book) by Mendel Cooper
{
    echo -n "$@" '[y/[n]] ' ; read ans
    case "$ans" in
        y*|Y*) return 0 ;;
        *) return 1 ;;
    esac
}
if [ $# -eq 0 ]; then
    echo "give (a list of) file(s)"
    exit 0
fi

PCAPs=$1

for i in $(ls -1 $PCAPs|sed 's/\.pcap//'); do
	ls -l ${i}_tStreams/ | tail -15 ; read FAKE ;
	if [ -e "${i}_tStreams" ]; then
		cd ${i}_tStreams/ ; ls -l ${i}_streams.ls-1 ; read FAKE ;
		head -3  ${i}_streams.ls-1 ; tail -3  ${i}_streams.ls-1 ;
		wc -l  ${i}_streams.ls-1 ;
		read FAKE ;
		ls -l ${i}*-ssl.bin | head -7 ; ls -l ${i}*-ssl.bin | tail -7 ;
		ls -l ${i}*-ssl.bin | wc -l ;
		cd - ;
		ask ;
		if [ "$?" == 0 ]; then
			mv -iv ${i}_tStreams ${i}.pcap Done/ ;
			read FAKE ;
		fi ;
	fi ;
done ;
