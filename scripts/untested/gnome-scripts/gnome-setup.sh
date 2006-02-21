GNOME_REL_MAJ=`echo ${GNOME_REL} | sed 's@\([0-9]*\.[0-9]*\).*@\1@g'`

export GNOME_PREFIX=/opt/gnome-${GNOME_REL_MAJ}

if [ ! -d /opt/gnome-${GNOME_REL} ]; then 
   echo " - creating /opt/gnome-${GNOME_REL}"
   mkdir -p /opt/gnome-${GNOME_REL}
fi
echo " - creating gnome-${GNOME_REL_MAJ} -> gnome-${GNOME_REL} symlink"
ln -sfn gnome-${GNOME_REL} /opt/gnome-${GNOME_REL_MAJ}


export PATH=${PATH}:${GNOME_PREFIX}/bin
export PKG_CONFIG_PATH=${PKG_CONFIG_PATH}:${GNOME_PREFIX}/lib/pkgconfig
export GNOME_LIBCONFIG_PATH=/usr/lib:${GNOME_PREFIX}/lib

grep ${GNOME_PREFIX}/${libdir} /etc/ld.so.conf > /dev/null 2>&1 ||
   echo "${GNOME_PREFIX}/${libdir}" >> /etc/ld.so.conf

grep ${GNOME_PREFIX}/man /etc/man.conf > /dev/null 2>&1 ||
echo "${GNOME_PREFIX}/man" >> /etc/man.conf

export XDG_DATA_DIRS=/usr/share:${GNOME_PREFIX}/share
