#!/bin/bash

### docbook-sgml ###

cd ${SRC}
LOG=docbook-sgml-${DBK_SGML_VER}-blfs.log

PKGDIR="docbook-${DBK_SGML_VER}"
if [ -d ${PKGDIR} ]; then rm -rf ${PKGDIR}; fi
mkdir ${PKGDIR}
cd ${PKGDIR}

case ${DBK_SGML_VER} in
   3.1 )
      unzip ${TARBALLS}/docbk-31.zip || barf
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

case ${DBK_SGML_VER} in
   3.1 )
      #
      cat >> /usr/share/sgml/docbook/sgml-dtd-3.1/catalog << "EOF"
-- Begin Single Major Version catalog changes --

PUBLIC "-//Davenport//DTD DocBook V3.0//EN" "docbook.dtd"

  -- End Single Major Version catalog changes --
EOF
   ;;
   4.3 )
      cat >> /usr/share/sgml/docbook/sgml-dtd-4.3/catalog << "EOF"
-- Begin Single Major Version catalog changes --

PUBLIC "-//OASIS//DTD DocBook V4.2//EN" "docbook.dtd"
PUBLIC "-//OASIS//DTD DocBook V4.1//EN" "docbook.dtd"
PUBLIC "-//OASIS//DTD DocBook V4.0//EN" "docbook.dtd"

  -- End Single Major Version catalog changes --
EOF
   ;;
esac
