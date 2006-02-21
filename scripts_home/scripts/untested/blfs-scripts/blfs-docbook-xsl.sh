#!/bin/bash

### docbook-xsl ###

cd ${SRC}
LOG=docbook-xsl-blfs.log

unpack_tarball docbook-xsl-${DBK_XSL_VER}
cd ${PKGDIR}

install -d /usr/share/xml/docbook/xsl-stylesheets-${DBK_XSL_VER} &&
chown -R root:root . &&

cp -af INSTALL VERSION common eclipse extensions fo html htmlhelp \
    images javahelp lib manpages params profiling template xhtml \
    /usr/share/xml/docbook/xsl-stylesheets-${DBK_XSL_VER} &&
install -d /usr/share/doc/xml &&
cp -af doc/* /usr/share/doc/xml &&

cd /usr/share/xml/docbook/xsl-stylesheets-${DBK_XSL_VER} &&
sh INSTALL &&

if [ ! -f /etc/xml/catalog ]; then mkdir -p /etc/xml; xmlcatalog \
    --noout --create /etc/xml/catalog; fi &&
if [ ! -e /etc/xml/docbook ]; then xmlcatalog --noout --create \
    /etc/xml/docbook; fi &&

xmlcatalog --noout --add "rewriteSystem" \
    "http://docbook.sourceforge.net/release/xsl/${DBK_XSL_VER}" \
    "/usr/share/xml/docbook/xsl-stylesheets-${DBK_XSL_VER}" /etc/xml/catalog &&
xmlcatalog --noout --add "rewriteURI" \
    "http://docbook.sourceforge.net/release/xsl/${DBK_XSL_VER}" \
    "/usr/share/xml/docbook/xsl-stylesheets-${DBK_XSL_VER}" /etc/xml/catalog &&
xmlcatalog --noout --add "delegateSystem" \
    "http://docbook.sourceforge.net/release/xsl/" \
    "file:///etc/xml/docbook" /etc/xml/catalog &&
xmlcatalog --noout --add "delegateURI" \
    "http://docbook.sourceforge.net/release/xsl/" \
    "file:///etc/xml/docbook" /etc/xml/catalog

# Setup shell env for xsl
if [ ! -d /etc/profile.d ]; then mkdir /etc/profile.d ; fi
cat > /etc/profile.d/xsl.sh << EOF
# Set up Environment Variable for XSL Processing
export XML_CATALOG_FILES="/usr/share/xml/docbook/\
xsl-stylesheets-${DBK_XSL_VER}/catalog.xml /etc/xml/catalog"
EOF

# Configure
# TODO: need to sanely add more versions in here
VERS="1.61.3 1.65.1 1.66.1 1.67.0 1.67.2"
VERS=`echo ${VERS} | sed "s@${DBK_XSL_VER}.*@@g"`
# When building gtk-doc, it searches for release/xsl/current...
# add this first...
VERS="current ${VERS}"

for ver in ${VERS} ; do
   xmlcatalog --noout --add "rewriteSystem" \
      "http://docbook.sourceforge.net/release/xsl/${ver}" \
      "/usr/share/xml/docbook/xsl-stylesheets-${DBK_XSL_VER}" \
      /etc/xml/catalog &&
   xmlcatalog --noout --add "rewriteURI" \
      "http://docbook.sourceforge.net/release/xsl/${ver}" \
      "/usr/share/xml/docbook/xsl-stylesheets-${DBK_XSL_VER}" \
      /etc/xml/catalog
done

