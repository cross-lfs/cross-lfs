#!/bin/bash
# Create a GCC Patch

# Get Version #
#
VERSION=$1

# Check Input
#
if [ "${VERSION}" = "" ]; then
  echo "$0 - GCC_Version"
  echo "This will Create a Patch for GCC GCC_Version"
  exit 255
fi

# Download GCC Source
#
cd /usr/src
if ! [ -e gcc-${VERSION}.tar.bz2  ]; then
  wget ftp://gcc.gnu.org/pub/gcc/releases/gcc-${VERSION}/gcc-${VERSION}.tar.bz2
fi

# Cleanup Directory
#
rm -rf gcc-${VERSION} gcc-${VERSION}.orig
tar xvf gcc-${VERSION}.tar.bz2
mv gcc-${VERSION} gcc-${VERSION}.orig
CURRENTDIR=$(pwd -P)

# Get Current Updates from SVN
#
cd /usr/src
NUM1=$(echo ${VERSION} | cut -f1 -d.)
NUM2=$(echo ${VERSION} | cut -f2 -d.)
FIXEDVERSION=$(echo -n "$NUM1" ; echo -n "_" ; echo -e "$NUM2")
svn export svn://gcc.gnu.org/svn/gcc/branches/gcc-${FIXEDVERSION}-branch gcc-${VERSION}

# Cleanup
DIRS="gcc-${VERSION} gcc-${VERSION}.orig"
for DIRECTORY in ${DIRS}; do
  cd ${DIRECTORY}
  REMOVE="ABOUT-NLS COPYING COPYING.LIB ChangeLog ChangeLog.tree-ssa MAINTAINERS Makefile.def
    Makefile.in Makefile.tpl README README.SCO boehm-gc/ChangeLog BUGS FAQ LAST_UPDATED
    MD5SUMS NEWS bugs.html faq.html gcc/BASE-VER gcc/DATESTAMP gcc/DEV-PHASE gcc/c-parse.c
    gcc/gengtype-lex.c gcc/c-parse.y gcc/gengtype-yacc.c gcc/gengtype-yacc.h gcc/f/BUGS gcc/f/NEWS
    gcc/java/parse-scan.c gcc/java/parse.c gcc/objc/objc-parse.c gcc/objc/objc-parse.y"
  for file in ${REMOVE}; do
    rm -f $file
  done
  rm -rf INSTALL
  rm -f fastjar/*.{1,info} gcc/doc/*.{1,info,7} gcc/fortran/*.{1,info,7}
  rm -f gcc/po/*.{gmo,po}  libcpp/po/*.{gmo,po} libgomp/*.{1,info,7}
  cd .. 
done

# Create Patch
#
cd /usr/src
echo "Submitted By: Jim Gifford (jim at cross-lfs dot org)" > gcc-${VERSION}-branch_update-x.patch
echo "Date: `date +%m-%d-%Y`" >> gcc-${VERSION}-branch_update-x.patch
echo "Initial Package Version: ${VERSION}" >> gcc-${VERSION}-branch_update-x.patch
echo "Origin: Upstream" >> gcc-${VERSION}-branch_update-x.patch
echo "Upstream Status: Applied" >> gcc-${VERSION}-branch_update-x.patch
echo "Description: This is a branch update for gcc-${VERSION}, and should be" >> gcc-${VERSION}-branch_update-x.patch
echo "             rechecked periodically." >> gcc-${VERSION}-branch_update-x.patch
echo "" >> gcc-${VERSION}-branch_update-x.patch
diff -Naur gcc-${VERSION}.orig gcc-${VERSION} >> gcc-${VERSION}-branch_update-x.patch
echo "Created /usr/src/gcc-${VERSION}-branch_update-x.patch."
