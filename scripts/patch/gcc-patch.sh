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
install -d ~/tmp
cd ~/tmp
if ! [ -e gcc-${VERSION}.tar.bz2  ]; then
  wget ftp://gcc.gnu.org/pub/gcc/releases/gcc-${VERSION}/gcc-${VERSION}.tar.bz2
fi

# Set Patch Number
#
cd ~/tmp
wget http://svn.cross-lfs.org/svn/repos/patches/gcc/ --no-remove-listing
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
for num in $(seq 1 99); do
  PATCH_NUM2=$(cat index.html | grep "${SOURCEVERSION}" | grep fixes-${num}.patch | cut -f2 -d'"' | cut -f1 -d'"'| cut -f4 -d- | cut -f1 -d. | tail -n 1)
  if [ "${PATCH_NUM2}" = "0" -a "${num}" = "1" ]; then
    PATCH_NUM2=$(expr ${PATCH_NUM2} + 1)
    break
  fi
  if [ "${PATCH_NUM2}" != "${num}" ]; then
    PATCH_NUM2=$(expr ${num})
    break
  fi
done
rm -f index.html

# Cleanup Directory
#
cd ~/tmp
rm -rf gcc-${VERSION} gcc-${VERSION}.orig
tar xvf gcc-${VERSION}.tar.bz2
mv gcc-${VERSION} gcc-${VERSION}.orig

# Get Current Updates from SVN
#
cd ~/tmp
NUM1=$(echo ${VERSION} | cut -f1 -d.)
NUM2=$(echo ${VERSION} | cut -f2 -d.)
FIXEDVERSION=$(echo -n "$NUM1" ; echo -n "_" ; echo -e "$NUM2")
REVISION=$(svn info svn://gcc.gnu.org/svn/gcc/branches/gcc-${FIXEDVERSION}-branch | grep "Last Changed Rev" | cut -f2 -d: | sed -e 's/ //g')
svn export svn://gcc.gnu.org/svn/gcc/branches/gcc-${FIXEDVERSION}-branch gcc-${VERSION}

# Add a custom version string
#
cd ~/tmp
DATE_STAMP=$(cat gcc-${VERSION}/gcc/DATESTAMP)
echo "${VERSION}" > gcc-${VERSION}/gcc/BASE-VER
sed -i "s:PKGVERSION:\"(GCC for Cross-LFS ${VERSION}.${DATE_STAMP}) \":" gcc-${VERSION}/gcc/version.c

# Cleanup
#
cd ~/tmp
DIRS="gcc-${VERSION} gcc-${VERSION}.orig"
for DIRECTORY in ${DIRS}; do
  cd ~/tmp/${DIRECTORY}
  REMOVE="ABOUT-NLS COPYING COPYING.LIB MAINTAINERS Makefile.def
    Makefile.in Makefile.tpl README README.SCO BUGS FAQ LAST_UPDATED
    MD5SUMS NEWS bugs.html faq.html gcc/BASE-VER gcc/DEV-PHASE
    gcc/f/BUGS gcc/f/NEWS gcc/gengtype-lex.c INSTALL/binaries.html
    INSTALL/build.html INSTALL/configure.html INSTALL/download.html
    INSTALL/finalinstall.html INSTALL/gfdl.html INSTALL/index.html
    INSTALL/old.html INSTALL/prerequisites.html INSTALL/specific.html
    INSTALL/test.html"
  for file in ${REMOVE}; do
    rm -f $file
  done
  for file in $(find . -name "ChangeLog*" | sed -e 's@./@@'); do
    rm -fv ${file}
  done
  REMVOVE_DIRS="INSTALL"
  for dir in ${REMOVE_DIRS}; do
    rm -rfv ${dir}
  done
  rm -fv fastjar/*.{1,info} gcc/doc/*.{1,info,7} gcc/fortran/*.{1,info,7} gcc/po/*.{gmo,po}
  rm -rf libcpp/po/*.{gmo,po} libgomp/*.{1,info,7} libjava/classpath/doc/*.{1,info}
 cd .. 
done

# Create Patch
#
cd ~/tmp
install -d ~/patches
echo "Submitted By: Jim Gifford (jim at cross-lfs dot org)" > ~/patches/gcc-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Date: `date +%m-%d-%Y`" >> ~/patches/gcc-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Initial Package Version: ${VERSION}" >> ~/patches/gcc-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Origin: Upstream" >> ~/patches/gcc-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Upstream Status: Applied" >> ~/patches/gcc-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Description: This is a branch update for gcc-${VERSION}, and should be" >> ~/patches/gcc-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "             rechecked periodically." >> ~/patches/gcc-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "" >> ~/patches/gcc-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "This patch was made from Revision # ${REVISION}." >> ~/patches/gcc-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "" >> ~/patches/gcc-${VERSION}-branch_update-${PATCH_NUM}.patch
diff -Naur gcc-${VERSION}.orig gcc-${VERSION} >> ~/patches/gcc-${VERSION}-branch_update-${PATCH_NUM}.patch
echo "Created ~/patches/gcc-${VERSION}-branch_update-${PATCH_NUM}.patch."

# Create Another Copy to create fixes patch
#
cd ~/tmp
if [ -e ${PATCH_DIR}/${VERSION} ]; then
  rm -rf gcc-${VERSION}.orig
  cp -ar gcc-${VERSION} gcc-${VERSION}.orig

  # Apply Patches from directories
  #
  cd ~/tmp/gcc-${VERSION}
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

  # Cleanup Directory
  #
  cd ~/tmp/gcc-${VERSION}
  rm -f $(find * -name "*~")
  rm -f $(find * -name "*.orig")
  rm -f $(find * -name "*.rej")
  rm -f *.orig *~ *.rej

  # Create Patch
  #
  cd ~/tmp
  install -d ~/patches
  echo "Submitted By: Jim Gifford (jim at cross-lfs dot org)" > ~/patches/gcc-${VERSION}-fixes-${PATCH_NUM2}.patch
  echo "Date: `date +%m-%d-%Y`" >> ~/patches/gcc-${VERSION}-fixes-${PATCH_NUM2}.patch
  echo "Initial Package Version: ${VERSION}" >> ~/patches/gcc-${VERSION}-fixes-${PATCH_NUM2}.patch
  echo "Origin: Upstream" >> ~/patches/gcc-${VERSION}-fixes-${PATCH_NUM2}.patch
  echo "Upstream Status: Applied" >> ~/patches/gcc-${VERSION}-fixes-${PATCH_NUM2}.patch
  echo "Description: This Patch contains fixes for gcc-${VERSION}, and should be" >> ~/patches/gcc-${VERSION}-fixes-${PATCH_NUM2}.patch
  echo "             rechecked periodically. These patches are not for inclusion in the book" >> ~/patches/gcc-${VERSION}-fixes-${PATCH_NUM2}.patch
  echo "             but for testing purposes only. " >> ~/patches/gcc-${VERSION}-fixes-${PATCH_NUM2}.patch
  echo "" >> ~/patches/gcc-${VERSION}-fixes-${PATCH_NUM2}.patch
  diff -Naur gcc-${VERSION}.orig gcc-${VERSION} >> ~/patches/gcc-${VERSION}-fixes-${PATCH_NUM2}.patch
  echo "Created ~/patches/gcc-${VERSION}-fixes-${PATCH_NUM2}.patch."
fi

# Cleanup Directory
#
cd ~/tmp
rm -rf gcc-${VERSION} gcc-${VERSION}.orig
