#!/bin/bash

# build-blfs-extra.sh 
#
# Script to build blfs packages
# 
# Authors: Ryan Oliver <ryan.oliver@pha.com.au
#
# $LastChangedBy: ryan $
# $LastChangedDate: 2004-09-28 17:23:32 +1000 (Tue, 28 Sep 2004) $
# $LastChangedRevision: 238 $

# Set SELF to be name of script called, minus any path...
SELF=$(basename ${0})
echo "Running ${SELF}"
VERSION="3.0.1"
DATE=$(date +'%Y%m%d')
export DATE

# Read in build configuration information
# plfs-config should reside in the same directory as this script.
# We need to use dirname to determine where to find it as SCRIPTS
# env var is not set yet (set in plfs-config itself)

# HACK: while in untested dir, plfs-config resides one dir below
. `dirname ${0}`/../plfs-config

# Sanity check, are ${LFS}, ${HST_TOOLS} and ${TGT_TOOLS} set?
if [ "X${LFS}" = "X" -o "X${HST_TOOLS}" = "X" -o "X${TGT_TOOLS}" = "X" ]; then
   echo "Error: Not all required environment vars have been set." 1>&2
   echo "       Check plfs-config" 1>&2
   exit 1
fi

export LFS=""

# Get package version information
. ${SCRIPTS}/plfs-packages
. ${SCRIPTS}/blfs-packages

# Source Functions and definitions
. ${SCRIPTS}/build-init.sh

# extra for under untested dir
. ${SCRIPTS}/untested/blfs-scripts/blfs-packages

. ${SCRIPTS}/untested/gnome-scripts/gnome-platform-packages
. ${SCRIPTS}/untested/gnome-scripts/gnome-desktop-packages
#env
. ${SCRIPTS}/untested/kde-scripts/kde-packages

. ${SCRIPTS}/untested/blfs-scripts/qt-setup.sh
. ${SCRIPTS}/untested/gnome-scripts/gnome-setup.sh
. ${SCRIPTS}/untested/kde-scripts/kde-setup.sh
. ${SCRIPTS}/untested/blfs-scripts/java-setup.sh

export TARBALLS=/proj/blfs-pkgs
export GNOME_TARBALLS=/mnt/tarballs/gnome
export KDE_TARBALLS=/mnt/tarballs/kde
export PATCHES=${SCRIPTS}/untested/blfs-patches

unset LD_LIBRARY_PATH
unset LD_PRELOAD

# Configure uses these if set, and will not look for a cross-compiler
unset CC CXX

# Setup PATH
#export PATH=/bin:/sbin:/usr/bin:/usr/sbin

# If ${SRC} does not exist, create it
test -d ${SRC} || mkdir -p ${SRC}

mkdir -p ${CONFLOGS}
mkdir -p ${BUILDLOGS}
mkdir -p ${INSTLOGS}
mkdir -p ${TESTLOGS}
cd ${SRC}

#scripts_dir="cross-scripts-${VERSION}"
scripts_dir="untested"

. ${SCRIPTS}/untested/blfs-scriptlist

#echo ${script_list}

SCRIPTLIST=`echo "${script_list}" | \
  sed "s@\(.*\)@${scripts_dir}/\1@"`

# Check if we are resuming from a particular script
test ! -z "${1}" &&
{
   SCRIPTLIST=`echo ${SCRIPTLIST} | sed "s@.*\(${1}.*\)@untested/\1@g"`
}
                                                                                
echo ' o Checking for needed sources and tarballs'
#check_tarballs ${SCRIPTLIST}

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
