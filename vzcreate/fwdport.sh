#!/bin/bash
ARGS=3
if [[ $# -ne "$ARGS"  ]]
then
    echo "usage: `basename $0` <ipaddress> <port from(external)> <port to(internal)>"
    echo "for example: `basename $0` 10.10.10.5 2221 22"
    exit 1

fi
	    
#enabling forwarding for nginx
iptables -t nat -A PREROUTING -p tcp -d 87.118.90.42 --dport $2 -i eth0 -j DNAT --to-destination $1:$3
