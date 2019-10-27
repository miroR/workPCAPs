#!/bin/bash
#
# PCAPs-stream-clean.sh -- segregate out all streams with less than 2 packets,
#                            and keep only streams holding 3 or more packets.
#                            Needed, because those small streams slow down
#                            horribly my tshark-streams.sh.
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

PCAPs=$1
echo \$PCAPs: $PCAPs
#read NOOP
PCAPs_tr=$(ls -1 $1 | tr '\012' ' ')
echo \$PCAPs_tr: $PCAPs_tr
#read NOOP
echo "ls -1 \$PCAPs|sed 's/\.pcap//'"
echo "ls -1 $PCAPs|sed 's/\.pcap//'"
ls -1 $PCAPs|sed 's/\.pcap//'
read NOOP
for i in $(ls -1 $PCAPs|sed 's/\.pcap//'); do
    if ( grep "^[0-9]" "${i}_str_fr_list" ); then
        echo "The $i.pcap seems to have been already processed:"
        ls -l $i.pcap
        ls -l ${i}_str_fr_list
        echo "NOTE: It is the user's responsability to keep their archives in order."
        echo "(If the ${i}_str_fr_list is not correct, pls. remove it and rerun $0.)"
        echo "[ sleep 1 ]"
        sleep 1
        continue
    fi
    TMP="$(mktemp -d "/tmp/$i.$$.XXXXXXXX")"
    ls -ld $TMP
    ls -l $TMP
    #read NOOP
    ls -l $i.pcap
    tshark -r $i.pcap -T fields -e frame.number -e tcp.stream \
        > $TMP/${i}_fr_no_stream_list
    # debug 6 lines
    echo "ls -l $TMP/${i}_fr_no_stream_list"
    ls -l $TMP/${i}_fr_no_stream_list
    head $TMP/${i}_fr_no_stream_list
    tail $TMP/${i}_fr_no_stream_list
    echo "(ls -l $TMP/${i}_fr_no_stream_list)"
    #read NOOP
    tshark -r $i.pcap -T fields -e frame.number -e tcp.stream \
        | awk '{ print $2 }' | grep '[[:print:]]' > $TMP/${i}_streams_list
    # debug 6 lines
    echo "ls -l $TMP/${i}_streams_list"
    ls -l $TMP/${i}_streams_list
    head $TMP/${i}_streams_list
    tail $TMP/${i}_streams_list
    echo "(ls -l $TMP/${i}_streams_list)"
    #read NOOP
    # Now sort that \${i}_streams_list
    str_num_tail_1=$(tail -1 $TMP/${i}_streams_list|sed 's/\012//')
    echo -n $str_num_tail_1|wc -c
    str_num_max_len=$(echo -n $str_num_tail_1|wc -c)
    echo \$str_num_max_len: $str_num_max_len
    #read NOOP
    str_num_len=1
    echo \$str_num_len: $str_num_len
    search_str='[0-9]'
    echo "\$search_str: $search_str"
    echo "$search_str"
    #read NOOP
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
        #read NOOP
        #done
        let str_num_len+=1
        echo \$str_num_len: $str_num_len
        echo "echo \${search_str}[0-9]"
        #read NOOP
        search_str=$(echo ${search_str}[0-9])
        echo \$search_str: $search_str
        #read NOOP
    done
    #read NOOP
    > $TMP/${i}_fr_no_stream_list_sort
    for stream in $(cat $TMP/${i}_streams_list_sort); do
        # debug
        #echo \$stream: $stream; ls -l $TMP/${i}_fr_no_stream_list
        grep "\<$stream$" $TMP/${i}_fr_no_stream_list \
            >> $TMP/${i}_fr_no_stream_list_sort
        ##read NOOP
    done; 
    # debug 6 lines
    echo "ls -l $TMP/${i}_fr_no_stream_list_sort"
    ls -l $TMP/${i}_fr_no_stream_list_sort
    head $TMP/${i}_fr_no_stream_list_sort
    tail $TMP/${i}_fr_no_stream_list_sort
    echo "(ls -l $TMP/${i}_streams_list_sort)"
    #read NOOP
    if ( grep "^[0-9]" "${i}_str_fr_list" ); then
        mv -iv ${i}_str_fr_list ${i}_str_fr_list.$(date +%s)
    else
        ls -l ${i}_str_fr_list
        cat ${i}_str_fr_list
        echo "(cat ${i}_str_fr_list)"
        rm -v ${i}_str_fr_list
    fi
cat > ${i}_str_fr_list <<EOF
# These packets all belong to streams that have no more than 2 packets each
# When removed from their PCAP, easier the work.
EOF
    for stream in $(<$TMP/${i}_streams_list_sort); do
        echo \"$stream\"
        cat $TMP/${i}_fr_no_stream_list_sort | awk '{ print $2 }' | grep "^$stream\>"
        #read NOOP
        str_cnt=$(cat $TMP/${i}_fr_no_stream_list_sort | awk '{ print $2 }' | grep "^$stream\>"|wc -l)
        echo \$str_cnt: $str_cnt
        #read NOOP
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
    if [ -e "$TMP/" ]; then
        rm -rf $TMP/
    fi
done
if [ -e "$TMP/" ]; then
    ls -l $TMP
    read NOOP
    trap "rm -rf $TMP/" EXIT INT TERM
fi

echo; echo \$PCAPs: $PCAPs; echo
read NOOP
for i in $(ls -1 $PCAPs|sed 's/\.pcap//'); do
    ls -l $i.pcap
    read NOOP
    # The second part. editcap the PCAP to make another with only ${i}_str_fr_list
    # packets, and the (desperately needed) one without. Then, if the mergecap'ing
    # them returns the original correctly, the work has tested correct.
    ls -l ${i}_str_fr_list
    read NOOP
    # This expected way, the command would often be too long, the editcap would
    # complain: "Out of room for packet selections."
    #> ${i}_CMD_rm
    #> ${i}_CMD_ok
    grep -v '^#' ${i}_str_fr_list > ${i}_str_fr_list_r
    #echo -n "editcap -r $i.pcap ${i}_rm.pcap " >> ${i}_CMD_rm
    #echo -n "editcap -r $i.pcap ${i}_ok.pcap " >> ${i}_CMD_ok
    #cat ${i}_str_fr_list_r | tr '\012' ' ' >> ${i}_CMD_rm
    #cat ${i}_str_fr_list_r | tr '\012' ' ' >> ${i}_CMD_ok
    #read NOOP
    index=-1
    # We need to keep two versions:
    cat ${i}_str_fr_list_r > str_fr_list_r_tmp_lines
    cat ${i}_str_fr_list_r | tr '\012' ' ' > str_fr_list_r_tmp
    cp -av  ${i}.pcap ${i}_tmp.pcap
    read NOOP
    while [ -s "str_fr_list_r_tmp" ]; do
        echo "ls -l str_fr_list_r_tmp"
        ls -l str_fr_list_r_tmp
        echo "head -c50 str_fr_list_r_tmp"
        head -c50 str_fr_list_r_tmp; echo
        echo "tail -c50 str_fr_list_r_tmp"
        tail -c50 str_fr_list_r_tmp; echo
        echo "(ls -l str_fr_list_r_tmp)"
        read NOOP
        tail -200 str_fr_list_r_tmp_lines > ${i}_str_fr_list_r${index}_lines
        tail -200 str_fr_list_r_tmp_lines | tr '\012' ' ' > ${i}_str_fr_list_r${index}

        echo -n "editcap -r ${i}_tmp.pcap ${i}_rm${index}.pcap " > ${i}_CMD_rm${index}
        echo "cat ${i}_CMD_rm${index}"
        cat ${i}_CMD_rm${index}
        read NOOP
        cat ${i}_str_fr_list_r${index} >> ${i}_CMD_rm${index}
        chmod 755 ${i}_CMD_rm${index}
        echo "ls -l ${i}_CMD_rm${index}"
        ls -l ${i}_CMD_rm${index}
        echo "head -c50 ${i}_CMD_rm${index}"
        head -c50 ${i}_CMD_rm${index}; echo
        echo "tail -c50 ${i}_CMD_rm${index}"
        tail -c50 ${i}_CMD_rm${index}; echo
        read NOOP
        read NOOP
        ./${i}_CMD_rm${index}
        ls -l ${i}_tmp.pcap ${i}_rm${index}.pcap
        read NOOP

        echo -n "editcap ${i}_tmp.pcap ${i}_ok${index}.pcap " > ${i}_CMD_ok${index}
        echo "cat ${i}_CMD_ok${index}"
        cat ${i}_CMD_ok${index}
        read NOOP
        cat ${i}_str_fr_list_r${index} >> ${i}_CMD_ok${index}
        chmod 755 ${i}_CMD_ok${index}
        ./${i}_CMD_ok${index}
        ls -l ${i}_tmp.pcap ${i}_ok${index}.pcap
        read NOOP
        mv -v ${i}_ok${index}.pcap ${i}_tmp.pcap
        index=$(echo $index-1|bc)
        echo \$index: $index
        read NOOP
        head -n-200 str_fr_list_r_tmp_lines > str_fr_list_r_tmp_r_lines
        ls -l  str_fr_list_r_tmp_lines str_fr_list_r_tmp_r_lines
        cat str_fr_list_r_tmp_r_lines | tr '\012' ' ' > str_fr_list_r_tmp_r
        read NOOP
        mv -v str_fr_list_r_tmp_r_lines str_fr_list_r_tmp_lines
        mv -v str_fr_list_r_tmp_r str_fr_list_r_tmp
        read NOOP
    done
done

# vim: set tabstop=4 expandtab:
