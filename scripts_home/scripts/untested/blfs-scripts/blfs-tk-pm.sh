#!/bin/bash

### Tk perl module ###

cd ${SRC}
LOG=tk-pm-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname

unpack_tarball Tk-${TK_PM_VER}
cd ${PKGDIR}

if [ ! "${libdirname}" = "lib" ]; then
   # Set X11LIB to */lib64 to override search in myConfig
   extra_conf="X11LIB=/usr/X11R6/${libdirname}"

   # Recursively edit every occurance of /usr/X11R6/lib
   echo " o Edit files to use /usr/X11R6/${libdirname}"
   files=`grep -l -d recurse /usr/X11R6/lib * `
   for file in ${files}; do
      echo " - editing ${file}"
      sed -i "s@X11R6/lib@X11R6/${libdirname}@g" ${file}
   done
fi

max_log_init Tk-pm ${TK_PM_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
perl Makefile.PL ${extra_conf} \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" || barf

min_log_init ${BUILDLOGS} &&
make \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

# Cannot run tests unless X is running...
# TODO: Add a check to see if we have X running...
#       Disabling test for the moment

#min_log_init ${TESTLOGS} &&
#make test \
#   >> ${LOGFILE} 2>&1 &&
#echo " o Test OK" || barf

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

