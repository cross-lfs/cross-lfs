#!/bin/bash
# Create a Bash Patch

# Get Version #
#
VERSION=$1

# Check Input
#
if [ "${VERSION}" = "" ]; then
  echo "$0 - Bash_Version"
  echo "This will Create a Patch for Bash Bash_Version"
  exit 255
fi

# Get the # of Patches
#
cd /usr/src
wget ftp://ftp.cwru.edu/pub/bash/bash-${VERSION}-patches/ --no-remove-listing
VERSION2=$(echo ${VERSION} | sed -e 's/\.//g')
FILES=$(cat index.html | grep "${VERSION2}" | cut -f2 -d'"' | cut -f4 -d. | cut -f3 -d- | tail -n 1)
rm -f .listing
rm -f index.html
SKIPPATCH=""
SKIPPED=""

# Download BASH Source
#
if ! [ -e bash-${VERSION}.tar.gz ]; then
  wget ftp://ftp.cwru.edu/pub/bash/bash-${VERSION}.tar.gz
fi

# Set Patch Number
#
cd /usr/src
wget http://svn.cross-lfs.org/svn/repos/cross-lfs/trunk/patches/ --no-remove-listing
PATCH_NUM=$(cat index.html | grep bash | grep "${VERSION}" | grep branch_update | cut -f2 -d'"' | cut -f1 -d'"'| cut -f4 -d- | cut -f1 -d. | tail -n 1)
PATCH_NUM=$(expr ${PATCH_NUM} + 1)
rm -f index.html

# Cleanup Directory
#
rm -rf bash-${VERSION} bash-${VERSION}.orig
tar xvf bash-${VERSION}.tar.gz
cp -ar bash-${VERSION} bash-${VERSION}.orig
cd bash-${VERSION}
CURRENTDIR=$(pwd -P)

# Download and Apply Patches
#
PATCHURL=ftp://ftp.cwru.edu/pub/bash/bash-${VERSION}-patches
mkdir /tmp/bash-${VERSION}
COUNT=1
while [ ${COUNT} -le ${FILES} ]; do
  cd /tmp/bash-${VERSION}           
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
      echo "Patch bash${VERSION2}-${DLCOUNT} skipped"
      SKIPPED="${SKIPPED} ${DLCOUNT}"
      SKIPME=yes
    fi
  done
  if [ "${SKIPME}" != "yes" ]; then
    if ! [ -e ${VERSION}.${DLCOUNT} ]; then
      wget --quiet ${PATCHURL}/bash${VERSION2}-${DLCOUNT}
    fi
    cd ${CURRENTDIR}
    patch --dry-run -s -f -Np0 -i /tmp/bash-${VERSION}/bash${VERSION2}-${DLCOUNT}
    if [ "$?" = "0" ]; then
      echo "Patch bash${VERSION2}-${DLCOUNT} applied"
      patch -s -Np0 -i /tmp/bash-${VERSION}/bash${VERSION2}-${DLCOUNT}
    else
     echo "Patch bash${VERSION2}-${DLCOUNT} not applied"
     rm -f /tmp/bash-${VERSION}/bash${VERSION2}-${DLCOUNT}
     SKIPPED="${SKIPPED} ${DLCOUNT}"
    fi
  fi
  COUNT=`expr ${COUNT} + 1`
done

# Cleanup Directory
#

for dir in $(find * -type d); do
  cd /usr/src/bash-${VERSION}/${dir}
  for file in $(find . -name '*~'); do
    rm -f ${file}
  done
  for file in $(find . -name '*.orig'); do
    rm -f ${file}
  done
done
cd /usr/src/bash-${VERSION}
rm -f *~ *.orig

# Create Patch
#
cd /usr/src
echo "Submitted By: Jim Gifford (jim at cross-lfs dot org)" > bash-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Date: `date +%m-%d-%Y`" >> bash-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Initial Package Version: ${VERSION}" >> bash-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Origin: Upstream" >> bash-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Upstream Status: Applied" >> bash-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Description: Contains all upstream patches up to ${VERSION}-${FILES}" >> bash-${VERSION}-branch_update-${PATCH_NUM}.patch
if [ -n "${SKIPPED}" ]; then
  echo "             The following patches were skipped" >> bash-${VERSION}-branch_update-${PATCH_NUM}.patch
  echo "            ${SKIPPED}" >> bash-${VERSION}-branch_update-${PATCH_NUM}.patch
fi
echo "" >> bash-${VERSION}-branch_update-${PATCH_NUM}.patch
diff -Naur bash-${VERSION}.orig bash-${VERSION} >> bash-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Created /usr/src/bash-${VERSION}-branch_update-${PATCH_NUM}.patch."
