#!/bin/sh

# cross-lfs temporary vim build
# -----------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

cd ${SRC}
LOG=vim-temp.log

unpack_tarball vim-${VIM_VER}
cd ${PKGDIR}

case ${VIM_VER} in
   6.[23] )
      # Set location for vimrc and gvimrc files
      # ( for < 6.1 we use CPPFLAGS to set this )
      echo "#define SYS_VIMRC_FILE \"${TGT_TOOLS}/etc/vimrc\"" >> src/feature.h
      echo "#define SYS_GVIMRC_FILE \"${TGT_TOOLS}/etc/gvimrc\"" >> src/feature.h
      # here for consistency only
      makeopts=""
   ;;
   6.1 ) 
      # Remove checks for -I/usr/local/include when setting CPPFLAGS
      apply_patch vim-${VIM_VER}
      # Set location for vimrc file
      makeopts="CPPFLAGS='-DSYS_VIMRC_FILE=\\\"${TGT_TOOLS}/etc/vimrc\\\"'"
   ;;
esac


max_log_init vim ${VIM_VER} "temp (shared)" ${CONFLOGS} ${LOG}
CFLAGS="-O2 -pipe ${TGT_CFLAGS}" \
./configure --prefix=/usr \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" &&

min_log_init ${BUILDLOGS} &&
#make CPPFLAGS='-DSYS_VIMRC_FILE=\"/etc/vimrc\"' \
make ${PMFLAGS} ${makeopts} \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make install  \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

ln -sf vim /usr/bin/vi

# Do we want to set up vim config here?
# Seems both good and bad to do it here.

