#!/bin/bash

# build-target.sh 
#
# Script for cross building target native tools
# 
# Authors: Ryan Oliver <ryan.oliver@pha.com.au
#          Finn Thain
#
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$

set +h

# Set SELF to be name of script called, minus any path...
SELF=$(basename ${0})
echo "Running ${SELF}"
VERSION="2.4.4"
DATE=$(date +'%Y%m%d')
export DATE

# Read in build configuration information
# plfs-config should reside in the same directory as this script.
# We need to use dirname to determine where to find it as SCRIPTS
# env var is not set yet (set in plfs-config itself)
. `dirname ${0}`/plfs-config

# Sanity check, are ${LFS}, ${HST_TOOLS} and ${TGT_TOOLS} set?
if [ "X${LFS}" = "X" -o "X${HST_TOOLS}" = "X" -o "X${TGT_TOOLS}" = "X" ]; then
   echo "Error: Not all required environment vars have been set." 1>&2
   echo "       Check plfs-config" 1>&2
   exit 1
fi

# Get package version information
. ${SCRIPTS}/plfs-packages

# Source Functions and definitions
. ${SCRIPTS}/build-init.sh


set +x
unset LD_LIBRARY_PATH
unset LD_PRELOAD

# Configure uses these if set, and will not look for a cross-compiler
unset CC CXX

export LDFLAGS="-s"

# Setup PATH
#export PATH=/bin:/sbin:/usr/bin:/usr/sbin
export PATH=${HST_TOOLS}/bin:${HST_TOOLS}/sbin:${PATH}

# If ${SRC} does not exist, create it
test -d ${SRC} || mkdir -p ${SRC}

if [ ! "${USE_SYSROOT}" = "Y" ]; then                                                      
   # If ${LFS}${TGT_TOOLS} directory doesn't exist, create it
   test -d ${LFS}${TGT_TOOLS} || mkdir -p ${LFS}${TGT_TOOLS}

   # create it ${TGT_TOOLS} symlink
   if [ ! -d `dirname ${TGT_TOOLS}` ]; then mkdir -p `dirname ${TGT_TOOLS}` ; fi
   ln -sf ${LFS}${TGT_TOOLS} `dirname ${TGT_TOOLS}`
fi

mkdir -p ${CONFLOGS}
mkdir -p ${BUILDLOGS}
mkdir -p ${INSTLOGS}
mkdir -p ${TESTLOGS}
cd ${SRC}

#scripts_dir="cross-scripts-${VERSION}"
scripts_dir="target-scripts"

# scripts for building target tools
test "Y" = "${MULTIARCH}" &&
{
script_list="target-binutils.sh
target-gcc.sh
target-zlib-32.sh
target-zlib-n32.sh
target-zlib-64.sh
target-gawk.sh
target-coreutils.sh
target-bzip2-32.sh
target-bzip2-n32.sh
target-bzip2-64.sh
target-gzip.sh
target-diffutils.sh
target-findutils.sh
target-m4.sh
target-bison.sh
target-flex.sh
target-make.sh
target-grep.sh
target-sed.sh
target-gettext-32.sh
target-gettext-n32.sh
target-gettext-64.sh
target-ncurses-32.sh
target-ncurses-n32.sh
target-ncurses-64.sh
target-patch.sh
target-tar.sh
target-bash.sh"
} || {
script_list="target-binutils.sh
target-gcc.sh
target-zlib.sh
target-gawk.sh
target-coreutils.sh
target-bzip2.sh
target-gzip.sh
target-diffutils.sh
target-findutils.sh
target-m4.sh
target-bison.sh
target-flex.sh
target-make.sh
target-grep.sh
target-sed.sh
target-gettext.sh
target-ncurses.sh
target-patch.sh
target-tar.sh
target-bash.sh"
}

# Packages common to both BIARCH and non-BIARCH
script_list="${script_list}
target-e2fsprogs.sh
target-procps.sh
target-sysvinit.sh
target-module-init-tools.sh
target-nettools.sh
target-inetutils.sh
target-util-linux.sh
target-strace.sh
target-sysklogd.sh"

if [ "${USE_HOTPLUG}" = "Y" ]; then
script_list="${script_list}
target-hotplug.sh"
fi

script_list="${script_list}
target-dev.sh
target-lfs-bootscripts.sh
target-kernel.sh
target-iana-etc.sh"

#target-modutils.sh
# Lilo bootloader
if [ "${USE_LILO}" = "Y" ]; then
script_list="${script_list}
host-nasm.sh
host-bin86.sh
host-lilo.sh
target-nasm.sh
target-bin86.sh
target-lilo.sh"
fi

# TODO: add nfs client, tcpwrappers portmap etc scripts
#       ( to allow us to nfs mount root on target box )
script_list="${script_list}
target-nfsutils.sh
target-tcp-wrappers.sh
target-portmap.sh"

script_list="${script_list}
target-iproute2.sh
target-final-prep-wrapper.sh"


SCRIPTLIST=`echo "${script_list}" | \
  sed "s@\(.*\)@${scripts_dir}/\1@"`

# Check if we are resuming from a particular script
test ! -z "${1}" &&
{
   SCRIPTLIST=`echo ${SCRIPTLIST} | sed "s@.*\(${1}.*\)@\1@g"`
}
                                                                                
echo ' o Checking for needed sources and tarballs'
check_tarballs ${SCRIPTLIST}
                                                                                
for script in ${SCRIPTLIST}; do
   echo "Running ${SCRIPTS}/${script}"
   # HACK: export SELF to be the script we are running
   #       (keeps logfile output correct)
   export SELF=${script}
   ${SCRIPTS}/${script}

   test 0 = ${?} ||
   {
      echo
      echo "Failed script was ${script}"
      echo "Please fix the error above from"
      echo "   ${SCRIPTS}/${script}"
      echo "and rerun the build with the command"
      echo
      echo "   ${0} $script"
      echo
      echo "to resume the build."
      exit 1
   }
done
