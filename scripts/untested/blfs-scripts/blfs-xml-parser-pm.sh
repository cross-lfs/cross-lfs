#!/bin/bash

### XML-Parser perl module ###

cd ${SRC}
LOG=xml-parser-pm-blfs.log

SELF=`basename ${0}`
set_buildenv

# No need to set libdirname etc, will use perl defaults which should
# correctly set CC and libdir 

unpack_tarball XML-Parser-${XML_PARSER_PM_VER}
cd ${PKGDIR}

max_log_init XML-Parser ${XML_PARSER_PM_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
perl Makefile.PL \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" || barf

min_log_init ${BUILDLOGS} &&
make \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

min_log_init ${TESTLOGS} &&
make test \
   >> ${LOGFILE} 2>&1 &&
echo " o Test OK" || barf

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

