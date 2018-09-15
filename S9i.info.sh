#!/bin/bash

# Just put "S9i.info.sh" file to the Zabbix ExternalScripts directory (/etc/zabbix/externalscripts by default).
# Required utilites: nc, timeout, time.
# only bash, no perl, no python and no etc

# If you like my work, please consider donating:
# BTC: 39DyYL4NxvBv1BTR7RK9UJJisqhTCQhFFa
# Dmitry Dvinskikh <dima@tevirp.ru>

COMMAND=$1
HOST=$2
ITEM=$3
PORT=$4
if [ "$PORT" = "" ]; then PORT=4028; fi
if [ "$COMMAND" != "stats" ] && [ "$COMMAND" != "summary" ] && [ "$COMMAND" != "version" ] && [ "$COMMAND" != "pools" ]; then 
    echo "command not found!"; exit 0; fi 

PR=`ps ax| grep $0 | grep -v 'grep'|wc -l`
if [ "${PR}" -gt 1000 ]; then exit; fi

FILE=/tmp/S9i.${HOST}.${COMMAND}.result
TIMEOUT=30
TIMEUPDATE=3

if [ "$ITEM" = "When" ]; then
    timeout $TIMEOUT echo -n "$COMMAND" | nc $HOST $PORT | sed s/\|/\\n/g | sed s/,/\\n/g >${FILE}.temp || exit 0
    if [ "$COMMAND" = "pools" ]; then
	while read LINE; do
	    IFS="="
	    set -- $LINE
	    if [ "$1" = "POOL" ]; then ADD=$2; fi
	    echo "$1${ADD}=$2" >> ${FILE}.temp2
	done < ${FILE}.temp
	mv -f ${FILE}.temp2 ${FILE}.temp
    fi
    mv -f ${FILE}.temp ${FILE}
    chown zabbix:zabbix ${FILE}
fi

if [[ $ITEM == "discovery"* ]]; then
    if test -f "$FILE"; then
	if [ "$ITEM" = "discoveryACN" ] && [ "$COMMAND" = "stats" ]; then
	    ITEMS=`cat $FILE | grep --text "chain_acn"| sed s/chain_acn//g | grep --text -v "=0$" |cut -d"=" -f1`
	fi
	if [ "$ITEM" = "discoveryFAN" ] && [ "$COMMAND" = "stats" ]; then
    	    ITEMS=`cat $FILE | grep --text "fan"| grep --text -v "num" | sed s/fan//g | grep --text -v "=0$" |cut -d"=" -f1`
	fi
	if [ "$ITEM" = "discoveryTEMP" ] && [ "$COMMAND" = "stats" ]; then
	    ITEMS=`cat $FILE | grep --text "temp"| grep --text -v "_" | sed s/temp//g | grep --text -v "=0$" |cut -d"=" -f1`
	fi
	if [ "$ITEM" = "discovery" ] && [ "$COMMAND" = "pools" ]; then
	    ITEMS=`cat $FILE | grep --text "POOL" | sed s/POOL//g |cut -d"=" -f1`
	fi
	if [[ -n ${ITEMS} ]]; then
	    JSON="{ \"data\":["
	    flag=0
	    for ITEM in ${ITEMS}; do
	        printf "%g" "$ITEM" &> /dev/null || exit
	        if [ $flag != 0 ]; then
		    JSON=${JSON}","
		fi
		flag=$flag+1
		JSON=${JSON}"{ \"{#ACN}\":\"${ITEM}\"}"
	    done
	    JSON=${JSON}"]}"
	    echo ${JSON}	
	fi
	exit
    fi
fi

RES=`find $FILE -mmin -$TIMEUPDATE -exec sh -c "grep $ITEM '{}' | wc -l"  \; 2>/dev/null`;

if [ "$RES" = "" ]; then echo ""; else echo `cat $FILE | grep --text "^$ITEM="| cut -d"=" -f2`; fi

exit

