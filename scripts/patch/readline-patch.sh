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
cd ~/tmp
wget ftp://ftp.cwru.edu/pub/bash/readline-${VERSION}-patches/ --no-remove-listing
VERSION2=$(echo ${VERSION} | sed -e 's/\.//g')
FILES=$(cat index.html | grep "${VERSION2}" | cut -f2 -d'"' | cut -f4 -d. | cut -f3 -d- | tail -n 1)
rm -f .listing
rm -f index.html
SKIPPATCH=""
SKIPPED=""

# Download Readline Source
#
cd ~/tmp
if ! [ -e readline-${VERSION}.tar.gz ]; then
  wget ftp://ftp.cwru.edu/pub/bash/readline-${VERSION}.tar.gz
fi

# Set Patch Number
#
cd ~/tmp
wget http://svn.cross-lfs.org/svn/repos/patches/readline/ --no-remove-listing
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
rm -rf readline-${VERSION} readline-${VERSION}.orig
tar xvf readline-${VERSION}.tar.gz
cp -ar readline-${VERSION} readline-${VERSION}.orig

# Download and Apply Patches
#
install -d ~/tmp/readline-${VERSION}-patches
cd ~/tmp/readline-${VERSION}
CURRENTDIR=$(pwd -P)
PATCHURL=ftp://ftp.cwru.edu/pub/bash/readline-${VERSION}-patches
mkdir /tmp/readline-${VERSION}
COUNT=1
while [ ${COUNT} -le ${FILES} ]; do
  cd ~/tmp/readline-${VERSION}           
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
      cd ~/tmp/readline-${VERSION}-patches
      wget --quiet ${PATCHURL}/readline${VERSION2}-${DLCOUNT}
    fi
    cd ${CURRENTDIR}
    patch --dry-run -s -f -Np0 -i ~/tmp/readline-${VERSION}-patches/readline${VERSION2}-${DLCOUNT}
    if [ "$?" = "0" ]; then
      echo "Patch readline${VERSION2}-${DLCOUNT} applied"
      patch -s -Np0 -i ~/tmp/readline-${VERSION}-patches/readline${VERSION2}-${DLCOUNT}
    else
      echo "Patch readline${VERSION2}-${DLCOUNT} not applied"
      rm -f ~/tmp/readline-${VERSION}-patches/readline${VERSION2}-${DLCOUNT}
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
  cd ~/tmp/readline-${VERSION}/${dir}
  for file in $(find . -name '*~'); do
    rm -f ${file}
  done
  for file in $(find . -name '*.orig'); do
    rm -f ${file}
  done
done
cd ~/tmp/readline-${VERSION}
rm -f *~ *.orig

# Create Patch
#
cd ~/tmp
echo "Submitted By: Jim Gifford (jim at cross-lfs dot org)" > ~/patches/readline-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Date: `date +%m-%d-%Y`" >> ~/patches/readline-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Initial Package Version: ${VERSION}" >> ~/patches/readline-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Origin: Upstream" >> ~/patches/readline-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Upstream Status: Applied" >> ~/patches/readline-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Description: Contains all upstream patches up to ${VERSION}-${FILES}" >> ~/patches/readline-${VERSION}-branch_update-${PATCH_NUM}.patch
if [ -n "${SKIPPED}" ]; then
  echo "            Thee following patches were skipped" >> ~/patches/readline-${VERSION}-branch_update-${PATCH_NUM}.patch
  echo "            ${SKIPPED}" >> ~/patches/readline-${VERSION}-branch_update-${PATCH_NUM}.patch
fi
echo "" >> ~/patches/readline-${VERSION}-branch_update-${PATCH_NUM}.patch
diff -Naur readline-${VERSION}.orig readline-${VERSION} >> ~/patches/readline-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Created ~/patches/readline-${VERSION}-branch_update-${PATCH_NUM}.patch."

# Cleanup Directory
#
cd ~/tmp
rm -rf readline-${VERSION} readline-${VERSION}.orig
