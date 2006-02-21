#!/bin/bash

### docbook-dsssl ###

cd ${SRC}
LOG=docbook-dsssl-blfs.log

unpack_tarball docbook-dsssl-${DBK_DSSSL_VER}
cd ${PKGDIR}

mkdir -p /usr/share/sgml/docbook/dsssl-stylesheets-${DBK_DSSSL_VER}/dtds/decls &&
mkdir -p /usr/share/sgml/docbook/dsssl-stylesheets-${DBK_DSSSL_VER}/lib &&
mkdir -p /usr/share/sgml/docbook/dsssl-stylesheets-${DBK_DSSSL_VER}/common &&
mkdir -p /usr/share/sgml/docbook/dsssl-stylesheets-${DBK_DSSSL_VER}/html &&
mkdir -p /usr/share/sgml/docbook/dsssl-stylesheets-${DBK_DSSSL_VER}/print &&
mkdir -p /usr/share/sgml/docbook/dsssl-stylesheets-${DBK_DSSSL_VER}/test &&
mkdir -p /usr/share/sgml/docbook/dsssl-stylesheets-${DBK_DSSSL_VER}/images &&
install bin/collateindex.pl /usr/bin &&
cp catalog VERSION /usr/share/sgml/docbook/dsssl-stylesheets-${DBK_DSSSL_VER} &&
cp dtds/decls/*.dcl \
   /usr/share/sgml/docbook/dsssl-stylesheets-${DBK_DSSSL_VER}/dtds/decls &&
cp lib/dblib.dsl \
   /usr/share/sgml/docbook/dsssl-stylesheets-${DBK_DSSSL_VER}/lib &&
cp common/*.dsl \
   /usr/share/sgml/docbook/dsssl-stylesheets-${DBK_DSSSL_VER}/common &&
cp common/*.ent \
   /usr/share/sgml/docbook/dsssl-stylesheets-${DBK_DSSSL_VER}/common &&
cp html/*.dsl \
   /usr/share/sgml/docbook/dsssl-stylesheets-${DBK_DSSSL_VER}/html &&
cp print/*.dsl \
   /usr/share/sgml/docbook/dsssl-stylesheets-${DBK_DSSSL_VER}/print &&
cp images/*.gif \
   /usr/share/sgml/docbook/dsssl-stylesheets-${DBK_DSSSL_VER}/images &&

install-catalog --add /etc/sgml/dsssl-docbook-stylesheets.cat \
    /usr/share/sgml/docbook/dsssl-stylesheets-${DBK_DSSSL_VER}/catalog &&
install-catalog --add /etc/sgml/sgml-docbook.cat \
    /etc/sgml/dsssl-docbook-stylesheets.cat

