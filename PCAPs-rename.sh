#!/bin/bash
#
# PCAPs-rename.sh            rename PCAPs of the "-C 100" set (see uncenz-1st)
#

hst=$1
ls -l dump*.pcap | sed 's/_Zaba//' | sed 's/_i\.pcap/.pcap/' | sed 's/.*_\(...\)\.pcap/\1/' \
    | grep -v ' \-> ' > .hst_all
ls -l dump*.pcap | sed 's/_Zaba//' | sed 's/_i\.pcap/.pcap/' | sed 's/.*_\(...\)\.pcap/\1/' \
    | grep -v ' \-> '|sort -u > .hst_uniq
echo "Running ${0##*/}"
hst_all_wc_l=$(cat .hst_all|wc -l)
hst_uniq_wc_l=$(cat .hst_uniq|wc -l)
echo \$hst_all_wc_l: $hst_all_wc_l
echo \$hst_uniq_wc_l: $hst_uniq_wc_l
if [ "$hst_uniq_wc_l" == "1" ]; then
    hst=$(<.hst_uniq)
else
    echo "Pls. give the \$hst, (mostly) the three letters before \"\.pcap\":"
    read hst
fi
echo \$hst: $hst
read NOP
if [ "X${hst}" == "X" ]; then
	echo "Can't go on with:"
	echo \$hst: $hst
	exit 0
fi
echo "The _i.pcap1 and such here. Below the not _i.pcap."
ls -1 *.pcap1
read NOP
for PCAP in $(ls -1 *.pcap1| grep _i.pcap1|sed "s/_${hst}_i\.pcap1//"); do
    echo \$PCAP: $PCAP
done
read NOP
for PCAP in $(ls -1 *.pcap1| grep _i.pcap1|sed "s/_${hst}_i\.pcap1//"); do
    echo "\$PCAP: $PCAP (start)"
    n=0
    if [ -e "${PCAP}_${hst}_i.pcap" ]; then
        #echo "in initial if"
        mv -iv ${PCAP}_${hst}_i.pcap ${PCAP}-0${n}_${hst}_i.pcap
        ls -l ${PCAP}-0${n}_${hst}_i.pcap
    fi 
    ln -s ${PCAP}-0${n}_${hst}_i.pcap ${PCAP}_${hst}_i.pcap
    ls -l  ${PCAP}_${hst}_i.pcap
    ls -lL  ${PCAP}_${hst}_i.pcap
    let n+=1 
    echo \$n: $n
    while [ -e "${PCAP}_${hst}_i.pcap${n}" ]; do
        echo "in while"
        if [ "$n" -lt "10" ]; then
            mv -iv ${PCAP}_${hst}_i.pcap${n} ${PCAP}-0${n}_${hst}_i.pcap
            ls -l ${PCAP}-0${n}_${hst}_i.pcap
            read NOP
        else
            mv -iv ${PCAP}_${hst}_i.pcap${n} ${PCAP}-${n}_${hst}_i.pcap
            ls -l ${PCAP}-${n}_${hst}_i.pcap
            read NOP
        fi
        let n+=1 
        echo \$n: $n
        read NOP
    done
    echo "\$PCAP: $PCAP (over)"
    read NOP
done

echo "Now the not _i.pcap."
ls -1 *.pcap1
read NOP
for PCAP in $(ls -1 *.pcap1|sed "s/_$hst\.pcap1//"); do
    echo "\$PCAP: $PCAP (start)"
    n=0
    if [ -e "${PCAP}_${hst}.pcap" ]; then
        echo "in initial if"
        mv -iv ${PCAP}_${hst}.pcap ${PCAP}-0${n}_${hst}.pcap
        ls -l ${PCAP}-0${n}_${hst}.pcap
    fi 
    ln -s ${PCAP}-0${n}_${hst}.pcap ${PCAP}_${hst}.pcap
    ls -l  ${PCAP}_${hst}.pcap
    ls -lL  ${PCAP}_${hst}.pcap
    let n+=1 
    echo \$n: $n
    while [ -e "${PCAP}_${hst}.pcap${n}" ]; do
        echo "in while"
        if [ "$n" -lt "10" ]; then
            mv -iv ${PCAP}_${hst}.pcap${n} ${PCAP}-0${n}_${hst}.pcap
            ls -l ${PCAP}-0${n}_${hst}.pcap
            read NOP
        else
            mv -iv ${PCAP}_${hst}.pcap${n} ${PCAP}-${n}_${hst}.pcap
            ls -l ${PCAP}-0${n}_${hst}.pcap
            read NOP
        fi
        let n+=1 
        echo \$n: $n
    done
    echo "\$PCAP: $PCAP (over)"
done

