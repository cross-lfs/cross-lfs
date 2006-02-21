#!/bin/bash

# cross-lfs final target partition prep
# -------------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

test x${LFS} != x || barf

LOG=final-prep-target.log
max_log_init "Final prep" "" "target" ${INSTLOGS} ${LOG}

### Final Prep for chroot ###

mkdir -p ${LFS}/{bin,boot,dev/pts,/dev/shm,etc/opt,home,lib,mnt,proc}
mkdir -p ${LFS}/{root,sbin,tmp,usr/local,var,opt}

case ${KERNEL_VER} in
   2.5* | 2.6* ) mkdir -p ${LFS}/sys ;;
esac

for dirname in ${LFS}/usr ${LFS}/usr/local
    do

    mkdir -p $dirname/{bin,etc,include,lib,sbin,share,src}
    # Apparently not FHS compliant but without these LFS breaks (RO)
    ln -sf share/{man,doc,info} $dirname

    # More FHS compliant but breaks LFS builds
    #mkdir -p $dirname/{bin,include,lib,sbin,share,src}

    mkdir -p $dirname/share/{dict,doc,info,locale,man}
    mkdir -p $dirname/share/{nls,misc,terminfo,zoneinfo}
    mkdir -p $dirname/share/man/man{1,2,3,4,5,6,7,8}
done
mkdir -p ${LFS}/usr/local/games
ln -sf share/man ${LFS}/usr/local
mkdir -p ${LFS}/var/{lock,log,mail,run,spool} &&
mkdir -p ${LFS}/var/{tmp,opt,cache,lib/misc,local} &&
mkdir -p ${LFS}/opt/{bin,doc,include,info} &&
mkdir -p ${LFS}/opt/{lib,man/man{1,2,3,4,5,6,7,8}} &&

touch ${LFS}/var/run/utmp ${LFS}/var/log/{btmp,lastlog,wtmp} &&
chmod 644 ${LFS}/var/run/utmp ${LFS}/var/log/{btmp,lastlog,wtmp}

chmod 0750 ${LFS}/root &&
chmod 1777 ${LFS}/tmp ${LFS}/var/tmp

if [ ! "${USE_SYSROOT}" = "Y" ]; then
   # setup bash symlinks
   ln -sf ..${TGT_TOOLS}/bin/bash ${LFS}/bin
   ln -sf bash ${LFS}/bin/sh

   # Required for glibc build
   ln -sf ..${TGT_TOOLS}/bin/pwd ${LFS}/bin
   ln -sf ../..${TGT_TOOLS}/bin/perl ${LFS}/usr/bin
   # added for glibc make check
   ln -sf ..${TGT_TOOLS}/bin/cat ${LFS}/bin

   # added for binutils ar test
   ln -sf ..${TGT_TOOLS}/bin/stty ${LFS}/bin
   # ln -sf ../..${TGT_TOOLS}/bin/msgfmt   ${LFS}/usr/bin
   # ln -sf ../..${TGT_TOOLS}/bin/xgettext ${LFS}/usr/bin
   # ln -sf ../..${TGT_TOOLS}/bin/msgmerge ${LFS}/usr/bin
   ln -sf ../..${TGT_TOOLS}/bin/install ${LFS}/usr/bin
   ln -sf ../usr/bin/install ${LFS}/bin

   # Added for ch6 findutils locate tests
   ln -sf ..${TGT_TOOLS}/bin/echo ${LFS}/bin

   ## CHECK IF FINDUTILS STILL NEEDS AWK/SED SYMLINKS ##
   ln -sf ..${TGT_TOOLS}/bin/sed ${LFS}/bin
   ln -sf ..${TGT_TOOLS}/bin/awk ${LFS}/bin

   # ch6 ed make check needs cmp
   ln -sf ../..${TGT_TOOLS}/bin/cmp ${LFS}/usr/bin

   # for ch6 coreutils user checks
   ln -sf ..${TGT_TOOLS}/bin/su ${LFS}/bin

   # For the bootscripts
   ln -sf ../..${TGT_TOOLS}/bin/find ${LFS}/usr/bin
   ln -sf ..${TGT_TOOLS}/sbin/fsck ${LFS}/sbin
   ln -sf ..${TGT_TOOLS}/bin/grep ${LFS}/bin
   ln -sf ..${TGT_TOOLS}/bin/ls ${LFS}/bin
   ln -sf ..${TGT_TOOLS}/bin/ln ${LFS}/bin
   ln -sf ..${TGT_TOOLS}/bin/mkdir ${LFS}/bin
   ln -sf ..${TGT_TOOLS}/bin/rm ${LFS}/bin
   ln -sf ..${TGT_TOOLS}/bin/sleep ${LFS}/bin
   ln -sf ..${TGT_TOOLS}/bin/chown ${LFS}/bin
   ln -sf ..${TGT_TOOLS}/bin/chmod ${LFS}/bin
   
   # for hotplug...
   ln -sf ..${TGT_TOOLS}/bin/uname ${LFS}/bin
   ln -sf ../..${TGT_TOOLS}/bin/env ${LFS}/usr/bin
   ln -sf ../..${TGT_TOOLS}/bin/cut ${LFS}/usr/bin
   ln -sf ../..${TGT_TOOLS}/bin/od ${LFS}/usr/bin
   ln -sf ../..${TGT_TOOLS}/bin/wc ${LFS}/usr/bin
   ln -sf ../..${TGT_TOOLS}/bin/readlink ${LFS}/usr/bin
fi

if [ ! -f ${LFS}/etc/passwd ]; then
   # Our new root user will be called "root".
   # NOTE root password field should be "x" if shadow is installed.
   echo "root::0:0:root:/root:/bin/bash" > ${LFS}/etc/passwd
   echo "plfstest:x:1000:100:root:/root:/bin/bash" >> ${LFS}/etc/passwd
   echo "nobody:x:65534:65534:nobody:/home:/bin/false" >> ${LFS}/etc/passwd
fi

chmod 644 ${LFS}/etc/passwd

if [ ! -f ${LFS}/etc/shadow ]; then
   # Get number of seconds since epoch
   LASTCHG=`date +%s`
   # Convert to days since epoch
   LASTCHG=`expr ${LASTCHG} / 86400`

   echo "root::${LASTCHG}:0:99999:7:::" > ${LFS}/etc/shadow
   echo "plfstest:!:${LASTCHG}:0:99999:7:::" >> ${LFS}/etc/shadow
   echo "nobody:!:${LASTCHG}:0:99999:7:::" >> ${LFS}/etc/shadow
fi

chmod 600 ${LFS}/etc/shadow

# Note: these are from LFS book CVS 2003-03-24, but with some modifications
if [ ! -f ${LFS}/etc/group ]; then
	cat > ${LFS}/etc/group << "EOF"
root:x:0:
bin:x:1:
sys:x:2:
kmem:x:3:
tty:x:4:
tape:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
wheel:x:12:
users:x:100:
nogroup:x:65534:
EOF
fi

chmod 644 ${LFS}/etc/group

# Create initial nsswitch.conf file

cat > ${LFS}/etc/nsswitch.conf << "EOF" 
passwd:	files
shadow:	files
group:	files
hosts:	files dns
EOF

# Create files required for NSS

# ${LFS}/etc/hosts should have been created when target-lfs-bootscripts was run.
# If it wasnt (???) create one here

test -f ${LFS}/etc/hosts || 
   echo -e "127.0.0.1\tlocalhost.localdomain\tlocalhost" > ${LFS}/etc/hosts

chmod 644 ${LFS}/etc/hosts

# TODO: need to install 
test -f ${LFS}/etc/resolv.conf ||
   touch ${LFS}/etc/resolv.conf

chmod 644 ${LFS}/etc/resolv.conf

# This fstab is merely a template, you will have to edit the / entry before
# attempting to boot a rw root filesystem.

cat > ${LFS}/etc/fstab << "EOF" 
#/dev/BOOT		/boot		ext2	noauto,noatime	1 1
#/dev/ROOT		/		xfs	noatime		0 0
#/dev/SWAP		none		swap	sw		0 0
#/dev/cdroms/cdrom0	/mnt/cdrom	iso9660	noauto,ro	0 0
#/dev/fd0		/mnt/floppy	auto	noauto		0 0
none			/proc		proc	defaults	0 0
none			/dev/pts	devpts	gid=4,mode=620	0 0
none			/dev/shm	tmpfs	defaults	0 0
EOF

case ${KERNEL_VER} in
   2.5* | 2.6* )
      echo "none		/sys		sysfs	defaults		0 0" >> ${LFS}/etc/fstab
   ;;
esac

chmod 644 ${LFS}/etc/fstab

# We create /etc/shells for the benefit of inetutils ftpd

cat > ${LFS}/etc/shells << "EOF"
/bin/sh
/bin/bash
EOF

chmod 644 ${LFS}/etc/shells

# TODO: need to create some (if not all) of the following 
# NSSFILES="ethers netmasks networks rpc netgroup automount aliases"

# Unfortunately we can't just chown to root only the stuff owned by the user
# running the build. That is because some installers created files with
# certain group and user rights (bin, tty, etc). This gets screwed up if
# the build host doesn't have identical system accounts to those in the
# passwd file we just installed. So we chown the whole damn thing to root, being
# careful of sticky, SGID and SUID files. Some systems clear those bits upon
# chown.
# The ch. 6 build will have to overwrite all of the problems this causes.

cd ${LFS}
( echo "These SUID files are having their user changed to root:"
find . -user 0 -o \( -perm +4000 -print \)
echo "These SGID files are having their group changed to root:"
find . -group 0 -o \( -perm +2000 -print \)
echo "These sticky directories are having their user/group changed to root:"
find . \( -user 0 -group 0 \) -o \( -perm +1000 -print \)
echo "These world writable executables are being made non-world writable:"
find . -type f -perm +111 -perm -2 -print
find . -type f -perm +111 -perm -2 -exec chmod o-w \{\} \; ) | tee -a ${LOGFILE}
chown -R 0 ${LFS}
chgrp -R 0 ${LFS}

echo export PS1="'"'\u@\h \W$ '"'" >${LFS}/etc/profile
echo export PATH=/bin:/usr/bin:/sbin:/usr/sbin:${TGT_TOOLS}/bin:${TGT_TOOLS}/sbin:${TGT_TOOLS}/usr/bin >>${LFS}/etc/profile

echo " o All OK"
