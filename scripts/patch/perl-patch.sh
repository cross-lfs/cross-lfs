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
if ! [ -e perl-${VERSION}.tar.gz  ]; then
  wget http://www.cpan.org/src/perl-${VERSION}.tar.gz
fi

# Cleanup Directory
#
rm -rf perl-${VERSION} perl-${VERSION}.orig
tar xvf perl-${VERSION}.tar.gz
mv perl-${VERSION} perl-${VERSION}.orig
CURRENTDIR=$(pwd -P)

# Get Current Updates from CVS
#
cd /usr/src
FIXEDVERSION=$(echo ${VERSION} | sed -e 's ..$  ')
rsync -avz rsync://perl5.git.perl.org/APC/perl-${FIXEDVERSION}.x perl-${VERSION}

# Cleanup
#
DIRS="perl-${VERSION} perl-${VERSION}.orig"
for DIRECTORY in ${DIRS}; do
  cd /usr/src/${DIRECTORY}
  FILE_LIST=".patch"
  for files in ${FILE_LIST}; do
    REMOVE=$(find * -name ${files})
    for file in $REMOVE; do
      rm -f ${file}
    done
  done

  REMOVE="Changes Changes5.10 Changes5.8"
  for file in $REMOVE; do
    rm -f ${file}
    done
    cd ..
done

# Cleanup Directory
#
for dir in $(find * -type d); do
  cd /usr/src/perl-${VERSION}
  for file in $(find . -name '*~'); do
    rm -f ${file}
  done
  for file in $(find . -name '*.orig'); do
    rm -f ${file}
  done
done
cd /usr/src/perl-${VERSION}
rm -f *~ *.orig
rm -f /usr/src/perl-${VERSION}.orig/md5.sum

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
