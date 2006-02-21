#!/bin/bash

# build-native.sh 
#
# Script to finish build for target natively
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
export PATH=${PATH}:${TGT_TOOLS}/bin:${TGT_TOOLS}/sbin

# If ${SRC} does not exist, create it
test -d ${SRC} || mkdir -p ${SRC}

mkdir -p ${CONFLOGS}
mkdir -p ${BUILDLOGS}
mkdir -p ${INSTLOGS}
mkdir -p ${TESTLOGS}
cd ${SRC}

#scripts_dir="cross-scripts-${VERSION}"
scripts_dir="native-scripts"

# scripts for building target tools
test "Y" = "${MULTIARCH}" &&
{
script_list="temp-tcl-32.sh
temp-tcl-64.sh
temp-expect-32.sh
temp-expect-64.sh
temp-dejagnu.sh
temp-texinfo.sh
temp-perl-32.sh
temp-perl-64.sh
copy-kern-hdrs.sh
native-glibc-32.sh
native-glibc-64.sh"
} || {
script_list="temp-tcl.sh
temp-expect.sh
temp-dejagnu.sh
temp-texinfo.sh
temp-perl.sh
copy-kern-hdrs.sh
native-glibc.sh"
}

script_list="${script_list}
temp-binutils.sh
specs-mod.sh
native-binutils.sh
native-gcc.sh"

test Y = "${MULTIARCH}" && 
{
script_list="${script_list}
native-zlib-32.sh
native-zlib-64.sh"
} || {
script_list="${script_list}
native-zlib.sh"
}

script_list="${script_list}
native-mktemp.sh
native-findutils.sh
native-gawk.sh"

test Y = "${MULTIARCH}" && 
{
script_list="${script_list}
native-ncurses-32.sh
native-ncurses-64.sh"
} || {
script_list="${script_list}
native-ncurses.sh"
}

test Y = "${USE_READLINE}" && 
{
test Y = "${MULTIARCH}" && 
{
script_list="${script_list}
native-readline-32.sh
native-readline-64.sh"
} || {
script_list="${script_list}
native-readline.sh"
}
}

script_list="${script_list}
native-vim.sh
native-m4.sh
native-bison.sh
native-less.sh
native-groff.sh
native-coreutils.sh
native-sed.sh"

test Y = "${MULTIARCH}" && 
{
script_list="${script_list}
native-flex-32.sh
native-flex-64.sh
native-gettext-32.sh
native-gettext-64.sh
native-nettools.sh
native-inetutils.sh
native-iproute2.sh
native-perl-32.sh
native-perl-64.sh
native-texinfo.sh
native-autoconf.sh
native-automake.sh
native-bash.sh
native-file-32.sh
native-file-64.sh"
} || {
script_list="${script_list}
native-flex.sh
native-gettext.sh
native-nettools.sh
native-inetutils.sh
native-iproute2.sh
native-perl.sh
native-texinfo.sh
native-autoconf.sh
native-automake.sh
native-bash.sh
native-file.sh"
}

# ARGH libtool.. gonna have to do some 
# thinking about how to handle this for bi-arch...
test Y = "${MULTIARCH}" && 
{
script_list="${script_list}
native-libtool-32.sh
native-libtool-64.sh"
} || {
script_list="${script_list}
native-libtool.sh"
}

test Y = "${MULTIARCH}" && 
{
script_list="${script_list}
native-bzip2-32.sh
native-bzip2-64.sh"
} || {
script_list="${script_list}
native-bzip2.sh"
}

script_list="${script_list}
native-diffutils.sh
native-ed.sh
native-kbd.sh
native-e2fsprogs.sh
native-grep.sh
native-gzip.sh
native-man.sh
native-make.sh
native-module-init-tools.sh
native-patch.sh
native-procinfo.sh"

test Y = "${MULTIARCH}" && 
{
script_list="${script_list}
native-procps-32.sh
native-procps-64.sh
native-shadow-32.sh
native-shadow-64.sh"
} || {
script_list="${script_list}
native-procps.sh
native-shadow.sh"
}

script_list="${script_list}
native-sysklogd.sh
native-sysvinit.sh
native-tar.sh
native-util-linux.sh
native-dev.sh"

# Final setup of profile/bashrc scripts etc
script_list="${script_list}
post-lfs-configuration.sh"

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
