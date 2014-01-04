#!/bin/sh
# Jonathan Norman

# Ncurses branch update patch generator

VERSION=$1

# Check Input
#
if [ "${VERSION}" = "" ]; then
  echo "$0 [ncurses_version]"
  echo "This will Create a Patch for ncurses ncurses_Version"
  exit 255
fi

TMP=~/tmp/ncurses-${VERSION}
PATCHDIR=${TMP}/patches
PATCHURL=ftp://invisible-island.net/ncurses/
SERIES=$(echo ${VERSION} | sed -e 's/\.//g')
CLFS_PATCHS=http://patches.cross-lfs.org/dev/

# Figure out patch number
UPDATE_NUM=0
UPDATE_NUM=$(curl -ls http://patches.cross-lfs.org/dev/ | grep ncurses-${VERSION}-branch_update | cut -d . -f 3 | cut -d - -f 3-)
UPDATE_NUM=$(expr ${UPDATE_NUM} + 1)

# Download patches
echo "Downloading patches for Ncurses ${VERSION}"
FILES=$(curl -sl ftp://invisible-island.net/ncurses/${VERSION}/ | grep patch | grep -v bz2 | grep -v asc)
mkdir -p $PATCHDIR
cd $PATCHDIR
for FILE in $FILES; do
	curl -O -# $PATCHURL/$VERSION/$FILE
done


echo "Downloading source for Ncurses $VERSION"
cd $TMP
curl -sO ftp://invisible-island.net/ncurses/ncurses-${VERSION}.tar.gz
tar -xvf ncurses-${VERSION}.tar.gz
cp -R ncurses-${VERSION} ncurses-${VERSION}.orig

echo -n "Generating Patch..."
cd ncurses-${VERSION}

gunzip -c $PATCHDIR/*.sh.gz | sh
for PATCH in $(ls $PATCHDIR | grep patch.gz); do
	gunzip -c $PATCHDIR/$PATCH | patch -Np1
done

cd $TMP

DATE=$(ls $PATCHDIR | tail -n1 | cut -d- -f3 | cut -d. -f1);

# Create patch
echo "Submitted By: Jonathan Norman (jonathan at bluesquarelinux dot co dot uk)" > ncurses-${VERSION}-branch_update-$UPDATE_NUM.patch
echo "Date: `date +%Y-%m-%d`" >> ncurses-${VERSION}-branch_update-$UPDATE_NUM.patch
echo "Initial Package Version: ${VERSION}" >> ncurses-${VERSION}-branch_update-$UPDATE_NUM.patch
echo "Origin: Upstream" >> ncurses-${VERSION}-branch_update-$UPDATE_NUM.patch
echo "Upstream Status: Applied" >> ncurses-${VERSION}-branch_update-$UPDATE_NUM.patch
echo "Description: Contains all upstream patches up to ${VERSION}-${DATE}" >> ncurses-${VERSION}-branch_update-$UPDATE_NUM.patch
echo "" >> ncurses-${VERSION}-branch_update-$UPDATE_NUM.patch

LC_ALL=C TZ=UTC0 diff -Naur ncurses-${VERSION}.orig ncurses-${VERSION} >> ncurses-${VERSION}-branch_update-$UPDATE_NUM.patch

echo "Done"
echo "Cleaning up"
rm -rf ncurses-${VERSION} ncurses-${VERSION}.orig #ncurses-${VERSION}.tar.bz2

echo "Created: $PWD/ncurses-${VERSION}-branch_update-$UPDATE_NUM.patch"
