#!/bin/bash

# Just put "s9*.sh" files to the Zabbix ExternalScripts directory (/etc/zabbix/externalscripts by default).
# Required utilites: nc, timeout.
# only bash, no perl, no python and no etc
# apt install ncat
# or
# yum install nmap-ncat

# If you like my work, please consider donating:
# BTC: 39DyYL4NxvBv1BTR7RK9UJJisqhTCQhFFa
# Dmitry Dvinskikh <dima@tevirp.ru>

COMMAND=$1
HOST=$2
PORT=$3
PARALLEL_EXEC=1000
TIMEOUT=3

if [ "$PORT" = "" ]; then PORT=4028; fi
if [ "$COMMAND" != "stats" ] && [ "$COMMAND" != "summary" ] && [ "$COMMAND" != "version" ] && [ "$COMMAND" != "pools" ]; then 
    echo "command not found!"; exit 1; fi 

PR=`ps ax| grep $0 | grep -v 'grep'|wc -l`
if [ "${PR}" -gt "${PARALLEL_EXEC}" ]; then exit; fi

timeout $TIMEOUT echo  {\"command\":\"$COMMAND\"} | nc $HOST $PORT || exit 1

exit
