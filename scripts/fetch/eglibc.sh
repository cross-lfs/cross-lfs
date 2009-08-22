#!/bin/bash
# Create a Eglibc Tarball

# Get Version #
#
VERSION=$1
SOURCEVERSION=$2

# Check Input
#
if [ "${VERSION}" = "" -o "${SOURCEVERSION}" = "" ]; then
  echo "$0 - Eglibc_Version"
  echo "This will Create a Tarball for Eglibc Eglibc_Series Eglibc_Version"
  echo "Example $0 2.19 2.19.1"
  exit 255
fi

# Clear out old Directory
#
rm -rf ~/tmp

# Set Patch Directory
#
PATCH_DIR=$(pwd -P)/eglibc

# Get Current Eglibc from SVN
#
install -d ~/tmp
cd ~/tmp
FIXEDVERSION=$(echo ${VERSION} | sed -e 's/\./_/g')
DL_REVISION=$(svn info svn://svn.eglibc.org/branches/eglibc-${FIXEDVERSION} | grep "Last Changed Rev" | cut -f2 -d: | sed -e 's/ //g')
echo "Retreiving Revision #${DL_REVISION} from SVN eglibc-${SOURCEVERSION}..."
svn export -r ${DL_REVISION} svn://svn.eglibc.org/branches/eglibc-${FIXEDVERSION} eglibc-${SOURCEVERSION}

# Set Patch Number
#
cd ~/tmp
wget http://svn.cross-lfs.org/svn/repos/patches/eglibc/ --no-remove-listing
for num in $(seq 1 99); do
  PATCH_NUM=$(cat index.html | grep "${SOURCEVERSION}" | grep fixes-${num}.patch | cut -f2 -d'"' | cut -f1 -d'"'| cut -f4 -d- | cut -f1 -d. | tail -n 1)
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
install -d ~/tmp/eglibc-${SOURCEVERSION}
cd ~/tmp/eglibc-${SOURCEVERSION}
DL_DATE=$(date +%Y%m%d)
echo "#define DL_DATE \"${DL_DATE}\"" >> libc/version.h
echo "#define DL_REVISION \"${DL_REVISION}\"" >> libc/version.h
sed -i "s@Compiled by GNU CC version@Built for Cross-LFS.\\\\n\\\\\nRetrieved on \"DL_DATE\".\\\\n\\\\\\nCompiled by GNU CC version@" libc/csu/version.c
sed -i "s@Compiled by GNU CC version@Revision # \"DL_REVISION\".\\\\n\\\\\\nCompiled by GNU CC version@" libc/csu/version.c
sed -i "s@static const char __libc_release@static const char __libc_dl_date[] = DL_DATE;\nstatic const char __libc_release@" libc/csu/version.c
sed -i "s@static const char __libc_release@static const char __libc_dl_revision[] = DL_REVISION;\nstatic const char __libc_release@" libc/csu/version.c

# Remove Files not needed
#
cd ~/tmp/eglibc-${SOURCEVERSION}
FILE_LIST=".cvsignore"
for files in ${FILE_LIST}; do
  REMOVE=$(find * -name ${files})
  for file in $REMOVE; do
    rm -f ${file}
  done
done

# Fix configuration files
#
cd ~/tmp/eglibc-${SOURCEVERSION}
echo "Updating Glibc configure files..."
find . -name configure -exec touch {} \;

# Create a copy of the Original Directory So We can do some Updates
#
cd ~/tmp/eglibc-${SOURCEVERSION}
cp -ar libc libc.orig

# Change gcc to BUILD_CC in the following files
#
cd ~/tmp/eglibc-${SOURCEVERSION}/libc
FIX_FILES="sunrpc/Makefile timezone/Makefile"
for fix_file in ${FIX_FILES}; do
  sed -i 's/gcc/\$\(BUILD_CC\)/g' ${fix_file}
done

# Make testsuite fixes
#
cd ~/tmp/eglibc-${SOURCEVERSION}/libc
sed -i 's|@BASH@|/bin/bash|' elf/ldd.bash.in
sed -i s/utf8/UTF-8/ libio/tst-fgetwc.c
sed -i '/tst-fgetws-ENV/ a\
tst-fgetwc-ENV = LOCPATH=$(common-objpfx)localedata' libio/Makefile

# Apply Patches from directories
#
cd ~/tmp/eglibc-${SOURCEVERSION}/libc
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
  cd ~/tmp/eglibc-${SOURCEVERSION}/libc
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
cd ~/tmp/eglibc-${SOURCEVERSION}/libc
rm -rf *.orig *~ *.rej

# Create Patch
#
cd ~/tmp/eglibc-${SOURCEVERSION}
install -d ~/patches/
diff -Naur libc.orig libc >> ~/patches/eglibc-${SOURCEVERSION}-fixes-${PATCH_NUM}.patch
if [ -e ~/patches/eglibc-${SOURCEVERSION}-fixes-${PATCH_NUM}.patch ]; then
  echo "Submitted By: Jim Gifford (jim at cross-lfs dot org)" > ~/patches/eglibc-${SOURCEVERSION}-fixes-${PATCH_NUM}.patch
  echo "Date: `date +%m-%d-%Y`" >>  ~/patches/eglibc-${SOURCEVERSION}-fixes-${PATCH_NUM}.patch
  echo "Initial Package Version: ${SOURCEVERSION}" >>  ~/patches/eglibc-${SOURCEVERSION}-fixes-${PATCH_NUM}.patch
  echo "Origin: Upstream" >>  ~/patches/eglibc-${SOURCEVERSION}-fixes-${PATCH_NUM}.patch
  echo "Upstream Status: Applied" >>  ~/patches/eglibc-${SOURCEVERSION}-fixes-${PATCH_NUM}.patch
  echo "Description: These are fixes eglibc-${SOURCEVERSION}, and should be" >>  ~/patches/eglibc-${SOURCEVERSION}-fixes-${PATCH_NUM}.patch
  echo "             rechecked periodically." >>  ~/patches/eglibc-${SOURCEVERSION}-fixes-${PATCH_NUM}.patch
  echo "" >>  ~/patches/eglibc-${SOURCEVERSION}-fixes-${PATCH_NUM}.patch
  diff -Naur libc.orig libc >>  ~/patches/eglibc-${SOURCEVERSION}-fixes-${PATCH_NUM}.patch
  echo "Created  ~/patches/eglibc-${SOURCEVERSION}-fixes-${PATCH_NUM}.patch."
else
  rm -f ~/patches/eglibc-${SOURCEVERSION}-fixes-${PATCH_NUM}.patch
fi

# Remove Patched Copy
#
cd ~/tmp/eglibc-${SOURCEVERSION}
rm -rf libc
mv libc.orig libc

# Compress
#
cd ~/tmp/eglibc-${SOURCEVERSION}
install -d ~/packages
echo "Creating Tarball for Eglibc Ports ${SOURCEVERSION}...."
tar cjf ~/packages/eglibc-ports-${SOURCEVERSION}-${DL_DATE}-r${DL_REVISION}.tar.bz2 ports
rm -rf ports
echo "Creating Tarball for Eglibc Linuxthreads ${SOURCEVERSION}...."
tar cjf ~/packages/eglibc-linuxthreads-${SOURCEVERSION}-${DL_DATE}-r${DL_REVISION}.tar.bz2 linuxthreads
rm -rf linuxthreads
echo "Creating Tarball for Eglibc LocaleDef ${SOURCEVERSION}...."
tar cjf ~/packages/eglibc-localedef-${SOURCEVERSION}-${DL_DATE}-r${DL_REVISION}.tar.bz2 localedef
rm -rf localedef
mv libc eglibc-${SOURCEVERSION}
echo "Creating Tarball for Eglibc ${SOURCEVERSION}...."
tar cjf ~/packages/eglibc-${SOURCEVERSION}-${DL_DATE}-r${DL_REVISION}.tar.bz2 eglibc-${SOURCEVERSION}

# Clean up Directores
#
cd ~/tmp
rm -rf eglibc-${SOURCEVERSION}

# Display Created Files
#
echo "Tarballs:"
echo "~/packages/eglibc-${SOURCEVERSION}-${DL_DATE}-r${DL_REVISION}.tar.bz2"
echo "~/packages/eglibc-ports-${SOURCEVERSION}-${DL_DATE}-r${DL_REVISION}.tar.bz2"
echo "~/packages/eglibc-linuxthreads-${SOURCEVERSION}-${DL_DATE}-r${DL_REVISION}.tar.bz2"
echo "~/packages/eglibc-localedef-${SOURCEVERSION}-${DL_DATE}-r${DL_REVISION}.tar.bz2"
if [ -e ~/patches/eglibc-${SOURCEVERSION}-fixes-${PATCH_NUM}.patch ]; then
  echo "Patches:"
  echo "~/patches/eglibc-${SOURCEVERSION}-fixes-${PATCH_NUM}.patch"
  echo
fi
