#!/bin/bash
# Create a GCC Specs Patch

# Get Version #
#
VERSION=$1

# Check Input
#
if [ "${VERSION}" = "" ]; then
	echo "$0 - GCC_Version"
	echo "This will Create a Patch for GCC Specs GCC_Version"
fi

# Download GCC Source
#
cd /usr/src
if ! [ -e gcc-${VERSION}.tar.bz2  ]; then
	wget ftp://ftp.gnu.org/gnu/gcc/gcc-${VERSION}/gcc-${VERSION}.tar.bz2
fi

# Cleanup Directory
#
rm -rf gcc-${VERSION} gcc-${VERSION}.orig
tar xvf gcc-${VERSION}.tar.bz2
cp -ar gcc-${VERSION} gcc-${VERSION}.orig
CURRENTDIR=$(pwd -P)

# Modify the Data
#
cd /usr/src/gcc-${VERSION}
for file in $(find gcc/config -name "*.h"); do
	if [ "$(echo ${file} | grep -c bsd)" = "0" ]; then
		if [ "$(cat ${file} | grep -c DYNAMIC_LINKER)" != "0" ]; then
			echo "Modifying ${file}..."
			sed -i '/DYNAMIC_LINKER/s@"/lib@"/tools/lib@' ${file}
		fi
		if [ "$(cat ${file} | grep -c DYNAMIC_LINKER)" != "0" ]; then
			echo "Modifying ${file}..."
			sed -i '/-dynamic-linker/s@ /lib@ /tools/lib@' ${file}
		fi
	fi
done


# Create Patch
#
cd /usr/src
echo "Submitted By: Jim Gifford (jim at cross-lfs dot org)" > gcc-${VERSION}-specs-x.patch
echo "Date: `date +%m-%d-%Y`" >> gcc-${VERSION}-specs-x.patch
echo "Initial Package Version: ${VERSION}" >> gcc-${VERSION}-specs-x.patch
echo "Origin: Idea originally developed by Ryan Oliver and Greg Schafer for" >> gcc-${VERSION}-specs-x.patch
echo "        the Pure LFS project." >> gcc-${VERSION}-specs-x.patch
echo "Upstream Status: Not Applied" >> gcc-${VERSION}-specs-x.patch
echo "Description: This patch modifies the location of the dynamic linker for gcc-${VERSION}." >> gcc-${VERSION}-specs-x.patch
echo "" >> gcc-${VERSION}-specs-x.patch
diff -Naur gcc-${VERSION}.orig gcc-${VERSION} >> gcc-${VERSION}-specs-x.patch
echo "Created /usr/src/gcc-${VERSION}-specs-x.patch."
