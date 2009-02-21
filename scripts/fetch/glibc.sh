#!/bin/bash
# Written By: Joe Ciccone <jciccone at gmail dot com>

# Usage, glibc.sh [cvs-tag] [tarball-version]
# An example of a CVS tag would be HEAD or glibc-2_9
# An example of a tarball version would be say the date, or 2.9, it will be
#   inserted into the output tarbal filename,
#   eg, glibc-[tarball-version].tar.bz2

CVStag=${1-HEAD}
TARver=${2-$(date +%Y%m%d)}

echo "Creating glibc-${TARver}.tar.bz2 and glibc-ports-${TARver}.tar.bz2 from the ${CVStag} CVS Tag."

tmpdir="$(mktemp -d)"
if test ! -d "${tmpdir}"; then
  tmpdir="/tmp/glibc-XXXX"
  mkdir -pv "${tmpdir}"
fi

if test ! -d "${tmpdir}"; then
  echo "Failed to create temp directory: ${tmpdir}"
  exit 1
fi

echo "Use \"anoncvs\" for the password."
cvs -z 9 -d :pserver:anoncvs@sources.redhat.com:/cvs/glibc login
if test $? -ne 0; then
  echo "Failed to login to glibc cvs server."
  rm -rf "${tmpdir}"
  exit 1
fi

pushd "${tmpdir}"

# Checkout from the cvs glibc
cvs -z 9 -d :pserver:anoncvs@sources.redhat.com:/cvs/glibc co -r "${CVStag}" libc 
mv libc "glibc-${TARver}"
if test $? -ne 0; then
  echo "Failed to check out libc, Leaving temp files in ${tmpdir}."
  exit 1
fi

# Checkout from the cvs glibc
cvs -z 9 -d :pserver:anoncvs@sources.redhat.com:/cvs/glibc co -r "${CVStag}" ports
mv ports "glibc-ports-${TARver}"
if test $? -ne 0; then
  echo "Failed to check out libc, Leaving temp files in ${tmpdir}."
  exit 1
fi

# If the timestamp of configure.in is newer the configure glibc will try to
# reconfigure itself, this can cause some errors while cross-compiling.
find "glibc-${TARver}" "glibc-ports-${TARver}" -name configure | xargs touch

# Clean out CVS Files
find "glibc-${TARver}" "glibc-ports-${TARver}" -name CVS -type d | xargs rm -rf
find "glibc-${TARver}" "glibc-ports-${TARver}" -name .cvsignore | xargs rm -rf

# Add a custom version string
DATE_STAMP=$(date +%Y%m%d)
sed -i "s@Copyright (C)@Built for Cross-LFS - ${DATE_STAMP}\\n\Copyright (C)@" csu/version.c

# Create tarballs
echo "Creating Tarballs"
tar cvjf "glibc-${TARver}.tar.bz2" "glibc-${TARver}"
tar cvjf "glibc-ports-${TARver}.tar.bz2" "glibc-ports-${TARver}"

# echo Pop back to the orig working directory and mv the tarballs over

popd
mv "${tmpdir}/glibc-${TARver}.tar.bz2" .
mv "${tmpdir}/glibc-ports-${TARver}.tar.bz2" .

rm -rf "${tmpdir}"
