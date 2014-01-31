#!/bin/bash
# Create a Perl Patch

# Get Version #
#
VERSION=$1

# Check Input
#
if [ "${VERSION}" = "" ]; then
  echo "$0 - Perl_Version"
  echo "This will Create a Patch for Perl Perl_Version"
  exit 255
fi

# Download Perl Source
#
cd /usr/src
if ! [ -e perl-${VERSION}.tar.bz2  ]; then
  wget http://www.cpan.org/src/perl-${VERSION}.tar.bz2
fi

# Set Patch Number
#
cd /usr/src
wget http://svn.cross-lfs.org/svn/repos/patches/perl/ --no-remove-listing
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
rm -f index.html

# Cleanup Directory
#
rm -rf perl-${VERSION} perl-${VERSION}.orig
tar xvf perl-${VERSION}.tar.bz2
mv perl-${VERSION} perl-${VERSION}.orig
CURRENTDIR=$(pwd -P)

# Get Current Updates from GIT
#
cd /usr/src
mkdir perl.git
cd perl.git
git clone git://perl5.git.perl.org/perl.git

# Cleanup
#
cd /usr/src/perl-${VERSION}
REMOVE=".patch AUTHORS Changes*"
for file in $REMOVE; do
  cd /usr/src/perl-${VERSION}
  rm -f ${file}
  cd /usr/src/perl-${VERSION}.orig
  rm -f ${file}
done
cd ..

# Remove Directories
#
cd /usr/src/perl-${VERSION}
REMOVE="os2 vms win32"
for dir in $REMOVE; do
  cd /usr/src/perl-${VERSION}
  rm -rf ${dir}
  cd /usr/src/perl-${VERSION}.orig
  rm -rf ${dir}
done
cd ..

# Create Patch
#
cd /usr/src
echo "Submitted By: Jim Gifford (jim at cross-lfs dot org)" > perl-${VERSION}-branch_update-x.patch
echo "Date: `date +%m-%d-%Y`" >> perl-${VERSION}-branch_update-x.patch
echo "Initial Package Version: ${VERSION}" >> perl-${VERSION}-branch_update-x.patch
echo "Origin: Upstream" >> perl-${VERSION}-branch_update-x.patch
echo "Upstream Status: Applied" >> perl-${VERSION}-branch_update-x.patch
echo "Description: This is a branch update for perl-${VERSION}, and should be" >> perl-${VERSION}-branch_update-x.patch
echo "             rechecked periodically." >> perl-${VERSION}-branch_update-x.patch
echo "" >> perl-${VERSION}-branch_update-x.patch
diff -Naur perl-${VERSION}.orig perl-${VERSION} >> perl-${VERSION}-branch_update-x.patch
echo "Created /usr/src/perl-${VERSION}-branch_update-x.patch."
