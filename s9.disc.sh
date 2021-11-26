#!/bin/bash

# Just put "s9*.sh" files to the Zabbix ExternalScripts directory (/etc/zabbix/externalscripts by default).
# Required utilites: nc, timeout
# only bash, no perl, no python and no etc

# If you like my work, please consider donating:
# BTC: 39DyYL4NxvBv1BTR7RK9UJJisqhTCQhFFa
# Dmitry Dvinskikh <dima@tevirp.ru>

COMMAND=$1
HOST=$2
ITEM=$3
PORT=$4

TIMEOUT=3
PARALLEL_EXEC=1000

if [ "$PORT" = "" ]; then PORT=4028; fi
if [ "$COMMAND" != "stats" ] && [ "$COMMAND" != "summary" ] && [ "$COMMAND" != "version" ] && [ "$COMMAND" != "pools" ]; then 
    echo "command not found!"; exit 1; fi 

PR=`ps ax| grep $0 | grep -v 'grep'|wc -l`
if [ "${PR}" -gt "${PARALLEL_EXEC}" ]; then exit; fi

CMD='timeout $TIMEOUT echo -n "$COMMAND" | nc $HOST $PORT | sed s/\|/\\n/g | sed s/,/\\n/g || exit 1'

if [[ $ITEM == "discovery"* ]]; then
	if [ "$ITEM" = "discoveryACN" ] && [ "$COMMAND" = "stats" ]; then
	    ITEMS=`eval $CMD | grep --text "chain_acn"| sed s/chain_acn//g | grep --text -v "=0$" |cut -d"=" -f1`
	    M=ACN
	fi
	if [ "$ITEM" = "discoveryFAN" ] && [ "$COMMAND" = "stats" ]; then
    	    ITEMS=`eval $CMD | grep --text "fan"| grep --text -v "num" | sed s/fan//g | grep --text -v "=0$" |cut -d"=" -f1`
	    M=FAN
	fi
	if [ "$ITEM" = "discoveryTEMP" ] && [ "$COMMAND" = "stats" ]; then
	    ITEMS=`eval $CMD | grep --text "temp"| grep --text -v "_" | sed s/temp//g | grep --text -v "=0$" |cut -d"=" -f1`
	    M=TEMP
	fi
	if [ "$ITEM" = "discovery" ] && [ "$COMMAND" = "pools" ]; then
	    ITEMS=`eval $CMD | grep --text "POOL" | cut -d"=" -f2`
	    M=POOL
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
		JSON=${JSON}"{ \"{#${M}}\":\"${ITEM}\"}"
	    done
	    JSON=${JSON}"]}"
	    echo ${JSON}	
	fi
	exit
fi

