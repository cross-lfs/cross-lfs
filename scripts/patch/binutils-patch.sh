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
install -d ~/tmp
cd ~/tmp
if ! [ -e binutils-${SOURCEVERSION}.tar.bz2  ]; then
  wget ftp://ftp.gnu.org/gnu/binutils/binutils-${SOURCEVERSION}.tar.bz2
fi

# Set Patch Number
#
cd ~/tmp
wget http://svn.cross-lfs.org/svn/repos/cross-lfs/trunk/patches/ --no-remove-listing
PATCH_NUM=$(cat index.html | grep binutils | grep "${SOURCEVERSION}" | grep branch_update | cut -f2 -d'"' | cut -f1 -d'"'| cut -f4 -d- | cut -f1 -d. | tail -n 1)
PATCH_NUM=$(expr ${PATCH_NUM} + 1)
PATCH_NUM2=$(cat index.html | grep binutils | grep "${SOURCEVERSION}" | grep fixes | cut -f2 -d'"' | cut -f1 -d'"'| cut -f4 -d- | cut -f1 -d. | tail -n 1)
PATCH_NUM2=$(expr ${PATCH_NUM2} + 1)
rm -f index.html

# Cleanup Directory
#
cd ~/tmp
rm -rf binutils-${SOURCEVERSION} binutils-${SOURCEVERSION}.orig
tar xvf binutils-${SOURCEVERSION}.tar.bz2

# Get Current Updates from CVS
#
cd ~/tmp
mv binutils-${SOURCEVERSION} binutils-${SOURCEVERSION}.orig
CURRENTDIR=$(pwd -P)
FIXEDVERSION=$(echo ${VERSION} | sed -e 's/\./_/g')
cvs -z 9 -d :pserver:anoncvs@sourceware.org:/cvs/src export -rbinutils-${FIXEDVERSION}-branch binutils
mv src binutils-${SOURCEVERSION}

# Cleanup
#
cd ~/tmp
DIRS="binutils-${SOURCEVERSION} binutils-${SOURCEVERSION}.orig"
for DIRECTORY in ${DIRS}; do
  cd ~/tmp/${DIRECTORY}
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
cd ~/tmp/binutils-${SOURCEVERSION}
rm -f ~/tmp/binutils-${SOURCEVERSION}.orig/md5.sum

# Make Binutils a Release
#
cd ~/tmp/binutils-${SOURCEVERSION}
sed -i 's/# RELEASE=y/RELEASE=y/g' bfd/Makefile.am
sed -i 's/# RELEASE=y/RELEASE=y/g' bfd/Makefile.in

# Customize the version string, so we know it's patched
#
cd ~/tmp/binutils-${SOURCEVERSION}
DATE_STAMP=$(date +%Y%m%d)
cd ~/tmp/binutils-${SOURCEVERSION}
sed -i "s:@PKGVERSION@:(GNU Binutils for Cross-LFS - Retrieved on ${DATE_STAMP}) :" bfd/Makefile.in

# Create Patch
#
cd ~/tmp
install -d ~/patches
echo "Submitted By: Jim Gifford (jim at cross-lfs dot org)" > ~/patches/binutils-${SOURCEVERSION}-branch_update-${PATCH_NUM}.patch
echo "Date: `date +%m-%d-%Y`" >>  ~/patches/binutils-${SOURCEVERSION}-branch_update-${PATCH_NUM}.patch
echo "Initial Package Version: ${SOURCEVERSION}" >>  ~/patches/binutils-${SOURCEVERSION}-branch_update-${PATCH_NUM}.patch
echo "Origin: Upstream" >>  ~/patches/binutils-${SOURCEVERSION}-branch_update-${PATCH_NUM}.patch
echo "Upstream Status: Applied" >>  ~/patches/binutils-${SOURCEVERSION}-branch_update-${PATCH_NUM}.patch
echo "Description: This is a branch update for binutils-${SOURCEVERSION}, and should be" >>  ~/patches/binutils-${SOURCEVERSION}-branch_update-${PATCH_NUM}.patch
echo "             rechecked periodically." >>  ~/patches/binutils-${SOURCEVERSION}-branch_update-${PATCH_NUM}.patch
echo "" >>  ~/patches/binutils-${SOURCEVERSION}-branch_update-${PATCH_NUM}.patch
echo "This patch was created on ${DATE_STAMP}" >>  ~/patches/binutils-${SOURCEVERSION}-branch_update-${PATCH_NUM}.patch
echo "" >>  ~/patches/binutils-${SOURCEVERSION}-branch_update-${PATCH_NUM}.patch
diff -Naur binutils-${SOURCEVERSION}.orig binutils-${SOURCEVERSION} >>  ~/patches/binutils-${SOURCEVERSION}-branch_update-${PATCH_NUM}.patch
echo "Created ~/patches/binutils-${SOURCEVERSION}-branch_update-${PATCH_NUM}.patch."

# Cleanliness is the name of my game!
#
unset DATE_STAMP

# Create Another Copy to create fixes patch
#
cd ~/tmp
if [ -e ${PATCH_DIR}/${VERSION} ]; then
  rm -rf binutils-${SOURCEVERSION}.orig
  cp -ar binutils-${SOURCEVERSION} binutils-${SOURCEVERSION}.orig

  # Apply Patches from directories
  #
  cd ~/tmp/binutils-${SOURCEVERSION}
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
  cd ~/tmp/binutils-${SOURCEVERSION}
  rm -f $(find * -name "*~")
  rm -f $(find * -name "*.orig")
  rm -f $(find * -name "*.rej")
  rm -f *.orig *~ *.rej

  # Create Patch
  #
  cd ~/tmp
  install -d ~/patches
  echo "Submitted By: Jim Gifford (jim at cross-lfs dot org)" > ~/patches/binutils-${SOURCEVERSION}-fixes-${PATCH_NUM2}.patch
  echo "Date: `date +%m-%d-%Y`" >> ~/patches/binutils-${SOURCEVERSION}-fixes-${PATCH_NUM2}.patch
  echo "Initial Package Version: ${VERSION}" >> ~/patches/binutils-${SOURCEVERSION}-fixes-${PATCH_NUM2}.patch
  echo "Origin: Upstream" >> ~/patches/binutils-${SOURCEVERSION}-fixes-${PATCH_NUM2}.patch
  echo "Upstream Status: Applied" >> ~/patches/binutils-${SOURCEVERSION}-fixes-${PATCH_NUM2}.patch
  echo "Description: This Patch contains fixes for binutils-${SOURCEVERSION}, and should be" >> ~/patches/binutils-${SOURCEVERSION}-fixes-${PATCH_NUM2}.patch
  echo "             rechecked periodically." >> ~/patches/binutils-${SOURCEVERSION}-fixes-${PATCH_NUM2}.patch
  echo "" >> ~/patches/binutils-${SOURCEVERSION}-fixes-${PATCH_NUM2}.patch
  diff -Naur binutils-${SOURCEVERSION}.orig binutils-${SOURCEVERSION} >> ~/patches/binutils-${SOURCEVERSION}-fixes-${PATCH_NUM2}.patch
  echo "Created ~/patches/binutils-${SOURCEVERSION}-fixes-${PATCH_NUM2}.patch."
fi

# Cleanup Directory
#
cd ~/tmp
rm -rf binutils-${SOURCEVERSION} binutils-${SOURCEVERSION}.orig
