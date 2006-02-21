#!/bin/bash

### docbook-xml ###

cd ${SRC}
LOG=docbook-xml-${DBK_XML_DTD_VER}-blfs.log

PKGDIR="docbook-xml-${DBK_XML_DTD_VER}"
if [ -d ${PKGDIR} ]; then rm -rf ${PKGDIR}; fi
mkdir ${PKGDIR}
cd ${PKGDIR}

unzip ${TARBALLS}/docbook-xml-${DBK_XML_DTD_VER}.zip || barf


install -d /usr/share/xml/docbook/xml-dtd-${DBK_XML_DTD_VER} &&
chown -R root:root . &&
cp -af docbook.cat *.dtd ent/ *.mod \
    /usr/share/xml/docbook/xml-dtd-${DBK_XML_DTD_VER} &&
if [ ! -e /etc/xml/catalog ]; then mkdir -p /etc/xml; xmlcatalog \
    --noout --create /etc/xml/catalog; fi &&
if [ ! -e /etc/xml/docbook ]; then xmlcatalog --noout --create \
    /etc/xml/docbook; fi &&
xmlcatalog --noout --add "public" \
    "-//OASIS//ELEMENTS DocBook XML Information Pool V${DBK_XML_DTD_VER}//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-${DBK_XML_DTD_VER}/dbpoolx.mod" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "public" \
    "-//OASIS//DTD DocBook XML V${DBK_XML_DTD_VER}//EN" \
    "http://www.oasis-open.org/docbook/xml/${DBK_XML_DTD_VER}/docbookx.dtd" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "public" \
    "-//OASIS//ENTITIES DocBook XML Character Entities V${DBK_XML_DTD_VER}//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-${DBK_XML_DTD_VER}/dbcentx.mod" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "public" \
    "-//OASIS//ENTITIES DocBook XML Notations V${DBK_XML_DTD_VER}//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-${DBK_XML_DTD_VER}/dbnotnx.mod" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "public" \
    "-//OASIS//ENTITIES DocBook XML Additional General Entities V${DBK_XML_DTD_VER}//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-${DBK_XML_DTD_VER}/dbgenent.mod" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "public" \
    "-//OASIS//ELEMENTS DocBook XML Document Hierarchy V${DBK_XML_DTD_VER}//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-${DBK_XML_DTD_VER}/dbhierx.mod" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "public" \
    "-//OASIS//DTD XML Exchange Table Model 19990315//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-${DBK_XML_DTD_VER}/soextblx.dtd" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "public" \
    "-//OASIS//DTD DocBook XML CALS Table Model V${DBK_XML_DTD_VER}//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-${DBK_XML_DTD_VER}/calstblx.dtd" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "rewriteSystem" \
    "http://www.oasis-open.org/docbook/xml/${DBK_XML_DTD_VER}" \
    "file:///usr/share/xml/docbook/xml-dtd-${DBK_XML_DTD_VER}" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "rewriteURI" \
    "http://www.oasis-open.org/docbook/xml/${DBK_XML_DTD_VER}" \
    "file:///usr/share/xml/docbook/xml-dtd-${DBK_XML_DTD_VER}" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "delegatePublic" \
    "-//OASIS//ENTITIES DocBook XML" \
    "file:///etc/xml/docbook" /etc/xml/catalog &&
xmlcatalog --noout --add "delegatePublic" \
    "-//OASIS//DTD DocBook XML" \
    "file:///etc/xml/docbook" /etc/xml/catalog &&
xmlcatalog --noout --add "delegateSystem" \
    "http://www.oasis-open.org/docbook/" \
    "file:///etc/xml/docbook" /etc/xml/catalog &&
xmlcatalog --noout --add "delegateURI" \
    "http://www.oasis-open.org/docbook/" \
    "file:///etc/xml/docbook" /etc/xml/catalog


# Configure
# TODO: need to sanely add more versions in here
VERS="4.1.2 4.2 4.3 4.4"
VERS=`echo ${VERS} | sed "s@${DBK_XML_DTD_VER}.*@@g"`

for ver in ${VERS} ; do
   case ${ver} in
   4.1.2 )
      xmlcatalog --noout --add "public" \
         "-//OASIS//DTD DocBook XML V${ver}//EN" \
         "http://www.oasis-open.org/docbook/xml/${ver}/docbookx.dtd" \
         /etc/xml/docbook &&
      xmlcatalog --noout --add "delegateSystem" \
         "http://www.oasis-open.org/docbook/xml/${ver}/" \
         "file:///etc/xml/docbook" /etc/xml/catalog &&
      xmlcatalog --noout --add "delegateURI" \
         "http://www.oasis-open.org/docbook/xml/${ver}/" \
         "file:///etc/xml/docbook" /etc/xml/catalog &&
      xmlcatalog --noout --add "rewriteSystem" \
         "http://www.oasis-open.org/docbook/xml/${ver}" \
         "file:///usr/share/xml/docbook/xml-dtd-${DBK_XML_DTD_VER}" \
         /etc/xml/docbook &&
      xmlcatalog --noout --add "rewriteURI" \
         "http://www.oasis-open.org/docbook/xml/${ver}" \
         "file:///usr/share/xml/docbook/xml-dtd-${DBK_XML_DTD_VER}" \
         /etc/xml/docbook
   ;;
   * ) 
      xmlcatalog --noout --add "rewriteURI" \
         "http://www.oasis-open.org/docbook/xml/${ver}" \
         "file:///usr/share/xml/docbook/xml-dtd-${DBK_XML_DTD_VER}" \
         /etc/xml/docbook
   ;;
   esac
done
