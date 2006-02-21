#!/bin/bash

### docbook-sgml ###

# TODO: need to install 4.4 (supporting 4.3) 4.2 (supporting 4.1 and 4.0)
#       and 3.1 (supporting 3.0)

cd ${SRC}
LOG=docbook-sgml-${DBK_SGML_VER}-blfs.log

PKGDIR="docbook-${DBK_SGML_VER}"
if [ -d ${PKGDIR} ]; then rm -rf ${PKGDIR}; fi
mkdir ${PKGDIR}
cd ${PKGDIR}

case ${DBK_SGML_VER} in
   3.1 )
      unzip ${TARBALLS}/docbk31.zip || barf
      sed -i -e '/ISO 8879/d' \
             -e "s|DTDDECL \"-//OASIS//DTD DocBook V${DBK_SGML_VER}//EN\"|SGMLDECL|g" \
         docbook.cat
   ;;
   4.* )
      unzip ${TARBALLS}/docbook-${DBK_SGML_VER}.zip || barf
      sed -i -e '/ISO 8879/d' \
          -e '/gml/d' docbook.cat
   ;;
esac

install -d /usr/share/sgml/docbook/sgml-dtd-${DBK_SGML_VER} &&
chown -R root:root . &&
install docbook.cat \
   /usr/share/sgml/docbook/sgml-dtd-${DBK_SGML_VER}/catalog &&
cp -af *.dtd *.mod *.dcl /usr/share/sgml/docbook/sgml-dtd-${DBK_SGML_VER} &&

install-catalog --add /etc/sgml/sgml-docbook-dtd-${DBK_SGML_VER}.cat \
    /usr/share/sgml/docbook/sgml-dtd-${DBK_SGML_VER}/catalog &&
install-catalog --add /etc/sgml/sgml-docbook-dtd-${DBK_SGML_VER}.cat \
    /etc/sgml/sgml-docbook.cat

VERS="4.4 4.3 4.2 4.1 4.0"
VERS=`echo ${VERS} | sed "s@${DBK_SGML_VER}.*@@g"`

catalog=/usr/share/sgml/docbook/sgml-dtd-${DBK_SGML_VER}/catalog

case ${DBK_SGML_VER} in
   3.1 )
      #
      cat >> ${catalog} << "EOF"
  -- Begin Single Major Version catalog changes --

PUBLIC "-//Davenport//DTD DocBook V3.0//EN" "docbook.dtd"

  -- End Single Major Version catalog changes --
EOF
   ;;
   4.* )

      echo "  -- Begin Single Major Version catalog changes --" >> ${catalog}
      echo "" >> ${catalog}
      for ver in ${VERS} ; do
         echo "PUBLIC \"-//OASIS//DTD DocBook V${ver}//EN\" \"docbook.dtd\"" \
            >> ${catalog}
      done
      echo "" >> ${catalog}
      echo "  -- End Single Major Version catalog changes --" >> ${catalog}
   ;;
esac
