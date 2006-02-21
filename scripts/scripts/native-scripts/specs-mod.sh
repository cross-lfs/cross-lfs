#!/bin/bash

# cross-lfs gcc specs file modification
# -------------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

# Modify gcc specs file

cd ${SRC}
                                                                                
# Change dynamic linker definition in gcc specs file
# to point at our new dynamic linker in /lib.
# Also repoint startfile_prefix_spec.
#

# Do we have a specs file?
SPECFILE=`${TGT_TOOLS}/bin/gcc --print-file-name specs`

# We dont have a specs file... generate one.
if [ "${SPECFILE}" = "specs" ]; then
   # A bit of a hack, as include is a directrory, but hey...
   SPECFILE=`${TGT_TOOLS}/bin/gcc --print-file-name include | \
             sed 's@include@specs@g'`
   ${TGT_TOOLS}/bin/gcc -dumpspecs > ${SPECFILE}
fi
                                                                                
grep ${TGT_TOOLS}/lib ${SPECFILE} > /dev/null 2>&1 &&
{
   cp ${SPECFILE} ./XX
   sed -e "s@${TGT_TOOLS}\(\(/lib\(\|32\|64\)\)\(/ld\(\|64\)\.so\.1\|/ld-linux\(\|-ia64\|-x86-64\)\.so\.\(1\|2\)\)\)@\1@g" \
       -e "/\*startfile_prefix_spec:/{
           h
           n
           s@${TGT_TOOLS}@/usr@g
           x
           x }" ./XX > ${SPECFILE}
   rm -f ./XX
}

