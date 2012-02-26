#!/bin/sh
# Jonathan Norman

# Vim branch update patch generator

VERSION=$1

# Check Input
#
if [ "${VERSION}" = "" ]; then
  echo "$0 [Vim_version]"
  echo "This will Create a Patch for Vim Vim_Version"
  exit 255
fi

TMP=~/tmp/vim-${VERSION}
PATCHDIR=${TMP}/patches
PATCHURL=ftp://ftp.vim.org/pub/vim/patches
SERIES=$(echo ${VERSION} | sed -e 's/\.//g')
CLFS_PATCHS=http://patches.cross-lfs.org/dev/

# Figure out patch number
UPDATE_NUM=$(curl -ls http://patches.cross-lfs.org/dev/ | grep vim-${VERSION} | cut -d . -f 3 | cut -d - -f 3-)
UPDATE_NUM=$(expr ${UPDATE_NUM} + 1)

# Download patches
echo "Downloading patches for VIM ${VERSION}"
PATCH_NUM=$(curl -s $PATCHURL/${VERSION}/ | grep " ${VERSION}." | cut -f 3- -d . | tail -n1)
mkdir -p $PATCHDIR
cd $PATCHDIR
curl -O -# $PATCHURL/$VERSION/$VERSION.[001-$PATCH_NUM]

echo "Downloading source for VIM $VERSION"
cd $TMP
curl -sO ftp://ftp.vim.org/pub/vim/unix/vim-${VERSION}.tar.bz2
tar -xvf vim-${VERSION}.tar.bz2
cp -R vim${SERIES} vim${SERIES}.orig

echo -n "Generating Patch..."
cd vim${SERIES}/src

for PATCH in $(ls $PATCHDIR); do
	patch -Np0 -i $PATCHDIR/$PATCH
	# echo $PATCHDIR/$PATCH
done

cd $TMP

# Create patch
echo "Submitted By: Jonathan Norman (jonathan at bluesquarelinux dot co dot uk)" > vim-${VERSION}-branch_update-$UPDATE_NUM.patch
echo "Date: `date +%Y-%m-%d`" >> vim-${VERSION}-branch_update-$UPDATE_NUM.patch
echo "Initial Package Version: ${VERSION}" >> vim-${VERSION}-branch_update-$UPDATE_NUM.patch
echo "Origin: Upstream" >> vim-${VERSION}-branch_update-$UPDATE_NUM.patch
echo "Upstream Status: Applied" >> vim-${VERSION}-branch_update-$UPDATE_NUM.patch
echo "Description: Contains all upstream patches up to ${VERSION}.${UPDATE_NUM}" >> vim-${VERSION}-branch_update-$UPDATE_NUM.patch
echo "" >> vim-${VERSION}-branch_update-$UPDATE_NUM.patch

LC_ALL=C TZ=UTC0 diff -Naur vim${SERIES}.orig vim${SERIES} >> vim-${VERSION}-branch_update-$UPDATE_NUM.patch

echo "Done"
echo "Cleaning up"
rm -rf vim${SERIES} vim${SERIES}.orig #vim-${VERSION}.tar.bz2

echo "Created: vim-${VERSION}-branch_update-$UPDATE_NUM.patch"
