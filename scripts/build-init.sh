#!/bin/bash
#
# build-init.sh
#
# Source Functions for cross-lfs build
# -----------------------------------------
# Authors:  Ryan Oliver  (ryan.oliver@pha.com.au)
#
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
#

# Check for stuff
#----------------

# Check for a grep which takes -E
for path in "" /bin/ /usr/bin/ /usr/xpg4/bin/ /usr/local/bin/ ; do
   echo X | ${path}grep -E X > /dev/null 2>&1 &&
   {
      export GREP="${path}grep"
      break
   }
done

GREP=egrep
if [ "${GREP}" = "" ]; then
   echo "install a grep on the system that handles -E"
   exit 1
fi

# Set your umask
umask 0022

#set shell to allow glob style matches
# ( bash specific )
shopt -s extglob

set +h

. ${SCRIPTS}/funcs/log-funcs.sh
. ${SCRIPTS}/funcs/tarball-funcs.sh
. ${SCRIPTS}/funcs/patching-funcs.sh
. ${SCRIPTS}/funcs/kernel_stub_header-funcs.sh
. ${SCRIPTS}/funcs/binutils-funcs.sh
. ${SCRIPTS}/funcs/multiarch-funcs.sh
. ${SCRIPTS}/funcs/stub_header-funcs.sh
. ${SCRIPTS}/funcs/glibc-funcs.sh
