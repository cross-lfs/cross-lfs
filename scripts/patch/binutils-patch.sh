#!/bin/bash
# Create a Binutils Patch

# Get Version #
#
VERSION=$1
SOURCEVERSION=$2

# Check Input
#
if [ "${VERSION}" = "" -o "${SOURCEVERSION}" = "" ]; then
  echo "$0 - Binutils_Version"
  echo "This will Create a Patch for Binutils Binutils_Series Binutils_Version"
  echo "Example $0 2.19 2.19.1"
  exit 255
fi

# 
# Download Binutils Source
#
cd /usr/src
if ! [ -e binutils-${SOURCEVERSION}.tar.bz2  ]; then
  wget ftp://ftp.gnu.org/gnu/binutils/binutils-${SOURCEVERSION}.tar.bz2
fi

# Cleanup Directory
#
rm -rf binutils-${SOURCEVERSION} binutils-${SOURCEVERSION}.orig
tar xvf binutils-${SOURCEVERSION}.tar.bz2
mv binutils-${SOURCEVERSION} binutils-${SOURCEVERSION}.orig
CURRENTDIR=$(pwd -P)

# Get Current Updates from CVS
#
cd /usr/src
FIXEDVERSION=$(echo ${VERSION} | sed -e 's/\./_/g')
cvs -z 9 -d :pserver:anoncvs@sourceware.org:/cvs/src export -rbinutils-${FIXEDVERSION}-branch binutils
mv src binutils-${SOURCEVERSION}

# Cleanup
#
DIRS="binutils-${SOURCEVERSION} binutils-${SOURCEVERSION}.orig"
for DIRECTORY in ${DIRS}; do
  cd /usr/src/${DIRECTORY}
  FILE_LIST=".cvsignore *.gmo"
  for files in ${FILE_LIST}; do
    REMOVE=$(find * -name ${files})
    for file in $REMOVE; do
      rm -f ${file}
    done
  done

  REMOVE=".cvsignore MAINTAINERS COPYING.LIBGLOSS COPYING.NEWLIB README-maintainer-mode depcomp
    ChangeLog compile ltgcc.m4 lt~obsolete.m4 etc/ChangeLog etc/add-log.el etc/add-log.vi"
  for file in $REMOVE; do
    rm -f ${file}
    done
    cd ..
done
cd /usr/src/binutils-${SOURCEVERSION}
rm -f /usr/src/binutils-${SOURCEVERSION}.orig/md5.sum

# Make Binutils a Release
#
cd /usr/src/binutils-${SOURCEVERSION}
sed -i 's/# RELEASE=y/RELEASE=y/g' bfd/Makefile.am
sed -i 's/# RELEASE=y/RELEASE=y/g' bfd/Makefile.in

# Create Patch
#
cd /usr/src
echo "Submitted By: Jim Gifford (jim at cross-lfs dot org)" > binutils-${SOURCEVERSION}-branch_update-x.patch
echo "Date: `date +%m-%d-%Y`" >> binutils-${SOURCEVERSION}-branch_update-x.patch
echo "Initial Package Version: ${SOURCEVERSION}" >> binutils-${SOURCEVERSION}-branch_update-x.patch
echo "Origin: Upstream" >> binutils-${SOURCEVERSION}-branch_update-x.patch
echo "Upstream Status: Applied" >> binutils-${SOURCEVERSION}-branch_update-x.patch
echo "Description: This is a branch update for binutils-${SOURCEVERSION}, and should be" >> binutils-${SOURCEVERSION}-branch_update-x.patch
echo "             rechecked periodically." >> binutils-${SOURCEVERSION}-branch_update-x.patch
echo "" >> binutils-${SOURCEVERSION}-branch_update-x.patch
diff -Naur binutils-${SOURCEVERSION}.orig binutils-${SOURCEVERSION} >> binutils-${SOURCEVERSION}-branch_update-x.patch
echo "Created /usr/src/binutils-${SOURCEVERSION}-branch_update-x.patch."
