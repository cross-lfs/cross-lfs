#!/bin/bash

# build-blfs.sh 
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
. `dirname ${0}`/plfs-config

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


set +x
unset LD_LIBRARY_PATH
unset LD_PRELOAD

# Configure uses these if set, and will not look for a cross-compiler
unset CC CXX

export LDFLAGS="-s"

# Setup PATH
export PATH=/bin:/sbin:/usr/bin:/usr/sbin

# If ${SRC} does not exist, create it
test -d ${SRC} || mkdir -p ${SRC}

mkdir -p ${CONFLOGS}
mkdir -p ${BUILDLOGS}
mkdir -p ${INSTLOGS}
mkdir -p ${TESTLOGS}
cd ${SRC}

#scripts_dir="cross-scripts-${VERSION}"
scripts_dir="blfs-scripts"

# scripts for building target tools

##############
# NFS support
##############
test "Y" = "${MULTIARCH}" &&
{
script_list="blfs-tcp-wrappers-32.sh
blfs-tcp-wrappers-64.sh"
} || {
script_list="blfs-tcp-wrappers.sh"
}

script_list="${script_list}
blfs-portmap.sh
blfs-nfs-utils.sh"

###################
#
###################
# TCL here so we can test kerberos.
# BDB also dependant
test "Y" = "${MULTIARCH}" &&
{
script_list="${script_list}
blfs-tcl-32.sh
blfs-tcl-64.sh"
} || {
script_list="${script_list}
blfs-tcl.sh"
}

test "Y" = "${MULTIARCH}" &&
{
script_list="${script_list}
blfs-cracklib-32.sh
blfs-cracklib-64.sh
blfs-linux-pam-32.sh
blfs-linux-pam-64.sh
blfs-mit-krb5-32.sh
blfs-mit-krb5-64.sh
blfs-bdb-32.sh
blfs-bdb-64.sh"
} || {
script_list="${script_list}
blfs-cracklib.sh
blfs-linux-pam.sh
blfs-mit-krb5.sh
blfs-bdb.sh"
}
#script_list="blfs-shadow-pam.sh"

####################
# OPENSSL + OPENSSH
####################
# Depends on krb5 libs (MIT)
test "Y" = "${MULTIARCH}" &&
{
script_list="${script_list}
blfs-openssl-32.sh
blfs-openssl-64.sh
blfs-openssh.sh"
} || {
script_list="${script_list}
blfs-openssl.sh
blfs-openssh.sh"
}

# reqs openssl, krb5, bdb, tcpwrappers (ldap)
test "Y" = "${MULTIARCH}" &&
{
script_list="${script_list}
blfs-cyrus-sasl-32.sh
blfs-cyrus-sasl-64.sh
blfs-openldap-32.sh
blfs-openldap-64.sh
blfs-nssldap-32.sh
blfs-nssldap-64.sh
blfs-ntp.sh"
} || {
script_list="${script_list}
blfs-cyrus-sasl.sh
blfs-openldap.sh
blfs-nssldap.sh
blfs-ntp.sh"
}

# TODO: have to do something with catering for 2 freetype-configs
#       for biarch, specifying the right freetype-config for
#       fontconfig, and fix the biarch libtool issues w fontconfig
test "Y" = "${MULTIARCH}" &&
{
script_list="${script_list}
blfs-libpng-32.sh
blfs-libpng-64.sh
blfs-freetype2-32.sh
blfs-freetype2-64.sh
blfs-expat-32.sh
blfs-expat-64.sh"
} || {
script_list="${script_list}
blfs-libpng.sh
blfs-freetype2.sh
blfs-expat.sh"
}

test "Y" = "${MULTIARCH}" &&
{
script_list="${script_list}
blfs-fontconfig-32.sh
blfs-fontconfig-64.sh
blfs-xorg-32.sh
blfs-xorg-64.sh"
} || {
script_list="${script_list}
blfs-fontconfig.sh
blfs-xorg.sh"
}

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
