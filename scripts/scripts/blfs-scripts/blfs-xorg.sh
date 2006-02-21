#!/bin/sh
#
# Xorg
#

# NOTE: Xorg handles bi-arch very well (at least on x86_64, havent tried 
#       others).
#       No need to set libdir or hack, libs automagically go to lib64 
#       or lib based on the emulation used.
#
#       /usr/X11R6/lib/X11 holds fonts etc, and handles locales under
#       there in lib/lib64 depending
#
# TODO: set libdir and libdirname in host.def to /usr/X11R6/lib and lib
#       respectively if doing uni-arch x86_64 build.
#       Will need to check how nvidia installer will deal with things though

cd ${SRC}
LOG=xorg-blfs.log
SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

unpack_tarball X11R${XORG_VER}-src &&
cd ${PKGDIR}

# From blfs 20050112 (Xorg 6.8.1):
# Xorg insists on putting its boot and profile scripts into the /etc directory
# even if we specifically tell it not to compile anything Xprint server or
# client related (see host.def below). The following command will suppress any
# such modifications: 
sed -i '/^SUBDIRS =/s/ etc$//' programs/Xserver/Xprint/Imakefile

# First patch ensures objects packed into static libs get built position
# independant, so they can be linked into shared libs. A notable barf
# without this patch is with NAS linking against a static libXau 
apply_patch X11R6.8.1-IncludeSharedObjectInNormalLib-1

# This patch ensures that if SharedLibXau is defined in host.def that it
# links correctly
apply_patch X11R6.8.1-fix_shared_libXau_link-1

# Build lndir ( NOTE: we don't particularly care whether this is 64 or 32 )
pushd config/util &&
make -f Makefile.ini lndir &&
cp lndir /usr/bin/ &&
popd

test -d ${SRC}/xcbuild${suffix} &&
   rm -rf ${SRC}/xcbuild${suffix}

mkdir ${SRC}/xcbuild${suffix}

# Create shadow tree
cd ${SRC}/xcbuild${suffix}
lndir ${SRC}/${PKGDIR} > /dev/null 2>&1

# Create host.def file
echo " o creating config/cf/host.def"

cat > config/cf/host.def << "EOF"
/* Begin Xorg host.def file */
 
/* System Related Information.  If you read and configure only one
 * section then it should be this one.  The Intel architecture defaults are
 * set for a i686 and higher.  Axp is for the Alpha architecture and Ppc is
 * for the Power PC.  AMD64 is for the Opteron processor. Note that there have 
 * been reports that the Ppc optimization line causes segmentation faults during 
 * build.  If that happens, try building without the DefaultGcc2PpcOpt line.  ***********/
 
/* #define DefaultGcc2i386Opt -O2 -fno-strength-reduce -fno-strict-aliasing -march=i686 */
/* #define DefaultGccAMD64Opt -O2 -fno-strength-reduce -fno-strict-aliasing -march=athlon64 */
/* #define DefaultGcc2AxpOpt  -O2 -mcpu=ev6 */
/* #define DefaultGcc2PpcOpt  -O2 -mcpu=750 */

#define HasFreetype2            YES
#define HasFontconfig           YES
#define HasExpat                YES
#define HasLibpng               YES
#define HasZlib                 YES

/*
 * Which drivers to build.  When building a static server, each of these
 * will be included in it.  When building the loadable server each of these
 * modules will be built.
 *
#define XF86CardDrivers         mga glint nv tga s3virge sis rendition \
                                neomagic i740 tdfx savage \
                                cirrus vmware tseng trident chips apm \
                                GlideDriver fbdev i128 \
                                ati AgpGartDrivers DevelDrivers ark cyrix \
                                siliconmotion \
                                vesa vga XF86OSCardDrivers XF86ExtraCardDrivers
 */
/*
 * Select the XInput devices you want by uncommenting this.
 *
#define XInputDrivers           mouse keyboard acecad calcomp citron \
                                digitaledge dmc dynapro elographics \
                                microtouch mutouch penmount spaceorb summa \
                                wacom void magictouch aiptek
 */
/* Most installs will only need this */

#define XInputDrivers           mouse keyboard

/* Disable building Xprint server and clients until we get them figured
 * out but build Xprint libraries to allow precompiled binaries such as
 * Acrobat Reader to run.
 */

#define XprtServer              NO
#define BuildXprintClients      NO

/* #define LibDirName		lib64 */

/* #define LibDir			/usr/X11R6/lib64/X11 */

/* End Xorg host.def file */
EOF

# remove references to linux/config.h (when using linux-libc-headers)
sed -i -e "s@#include <linux/config.h>@/* & */@" \
    `grep -lr linux/config.h *`

# TODO: check if CFLAGS/CXXFLAGS can be defined...
#       when applied in CC= or CXX= TGT_CFLAGS tend to be left out...
max_log_init Xorg ${XORG_VER} "blfs (shared)" ${BUILDLOGS} ${LOG}
CC="${CC-gcc} ${ARCH_CFLAGS}" \
CXX="${CXX-g++} ${ARCH_CFLAGS}" \
CFLAGS="${TGT_CFLAGS}" \
CXXFLAGS="${CFLAGS}" \
make World \
   >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
#make DESTDIR=/mnt/scriptcheck/Xorg${suffix} install \
make install \
   >> ${LOGFILE} 2>&1 &&
#make DESTDIR=/mnt/scriptcheck/Xorg${suffix} install.man \
make install.man \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

ln -sf ../X11R6/bin /usr/bin/X11 &&
ln -sf ../X11R6/lib/X11 /usr/lib/X11 &&
ln -sf ../X11R6/include/X11 /usr/include/X11

if [ "Y" = "${MULTIARCH}" ]; then
   use_wrapper /usr/X11R6/bin/xft-config /usr/X11R6/bin/xcursor-config \
               /usr/X11R6/bin/gccmakedep /usr/X11R6/bin/ccmakedep \
               /usr/X11R6/bin/imake /usr/X11R6/bin/xmkmf
fi

echo "---------------------------------------------------------------"
echo "To configure/setup Xorg fonts / DRI  please see blfs Chapter 25"
echo "---------------------------------------------------------------"
echo

