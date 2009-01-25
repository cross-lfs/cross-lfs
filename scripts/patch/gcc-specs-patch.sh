#!/bin/bash
# Create a GCC Specs Patch

# Get Version #
#
VERSION=$1

# Check Input
#
if [ "${VERSION}" = "" ]; then
  echo "$0 - GCC_Version"
  echo "This will Create a Patch for GCC Specs GCC_Version"
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
cp -ar gcc-${VERSION} gcc-${VERSION}.orig
CURRENTDIR=$(pwd -P)

# Modify the Data
#
cd /usr/src/gcc-${VERSION}
for file in $(find gcc/config -name "*.h"); do
  if [ "$(echo ${file} | grep -c bsd)" = "0" ]; then
    if [ "$(cat ${file} | grep -c DYNAMIC_LINKER)" != "0" ]; then
      echo "Modifying ${file}..."
      sed -i '/DYNAMIC_LINKER/s@"/lib@"/tools/lib@' ${file}
    fi
    if [ "$(cat ${file} | grep -c DYNAMIC_LINKER)" != "0" ]; then
      echo "Modifying ${file}..."
      sed -i '/-dynamic-linker/s@ /lib@ /tools/lib@' ${file}
    fi
    if [ "$(cat ${file} | grep -c LINK_SPEC)" != "0" ]; then
      echo "Modifying ${file}..."
      sed -i -e '/elf64_sparc -Y P,/s@/usr/lib64@/tools/lib64@' \
        -e '/elf32_sparc -Y P,/s@/usr/lib@/tools/lib@' \
        -e '/-dynamic-linker/s@ /lib@ /tools/lib@' ${file}
    fi
  fi
done


# Create Patch
#
cd /usr/src
echo "Submitted By: Jim Gifford (jim at cross-lfs dot org)" > gcc-${VERSION}-specs-x.patch
echo "Date: `date +%m-%d-%Y`" >> gcc-${VERSION}-specs-x.patch
echo "Initial Package Version: ${VERSION}" >> gcc-${VERSION}-specs-x.patch
echo "Origin: Idea originally developed by Ryan Oliver and Greg Schafer for" >> gcc-${VERSION}-specs-x.patch
echo "        the Pure LFS project." >> gcc-${VERSION}-specs-x.patch
echo "Upstream Status: Not Applied" >> gcc-${VERSION}-specs-x.patch
echo "Description: This patch modifies the location of the dynamic linker for gcc-${VERSION}." >> gcc-${VERSION}-specs-x.patch
echo "" >> gcc-${VERSION}-specs-x.patch
diff -Naur gcc-${VERSION}.orig gcc-${VERSION} >> gcc-${VERSION}-specs-x.patch

# Cleanup Directory
#
rm -rf gcc-${VERSION} gcc-${VERSION}.orig
tar xvf gcc-${VERSION}.tar.bz2
cp -ar gcc-${VERSION} gcc-${VERSION}.orig
CURRENTDIR=$(pwd -P)

# Modify the Data
#
cd /usr/src/gcc-${VERSION}
for file in $(find gcc/config -name "*.h"); do
  if [ "$(echo ${file} | grep -c bsd)" = "0" ]; then
    if [ "$(cat ${file} | grep -c DYNAMIC_LINKER)" != "0" ]; then
      echo "Modifying ${file}..."
      sed -i -e '/DYNAMIC_LINKER32/s@"/lib@"/tools/lib32@' \
       -e '/DYNAMIC_LINKERN32/s@"/lib32@"/tools/lib64@' \
       -e '/DYNAMIC_LINKER64/s@"/lib64@"/tools/lib@' \
       -e '/DYNAMIC_LINKER/s@"/lib@"/tools/lib@' ${file}
    fi
    if [ "$(cat ${file} | grep -c DYNAMIC_LINKER)" != "0" ]; then
      echo "Modifying ${file}..."
      sed -i '/-dynamic-linker/s@ /lib@ /tools/lib@' ${file}
    fi
    if [ "$(cat ${file} | grep -c LINK_SPEC)" != "0" ]; then
      echo "Modifying ${file}..."
      sed -i -e '/elf64_sparc -Y P,/s@/usr/lib64@/tools/lib@' \
        -e '/elf32_sparc -Y P,/s@/usr/lib@/tools/lib32@' \
        -e '/-dynamic-linker/s@ /lib@ /tools/lib@' ${file}
    fi
  fi
done

# Create Patch
#
cd /usr/src
echo "Submitted By: Jim Gifford (jim at cross-lfs dot org)" > gcc-${VERSION}-pure64_specs-x.patch
echo "Date: `date +%m-%d-%Y`" >> gcc-${VERSION}-pure64_specs-x.patch
echo "Initial Package Version: ${VERSION}" >> gcc-${VERSION}-pure64_specs-x.patch
echo "Origin: Idea originally developed by Ryan Oliver and Greg Schafer for" >> gcc-${VERSION}-pure64_specs-x.patch
echo "        the Pure LFS project." >> gcc-${VERSION}-pure64_specs-x.patch
echo "Upstream Status: Not Applied" >> gcc-${VERSION}-pure64_specs-x.patch
echo "Description: This patch modifies the location of the dynamic linker for gcc-${VERSION}." >> gcc-${VERSION}-pure64_specs-x.patch
echo "" >> gcc-${VERSION}-pure64_specs-x.patch
diff -Naur gcc-${VERSION}.orig gcc-${VERSION} >> gcc-${VERSION}-pure64_specs-x.patch

# Cleanup Directory
#
rm -rf gcc-${VERSION} gcc-${VERSION}.orig
tar xvf gcc-${VERSION}.tar.bz2
cp -ar gcc-${VERSION} gcc-${VERSION}.orig
CURRENTDIR=$(pwd -P)

# Modify the Data
#
cd /usr/src/gcc-${VERSION}
for file in $(find gcc/config -name "*.h"); do
  if [ "$(echo ${file} | grep -c bsd)" = "0" ]; then
    if [ "$(cat ${file} | grep -c DYNAMIC_LINKER)" != "0" ]; then
      echo "Modifying ${file}..."
      sed -i -e '/DYNAMIC_LINKER32/s@"/lib@"/lib32@' \
       -e '/DYNAMIC_LINKERN32/s@"/lib32@"/lib64@' \
       -e '/DYNAMIC_LINKER64/s@"/lib64@"/lib@' \
       -e '/DYNAMIC_LINKER/s@"/lib@"/lib@' ${file}
    fi
    if [ "$(cat ${file} | grep -c LINK_SPEC)" != "0" ]; then
      echo "Modifying ${file}..."
      sed -i -e '/elf64_sparc -Y P,/s@/usr/lib64@/usr/lib@' \
        -e '/elf32_sparc -Y P,/s@/usr/lib@/usr/lib32@' ${file}
    fi
  fi
done

for file in $(find gcc/config -name "t-linux*"); do
  if [ "$(cat ${file} | grep -c MULTILIB_OSDIRNAMES)" != "0" ]; then
    echo "Modifying ${file}..."
    if [ "$(echo ${file} | grep -c mips)" != "0" ]; then
      sed -i -e 's@MULTILIB_OSDIRNAMES = ../lib32 ../lib ../lib64@MULTILIB_OSDIRNAMES = ../lib64 ../lib32 ../lib@' \
        -e 's@MULTILIB_OSDIRNAMES = ../lib32 ../lib ../lib64@MULTILIB_OSDIRNAMES = ../lib64 ../lib32 ../lib@' ${file}
    else
      sed -i -e 's@MULTILIB_OSDIRNAMES = ../lib64 ../lib@MULTILIB_OSDIRNAMES = ../lib ../lib32@' \
        -e 's@MULTILIB_OSDIRNAMES.= ../lib64 .@MULTILIB_OSDIRNAMES\t= ../lib $@' ${file}
    fi
  fi
done

# Create Patch
#
cd /usr/src
echo "Submitted By: Jim Gifford (jim at cross-lfs dot org)" > gcc-${VERSION}-pure64-x.patch
echo "Date: `date +%m-%d-%Y`" >> gcc-${VERSION}-pure64-x.patch
echo "Initial Package Version: ${VERSION}" >> gcc-${VERSION}-pure64-x.patch
echo "Origin: Idea originally developed by Ryan Oliver and Greg Schafer for" >> gcc-${VERSION}-pure64-x.patch
echo "        the Pure LFS project." >> gcc-${VERSION}-pure64-x.patch
echo "Upstream Status: Not Applied" >> gcc-${VERSION}-pure64-x.patch
echo "Description: This patch modifies the location of the dynamic linker for gcc-${VERSION}." >> gcc-${VERSION}-pure64-x.patch
echo "" >> gcc-${VERSION}-pure64-x.patch
diff -Naur gcc-${VERSION}.orig gcc-${VERSION} >> gcc-${VERSION}-pure64-x.patch

echo "Created /usr/src/gcc-${VERSION}-specs-x.patch."
echo "Created /usr/src/gcc-${VERSION}-pure64_specs-x.patch."
echo "Created /usr/src/gcc-${VERSION}-pure64-x.patch."
