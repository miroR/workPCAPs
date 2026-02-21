#!/bin/bash
#
# see PCAPs-work-prep.sh, this creates two scripts instead, PCAPs-work-tH.sh and
# PCAPs-work-tS.sh. Need them separate, as tcpdump may require entering passphrase
# too often with PCAPs-work-tH.sh.
#

function ask()    # this function borrowed from "Advanced BASH Scripting Guide"
                # (a free book) by Mendel Cooper
{
    echo -n "$@" '[y/[n]] ' ; read ans
    case "$ans" in
        y*|Y*) return 0 ;;
        *) return 1 ;;
    esac
}

if [ $# -eq 0 ]; then
    echo "give (a list of) PCAP(s)"
    echo "(if globbing, you need to quote it, e.g.:"
    echo "${0##*/} \"*.pcap\")"
    exit 0
fi

PCAPs_raw=$1
#echo \$PCAPs_raw: $PCAPs_raw

ts=$(date +%s)
for file in PCAPs-work-tH.sh PCAPs-work-tS.sh ; do
    if [ -e "$file" ]; then
        mv -v $file ${file}_$(date +%s)
        > $file
    else
        > $file
    fi
done

ask "Manually choose, wireshark from compile dir (y) or distro wireshark (n, just hit Enter)"
if [ "$?" == 0 ]; then
    echo "WIRESHARK_RUN_FROM_BUILD_DIRECTORY=1" >> PCAPs-work-tS.sh
    echo "TSHARK=/Cmn/git/wireshark.d/wireshark-ninja/run/tshark" >> PCAPs-work-tS.sh
else
    echo "TSHARK=$(which tshark)" >> PCAPs-work-tS.sh
fi
if [ -e ".tcpdu-PDUs-noTor" ]; then rm -v .tcpdu-PDUs-noTor; fi
ask "These are non-tor PCAPs?"
if [ "$?" == 0 ]; then
    touch .tcpdu-PDUs-noTor
    ls -l .tcpdu-PDUs-noTor 
fi

> .pcaps-no-sym
for i in $(ls -1 $PCAPs_raw|sed 's/\.pcap//'); do
    if [ -L "$i.pcap" ]; then
        echo "Not echoing the symlink:"
        ls -l $i.pcap
        echo "in the sanitized list."
    else
        echo $i.pcap >> .pcaps-no-sym
    fi
done
cat .pcaps-no-sym
echo "(cat .pcaps-no-sym)"
ls -l .pcaps-no-sym
read FAKE
PCAPs_raw=$(<.pcaps-no-sym)
for pcap in $PCAPs_raw; do
    if [ ! -s "$pcap" ]; then
        ls -l $pcap
        echo $pcap >> .pcaps_empty
        echo "(empty PCAP, will not be worked)"
    else
        echo $pcap >> .pcaps
    fi
done
sort -u .pcaps-no-sym >  .pcaps-no-sym_sort-u
cat .pcaps .pcaps_empty | sort -u >  .pcaps_sort-u
if ( diff .pcaps-no-sym_sort-u .pcaps_sort-u ); then
    : #echo All correct, sleep 3 just for debugging
    #sleep 3
else
        echo "Error, pls. investigate!"
fi
PCAPs=$(<.pcaps)
echo \$PCAPs: $PCAPs
    

# Split into two possible scripts, i.e. first only tStreams blocks, then only
# tHostsConv blocks. It's important that these be separated, see comment at the
# very top.
for i in $(ls -1 $PCAPs|sed 's/\.pcap//'); do
    # else it works on empty (PCAPs that are not yet started work on can be
    # removed any time from the dir without nuissance with this outer
    # condition)
    # Tried, but it's more work, different than the include for other scripts:
    # . shark2use >> PCAPs-work-tS.sh
    echo "if [ -e \"${i}.pcap\" ];  then" >> PCAPs-work-tS.sh
    # setting up the tshark-streams dir to get working...
    echo "if [ ! -e  \"${i}_tStreams\" ];  then" >> PCAPs-work-tS.sh
    echo mkdir ${i}_tStreams >> PCAPs-work-tS.sh
    echo fi \; >> PCAPs-work-tS.sh
    echo cd ${i}_tStreams >> PCAPs-work-tS.sh
    # ...but w/o overwriting (or delete --before its turn-- the ${i}.pcap symlink and
    # overwrite)
    echo "if [ ! -e  \"${i}.pcap\" ];  then" >> PCAPs-work-tS.sh
    echo "ln -s ../$i.pcap" >> PCAPs-work-tS.sh
    if [ -e "${i}_SSLKEYLOGFILE.txt" ]; then
    echo ln -s ../${i}_SSLKEYLOGFILE.txt >> PCAPs-work-tS.sh
    echo tshark-streams.sh -r $i.pcap -k ${i}_SSLKEYLOGFILE.txt >> PCAPs-work-tS.sh
    echo "echo \"\$TSHARK -otls.keylog_file:${i}_SSLKEYLOGFILE.txt -r $i.pcap -q --export-object http,files\"" >> PCAPs-work-tS.sh
    echo "\$TSHARK -otls.keylog_file:${i}_SSLKEYLOGFILE.txt -r $i.pcap -q --export-object http,files" >> PCAPs-work-tS.sh
    echo "mv -iv files ../${i}_files" >> PCAPs-work-tS.sh
    else
    echo tshark-streams.sh -r $i.pcap >> PCAPs-work-tS.sh
    echo "\$TSHARK -r $i.pcap -q --export-object http,files" >> PCAPs-work-tS.sh
    echo "mv -iv files ../${i}_files" >> PCAPs-work-tS.sh
    fi
    echo fi >> PCAPs-work-tS.sh
    echo cd \- >> PCAPs-work-tS.sh
    echo fi >> PCAPs-work-tS.sh
    echo >> PCAPs-work-tS.sh
done



echo "For the PCAPs of your $1, NOT issue:"
echo "touch .non-interactive"
echo "in the related dirs?"
echo "( but then don't go anywhere, and keep replying"
echo "to:"
echo "*tshark-hosts-conv*"
echo "querying you over options... )"
ask
if [ "$?" == 0 ]; then
    echo "The session will be interactive."
    echo "(and you were warned it would be with y/Y)"
else
    for i in $(ls -1 $PCAPs|sed 's/\.pcap//'); do
        echo "if [ -e \"${i}.pcap\" ];  then" >> PCAPs-work-tH.sh
        echo "if [ ! -e  \"${i}_tHostsConv\" ];  then" >> PCAPs-work-tH.sh
        echo mkdir ${i}_tHostsConv >> PCAPs-work-tH.sh
        echo cd ${i}_tHostsConv >> PCAPs-work-tH.sh
        echo touch .non-interactive >> PCAPs-work-tH.sh
        echo cd \- >> PCAPs-work-tH.sh
        echo fi >> PCAPs-work-tH.sh
        echo fi >> PCAPs-work-tH.sh
    done
fi
echo >> PCAPs-work-tH.sh

for i in $(ls -1 $PCAPs|sed 's/\.pcap//'); do
    # setting up the tHostsConv dir to get working...
    # without -e $i.pcap it would run on empty (see similar condition for
    # tStreams above)...
    echo "if [ ! -e  \"${i}_tHostsConv\" ] && [ -e \"${i}.pcap\" ];  then" >> PCAPs-work-tH.sh
    echo mkdir ${i}_tHostsConv >> PCAPs-work-tH.sh
    echo fi >> PCAPs-work-tH.sh
    echo "if [ -e \"${i}.pcap\" ];  then cd ${i}_tHostsConv" >> PCAPs-work-tH.sh
    # ...but w/o overwriting (or you could deliberately delete --before its turn-- the
    # ${i}.pcap symlink to overwrite previous results)
    echo "if [ ! -e  \"${i}.pcap\" ];  then" >> PCAPs-work-tH.sh
    echo "ln -s ../$i.pcap" >> PCAPs-work-tH.sh
    if [ -e "${i}_SSLKEYLOGFILE.txt" ]; then
    echo ln -s ../${i}_SSLKEYLOGFILE.txt >> PCAPs-work-tH.sh
    echo tshark-hosts-conv.sh -r $i.pcap -k ${i}_SSLKEYLOGFILE.txt >> PCAPs-work-tH.sh
    else
    echo tshark-hosts-conv.sh -r $i.pcap >> PCAPs-work-tH.sh
    fi
    # unfinished, and too slow:
    #echo "if [ -e \"${i}_127.0.0.1.pcap\" ]; then" >> PCAPs-work-tH.sh
    # Terribly slow:
    #echo "tshark-PDUs.sh ${i}_127.0.0.1.pcap" >> PCAPs-work-tH.sh
    #echo fi >> PCAPs-work-tH.sh
    echo "if [ -e \"${i}_127.0.0.1.pcap\" ]; then" >> PCAPs-work-tH.sh
    if [ -e ".tcpdu-PDUs-noTor" ]; then
        echo "tcpdu-PDUs-noTor.sh ${i}_127.0.0.1.pcap" >> PCAPs-work-tH.sh    # 'tcpdu' for tcpdump
    else
        echo "tcpdu-PDUs.sh ${i}_127.0.0.1.pcap" >> PCAPs-work-tH.sh    # 'tcpdu' for tcpdump
    fi

    # from PCAPs-msg-r-PDU.sh
    PCAP_FILE_loc=$(echo $i.pcap|sed 's/\.pcap/_127\.0\.0\.1\.pcap/')
    echo \$PCAP_FILE_loc: $PCAP_FILE_loc
    #read FAKE
    num_dots=$(echo $PCAP_FILE_loc|sed 's/\./\n/g'| wc -l)
    num_dots_min_1=$(echo $num_dots - 1 | bc)
    echo \$num_dots_min_1: $num_dots_min_1
    ext=$(echo $PCAP_FILE_loc|cut -d. -f $num_dots)
    PCAP_loc=$(echo $PCAP_FILE_loc|sed "s/\(.*\)\.$ext/\1/")
    echo \$ext: $ext
    #read FAKE
    echo \$PCAP_loc: $PCAP_loc
    #read FAKE
    PCAP_FILE_loc=$PCAP_loc.$ext
    echo \$PCAP_FILE_loc: $PCAP_FILE_loc
    #read FAKE
    pcap_data=${PCAP_loc}_data.d
    echo \$pcap_data: $pcap_data
    #echo "mv -v ${pcap_data}_stamps-len ../" >> PCAPs-work-tH.sh
    #echo "mv -v $pcap_data ../" >> PCAPs-work-tH.sh
    #echo "mv -v ${pcap_data}_TEXT.ls-1 ../" >> PCAPs-work-tH.sh
    echo fi >> PCAPs-work-tH.sh
    echo fi >> PCAPs-work-tH.sh
    echo cd \- >> PCAPs-work-tH.sh
    echo "if [ -e \"${i}_conv-ip_l.txt\" ] && [ ! -s \"${i}_conv-ip_l.txt\" ]; then" >> PCAPs-work-tH.sh
    echo ls -l ${i}_conv-ip_l.txt >> PCAPs-work-tH.sh
    echo rm -v ${i}_conv-ip_l.txt >> PCAPs-work-tH.sh
    echo fi >> PCAPs-work-tH.sh >> PCAPs-work-tH.sh
    echo "if [ ! -e \"${i}_conv-ip_l.txt\" ]; then" >> PCAPs-work-tH.sh
    echo conv-ip_l.sh $i.pcap >> PCAPs-work-tH.sh
    echo fi >> PCAPs-work-tH.sh
    echo fi >> PCAPs-work-tH.sh
    echo >> PCAPs-work-tH.sh
    # tshark-hosts-conv can run non-interactively and PCAPs-work-tH.sh can be run
    # multiple instances in same directory where you place your PCAPs.
done

chmod 755 PCAPs-work-tH.sh
chmod 755 PCAPs-work-tS.sh

mv -iv Tmp.d/*-00_???.pcap .
mv -iv Tmp.d/*_???.pcap .
ls -l Tmp.d/
rmdir -v Tmp.d/
read NOP

echo "There are two scripts that we created:"
ls -l PCAPs-work-tH.sh PCAPs-work-tS.sh
read FAKE_permanent
# vim: set tabstop=4 expandtab:    
