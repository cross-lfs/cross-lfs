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

# Set Patch Directory
#
PATCH_DIR=$(pwd -P)/gcc

# Download GCC Source
#
cd /usr/src
if ! [ -e gcc-${VERSION}.tar.bz2  ]; then
  wget ftp://gcc.gnu.org/pub/gcc/releases/gcc-${VERSION}/gcc-${VERSION}.tar.bz2
fi

# Set Patch Number
#
cd /usr/src
wget http://svn.cross-lfs.org/svn/repos/cross-lfs/trunk/patches/ --no-remove-listing > /dev/null 2>&1
PATCH_NUM=$(cat index.html | grep gcc | grep "${VERSION}" | grep branch_update | cut -f2 -d'"' | cut -f1 -d'"'| cut -f4 -d- | cut -f1 -d. | tail -n 1)
PATCH_NUM=$(expr ${PATCH_NUM} + 1)
PATCH_NUM2=$(cat index.html | grep gcc | grep "${VERSION}" | grep fixes | cut -f2 -d'"' | cut -f1 -d'"'| cut -f4 -d- | cut -f1 -d. | tail -n 1)
PATCH_NUM2=$(expr ${PATCH_NUM2} + 1)
rm -f index.html

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
REVISION=$(svn info svn://gcc.gnu.org/svn/gcc/branches/gcc-${FIXEDVERSION}-branch | grep "Last Changed Rev" | cut -f2 -d: | sed -e 's/ //g')
svn export svn://gcc.gnu.org/svn/gcc/branches/gcc-${FIXEDVERSION}-branch gcc-${VERSION}

# Add a custom version string
#
DATE_STAMP=$(cat gcc-${VERSION}/gcc/DATESTAMP)
echo "${VERSION}" > gcc-${VERSION}/gcc/BASE-VER
sed -i "s:PKGVERSION:\"(GCC for Cross-LFS ${VERSION}.${DATE_STAMP}) \":" gcc-${VERSION}/gcc/version.c

# Cleanup
#
DIRS="gcc-${VERSION} gcc-${VERSION}.orig"
for DIRECTORY in ${DIRS}; do
  cd ${DIRECTORY}
  REMOVE="ABOUT-NLS COPYING COPYING.LIB MAINTAINERS Makefile.def
    Makefile.in Makefile.tpl README README.SCO BUGS FAQ LAST_UPDATED
    MD5SUMS NEWS bugs.html faq.html gcc/BASE-VER gcc/DEV-PHASE
    gcc/f/BUGS gcc/f/NEWS gcc/c-parse.c gcc/gengtype-lex.c gcc/c-parse.y
    gcc/gengtype-yacc.c gcc/gengtype-yacc.h gcc/java/parse-scan.c
    gcc/java/parse.c gcc/objc/objc-parse.c gcc/objc/objc-parse.y
    libjava/classpath/doc/cp-tools.info"
  for file in ${REMOVE}; do
    rm -f $file
  done
  for file in $(find . -name "ChangeLog*" | sed -e 's@./@@'); do
    rm -f ${file}
  done
  rm -rf INSTALL
  rm -f fastjar/*.{1,info} gcc/doc/*.{1,info,7} gcc/fortran/*.{1,info,7}
  rm -f gcc/po/*.{gmo,po}  libcpp/po/*.{gmo,po} libgomp/*.{1,info,7}
  rm -f libjava/classpath/doc/*.{1,info}
  cd .. 
done

# Create Patch
#
cd /usr/src
echo "Submitted By: Jim Gifford (jim at cross-lfs dot org)" > gcc-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Date: `date +%m-%d-%Y`" >> gcc-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Initial Package Version: ${VERSION}" >> gcc-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Origin: Upstream" >> gcc-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Upstream Status: Applied" >> gcc-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Description: This is a branch update for gcc-${VERSION}, and should be" >> gcc-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "             rechecked periodically." >> gcc-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "" >> gcc-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "This patch was made from Revision # ${REVISION}." >> gcc-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "" >> gcc-${VERSION}-branch_update-${PATCH_NUM}.patch
diff -Naur gcc-${VERSION}.orig gcc-${VERSION} >> gcc-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Created /usr/src/gcc-${VERSION}-branch_update-${PATCH_NUM}.patch."

# Create Another Copy to create fixes patch
#
cd /usr/src
rm -rf gcc-${VERSION}.orig
cp -ar gcc-${VERSION} gcc-${VERSION}.orig

# Apply Patches from directories
#
cd /usr/src/gcc-${VERSION}
if [ -e ${PATCH_DIR}/${VERSION} ]; then
  PATCH_FILES=$(ls ${PATCH_DIR}/${VERSION}/*.patch)
  if [ "${PATCH_FILES}" != "" ]; then
    for pfile in ${PATCH_FILES}; do
      echo "Applying - ${pfile}..."
      for pvalue in $(seq 0 5); do
        patch --dry-run -Np${pvalue} -i ${pfile} > /dev/null 2>&1
        if [ "${?}" = "0" ]; then
          PVALUE=${pvalue}
          break
        fi
      done
      if [ "${PVALUE}" != "" ]; then
        patch -Np${PVALUE} -i ${pfile}
      else
        echo "Patch: ${pfile} Failed to Apply..."
        exit 255
      fi
    done
  fi
fi

# Cleanup Directory
#

for dir in $(find * -type d); do
  cd /usr/src/gcc-${VERSION}/${dir}
  for file in $(find . -name '*~'); do
    rm -f ${file}
  done
  for file in $(find . -name '*.orig'); do
    rm -f ${file}
  done
  for file in $(find . -name '*.rej'); do
    rm -f ${file}
  done
done
cd /usr/src/gcc-${VERSION}/
rm -rf *.orig *~ *.rej

# Create Patch
#
cd /usr/src
echo "Submitted By: Jim Gifford (jim at cross-lfs dot org)" > gcc-${VERSION}-fixes-${PATCH_NUM2}.patch
echo "Date: `date +%m-%d-%Y`" >> gcc-${VERSION}-fixes-${PATCH_NUM2}.patch
echo "Initial Package Version: ${VERSION}" >> gcc-${VERSION}-fixes-${PATCH_NUM2}.patch
echo "Origin: Upstream" >> gcc-${VERSION}-fixes-${PATCH_NUM2}.patch
echo "Upstream Status: Applied" >> gcc-${VERSION}-fixes-${PATCH_NUM2}.patch
echo "Description: This Patch contains fixes for gcc-${VERSION}, and should be" >> gcc-${VERSION}-fixes-${PATCH_NUM2}.patch
echo "             rechecked periodically." >> gcc-${VERSION}-fixes-${PATCH_NUM2}.patch
echo "" >> gcc-${VERSION}-fixes-${PATCH_NUM2}.patch
diff -Naur gcc-${VERSION}.orig gcc-${VERSION} >> gcc-${VERSION}-fixes-${PATCH_NUM2}.patch
echo "Created /usr/src/gcc-${VERSION}-fixes-${PATCH_NUM2}.patch."
