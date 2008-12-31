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
cd /usr/src
cd bash-${VERSION}
for file in $(find * -name *~); do
	rm -f ${file}
done
for file in $(find * -name *.orig); do
	rm -f ${file}
done

# Create Patch
#
cd /usr/src
echo "Submitted By: Jim Gifford (jim at linuxfromscratch dot org)" > bash-${VERSION}-fixes-x.patch
echo "Date: `date +%m-%d-%Y`" >> bash-${VERSION}-fixes-x.patch
echo "Initial Package Version: ${VERSION}" >> bash-${VERSION}-fixes-x.patch
echo "Origin: Upstream" >> bash-${VERSION}-fixes-x.patch
echo "Upstream Status: Applied" >> bash-${VERSION}-fixes-x.patch
echo "Description: Contains all upstream patches up to ${VERSION}-${FILES}" >> bash-${VERSION}-fixes-x.patch
if [ -n "${SKIPPED}" ]; then
	echo "             The following patches were skipped" >> bash-${VERSION}-fixes-x.patch
	echo "            ${SKIPPED}" >> bash-${VERSION}-fixes-x.patch
fi
echo "" >> bash-${VERSION}-fixes-x.patch
diff -Naur bash-${VERSION}.orig bash-${VERSION} >> bash-${VERSION}-fixes-x.patch
echo "Created /usr/src/bash-${VERSION}-fixes-x.patch."

