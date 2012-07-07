#!/bin/bash
vzconfig=vzcreate.conf

ARGS=1
if [[ $# -ne "$ARGS"  ]]
then
    echo "usage: `basename $0` <VE ipaddress in iptables format>"
    echo "for example: `basename $0` 10.10.10.5/32"
    exit 1

fi

if [ -r $vzconfig ]; then 
    . $vzconfig
else
    echo "failed to read config $vzconfig"
    exit 2
fi
#echo "my ip is $myip"

if [ -z "$myip" ];then echo "myip is empty!";exit 2;fi
if [ -z "$GINIF" ];then echo "GINIF is empty!";exit 2;fi
	    
iptables -t nat -A POSTROUTING -s $1 -o $GINIF -j SNAT --to $myip
