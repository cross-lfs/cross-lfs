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
fi

# Get Patch Names
#
cd /usr/src
wget ftp://invisible-island.net/ncurses/${VERSION}/ --no-remove-listing
ROLLUP=$(cat index.html | grep bz2 | cut -f2 -d'>' | cut -f1 -d'<' | tail -n 1)
ROLLPATCH=$(echo ${ROLLUP} | cut -f3 -d-)
FILES=$(cat index.html | grep ${VERSION}-2 | grep patch.gz | cut -f2 -d'>' | cut -f1 -d'<')
rm -f .listing
rm -f index.html

# Download Ncurses Source
#
if ! [ -e ncurses-${VERSION}.tar.gz ]; then
	wget ftp://invisible-island.net/ncurses/ncurses-${VERSION}.tar.gz
fi

# Cleanup Directory
#
rm -rf ncurses-${VERSION} ncurses-${VERSION}.orig
tar xvf ncurses-${VERSION}.tar.gz
cp -ar ncurses-${VERSION} ncurses-${VERSION}.orig
cd ncurses-${VERSION}

# Download and Apply Rollup Patch
#
CURRENTDIR=$(pwd -P)
mkdir /tmp/ncurses-${VERSION}
cd /tmp/ncurses-${VERSION}
if [ "${ROLLUP}" != "" ]; then
	echo "Getting Rollup ${ROLLUP} Patch..."
	wget --quiet ftp://invisible-island.net/ncurses/${VERSION}/${ROLLUP}
	cd ${CURRENTDIR}
	echo "Applying Rollup ${ROLLUP} Patch..."
	cp /tmp/ncurses-${VERSION}/${ROLLUP} ${CURRENTDIR}/${ROLLUP}
	bunzip2 ${ROLLUP}
	ROLLUP2=$(echo ${ROLLUP} | sed -e 's/.bz2//g')
	sh ${ROLLUP2}
fi

# Download and Apply Patches
#
for file in ${FILES}; do
	if [ "${ROLLPATCH}" != "" ]; then
		TEST=$(echo ${file} | grep -c ${ROLLPATCH})
	else
		TEST=0
	fi
	if [ "${TEST}" = "0" ]; then
		cd /tmp/ncurses-${VERSION}
		echo "Getting Patch ${file}..."
		wget --quiet ftp://invisible-island.net/ncurses/${VERSION}/${file}
		cd ${CURRENTDIR}
		gunzip -c /tmp/ncurses-${VERSION}/${file} | patch --dry-run -s -f -Np1
		if [ "$?" = "0" ]; then
			echo "Apply Patch ${file}..."
			gunzip -c /tmp/ncurses-${VERSION}/${file} | patch -Np1
			LASTFILE=$(echo ${file} | cut -f2 -d. | cut -f2 -d-)
		fi
	fi
done

# Cleanup Directory
#
# Cleanup Directory
#
for dir in $(find * -type d); do
	cd /usr/src/ncurses-${VERSION}/${dir}
	for file in $(find * -name *~); do
		rm -f ${file}
	done
	for file in $(find * -name *.orig); do
		rm -f ${file}
	done
done
cd /usr/src/ncurses-${VERSION}/${dir}
rm -f *.orig *~

# Create Patch
#
cd /usr/src
echo "Submitted By: Jim Gifford (jim at cross-lfs dot org)" > ncurses-${VERSION}-branch_update-x.patch
echo "Date: `date +%m-%d-%Y`" >> ncurses-${VERSION}-branch_update-x.patch
echo "Initial Package Version: ${VERSION}" >> ncurses-${VERSION}-branch_update-x.patch
echo "Origin: Upstream" >> ncurses-${VERSION}-branch_update-x.patch
echo "Upstream Status: Applied" >> ncurses-${VERSION}-branch_update-x.patch
echo "Description: This is a branch update for NCurses-${VERSION}, and should be" >> ncurses-${VERSION}-branch_update-x.patch
echo "             rechecked periodically. This patch covers up to ${VERSION}-${LASTFILE}." >> ncurses-${VERSION}-branch_update-x.patch
echo "" >> ncurses-${VERSION}-branch_update-x.patch
diff -Naur ncurses-${VERSION}.orig ncurses-${VERSION} >> ncurses-${VERSION}-branch_update-x.patch
echo "Created /usr/src/ncurses-${VERSION}-branch_update-x.patch."
