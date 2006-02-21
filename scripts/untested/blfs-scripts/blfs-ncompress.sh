#!/bin/bash
#
# ncompress
#

cd ${SRC}
LOG=blfs-ncompress.log

set_libdirname
setup_multiarch

unpack_tarball ncompress-${NCOMPRESS_VER} &&
cd ${PKGDIR}

case ${NCOMPRESS_VER} in
   4.2.4 )
      apply_patch ncompress-4.2.4-gcc34
      apply_patch ncompress_4.2.4-15
   ;;
   * )
      echo "*** Please check if ncompress ${NCOMPRESS_VER} requires patching ***"
      echo "*** then please update this script (and send patch)      ***"
      exit 1
   ;;
esac

max_log_init ncompress ${NCOMPRESS_VER} "blfs (shared)" ${BUILDLOGS} ${LOG}

sed -e "s@options= @options= -O3 ${TGT_CFLAGS} @" \
    -e "s@CC=cc@CC=${CC-gcc} ${ARCH_CFLAGS}@" \
	Makefile.def > Makefile

make \
  >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

if [ -f /usr/bin/compress ]; then rm -f /usr/bin/compress ; fi
rm -f /usr/bin/uncompress
cp compress /usr/bin/compress
ln -sf compress /usr/bin/uncompress

