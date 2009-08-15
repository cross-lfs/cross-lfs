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
install -d ~/tmp
cd ~/tmp
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
cd ~/tmp
wget http://svn.cross-lfs.org/svn/repos/patches/bash/ --no-remove-listing
for num in $(seq 1 99); do
  PATCH_NUM=$(cat index.html | grep "${VERSION}" | grep branch_update-${num}.patch | cut -f2 -d'"' | cut -f1 -d'"'| cut -f4 -d- | cut -f1 -d. | tail -n 1)
  if [ "${PATCH_NUM}" = "0" -a "${num}" = "1" ]; then
    PATCH_NUM=$(expr ${PATCH_NUM} + 1)
    break
  fi
  if [ "${PATCH_NUM}" != "${num}" ]; then
    PATCH_NUM=$(expr ${num})
    break
  fi
done
rm -f index.html

# Cleanup Directory
#
cd ~/tmp
rm -rf bash-${VERSION} bash-${VERSION}.orig
tar xvf bash-${VERSION}.tar.gz
cp -ar bash-${VERSION} bash-${VERSION}.orig

# Download and Apply Patches
#
install -d ~/tmp/bash-${VERSION}-patches
cd ~/tmp/bash-${VERSION}
CURRENTDIR=$(pwd -P)
PATCHURL=ftp://ftp.cwru.edu/pub/bash/bash-${VERSION}-patches
COUNT=1
while [ ${COUNT} -le ${FILES} ]; do
  cd ~/tmp/bash-${VERSION}           
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
      cd ~/tmp/bash-${VERSION}-patches
      wget --quiet ${PATCHURL}/bash${VERSION2}-${DLCOUNT}
    fi
    cd ${CURRENTDIR}
    patch --dry-run -s -f -Np0 -i ~/tmp/bash-${VERSION}-patches/bash${VERSION2}-${DLCOUNT}
    if [ "$?" = "0" ]; then
      echo "Patch bash${VERSION2}-${DLCOUNT} applied"
      patch -s -Np0 -i ~/tmp/bash-${VERSION}-patches/bash${VERSION2}-${DLCOUNT}
    else
     echo "Patch bash${VERSION2}-${DLCOUNT} not applied"
     rm -f ~/tmp/bash-${VERSION}-patches/bash${VERSION2}-${DLCOUNT}
     SKIPPED="${SKIPPED} ${DLCOUNT}"
    fi
  fi
  COUNT=`expr ${COUNT} + 1`
done

# Cleanup Directory
#
cd ~/tmp/bash-${VERSION}
for dir in $(find * -type d); do
  cd ~/tmp/bash-${VERSION}/${dir}
  for file in $(find . -name '*~'); do
    rm -f ${file}
  done
  for file in $(find . -name '*.orig'); do
    rm -f ${file}
  done
done
cd ~/tmp/bash-${VERSION}
rm -f *~ *.orig

# Create Patch
#
cd ~/tmp
install -d ~/patches
echo "Submitted By: Jim Gifford (jim at cross-lfs dot org)" > ~/patches/bash-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Date: `date +%m-%d-%Y`" >> ~/patches/bash-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Initial Package Version: ${VERSION}" >> ~/patches/bash-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Origin: Upstream" >> ~/patches/bash-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Upstream Status: Applied" >> ~/patches/bash-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Description: Contains all upstream patches up to ${VERSION}-${FILES}" >> ~/patches/bash-${VERSION}-branch_update-${PATCH_NUM}.patch
if [ -n "${SKIPPED}" ]; then
  echo "             The following patches were skipped" >> ~/patches/bash-${VERSION}-branch_update-${PATCH_NUM}.patch
  echo "            ${SKIPPED}" >> ~/patches/bash-${VERSION}-branch_update-${PATCH_NUM}.patch
fi
echo "" >> ~/patches/bash-${VERSION}-branch_update-${PATCH_NUM}.patch
diff -Naur bash-${VERSION}.orig bash-${VERSION} >> ~/patches/bash-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Created ~/patches/bash-${VERSION}-branch_update-${PATCH_NUM}.patch."

# Cleanup Directory
#
cd ~/tmp
rm -rf bash-${VERSION} bash-${VERSION}.orig
