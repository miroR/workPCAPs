#!/bin/bash
#
# PCAPs-work-prep-sep.sh -- work captured network traces (PCAPs)
#                           rewrite of now obsolete PCAPs-work-prep.sh
#
# Copyright (C) 2026 Miroslav Rovis, <https://www.CroatiaFidelis.hr/>
#
# released under BSD license, pls. see LICENSE, or assume  general BSD license

function ask()
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

PCAPs=( $1 )
echo \$PCAPs: $PCAPs
echo \$PCAPs[@]: ${PCAPs[@]}
read NOP

ts=$(date +%s)
for file in PCAPs-work-tH.sh PCAPs-work-tS.sh ; do
    if [ -e "$file" ]; then
        mv -v $file ${file}.PREV
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
unset tcpdu_PDUs_noTor
ask "These are non-tor PCAPs?"
if [ "$?" == 0 ]; then
    tcpdu_PDUs_noTor="y"
else
    : # remains unset
fi
echo \$tcpdu_PDUs_noTor: $tcpdu_PDUs_noTor
read NOP

for i in $(ls -1 ${PCAPs[ord]}|sed 's/\.pcap//'); do
    if [ -L "$i.pcap" ]; then
        echo "will be 'continue'ing in this one^s turn"
        ls -l $i.pcap
    fi
done
read NOP
    

# Split into two possible scripts, i.e. first only tStreams blocks, then only
# tHostsConv blocks. It's important that these be separated, see comment at the
# very top.
for PCAP in ${PCAPs[@]}; do
    echo $PCAP
done
read NOP
for PCAP in ${PCAPs[@]}; do
    i=$(echo $PCAP|sed 's/\.pcap//')
    if [ -L "$i.pcap" ]; then
        echo "Not working the symlinked PCAP:"
        ls -l $i.pcap
        echo "sleep 1 and 'continue'"
        sleep 1
        continue
    fi
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
    for PCAP in ${PCAPs[@]}; do
        i=$(echo $PCAP|sed 's/\.pcap//')
        if [ -L "$i.pcap" ]; then
            echo "Not working the symlinked PCAP:"
            ls -l $i.pcap
            echo "sleep 1 and 'continue'"
            sleep 1
            continue
        fi
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

for PCAP in ${PCAPs[@]}; do
    i=$(echo $PCAP|sed 's/\.pcap//')
    if [ -L "$i.pcap" ]; then
        echo "Not working the symlinked PCAP:"
        ls -l $i.pcap
        echo "sleep 1 and 'continue'"
        sleep 1
        continue
    fi
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
    if [ -n "$tcpdu_PDUs_noTor" ]; then
        echo "tcpdu-PDUs-noTor.sh ${i}_127.0.0.1.pcap" >> PCAPs-work-tH.sh    # 'tcpdu' for tcpdump
    else
        echo "tcpdu-PDUs.sh ${i}_127.0.0.1.pcap" >> PCAPs-work-tH.sh
    fi

    # from PCAPs-msg-r-PDU.sh
    PCAP_FILE_loc=$(echo $i.pcap|sed 's/\.pcap/_127\.0\.0\.1\.pcap/')
    echo \$PCAP_FILE_loc: $PCAP_FILE_loc
    #read NOP
    num_dots=$(echo $PCAP_FILE_loc|sed 's/\./\n/g'| wc -l)
    num_dots_min_1=$(echo $num_dots - 1 | bc)
    echo \$num_dots_min_1: $num_dots_min_1
    ext=$(echo $PCAP_FILE_loc|cut -d. -f $num_dots)
    PCAP_loc=$(echo $PCAP_FILE_loc|sed "s/\(.*\)\.$ext/\1/")
    echo \$ext: $ext
    #read NOP
    echo \$PCAP_loc: $PCAP_loc
    #read NOP
    PCAP_FILE_loc=$PCAP_loc.$ext
    echo \$PCAP_FILE_loc: $PCAP_FILE_loc
    #read NOP
    pcap_data=${PCAP_loc}_data.d
    echo \$pcap_data: $pcap_data
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
done

for file in PCAPs-work-tH.sh PCAPs-work-tS.sh ; do
    if [ -e "$file.PREV" ]; then
        if ( diff $file.PREV $file ); then
            mv -v $file.PREV $file
            echo "(the new $file was identical to old)"
        fi
    fi
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
read NOP_permanent
# vim: set tabstop=4 expandtab:    
