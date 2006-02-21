#!/bin/sh

### qt ###
cd ${SRC}
LOG=qt-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

# qt-setup.sh should have been sourced 
#QT_INSTALL_SELF_CONTAINED=Y
#USE_MYSQL=Y
#USE_PGSQL=Y
#USE_UNIXODBC=Y

if [ "Y" = "${QT_INSTALL_SELF_CONTAINED}" ]; then
   # for now, install to /opt
   qtprefix="/opt/qt-${QT_VER}"
   qtheaderdir="${qtprefix}/include"
   extra_conf="${extra_conf} -libdir ${qtprefix}/${libdirname}"
   # TODO: probably only want to do this if BIARCH, but hey
   #       plugins should probably go under libdir
   #       This stops the plugins from each arch getting clobbering
   extra_conf="${extra_conf} -plugindir ${qtprefix}/${libdirname}/plugins"
   headerdir=
else
   qtprefix="/usr"
   qtheaderdir="${qtprefix}/include/qt"
   extra_conf="${extra_conf} -docdir ${qtprefix}/share/doc/qt"
   extra_conf="${extra_conf} -headerdir ${qtprefix}/include/qt"
   extra_conf="${extra_conf} -libdir ${qtprefix}/${libdirname}"
   extra_conf="${extra_conf} -plugindir ${qtprefix}/${libdirname}/qt/plugins"
   extra_conf="${extra_conf} -datadir ${qtprefix}/share/qt"
   extra_conf="${extra_conf} -translationdir ${qtprefix}/share/qt/translations"
   extra_conf="${extra_conf} -sysconfdir /etc/qt"
fi

if [ "${USE_MYSQL}" = "Y" ]; then
   extra_conf="${extra_conf} -plugin-sql-mysql $( mysql_config --include )"
   echo extra_conf
fi


if [ "${USE_POSTGRES}" = "Y" ]; then
   extra_conf="${extra_conf} -plugin-sql-psql -I$( pg_config --includedir )"
fi

if [ "${USE_ODBC}" = "Y" ]; then
   extra_conf="${extra_conf} -plugin-sql-odbc -I/usr/include"
fi

unpack_tarball qt-x11-free-${QT_VER}
cd ${PKGDIR}

# Here we have to handle lib / lib64 , and also handle multilib compilers
if [ "Y" = "${MULTIARCH}" ]; then
   platform="linux-g++"
   if [ "${libdirname}" = "lib64" ]; then platform="linux-g++-64" ; fi
fi

sed -i "s@\(gcc\|g++\)@& ${ARCH_CFLAGS} ${TGT_CFLAGS}@g" \
   mkspecs/${platform}/qmake.conf

# Force removal of existing file when installing
echo "QMAKE_INSTALL_FILE      = cp --remove-destination" \
   >> mkspecs/${platform}/qmake.conf
sed -i -e 's@cp -f@cp --remove-destination@g' \
   qmake/Makefile.unix

extra_conf="${extra_conf} -platform ${platform}"

export QTDIR="${SRC}/${PKGDIR}"
export LD_LIBRARY_PATH="${QTDIR}/lib:${LD_LIBRARY_PATH}" 
export PATH=${QTDIR}/bin:${PATH}

max_log_init qt ${QT_VER} "blfs (shared)" ${CONFLOGS} ${LOG}
echo "yes" | ./configure \
   -prefix ${qtprefix} ${extra_conf} \
   -no-exceptions -thread -plugin-imgfmt-png \
   -system-libpng -system-libmng -system-zlib -system-libjpeg \
   -system-nas-sound -qt-gif -tablet \
   >> ${LOGFILE} 2>&1 &&
echo " o Configure OK" || barf

min_log_init ${BUILDLOGS} &&
make \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" || barf

if [ "Y" = "${MULTIARCH}" ]; then
   # Preserve any existing configurations for the other
   # qt platform during install
   case ${platform} in
      linux-g++ )
         if [ -d ${qtprefix}/mkspecs/linux-g++-64 ];then
            mv ${qtprefix}/mkspecs/linux-g++-64 \
               ${qtprefix}/mkspecs/linux-g++-64-ORIG
         fi
      ;;
      linux-g++-64 )
         if [ -d ${qtprefix}/mkspecs/linux-g++ ];then
            mv ${qtprefix}/mkspecs/linux-g++ \
               ${qtprefix}/mkspecs/linux-g++-ORIG
         fi
      ;;
   esac
fi

min_log_init ${INSTLOGS} &&
make install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

if [ "Y" = "${MULTIARCH}" ]; then
   case ${platform} in
      linux-g++ )
         if [ -d ${qtprefix}/mkspecs/linux-g++-64-ORIG ];then
            rm -rf ${qtprefix}/mkspecs/linux-g++-64
            mv ${qtprefix}/mkspecs/linux-g++-64-ORIG \
               ${qtprefix}/mkspecs/linux-g++-64
         fi
      ;;
      linux-g++-64 )
         if [ -d ${qtprefix}/mkspecs/linux-g++-ORIG ];then
            rm -rf ${qtprefix}/mkspecs/linux-g++
            mv ${qtprefix}/mkspecs/linux-g++-ORIG \
               ${qtprefix}/mkspecs/linux-g++
         fi
      ;;
   esac
fi

if [ "Y" = "${QT_INSTALL_SELF_CONTAINED}" ]; then
   ln -sfn qt-${QT_VER} /opt/qt
   cp -r doc/man ${qtprefix}/doc
   cp -r examples ${qtprefix}/doc
else
   cp -r doc/man ${qtprefix}/share
   cp -r examples ${qtprefix}/share/doc/qt
fi

ln -s libqt-mt.so ${qtprefix}/${libdirname}/libqt.so &&
rm ${qtprefix}/bin/qmake &&
install -m755 -oroot -groot qmake/qmake ${qtprefix}/bin

if [ "Y" = "${MULTIARCH}" ]; then
   use_wrapper ${qtprefix}/bin/{qmake,uic,moc,qtconfig}

   # There is one header file (qconfig.h) which will be different
   # between 32 and 64 bit ( stores things such as size of long long
   # for the given architecture ). Here we move it to a subdir and
   # create a stub header
   create_stub_hdrs ${qtheaderdir}/qconfig.h
fi
