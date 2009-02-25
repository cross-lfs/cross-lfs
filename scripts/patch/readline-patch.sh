#!/bin/bash
# Create a Readline Patch

# Get Version #
#
VERSION=$1

# Check Input
#
if [ "${VERSION}" = "" ]; then
  echo "$0 - Readline_Version"
  echo "This will Create a Patch for Readline Readline_Version"
  exit 255
fi

# Get the # of Patches
#
cd /usr/src
wget ftp://ftp.cwru.edu/pub/bash/readline-${VERSION}-patches/ --no-remove-listing
VERSION2=$(echo ${VERSION} | sed -e 's/\.//g')
FILES=$(cat index.html | grep "${VERSION2}" | cut -f2 -d'"' | cut -f4 -d. | cut -f3 -d- | tail -n 1)
rm -f .listing
rm -f index.html
SKIPPATCH=""
SKIPPED=""

# Download Readline Source
#
if ! [ -e readline-${VERSION}.tar.gz ]; then
  wget ftp://ftp.cwru.edu/pub/bash/readline-${VERSION}.tar.gz
fi

# Set Patch Number
#
cd /usr/src
wget http://svn.cross-lfs.org/svn/repos/cross-lfs/trunk/patches/ --no-remove-listing
PATCH_NUM=$(cat index.html | grep readline | grep "${VERSION}" | grep branch_update | cut -f2 -d'"' | cut -f1 -d'"'| cut -f4 -d- | cut -f1 -d. | tail -n 1)
PATCH_NUM=$(expr ${PATCH_NUM} + 1)
rm -f index.html

# Cleanup Directory
#
rm -rf readline-${VERSION} readline-${VERSION}.orig
tar xvf readline-${VERSION}.tar.gz
cp -ar readline-${VERSION} readline-${VERSION}.orig
cd readline-${VERSION}
CURRENTDIR=$(pwd -P)

# Download and Apply Patches
#
PATCHURL=ftp://ftp.cwru.edu/pub/bash/readline-${VERSION}-patches
mkdir /tmp/readline-${VERSION}
COUNT=1
while [ ${COUNT} -le ${FILES} ]; do
  cd /tmp/readline-${VERSION}           
  DLCOUNT="${COUNT}"
  SKIPME=no
  if [ "${COUNT}" -lt "100" ]; then
    DLCOUNT="0${COUNT}"
  fi
  if [ "${COUNT}" -lt "10" ]; then
    DLCOUNT="00${COUNT}"
  fi
  for skip in ${SKIPPATCH} ; do
    if [ "${DLCOUNT}" = "$skip" ]; then
      echo "Patch readline${VERSION2}-${DLCOUNT} skipped"
      SKIPPED="${SKIPPED} ${DLCOUNT}"
      SKIPME=yes
    fi
  done
  if [ "${SKIPME}" != "yes" ]; then
    if ! [ -e ${VERSION}.${DLCOUNT} ]; then
      wget --quiet ${PATCHURL}/readline${VERSION2}-${DLCOUNT}
    fi
    cd ${CURRENTDIR}
    patch --dry-run -s -f -Np0 -i /tmp/readline-${VERSION}/readline${VERSION2}-${DLCOUNT}
    if [ "$?" = "0" ]; then
      echo "Patch readline${VERSION2}-${DLCOUNT} applied"
      patch -s -Np0 -i /tmp/readline-${VERSION}/readline${VERSION2}-${DLCOUNT}
    else
      echo "Patch readline${VERSION2}-${DLCOUNT} not applied"
      rm -f /tmp/readline-${VERSION}/readline${VERSION2}-${DLCOUNT}
      SKIPPED="${SKIPPED} ${DLCOUNT}"
     fi
    fi
    COUNT=`expr ${COUNT} + 1`
done

# Cleanup Directory
#
# Cleanup Directory
#
for dir in $(find * -type d); do
  cd /usr/src/readline-${VERSION}/${dir}
  for file in $(find . -name '*~'); do
    rm -f ${file}
  done
  for file in $(find . -name '*.orig'); do
    rm -f ${file}
  done
done
cd /usr/src/readline-${VERSION}
rm -f *~ *.orig

# Create Patch
#
cd /usr/src
echo "Submitted By: Jim Gifford (jim at cross-lfs dot org)" > readline-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Date: `date +%m-%d-%Y`" >> readline-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Initial Package Version: ${VERSION}" >> readline-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Origin: Upstream" >> readline-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Upstream Status: Applied" >> readline-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Description: Contains all upstream patches up to ${VERSION}-${FILES}" >> readline-${VERSION}-branch_update-${PATCH_NUM}.patch
if [ -n "${SKIPPED}" ]; then
  echo "            Thee following patches were skipped" >> readline-${VERSION}-branch_update-${PATCH_NUM}.patch
  echo "            ${SKIPPED}" >> readline-${VERSION}-branch_update-${PATCH_NUM}.patch
fi
echo "" >> readline-${VERSION}-branch_update-${PATCH_NUM}.patch
diff -Naur readline-${VERSION}.orig readline-${VERSION} >> readline-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Created /usr/src/readline-${VERSION}-branch_update-${PATCH_NUM}.patch."
