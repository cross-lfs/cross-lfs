#!/bin/bash

# cross-lfs target iana-etc installation
# --------------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=iana-etc.log
unpack_tarball iana-etc-${IANA_ETC_VER} &&

cd ${PKGDIR}

max_log_init iana-etc ${IANA_ETC_VER} '' ${BUILDLOGS} ${LOG}

make > ${LOGFILE} && echo " o Build OK" || barf

min_log_init ${INSTLOGS}

make PREFIX=${LFS} install > ${LOGFILE} && echo " o All OK" || barf
