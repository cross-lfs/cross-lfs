#!/bin/bash
# Create a Binutils Tarball

# Get Version #
#
VERSION=$1

# Check Input
#
if [ "${VERSION}" = "" ]; then
  echo "$0 - Binutils_Version"
  echo "This will Create a Tarball for Binutils Binutils_Version"
  echo "Example $0 2.19.51"
  exit 255
fi

# Clear out old Directory
#
rm -rf ~/tmp

# Set Patch Directory
#
PATCH_DIR=$(pwd -P)/binutils

# Get Current binutils from SVN
#
install -d ~/tmp
cd ~/tmp
echo "Pulling latest Binutils trunk from CVS..."
cvs -z 9 -d :pserver:anoncvs@sourceware.org:/cvs/src export -rHEAD binutils

# Set Patch Number
#
cd ~/tmp
wget http://svn.cross-lfs.org/svn/repos/patches/binutils/ --no-remove-listing
for num in $(seq 1 99); do
  PATCH_NUM=$(cat index.html | grep "${VERSION}" | grep fixes-${num}.patch | cut -f2 -d'"' | cut -f1 -d'"'| cut -f4 -d- | cut -f1 -d. | tail -n 1)
  if [ "${PATCH_NUM}" = "0" -a "${num}" = "1" ]; then
    PATCH_NUM=$(expr ${PATCH_NUM} + 1)
    break
  fi
  if [ "${PATCH_NUM}" != "${num}" ]; then
    PATCH_NUM=$(expr ${num})
    break
  fi
done
rm -f index.html

# Customize the version string, so we know it's patched
#
cd ~/tmp
mv src binutils-${VERSION}
DL_DATE=$(date +%Y%m%d)
cd ~/tmp/binutils-${VERSION}
sed -i "s:@PKGVERSION@:(GNU Binutils for Cross-LFS - Retrieved on ${DL_DATE}) :" bfd/Makefile.in

# Remove Files not needed
#
cd ~/tmp/binutils-${VERSION}
FILE_LIST=".cvsignore"
for files in ${FILE_LIST}; do
  REMOVE=$(find * -name ${files})
  for file in $REMOVE; do
    rm -f ${file}
  done
done

# Create a copy of the Original Directory So We can do some Updates
#
cd ~/tmp
cp -ar binutils-${VERSION} binutils-${VERSION}.orig

# Apply Patches from directories
#
cd ~/tmp/binutils-${VERSION}
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
  cd ~/tmp/binutils-${VERSION}
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
cd ~/tmp/binutils-${VERSION}
rm -rf *.orig *~ *.rej

# Create Patch
#
diff -Naur ~/tmp/binutils-${VERSION} ~/tmp/binutils-${VERSION}.orig >>  ~/public_html/binutils-${VERSION}-fixes-${PATCH_NUM}.patch
if [ "$(cat ~/public_html/binutils-${VERSION}-fixes-${PATCH_NUM}.patch)" != "" ]; then
  cd ~/tmp/binutils-${VERSION}
  install -d ~/public_html/
  echo "Submitted By: Jim Gifford (jim at cross-lfs dot org)" >  ~/public_html/binutils-${VERSION}-fixes-${PATCH_NUM}.patch
  echo "Date: `date +%m-%d-%Y`" >>  ~/public_html/binutils-${VERSION}-fixes-${PATCH_NUM}.patch
  echo "Initial Package Version: ${VERSION}" >>  ~/public_html/binutils-${VERSION}-fixes-${PATCH_NUM}.patch
  echo "Origin: Upstream" >>  ~/public_html/binutils-${VERSION}-fixes-${PATCH_NUM}.patch
  echo "Upstream Status: Applied" >>  ~/public_html/binutils-${VERSION}-fixes-${PATCH_NUM}.patch
  echo "Description: These are fixes binutils-${VERSION}, and should be" >>  ~/public_html/binutils-${VERSION}-fixes-${PATCH_NUM}.patch
  echo "             rechecked periodically." >>  ~/public_html/binutils-${VERSION}-fixes-${PATCH_NUM}.patch
  echo "" >>  ~/public_html/binutils-${VERSION}-fixes-${PATCH_NUM}.patch
  diff -Naur ~/tmp/binutils-${VERSION} ~/tmp/binutils-${VERSION}.orig >>  ~/public_html/binutils-${VERSION}-fixes-${PATCH_NUM}.patch
  echo "Created  ~/public_html/binutils-${VERSION}-fixes-${PATCH_NUM}.patch."
else
  rm ~/public_html/binutils-${VERSION}-fixes-${PATCH_NUM}.patch
fi

# Remove Patched Copy
#
cd ~/tmp
rm -rf binutils-${VERSION}
mv binutils-${VERSION}.orig binutils-${VERSION}

# Compress
#
cd ~/tmp
install -d ~/packages
echo "Creating Tarball for Binutils ${VERSION}...."
tar cjf ~/packages/binutils-${VERSION}-${DL_DATE}.tar.bz2 binutils-${VERSION}

# Clean up Directores
#
cd ~/tmp
rm -rf binutils-${VERSION}
