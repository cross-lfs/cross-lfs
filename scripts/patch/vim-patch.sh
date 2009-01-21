#!/bin/bash
# Create a VIM Patch

# Get Version #
#
VERSION=$1

# Check Input
#
if [ "${VERSION}" = "" ]; then
  echo "$0 - Vim_Version"
  echo "This will Create a Patch for Vim Vim_Version"
  exit 255
fi

# Get the # of Patches
#
cd /usr/src
wget ftp://ftp.vim.org/pub/vim/patches/${VERSION}/ --no-remove-listing
FILES=$(cat index.html | grep "${VERSION}" | cut -f6 -d. | cut -f1 -d'"' | sed '/^$/d' | tail -n 1)
rm -f .listing
rm -f index.html
SERIES=$(echo ${VERSION} | sed -e 's/\.//g')
SKIPPATCH=""
SKIPPED=""

# Download VIM Source
#
if ! [ -e vim-${VERSION}.tar.bz2 ]; then
  wget ftp://ftp.vim.org/pub/vim/unix/vim-${VERSION}.tar.bz2
fi

# Cleanup Directory
#
rm -rf vim${SERIES} vim${SERIES}.orig
tar xvf vim-${VERSION}.tar.bz2
cp -ar vim${SERIES} vim${SERIES}.orig
cd vim${SERIES}
CURRENTDIR=$(pwd -P)

# Download and Apply Patches
#
PATCHURL=ftp://ftp.vim.org/pub/vim/patches/${VERSION}
mkdir /tmp/vim-${VERSION}
COUNT=1
while [ ${COUNT} -le ${FILES} ]; do
  cd /tmp/vim-${VERSION}            
  DLCOUNT="${COUNT}"
  SKIPME=no
  if [ "${COUNT}" -lt "100" ]; then
    DLCOUNT="0${COUNT}"
  fi
  if [ "${COUNT}" -lt "10" ]; then
    DLCOUNT="00${COUNT}"
  fi
  for skip in ${SKIPPATCH} ; do
    if [ "${DLCOUNT}" = "${skip}" ]; then
      echo "Patch ${VERSION}.${DLCOUNT} skipped"
      SKIPPED="${SKIPPED} ${DLCOUNT}"
      SKIPME=yes
    fi
  done
  if [ "${SKIPME}" != "yes" ]; then
    if ! [ -e ${VERSION}.${DLCOUNT} ]; then
      wget --quiet $PATCHURL/${VERSION}.${DLCOUNT}
    fi
    cd $CURRENTDIR
    patch --dry-run -s -f -Np0 -i /tmp/vim-${VERSION}/${VERSION}.${DLCOUNT}
    if [ "$?" = "0" ]; then
      echo "Patch ${VERSION}.${DLCOUNT} applied"
      patch -s -Np0 -i /tmp/vim-${VERSION}/${VERSION}.${DLCOUNT}
    else
      echo "Patch ${VERSION}.${DLCOUNT} not applied"
      rm -f /tmp/vim-${VERSION}/${VERSION}.${DLCOUNT}
      SKIPPED="${SKIPPED} ${DLCOUNT}"
    fi
   fi
   COUNT=`expr ${COUNT} + 1`
done

# Cleanup Directory
#
for dir in $(find * -type d); do
  cd /usr/src/vim${SERIES}
  for file in $(find . -name '*~'); do
    rm -f ${file}
  done
  for file in $(find . -name '*.orig'); do
    rm -f ${file}
  done
done
cd /usr/src/vim${SERIES}
rm -f *~ *.orig

# Create Patch
#
cd /usr/src
echo "Submitted By: Jim Gifford (jim at cross-lfs dot org)" > vim-${VERSION}-branch_update-x.patch
echo "Date: `date +%m-%d-%Y`" >> vim-${VERSION}-branch_update-x.patch
echo "Initial Package Version: ${VERSION}" >> vim-${VERSION}-branch_update-x.patch
echo "Origin: Upstream" >> vim-${VERSION}-branch_update-x.patch
echo "Upstream Status: Applied" >> vim-${VERSION}-branch_update-x.patch
echo "Description: Contains all upstream patches up to ${VERSION}.${FILES}" >> vim-${VERSION}-branch_update-x.patch
if [ -n "${SKIPPED}" ]; then
  echo "             The following patches were skipped" >> vim-${VERSION}-branch_update-x.patch
  echo "            ${SKIPPED}" >> vim-${VERSION}-branch_update-x.patch
fi
echo "" >> vim-${VERSION}-branch_update-x.patch
diff -Naur vim${SERIES}.orig vim${SERIES} >> vim-${VERSION}-branch_update-x.patch
echo "Created /usr/src/vim-${VERSION}-branch_update-x.patch."
