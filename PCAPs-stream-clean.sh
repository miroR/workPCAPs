#!/bin/bash
#
# PCAPs-stream-clean.sh -- segregate out all streams with less than $LIMIT packets,
#                            and keep only streams holding $LIMIT+1 or more packets.
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

. shark2use

if [ $# -eq 0 ]; then
    echo "give (a list of) PCAP(s)"
    echo "(if globbing, you need to quote it, e.g.:"
    echo "${0##*/} \"*.pcap\")"
    exit 0
fi
PCAPs=$1
echo \$PCAPs: $PCAPs|grep -v "_rm-\|rm.pcap\|_tmp.pcap"
read NOP
PCAPs_tr=$(ls -1 $1|grep -v "_rm-\|rm.pcap\|_tmp.pcap" | tr '\012' ' ')
echo \$PCAPs_tr: $PCAPs_tr
read NOP
echo "ls -1 \$PCAPs|sed 's/\.pcap//'|grep -v \"_rm-\|rm.pcap\|_tmp.pcap\""
echo "ls -1 $PCAPs|sed 's/\.pcap//'|grep -v \"_rm-\|rm.pcap\|_tmp.pcap\""
read NOP
ls -1 $PCAPs|grep -v "_rm-\|rm.pcap\|_tmp.pcap"|sed 's/\.pcap//'
read NOP

hash=$(cksum $0|cut -d' ' -f1)
ts="$(date +%s)"
tsha="${ts}_${hash}"
echo \$tsha: $tsha
pcaps_no_sym=.pcaps-no-sym_${tsha}
echo \$pcaps_no_sym: $pcaps_no_sym
read NOP
> $pcaps_no_sym
ls -l $pcaps_no_sym
read NOP
for i in $(ls -1 $PCAPs|sed 's/\.pcap//'); do
    if [ -L "$i.pcap" ]; then
        echo "Not echoing the symlink:"
        ls -l $i.pcap
        echo "in the sanitized list."
    else
        echo $i.pcap >> $pcaps_no_sym
    fi
done
cat $pcaps_no_sym
echo "(cat $pcaps_no_sym)"
ls -l $pcaps_no_sym
read FAKE
PCAPs=$(<$pcaps_no_sym)
rm -v $pcaps_no_sym

echo "Listing only:"
for i in $(ls -1 $PCAPs|grep -v "_rm-\|rm.pcap\|_tmp.pcap"|sed 's/\.pcap//'); do
    ls -l $i.pcap
done
echo "(Listing only)"
read NOP
    
echo "=-=-=-=-=-=-=-=-=-=-=-= the first part: -=-=-=-=-=-=-==-=-=-=-="
echo "==   creating the list of no-content tcp.streams, per PCAP  ==="
echo "=-=-=-=-=-=-=-=-=-=-=-= (the first part) =-=-=-=-=-=-==-=-=-=-="
read NOP
for i in $(ls -1 $PCAPs|grep -v "_rm-\|rm.pcap\|_tmp.pcap"|sed 's/\.pcap//'); do
    echo "Assessing/deciding whether to work on:"
    ls -l $i.pcap
    . cont_br_short
    if [ -e "${i}_rm.pcap" ]; then
        echo "We skip this PCAP."
        echo "rm ${i}_rm.pcap if you want to redo ${i}.pcap:"
		ls -l ${i}*.pcap
		read NOP
        continue
    fi
    if [ -n "$2" ]; then
        LIMIT=$2
    else
        echo "type in the \$LIMIT (integer) for dividing the PCAP in two,"
        echo "first with streams of \$str_cnt (number of frames it contains)"
        echo "greater than the \$LIMIT, and the second less than"
        echo "Hit Enter to accept the default \"2\""
        echo "Type y/Y to type in a different integer."
        ask
        if [ "$?" == 0 ]; then
            echo "Type the integer now:"
            read LIMIT
        else
            LIMIT=2
        fi
    fi
    echo \$LIMIT: $LIMIT
    if [ ! -e ".${i}_stream-clean.lock" ]; then
        touch .${i}_stream-clean.lock
        ls -l .${i}_stream-clean.lock
    else
        ls -l .${i}_stream-clean.lock
        echo "We 'continue'."
        continue
    fi
    echo "Working on:"
    ls -l $i.pcap
    read NOP
    if [ -e "${i}_str_fr_list" ]; then
        ls -l ${i}_str_fr_list
        grep -v '^#' ${i}_str_fr_list > ${i}_str_fr_list_r
        if ( grep -q "^[0-9]" "${i}_str_fr_list_r" ); then
            echo "The $i.pcap seems to have been already processed:"
            ls -l $i.pcap
            echo "[ sleep 1 ]"
            sleep 1
            continue
        else
            # Case here is PCAP has none no-content tcp.stream, i.e.
            if [ ! -s "${i}_str_fr_list_r" ]; then
                ls -l $i.pcap
                echo "likely has none no-content streams." 
                read NOP
                continue
            else
                echo "NOTE: It is the user's responsability to keep their archives in order."
                echo "The ${i}_str_fr_list may not be correct."
                echo "Maybe remove it and rerun/fix $0.)"
            fi
        fi
    fi
    TMP="$(mktemp -d "/tmp/$i.$$.XXXXXXXX")"
    ls -ld $TMP
    ls -l $TMP
    read NOP

    ls -l $i.pcap
    $TSHARK -r $i.pcap -T fields -e frame.number -e tcp.stream \
        > $TMP/${i}_fr_no_stream_list
    # debug 6 lines
    echo "ls -l $TMP/${i}_fr_no_stream_list"
    ls -l $TMP/${i}_fr_no_stream_list
    head $TMP/${i}_fr_no_stream_list
    tail $TMP/${i}_fr_no_stream_list
    echo "(ls -l $TMP/${i}_fr_no_stream_list)"
    read NOP
    $TSHARK -r $i.pcap -T fields -e frame.number -e tcp.stream \
        | awk '{ print $2 }' | grep '[[:print:]]' > $TMP/${i}_streams_list
    # debug 6 lines
    echo "ls -l $TMP/${i}_streams_list"
    ls -l $TMP/${i}_streams_list
    head $TMP/${i}_streams_list
    tail $TMP/${i}_streams_list
    echo "(ls -l $TMP/${i}_streams_list)"
    echo "Next: \"Now sort that \${i}_streams_list\""
    read NOP
    # Needed to really get the largest in tail:
    unset greatest
    for stream in $(<$TMP/${i}_streams_list); do
        if [ -n "$greatest" ]; then
            if [ "$stream" -gt "$greatest" ]; then
                greatest=$stream
            fi
        else
            greatest=$stream
        fi
    done
    echo \$greatest: $greatest
    read NOP
    # Now sort that \${i}_streams_list
    #str_num_tail_1=$(tail -1 $TMP/${i}_streams_list_TMP_SORT|sed 's/\012//')
    echo -n $greatest|wc -c
    str_num_max_len=$(echo -n $greatest|wc -c)
    echo \$str_num_max_len: $str_num_max_len
    read NOP
    str_num_len=1
    echo \$str_num_len: $str_num_len
    search_str='[0-9]'
    echo "\$search_str: $search_str"
    echo "$search_str"
    read NOP
    > $TMP/${i}_streams_list_sort
    while [ "$str_num_len" -le "$str_num_max_len" ]; do
        #for str in $(<$TMP/${i}_streams_list); do
        grep "^$search_str\>" $TMP/${i}_streams_list | sort -u \
            >> $TMP/${i}_streams_list_sort
        # debug 5 lines
        ls -l $TMP/${i}_streams_list_sort
        head -n3 $TMP/${i}_streams_list_sort
        tail -n3 $TMP/${i}_streams_list_sort
        echo "(ls -l $TMP/${i}_streams_list_sort)"
        let str_num_len+=1
        echo \$str_num_len: $str_num_len
        echo "echo \${search_str}[0-9]"
        read NOP
        search_str=$(echo ${search_str}[0-9])
        echo \$search_str: $search_str
        read NOP
    done
    read NOP
    > $TMP/${i}_fr_no_stream_list_sort
    for stream in $(<$TMP/${i}_streams_list_sort); do
        # debug
        #echo \$stream: $stream; ls -l $TMP/${i}_fr_no_stream_list
        grep "\<$stream$" $TMP/${i}_fr_no_stream_list \
            >> $TMP/${i}_fr_no_stream_list_sort
        read NOP
    done; 
    # debug 6 lines
    echo "ls -l $TMP/${i}_fr_no_stream_list_sort"
    ls -l $TMP/${i}_fr_no_stream_list_sort
    head $TMP/${i}_fr_no_stream_list_sort
    tail $TMP/${i}_fr_no_stream_list_sort
    echo "(ls -l $TMP/${i}_streams_list_sort)"
    read NOP
    if ( grep "^[0-9]" "${i}_str_fr_list" ); then
        mv -iv ${i}_str_fr_list ${i}_str_fr_list.$(date +%s)
    else
        ls -l ${i}_str_fr_list
        cat ${i}_str_fr_list
        echo "(cat ${i}_str_fr_list)"
        rm -v ${i}_str_fr_list
    fi
cat > ${i}_str_fr_list <<EOF
# These packets all belong to streams that have no more than $LIMIT packets each
# When removed from their PCAP, easier the work.
EOF
		echo "temp NOTE --DELETE THIS AFTERWARDS-- modify $TMP/${i}_fr_no_stream_list_sort NOW"
        read NOP
    for stream in $(<$TMP/${i}_streams_list_sort); do
        echo \"$stream\"
        cat $TMP/${i}_fr_no_stream_list_sort | awk '{ print $2 }' | grep "^$stream\>"
        read NOP
        str_cnt=$(cat $TMP/${i}_fr_no_stream_list_sort | awk '{ print $2 }' | grep "^$stream\>"|wc -l)
        echo \$stream: $stream \$str_cnt: $str_cnt
        #read NOP
        if [ "$str_cnt" -le "$LIMIT" ]; then
            str_fr=$(cat $TMP/${i}_fr_no_stream_list_sort | grep "[[:space:]]$stream\>" | awk '{ print $1 }')
            echo \$str_fr: $str_fr
            echo $str_fr >> ${i}_str_fr_list
        fi
    done
    echo "Done (in first part):"
    ls -l $i.pcap
    read NOP

    #trap "rm -rf $TMP/" EXIT INT TERM
    #export TMP
    #if [ -e "$TMP/" ]; then
    #    rm -rf $TMP/
    #fi
done
# this if cond from /usr/bin/startx
if [ x"$TMP" = x ]; then
    echo "\$TMP is empty"
else
    ls -l $TMP
    trap "rm -rf $TMP/" EXIT INT TERM
fi
read NOP

# produces no output, why? I thought at least the initial "echo \$PCAPs show've been seen"
echo; echo \$PCAPs: $PCAPs|grep -v "_rm-\|rm.pcap\|_tmp.pcap"; echo
read NOP
# we still have $1?
echo \$1: $1
read NOP
PCAPs=$1
echo \$PCAPs: $PCAPs|grep -v "_rm-\|rm.pcap\|_tmp.pcap"
read NOP
PCAPs_tr=$(ls -1 $1|grep -v "_rm-\|rm.pcap\|_tmp.pcap" | tr '\012' ' ')
echo \$PCAPs_tr: $PCAPs_tr
read NOP
echo "ls -1 \$PCAPs|sed 's/\.pcap//'|grep -v \"_rm-\|rm.pcap\|_tmp.pcap\""
echo "ls -1 $PCAPs|sed 's/\.pcap//'|grep -v \"_rm-\|rm.pcap\|_tmp.pcap\""
read NOP
ls -1 $PCAPs|grep -v "_rm-\|rm.pcap\|_tmp.pcap"|sed 's/\.pcap//'
read NOP
echo "=-=-=-=-=-=-=-=-=-=-=-=-=- the second part: -=-=-=-=-=-=-=-=-=-=-=-=-="
echo "==  creating \${i}_ok\${index}.pcap without no-content tcp.streams  =="
echo "==      and \${i}_rm\${index}.pcap with no-content tcp.streams      =="
echo "=-=-=-=-=-=-=-=-=-=-=-=-=- (the second part) =-=-=-=-=-=-=-=-=-=-=-=-="
read NOP
for i in $(ls -1 $PCAPs|grep -v "_rm-\|rm.pcap\|_tmp.pcap"|sed 's/\.pcap//'); do
    ls -l $i.pcap
    if [ ! -e ".${i}_stream-clean-2nd.lock" ]; then
        touch .${i}_stream-clean-2nd.lock
        ls -l .${i}_stream-clean-2nd.lock
    else
        ls -l .${i}_stream-clean-2nd.lock
        echo "We 'continue'."
        continue
    fi
    # Miserably pasting over this if cond.
    read NOP
    if [ -e "${i}_str_fr_list" ]; then
        ls -l ${i}_str_fr_list
        grep -v '^#' ${i}_str_fr_list > ${i}_str_fr_list_r
        if ! ( grep -q "^[0-9]" "${i}_str_fr_list_r" ); then
            # Case here is PCAP has none no-content tcp.stream, i.e.
            if [ ! -s "${i}_str_fr_list_r" ]; then
                ls -l $i.pcap
                echo "likely has none no-content streams." 
                read NOP
                continue
            fi
        fi
    fi
    if [ -e "${i}_rm.pcap" ]; then
        ask "anew?" ;
        if [ "$?" == 0 ]; then
            echo "Fine, we'll be processing ${i}.pcap (all over)"
            echo "and merging ${i}_rm.pcap (again)."
            echo "(but you may be asked one more time,"
            echo "and there might be some overwriting to confirm)"
        else
            echo "User declined to process $i.pcap and merge ${i}_rm.pcap (again)." 
            continue
        fi
        read NOP
    fi
    if [ -e "$i.pcap.O" ]; then
        ask "anew?" ;
        if [ "$?" == 0 ]; then
            echo "Fine, we'll be doing $i.pcap (all over) next."
            mv -iv $i.pcap.O $i.pcap
        else
            echo "User declined to re-work $i.pcap"
            continue
        fi
        read NOP
    fi
    # The second part. editcap the PCAP to make another with only ${i}_str_fr_list
    # packets, and the (desperately needed) one without. Then, if the mergecap'ing
    # them returns the original correctly, the work has tested correct.
    ls -l ${i}_str_fr_list
    read NOP
    # This expected way, the command would often be too long, the editcap would
    # complain: "Out of room for packet selections."
    #> ${i}_CMD_rm
    #> ${i}_CMD_ok
    grep -v '^#' ${i}_str_fr_list > ${i}_str_fr_list_r
    #echo -n "editcap -r $i.pcap ${i}_rm.pcap " >> ${i}_CMD_rm
    #echo -n "editcap -r $i.pcap ${i}_ok.pcap " >> ${i}_CMD_ok
    #cat ${i}_str_fr_list_r | tr '\012' ' ' >> ${i}_CMD_rm
    #cat ${i}_str_fr_list_r | tr '\012' ' ' >> ${i}_CMD_ok
    read NOP
    index=-1
    # We need to keep two versions:
    cat ${i}_str_fr_list_r > ${i}_str_fr_list_r_tmp_lines
    cat ${i}_str_fr_list_r | tr '\012' ' ' > ${i}_str_fr_list_r_tmp
    cp -av  ${i}.pcap ${i}_tmp.pcap
    read NOP
    while [ -s "${i}_str_fr_list_r_tmp" ]; do
        echo "ls -l ${i}_str_fr_list_r_tmp"
        ls -l ${i}_str_fr_list_r_tmp
        echo "head -c100 ${i}_str_fr_list_r_tmp"
        head -c100 ${i}_str_fr_list_r_tmp; echo
        echo "tail -c50 ${i}_str_fr_list_r_tmp"
        tail -c50 ${i}_str_fr_list_r_tmp; echo
        echo "(ls -l ${i}_str_fr_list_r_tmp)"
        read NOP
        tail -200 ${i}_str_fr_list_r_tmp_lines > ${i}_str_fr_list_r${index}_lines
        tail -200 ${i}_str_fr_list_r_tmp_lines | tr '\012' ' ' > ${i}_str_fr_list_r${index}

        echo -n "$EDITCAP -r ${i}_tmp.pcap ${i}_rm${index}.pcap " > ${i}_CMD_rm${index}
        echo "cat ${i}_CMD_rm${index}"
        cat ${i}_CMD_rm${index}
        read NOP
        cat ${i}_str_fr_list_r${index} >> ${i}_CMD_rm${index}
        chmod 755 ${i}_CMD_rm${index}
        echo "ls -l ${i}_CMD_rm${index}"
        ls -l ${i}_CMD_rm${index}
        echo "head -c100 ${i}_CMD_rm${index}"
        head -c100 ${i}_CMD_rm${index}; echo
        echo "tail -c50 ${i}_CMD_rm${index}"
        tail -c50 ${i}_CMD_rm${index}; echo
        read NOP
        ./${i}_CMD_rm${index}
        ls -l ${i}_tmp.pcap ${i}_rm${index}.pcap
        read NOP

        echo -n "$EDITCAP ${i}_tmp.pcap ${i}_ok${index}.pcap " > ${i}_CMD_ok${index}
        echo "cat ${i}_CMD_ok${index}"
        cat ${i}_CMD_ok${index}
        read NOP
        cat ${i}_str_fr_list_r${index} >> ${i}_CMD_ok${index}
        chmod 755 ${i}_CMD_ok${index}
        ./${i}_CMD_ok${index}
        ls -l ${i}_tmp.pcap ${i}_ok${index}.pcap
        read NOP
        mv -v ${i}_ok${index}.pcap ${i}_tmp.pcap
        index=$(echo $index-1|bc)
        echo \$index: $index
        read NOP
        head -n-200 ${i}_str_fr_list_r_tmp_lines > ${i}_str_fr_list_r_tmp_r_lines
        ls -l  ${i}_str_fr_list_r_tmp_lines ${i}_str_fr_list_r_tmp_r_lines
        cat ${i}_str_fr_list_r_tmp_r_lines | tr '\012' ' ' > ${i}_str_fr_list_r_tmp_r
        read NOP
        mv -v ${i}_str_fr_list_r_tmp_r_lines ${i}_str_fr_list_r_tmp_lines
        mv -v ${i}_str_fr_list_r_tmp_r ${i}_str_fr_list_r_tmp
        read NOP
    done
    mv -iv  ${i}.pcap ${i}.pcap.O
    mv -iv  ${i}_tmp.pcap ${i}.pcap
    ls -1tr ${i}_rm-*.pcap
    echo -n "$MERGECAP " > ${i}_merge_rm_CMD.sh
    echo -n "-w ${i}_rm.pcap " >> ${i}_merge_rm_CMD.sh
    ls -1tr ${i}_rm-*.pcap | sed 's/\.pcap//' | sed 's/\(.*\)/\1.pcap \\/' >> \
        ${i}_merge_rm_CMD.sh
        echo ";" >> ${i}_merge_rm_CMD.sh
    chmod 755 ${i}_merge_rm_CMD.sh
    read NOP
    ./${i}_merge_rm_CMD.sh
    echo -n "$MERGECAP " > ${i}_merge_CMD.sh
    echo -n "-w ${i}.pcap.RE ${i}_rm.pcap ${i}.pcap " >> ${i}_merge_CMD.sh
    chmod 755 ${i}_merge_CMD.sh
    read NOP
    ./${i}_merge_CMD.sh
    echo "=-=-=-=-=-=-=-=-=-=-=-=-=- verifying and cleaning: -=-=-=-=-=-=-=-=-=-=-=-=-="
    read NOP
    $CAPINFOS $i.pcap.RE \
        | grep 'Number of packets = \|Capture duration:\|First packet time:\|Last packet time:'\
        > $i.pcap.RE_test
    $CAPINFOS $i.pcap.O \
        | grep 'Number of packets = \|Capture duration:\|First packet time:\|Last packet time:'\
        > $i.pcap.O_test
    echo "capinfos $i.pcap.O_test\|grep ..."
    cat $i.pcap.O_test
    read NOP
    echo "capinfos $i.pcap.RE_test\|grep ..."
    cat $i.pcap.RE_test
    read NOP
    if ( diff $i.pcap.O_test $i.pcap.RE_test ); then
        echo "There have been no loss of packets in this $i.pcap carving: "
        echo "capinfos $i.pcap.O (the original): "
        echo "capinfos $i.pcap.RE (the re-merged from"
        echo "   without no-content tcp.streams, the new renamed"
        ls -l $i.pcap
        echo "  and the"
        ls -l ${i}_rm.pcap
        echo "  all-no-content tcp.streams)"
        echo "Removing all the temps:"
        rm -v ${i}_str_fr_list_*
        rm -v ${i}_rm-*.pcap
        rm -v ${i}_merge_rm_CMD.sh ${i}_merge_CMD.sh ${i}_CMD*
        rm -v $i.pcap.O_test $i.pcap.RE_test
        rm -v $i.pcap.RE
    else
        echo "There has been loss of packets (or other error) in this $i.pcap carving: "
        echo "The $i.pcap.O (the original): "
        echo "and the $i.pcap.RE (the re-merged for verification"
        echo "do not correspond."
        echo "Pls. study the temps now."
        read NOP
        ask "Remove all the temps now?"
        if [ "$?" == 0 ]; then
            rm -v ${i}_str_fr_list_*
            rm -v ${i}_rm-*.pcap
            rm -v ${i}_merge_rm_CMD.sh ${i}_merge_CMD.sh ${i}_CMD*
            rm -v $i.pcap.O_test $i.pcap.RE_test
            rm -v $i.pcap.RE
            rm -v .${i}_stream-clean.lock
            rm -v .${i}_stream-clean-2nd.lock
        fi
    fi
done

# vim: set tabstop=4 expandtab:
