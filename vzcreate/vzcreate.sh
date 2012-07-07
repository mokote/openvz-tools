#!/bin/bash
vzconfig=vzcreate.conf


ARGS=5
if [[ $# -lt "$ARGS"  ]]
then
    echo "usage: `basename $0` <veid> <hostname> <ipaddress> <name> <template>"
    echo "for example: `basename $0` 1500 testvz.local 192.168.0.140 testvz debian-5.0-i386-minimal"
    echo ""
    echo "templates can be found in /var/lib/vz/template/cache/ without .tar.gz"
    templates=$(ls -1 /var/lib/vz/template/cache/*.tar.gz|sed 's%\.tar\.gz%%')
    tempcode=$?
    if [ "$tempcode" -ne 0 -o -z "$templates" ]
    then
        echo "no templates found"
    else
        echo "found templates:"
        for i in ${templates};do
            echo $(basename $i)
        done
    fi
    exit 1
	    
fi
if [ -r $vzconfig ]; then 
    . $vzconfig
else
    echo "failed to read config $vzconfig"
    exit 2
fi
nsstring=""
for i in $nameservers;do
    #echo "nameserver is $i"
    nsstring="$nsstring --nameserver $i"
done
#echo "my ip is $myip"

if [ -z "$nsstring" ];then echo "nameservers list is empty!";exit 2;fi
if [ -z "$myip" ];then echo "myip is empty!";exit 2;fi


vzctl create $1 --ostemplate $5 --hostname $2 --ipadd $3
vzctl set $1 --name $4 $nsstring --searchdomain local --save
