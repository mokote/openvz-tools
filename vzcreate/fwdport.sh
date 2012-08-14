#!/bin/bash
vzconfig=vzcreate.conf

ARGS=3
if [[ $# -ne "$ARGS"  ]]
then
    echo "usage: `basename $0` <ipaddress> <port from(external)> <port to(internal)>"
    echo "for example: `basename $0` 10.10.10.5 2221 22"
    exit 1

fi

if [ -r $vzconfig ]; then
    . $vzconfig
else
    echo "failed to read config $vzconfig"
    exit 2
fi

if [ -z "$myip" ];then echo "myip is empty!";exit 2;fi
if [ -z "$GINIF" ];then echo "GINIF is empty!";exit 2;fi
#enabling forwarding for nginx
iptables -t nat -A PREROUTING -p tcp -d "${myip}" --dport $2 -i "${GINIF}" -j DNAT --to-destination $1:$3
