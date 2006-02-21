#!/bin/bash

# cross-lfs native copy kernel headers
# ------------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

if [ ! -d /usr/include ]; then mkdir /usr/include; fi

if [ ! -d /usr/include/asm ]; then
   echo " o Copying kernel headers from"
   echo "   ${TGT_TOOLS}/include to /usr/include"
   cp -Rp ${TGT_TOOLS}/include/asm* /usr/include
   cp -Rp ${TGT_TOOLS}/include/linux /usr/include
fi

