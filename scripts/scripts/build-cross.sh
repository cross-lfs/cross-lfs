#!/bin/bash

# build-cross-2.4.4.sh 
#
# Master script for cross building LFS chapter 5.
# 
# Authors: Ryan Oliver <ryan.oliver@pha.com.au
#          Finn Thain
#
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$

# Set SELF to be name of script called, minus any path...

# turn off bash command hash
set +h

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
                                                                                
export LDFLAGS="-s"

# Setup PATH
#export PATH=/bin:/sbin:/usr/bin:/usr/sbin
export PATH=${HST_TOOLS}/bin:${HST_TOOLS}/sbin:${PATH}

# If using distcc, expect that user has set up their own symlinks
#export DISTCC_HOSTS="localhost sirius"
#DISTCCDIR=/usr/distcc/bin
#export PATH=${DISTCCDIR}:${PATH}

# If ${SRC} does not exist, create it
test -d ${SRC} || mkdir -p ${SRC}

# If ${LFS} directory doesn't exist, create it
test -d ${LFS} || mkdir -p ${LFS}

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
scripts_dir="cross-scripts"

test "Y" = "${USE_SANITISED_HEADERS}" &&
{
   script_list="cross-kern-hdrs.sh
cross-san-kern-hdrs.sh"
} || {
   script_list="cross-kern-hdrs.sh"
}

script_list="${script_list}
cross-binutils.sh
cross-glibc-hdrs.sh
cross-gcc-static.sh"

if [ ! "Y" = "${NO_GCC_EH}" ]; then
   if [ "Y" = "${MULTIARCH}" ]; then
      script_list="${script_list}
cross-glibc-crtobjs-32.sh
cross-glibc-crtobjs-64.sh
cross-gcc-shared.sh"
   else
      script_list="${script_list}
cross-glibc-crtobjs.sh
cross-gcc-shared.sh"
   fi
fi


if [ "Y" = "${MULTIARCH}" ]; then
   if [ "N" = "${DEFAULT_64}" ]; then 
      script_list="${script_list}
cross-glibc-full-64.sh
cross-glibc-full-32.sh
cross-gcc-final.sh"
   else
      script_list="${script_list}
cross-glibc-full-32.sh
cross-glibc-full-64.sh
cross-gcc-final.sh"
   fi
else
   script_list="${script_list}
cross-glibc-full.sh
cross-gcc-final.sh"
fi

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
