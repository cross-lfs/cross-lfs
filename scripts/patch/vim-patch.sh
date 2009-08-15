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
cd ~/tmp
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

# Set Patch Number
#
cd ~/tmp
wget http://svn.cross-lfs.org/svn/repos/patches/vim/ --no-remove-listing
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
rm -rf vim${SERIES} vim${SERIES}.orig
tar xvf vim-${VERSION}.tar.bz2
cp -ar vim${SERIES} vim${SERIES}.orig

# Download and Apply Patches
#
install -d ~/tmp/vim-${VERSION}-patches
cd ~/tmp/vim${SERIES}
CURRENTDIR=$(pwd -P)
PATCHURL=ftp://ftp.vim.org/pub/vim/patches/${VERSION}
COUNT=1
while [ ${COUNT} -le ${FILES} ]; do
  cd ~/tmp/vim${SERIES}
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
      cd ~/tmp/vim-${VERSION}-patches
      wget --quiet $PATCHURL/${VERSION}.${DLCOUNT}
    fi
    cd $CURRENTDIR
    patch --dry-run -s -f -Np0 -i ~/tmp/vim-${VERSION}-patches/${VERSION}.${DLCOUNT}
    if [ "$?" = "0" ]; then
      echo "Patch ${VERSION}.${DLCOUNT} applied"
      patch -s -Np0 -i ~/tmp/vim-${VERSION}-patches/${VERSION}.${DLCOUNT}
    else
      echo "Patch ${VERSION}.${DLCOUNT} not applied"
      SKIPPED="${SKIPPED} ${DLCOUNT}"
    fi
   fi
   COUNT=$(expr ${COUNT} + 1)
done

# Cleanup Directory
#
for dir in $(find * -type d); do
  cd ~/tmp/vim${SERIES}
  for file in $(find . -name '*~'); do
    rm -f ${file}
  done
  for file in $(find . -name '*.orig'); do
    rm -f ${file}
  done
done
cd ~/tmp/vim${SERIES}
rm -f *~ *.orig

# Create Patch
#
cd ~/tmp
echo "Submitted By: Jim Gifford (jim at cross-lfs dot org)" > ~/patches/vim-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Date: `date +%m-%d-%Y`" >> ~/patches/vim-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Initial Package Version: ${VERSION}" >> ~/patches/vim-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Origin: Upstream" >> ~/patches/vim-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Upstream Status: Applied" >> ~/patches/vim-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Description: Contains all upstream patches up to ${VERSION}.${FILES}" >> ~/patches/vim-${VERSION}-branch_update-${PATCH_NUM}.patch
if [ -n "${SKIPPED}" ]; then
  echo "             The following patches were skipped" >> ~/patches/vim-${VERSION}-branch_update-${PATCH_NUM}.patch
  echo "            ${SKIPPED}" >> ~/patches/vim-${VERSION}-branch_update-${PATCH_NUM}.patch
fi
echo "" >> ~/patches/vim-${VERSION}-branch_update-${PATCH_NUM}.patch
diff -Naur vim${SERIES}.orig vim${SERIES} >> ~/patches/vim-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Created ~/patches/vim-${VERSION}-branch_update-${PATCH_NUM}.patch."

# Cleanup Directory
#
rm -rf vim${SERIES} vim${SERIES}.orig
