#!/bin/bash
#  Copyright  (C) 2012, Roman Ovchinnikov, coolthecold@gmail.com
#

#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

#  This script should build kernel in debian way from openvz patches for rhel and vanilla kernel.
#  use -h option to show help

#buildir base
BUILDDIR="/usr/src"

#building tools, like make-kpkg
NEEDPACKAGES="build-essential kernel-package fakeroot"

#kernel.org url for vanilla kernel
KERNEL_BASE_URL="http://www.kernel.org/pub/linux/kernel/v2.6"
OPENVZ_BASE_URL="http://download.openvz.org/kernel/branches"

declare -A opts
declare -A KERNELINFO
KERNELINFO["base"]="2.6.32"
KERNELINFO["ovzname"]="042stab057.1"
KERNELINFO["rhelid"]="6"
KERNELINFO["rhelbranch"]="rhel6-2.6.32"
KERNELINFO["arch"]="x86_64"
#http://download.openvz.org/kernel/branches/rhel6-2.6.32/042stab049.6/configs/config-2.6.32-042stab049.6.x86_64
#http://download.openvz.org/kernel/branches/rhel6-2.6.32/042stab049.6/patches/patch-042stab049.6-combined.gz
#http://www.kernel.org/pub/linux/kernel/v2.6/linux-2.6.32.tar.bz2

PROGNAME=$(basename $0)

print_usage() {

    local hpart
    hpart=$(host_to_localpart)

    echo "Usage: $PROGNAME [-h] [-B <base>] [-O <ovzname>] [-R <rhelid>] [-b <rhelbranch>] [-A <arch>] [-L <localname>] [-D <builddir>]"
    echo ""
    echo "-h - show this help"
    echo "-B <base> - specifies base (vanilla) kernel version to use, currently this is 2.6.32."
    echo "-O <ovzname> - specifies version for kernel patch which openvz guys have."
    echo "-R <rhelid> - specifies rhel version id, now latest rhel is 6, previous was 5."
    echo "-b <rhelbranch> - specifies rhel kernel branch, for now should be rhel6-2.6.32, for rhel 5 should be something like rhel5-2.6.18."
    echo "-A <arch> - specifies processor architecture to use. For now applyed only for config downloading, as building for i386 almost has no reasons."
    echo "-L <localname> - specifies string appended to package, this will allow to distinguish your custom kernel from mirads of others. Highly recommended to be specified by hand, if missed will be set to 2nd level domain or hostname. For this machine defaults to \"${hpart}\" ."
    echo "-D <builddir> - specifies directory where to do kernel builds, as it may require some space, like 10-15GB. Defaults to $BUILDDIR ."
    echo ""
    echo ""
    echo "As default options should be sane, you may need to change <localname> parameter."
}

print_help() {
    echo "$PROGNAME"
    echo ""
    print_usage
    echo ""
    echo "This script should build kernel in debian way from openvz patches for rhel and vanilla kernel"
}

str_to_localpart() {
    if [[ -z $1 ]];then return 1;fi

    local hdata hparts localpart

    hdata=(${1//./ }); #changing dots into spaces, then creating array from this
    hparts=${#hdata[@]}
    if [[ $hparts -gt 1 ]];then
        for i in $(($hparts - 2)) $(($hparts - 1));do
            if [[ -z $localpart ]];then
                localpart="${hdata[i]}"
            else
                localpart="${localpart}.${hdata[i]}"
            fi
        done
    else
        localpart=${hdata[0]}
    fi
    echo $localpart
}
host_to_localpart() {
    local hpart
    hpart=$(hostname --fqdn)
    hpart=$(str_to_localpart $hpart)
    echo "$hpart"
}
show_opts() {
    echo "The next options will be used for building kernel"
    for i in "base" "ovzname" "rhelid" "rhelbranch" "arch" "localname" "builddir";do
        echo "$i: ${opts[$i]}"
    done
}

#saving arguments count
argcount=$#

while getopts ":hB:O:R:b:A:L:D:" Option; do
  case $Option in
    h)
      print_help
      exit 0
      ;;
    B)
      opts["base"]="${OPTARG}"
      ;;
    O)
      opts["ovzname"]="${OPTARG}"
      ;;
    R)
      opts["rhelid"]="${OPTARG}"
      ;;
    b)
      opts["rhelbranch"]="${OPTARG}"
      ;;
    A)
      opts["arch"]="${OPTARG}"
      ;;
    L)
      opts["localname"]="${OPTARG}"
      ;;
    D)
      opts["builddir"]="${OPTARG}"
      ;;
    *)
      print_help
      exit 2
      ;;
  esac
done
shift $(($OPTIND - 1))

#let's show building options
for i in "base" "ovzname" "rhelid" "rhelbranch" "arch";do
    opts[$i]=${opts[$i]:-${KERNELINFO[$i]}}
done
opts["localname"]=${opts["localname"]:-$(host_to_localpart)}
opts["builddir"]=${opts["builddir"]:-${BUILDDIR}}

#echo -e "\n\n";
echo "----------------------"
show_opts

#runtime configuration
kernel_name="linux-${opts["base"]}"
patch_url="${OPENVZ_BASE_URL}/${opts["rhelbranch"]}/${opts["ovzname"]}/patches/patch-${opts["ovzname"]}-combined.gz"
patch_filename="patch-${opts["ovzname"]}-combined"
config_url="${OPENVZ_BASE_URL}/${opts["rhelbranch"]}/${opts["ovzname"]}/configs/config-${opts["base"]}-${opts["ovzname"]}.${opts["arch"]}"
config_filename="config-${opts["base"]}-${opts["ovzname"]}.${opts["arch"]}"

#requirements
echo "checking requirements..."

#checking packages
do_exit=0
for i in $NEEDPACKAGES;do
    dpkg -p "$i" 1>/dev/null 2>&1
    if [ $? -ne 0 ];then
        echo "missing package $i"
        do_exit=1
    fi
done
if [ $do_exit -ne 0 ];then
    echo "exiting";exit 1
else
    echo "done"
fi

#giving user time to think a bit
if [[ $argcount -lt 1 ]];then
    echo -e "\n\n"
    echo "No parameters were specified, build will start in 10 seconds with settings from above. Press Ctrl+C to stop bulding or Enter to start"
    echo "use \"$0 -h\" to obtain help"
    read -t 10 || true
fi

############ here we go #########
echo -e "\n"
echo "#### Building has begun ####"

echo "changing directory to ${opts["builddir"]} ..."
cd "${opts["builddir"]}"
if [ $? -ne 0 ];then #failed
    echo "can't change directory to ${opts["builddir"]}, exiting"
    exit 1
fi


#need to download compressed kernel image if it doesn't exist yet
if ! [ -f "$kernel_name.tar.bz2" ];then
    urltoget="${KERNEL_BASE_URL}/${kernel_name}.tar.bz2"
    wget "$urltoget" -O "${kernel_name}.tar.bz2"
    if [ $? -ne 0 ];then #failed
        echo "download kernel tarball from $urltoget failed, exiting"
        exit 1
    fi
else
    echo "kernel tarball $kernel_name.tar.bz2 already exists, skipping download"
fi

#clearing old build directory, just in case
if [ -d "./${kernel_name}" ];then
    echo "removing old dir ./${kernel_name}"
    rm -rf "./${kernel_name}"
    if [ $? -ne 0 ];then #failed
        echo "remove failed, exiting"
        exit 1
    fi
fi

#unpacking archive
tar -xf "${kernel_name}.tar.bz2"
if [ $? -ne 0 ];then #failed
    echo "unpacking failed, exiting"
    exit 1
fi

#downloading config
if ! [ -f "$config_filename" ];then
    wget "$config_url" -O "$config_filename"
    if [ $? -ne 0 ];then #failed
        echo "download config from $config_url failed, exiting"
        exit 1
    fi
else
    echo "config file $config_filename already exists, skipping download"
fi

#..patch now
if ! [ -f "$patch_filename" ];then
    wget "$patch_url" -O "$patch_filename.gz"
    if [ $? -ne 0 ];then #failed
        echo "download patch from $patch_url failed, exiting"
        exit 1
    fi
    gzip -d "$patch_filename"
    if [ $? -ne 0 ];then #failed
        echo "unzip of patch failed, exiting"
        exit 1
    fi
 
else
    echo "patch file $patch_filename already exists, skipping download"
fi

#everything is downloaded, patching now
cd ${kernel_name}
#dry run for patch
patch --dry-run --verbose -p1 < "../$patch_filename" > ../patch.log
if [ $? -ne 0 ];then
    echo "patch failed to apply clean. check ../patch.log. exiting"
    exit 1
fi

#checking if patch has failed hunks
fgrep -q 'FAILED at' "../patch.log"
if [ $? -eq 0 ]; then #grep found some failed strings or just patch failed, we should abort now
    echo "patch failed to apply clean. check ../patch.log. exiting"
    exit 1
else
    echo "patch should apply clean now, trying..."
    patch --verbose -p1 < "../$patch_filename" > ../patch.log
    if [ $? -ne 0 ]; then #patch failed somehow anyway
        echo "patch failed to apply clean. check ../patch.log. exiting"
        exit 1
    else
        echo "patch applyed without error"
    fi
fi

#kernel is patched now, copying config
cp ../"$config_filename" .config

#compiling
#how much cpu we have?
cpucount=$(grep -cw ^processor /proc/cpuinfo)
CMD="fakeroot make-kpkg --jobs $cpucount --initrd --arch_in_name --append-to-version -${opts["ovzname"]}-el${opts["rhelid"]}-openvz --revision ${opts["base"]}~${opts["localname"]} kernel_image kernel_source kernel_headers"
echo -e "\n"
echo "using next command to create package:"
echo "$CMD"
sh -c "$CMD"
build_result=$?
if [[ $build_result -ne 0 ]];then
    echo "build failed"
else
    echo "build succeeded, debian packages may be found in ${opts["builddir"]}"
fi
