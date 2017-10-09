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

PCAPs=$1

if [ -e "PCAPs-work.sh" ]; then
	mv -iv PCAPs-work.sh PCAPs-work.sh_$(date +%s)
	> PCAPs-work.sh
else
	> PCAPs-work.sh
fi

echo "For the PCAPs you gave:"
echo "$1"
echo "issue:"
echo "touch .tshark-hosts-conv_non-interactive"
echo "in the related dirs that we'll create?"
echo "( else, don't go anywhere, and keep replying"
echo "to:"
echo "*tshark-hosts-conv*"
echo "querying you over options... )"
# else while you're watching how the script fares, issue a touch
# .tshark-hosts-conv_non-interactive before this script chdir into the dir in
# question
ask
if [ "$?" == 0 ]; then
	for i in $(ls -1 $PCAPs|sed 's/\.pcap//'); do
		echo "if [ ! -e  \"${i}_tHostsConv\" ];  then" >> PCAPs-work.sh
		echo mkdir ${i}_tHostsConv >> PCAPs-work.sh
		echo cd ${i}_tHostsConv >> PCAPs-work.sh
		echo touch .tshark-hosts-conv_non-interactive >> PCAPs-work.sh
		echo fi >> PCAPs-work.sh
		echo cd \- >> PCAPs-work.sh
	done
fi

for i in $(ls -1 $PCAPs|sed 's/\.pcap//'); do
	# setting up the tshark-streams dir to get working...
	echo "if [ ! -e  \"${i}_tStreams\" ];  then" >> PCAPs-work.sh
	echo mkdir ${i}_tStreams >> PCAPs-work.sh
	echo fi \; >> PCAPs-work.sh
	echo cd ${i}_tStreams >> PCAPs-work.sh
	# ...but w/o overwriting (or delete --before its turn-- the ${i}.pcap symlink and
	# overwrite)
	echo "if [ ! -e  \"${i}.pcap\" ];  then" >> PCAPs-work.sh
	echo "ln -s ../$i.pcap" >> PCAPs-work.sh
	echo tshark-streams.sh -r $i.pcap >> PCAPs-work.sh
	echo fi >> PCAPs-work.sh
	echo cd \- >> PCAPs-work.sh
	# setting up the tshark-streams dir to get working...
	echo "if [ ! -e  \"${i}_tHostsConv\" ];  then" >> PCAPs-work.sh
	echo mkdir ${i}_tHostsConv >> PCAPs-work.sh
	echo fi >> PCAPs-work.sh
	echo cd ${i}_tHostsConv >> PCAPs-work.sh
	# ...but w/o overwriting (or delete --before its turn-- the ${i}.pcap symlink and
	# overwrite)
	echo "if [ ! -e  \"${i}.pcap\" ];  then" >> PCAPs-work.sh
	echo "ln -s ../$i.pcap" >> PCAPs-work.sh
	echo tshark-hosts-conv.sh -r $i.pcap >> PCAPs-work.sh
	echo fi >> PCAPs-work.sh
	echo cd \- >> PCAPs-work.sh
	# If I get tshark-hosts-conv to run non-interactively (likely soon if it isn't done
	# already), the PCAPs-work.sh can be run multiple instances in same directory where
	# you place your PCAPs.
done
chmod 755 PCAPs-work.sh
