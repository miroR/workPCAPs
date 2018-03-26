#!/bin/bash
#
if [ $# -eq 0 ]; then
	echo "give (a list of) file(s)"
	exit 0
fi

function ask()	# this function borrowed from "Advanced BASH Scripting Guide"
				# (a free book) by Mendel Cooper
{
	echo -n "$@" '[y/[n]] ' ; read ans
	case "$ans" in
		y*|Y*) return 0 ;;
		*) return 1 ;;
	esac
}

#echo \$1: $1
#read FAKE
PCAPs=$1
echo \$PCAPs: $PCAPs
#read FAKE
#PCAPs_tr=$(ls -1 $1 | tr '\012' ' ')
#echo $PCAPs_tr
#read FAKE

if [ -e "PCAPs-work.sh" ]; then
	mv -iv PCAPs-work.sh PCAPs-work.sh_$(date +%s)
	> PCAPs-work.sh
else
	> PCAPs-work.sh
fi

echo "For the PCAPs of your $1, issue:"
echo "touch .tshark-hosts-conv_non-interactive"
echo "in the related dirs?"
echo "( else, don't go anywhere, and keep replying"
echo "to:"
echo "*tshark-hosts-conv*"
echo "querying you over options... )"
ask
if [ "$?" == 0 ]; then
	for i in $(ls -1 $PCAPs|sed 's/\.pcap//'); do
		echo "if [ ! -e  \"${i}_tHostsConv\" ];  then" >> PCAPs-work.sh
		echo mkdir ${i}_tHostsConv >> PCAPs-work.sh
		echo fi >> PCAPs-work.sh
		echo cd ${i}_tHostsConv >> PCAPs-work.sh
		echo touch .tshark-hosts-conv_non-interactive >> PCAPs-work.sh
		echo cd \- >> PCAPs-work.sh
	done
fi

## pause to check (comment out if all is fine)
#echo "echo Pause for a check. Enter to continue." >> PCAPs-work.sh
#echo "read FAKE" >> PCAPs-work.sh

for i in $(ls -1 $PCAPs|sed 's/\.pcap//'); do
	# else it works on empty (PCAPs that are not yet started work on can be
	# removed any time from the dir without nuissance with this outer
	# condition)
	echo "if [ -e \"${i}.pcap\" ];  then" >> PCAPs-work.sh
	# setting up the tshark-streams dir to get working...
	echo "if [ ! -e  \"${i}_tStreams\" ];  then" >> PCAPs-work.sh
	echo mkdir ${i}_tStreams >> PCAPs-work.sh
	echo fi \; >> PCAPs-work.sh
	echo cd ${i}_tStreams >> PCAPs-work.sh
	# ...but w/o overwriting (or delete --before its turn-- the ${i}.pcap symlink and
	# overwrite)
	echo "if [ ! -e  \"${i}.pcap\" ];  then" >> PCAPs-work.sh
	echo "ln -s ../$i.pcap" >> PCAPs-work.sh
	if [ -e "${i}_SSLKEYLOGFILE.txt" ]; then
	echo ln -s ../${i}_SSLKEYLOGFILE.txt >> PCAPs-work.sh
	echo tshark-streams.sh -r $i.pcap -k ${i}_SSLKEYLOGFILE.txt >> PCAPs-work.sh
	else
	echo tshark-streams.sh -r $i.pcap >> PCAPs-work.sh
	fi
	echo fi >> PCAPs-work.sh
	echo cd \- >> PCAPs-work.sh
	echo fi >> PCAPs-work.sh
	# setting up the tshark-streams dir to get working...
	# without -e $i.pcap it would run on empty (see similar condition for
	# tStreams above)...
	echo "if [ ! -e  \"${i}_tHostsConv\" ] && [ -e \"${i}.pcap\" ];  then" >> PCAPs-work.sh
	echo mkdir ${i}_tHostsConv >> PCAPs-work.sh
	echo fi >> PCAPs-work.sh
	echo "if [ -e \"${i}.pcap\" ];  then cd ${i}_tHostsConv" >> PCAPs-work.sh
	# ...but w/o overwriting (or you could deliberately delete --before its turn-- the
	# ${i}.pcap symlink to overwrite previous results)
	echo "if [ ! -e  \"${i}.pcap\" ];  then" >> PCAPs-work.sh
	echo "ln -s ../$i.pcap" >> PCAPs-work.sh
	if [ -e "${i}_SSLKEYLOGFILE.txt" ]; then
	echo ln -s ../${i}_SSLKEYLOGFILE.txt >> PCAPs-work.sh
	echo tshark-hosts-conv.sh -r $i.pcap -k ${i}_SSLKEYLOGFILE.txt >> PCAPs-work.sh
	else
	echo tshark-hosts-conv.sh -r $i.pcap >> PCAPs-work.sh
	fi
	echo fi >> PCAPs-work.sh
	echo cd \- >> PCAPs-work.sh
	echo fi >> PCAPs-work.sh
	# tshark-hosts-conv can run non-interactively and PCAPs-work.sh can be run
	# multiple instances in same directory where you place your PCAPs.
done
chmod 755 PCAPs-work.sh
