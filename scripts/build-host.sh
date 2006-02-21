#!/bin/bash

# build-host.sh
# (was build-native-2.4.4.sh)
#
# Master script for building native tools on the build host
# required for the creation of a cross-toolchain
# 
# Authors: Ryan Oliver <ryan.oliver@pha.com.au
#          Finn Thain
#
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
#

# Set SELF to be name of script called, minus any path...
SELF=`basename ${0}`
echo "Running ${SELF}"
VERSION="2.4.4"
DATE=`date +'%Y%m%d'`
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

# Setup PATH
export PATH=${HST_TOOLS}/bin:${HST_TOOLS}/sbin:${PATH}

set +x
unset LD_LIBRARY_PATH
unset LD_PRELOAD
                                                                                
export LDFLAGS="-s"

# If ${SRC} does not exist, create it
test -d ${SRC} || mkdir -p ${SRC}

# If ${LFS}${TOOLS} directory doesn't exist, create it
test -d ${LFS}${TGT_TOOLS} || mkdir -p ${LFS}${TGT_TOOLS}
                                                                                
# If ${TGT_TOOLS} symlink doesn't exist, create it
test -L ${TGT_TOOLS} || ln -sf ${LFS}${TGT_TOOLS} ${TGT_TOOLS}
echo ' o Checking for needed tarballs'
                                                                                
mkdir -p ${CONFLOGS}
mkdir -p ${BUILDLOGS}
mkdir -p ${INSTLOGS}
mkdir -p ${TESTLOGS}
cd ${SRC}

scripts_dir="host-scripts"

# Ideally we'd have flex before make, but flex doesn't like being
# built with sun's make...

script_list="host-m4.sh
host-bison.sh
host-make.sh
host-flex.sh
host-gawk.sh
host-grep.sh
host-sed.sh
host-coreutils-binaries.sh
host-autoconf.sh
host-automake.sh
host-libtool.sh
host-patch.sh
host-binutils.sh
host-gcc.sh
host-gettext.sh
host-ncurses.sh
host-texinfo.sh"

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
