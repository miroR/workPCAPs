#!/bin/bash
function ask()    # this function borrowed from "Advanced BASH Scripting Guide"
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
            repeat_last="y"
            while [ "$repeat_last" == "y" ]; do
                if ( grep -q $i.pcap TO_DO ); then
                    repeat_last="n"; continue
                fi
                echo ;echo "=-=-=-=-=-=";ls -lL $i.pcap
                if [ ! -e "${i}_tStreams/${i}_streams.ls-1" ] && \
                    ! ( grep -q $i.pcap TO_DO ); then
                    echo "Probably TO_DO?"
                    ask
                    if [ "$?" == 0 ]; then
                        echo $i.pcap >> TO_DO; echo
                        repeat_last="n"
                    fi
                fi
                tail -$tail_n ${i}_tStreams/${i}_streams.ls-1 | tr '\012' ' '; echo
                ls -lLtr ${i}_tStreams/ | tail -$tail_n
                if ( ls -1tr ${i}_tStreams/ | grep _streams_h2_EMPTY.ls-1 ); then
                    num_ssl_h2=$(ls -1tr ${i}_tStreams/  | tail -n7 \
                            | grep '\-ssl-h2-' | wc -l)
                    echo \$num_ssl_h2: $num_ssl_h2
                    if [ "$num_ssl_h2" -ge "3" ]; then
                            ls -1tr ${i}_tStreams/ | grep -v '\.raw' | tail -n1 \
                                | sed 's/.*_s\(.*\)-ssl-h2.*/\1/'
                            ord_h2=$(ls -1tr ${i}_tStreams/ | grep '\-ssl-h2-' \
                                | grep -v '\.raw' | tail -n1 \
                                | sed 's/.*_s\(.*\)-ssl-h2.*/\1/')
                            echo \$ord_h2: $ord_h2
                            echo "--==~==--"
                            tail -n2 ${i}_tStreams/${i}_s${ord_h2}_h2.ls-1 \
                                | tr '\012' ' '; echo
                            echo "(tail -n2 ${i}_tStreams/${i}_s${ord_h2}_h2.ls-1)"
                            echo "--==~==--"
                    fi
                fi
                ask "Repeat?"
                if [ "$?" == 0 ]; then 
                    echo will repeat
                    ask "Increase/decrease \$tail_n from current $tail_n?"
                    if [ "$?" == 0 ]; then 
                        echo "Type a digit (no error checking)"
                        read tail_n
                        echo "\$tail_n now: $tail_n"
                    fi
                else
                    repeat_last="n"
                fi
            done
            if ! ( grep -q $i.pcap TO_DO ); then
                echo "Probably DONE?"
                ask
                if [ "$?" == 0 ]; then
                    echo $i.pcap >> DONE; echo
                fi
            fi
        fi
    else
        echo -e -n "$RED $i.pcap $RESETCOLOR"
    fi
done
echo; echo -e "Legend: $RED dump_....pcap $RESETCOLOR NOT processed yet (if any)."
if [ -e "TO_DO" ]; then
    TO_DO_inline=$(cat TO_DO|tr '\012' ' ')
    echo -e "However, pls. note that:"
    echo -e "$RED $TO_DO_inline $RESETCOLOR"
    echo "likely remain to be split and worked:"
    ls -l $(<TO_DO)
fi
echo "=-=-=-=-=-="
# vim: set tabstop=4 expandtab:
