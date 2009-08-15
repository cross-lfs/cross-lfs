#!/bin/bash
# Create a Ncuruses Patch

# Get Version #
#
VERSION=$1

# Check Input
#
if [ "${VERSION}" = "" ]; then
  echo "$0 - Ncurses_Version"
  echo "This will Create a Patch for Ncurses Ncurses_Version"
  exit 255
fi

# Get Patch Names
#
cd ~/tmp
wget ftp://invisible-island.net/ncurses/${VERSION}/ --no-remove-listing
ROLLUP=$(cat index.html | grep bz2 | cut -f2 -d'>' | cut -f1 -d'<' | tail -n 1)
ROLLPATCH=$(echo ${ROLLUP} | cut -f3 -d-)
FILES=$(cat index.html | grep ${VERSION}-2 | grep patch.gz | cut -f2 -d'>' | cut -f1 -d'<')
rm -f .listing
rm -f index.html

# Download Ncurses Source
#
cd ~/tmp
if ! [ -e ncurses-${VERSION}.tar.gz ]; then
  wget ftp://invisible-island.net/ncurses/ncurses-${VERSION}.tar.gz
fi

# Set Patch Number
#
cd ~/tmp
wget http://svn.cross-lfs.org/svn/repos/patches/ncurses/ --no-remove-listing
for num in $(seq 1 99); do
  PATCH_NUM=$(cat index.html | grep "${VERSION}" | grep branch_update-${num} | cut -f2 -d'"' | cut -f1 -d'"'| cut -f4 -d- | cut -f1 -d. | tail -n 1)
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
rm -rf ncurses-${VERSION} ncurses-${VERSION}.orig
tar xvf ncurses-${VERSION}.tar.gz
cp -ar ncurses-${VERSION} ncurses-${VERSION}.orig

# Download and Apply Rollup Patch
#
cd ~/tmp/ncurses-${VERSION}
CURRENTDIR=$(pwd -P)
mkdir ~/tmp/ncurses-${VERSION}-patches
cd ~/tmp/ncurses-${VERSION}
if [ "${ROLLUP}" != "" ]; then
  echo "Getting Rollup ${ROLLUP} Patch..."
  cd ~/tmp/ncurses-${VERSION}-patches
  wget --quiet ftp://invisible-island.net/ncurses/${VERSION}/${ROLLUP}
  cd ${CURRENTDIR}
  echo "Applying Rollup ${ROLLUP} Patch..."
  cp ~/tmp/ncurses-${VERSION}-patches/${ROLLUP} ${CURRENTDIR}/${ROLLUP}
  bunzip2 ${ROLLUP}
  ROLLUP2=$(echo ${ROLLUP} | sed -e 's/.bz2//g')
  sh ${ROLLUP2}
fi

# Download and Apply Patches
#
install -d ~/tmp/ncurses-${VERSION}-patches
cd ~/tmp/ncurses-${VERSION}
CURRENTDIR=$(pwd -P)
for file in ${FILES}; do
  if [ "${ROLLPATCH}" != "" ]; then
    TEST=$(echo ${file} | grep -c ${ROLLPATCH})
  else
    TEST=0
  fi
  if [ "${TEST}" = "0" ]; then
    cd ~/tmp/ncurses-${VERSION}-patches
    echo "Getting Patch ${file}..."
    wget --quiet ftp://invisible-island.net/ncurses/${VERSION}/${file}
    cd ${CURRENTDIR}
    gunzip -c ~/tmp/ncurses-${VERSION}-patches/${file} | patch --dry-run -s -f -Np1
    if [ "$?" = "0" ]; then
      echo "Apply Patch ${file}..."
      gunzip -c ~/tmp/ncurses-${VERSION}-patches/${file} | patch -Np1
      LASTFILE=$(echo ${file} | cut -f2 -d. | cut -f2 -d-)
    fi
  fi
done

# Cleanup Directory
#
cd ~/tmp
cd ncurses-${VERSION}
for dir in $(find * -type d); do
  cd ~/tmp/ncurses-${VERSION}/${dir}
  for file in $(find . -name '*~'); do
    rm -f ${file}
  done
  for file in $(find . -name '*.orig'); do
    rm -f ${file}
  done
done
cd ~/tmp/ncurses-${VERSION}
rm -f *~ *.orig

# Create Patch
#
cd ~/tmp
echo "Submitted By: Jim Gifford (jim at cross-lfs dot org)" > ~/patches/ncurses-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Date: `date +%m-%d-%Y`" >> ~/patches/ncurses-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Initial Package Version: ${VERSION}" >> ~/patches/ncurses-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Origin: Upstream" >> ~/patches/ncurses-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Upstream Status: Applied" >> ~/patches/ncurses-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Description: This is a branch update for NCurses-${VERSION}, and should be" >> ~/patches/ncurses-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "             rechecked periodically. This patch covers up to ${VERSION}-${LASTFILE}." >> ~/patches/ncurses-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "" >> ~/patches/ncurses-${VERSION}-branch_update-${PATCH_NUM}.patch
diff -Naur ncurses-${VERSION}.orig ncurses-${VERSION} >> ~/patches/ncurses-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Created ~/patches/ncurses-${VERSION}-branch_update-${PATCH_NUM}.patch."

# Cleanup Directory
#
cd ~/tmp
rm -rf ncurses-${VERSION} ncurses-${VERSION}.orig
