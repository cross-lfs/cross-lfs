#!/bin/bash

### gsm ###

cd ${SRC}
LOG=gsm-blfs.log

SELF=`basename ${0}`
set_buildenv
set_libdirname
setup_multiarch

unpack_tarball gsm-${GSM_VER}
cd ${PKGDIR}

# Add support for building shared lib
sed -i -e '/^LIBGSM.*/a\
SHLIBGSM = libgsm.so.0' \
       -e 's@^all:.*\$(LIBGSM)@& $(LIB)/$(SHLIBGSM)@' \
       -e '/^GSM_INSTALL_TARGETS.*/a\
		$(GSM_INSTALL_LIB)/$(SHLIBGSM) \\' \
       -e 's@\$(LD) $(LFLAGS)@& -L$(LIB)@' \
       -e '/\$(LD)/s@\(\$(TOAST_OBJECTS)\) \$(LIBGSM)@\1 -lgsm@g' \
   Makefile

cat >> Makefile <<"EOF"

$(LIB)/$(SHLIBGSM):		$(LIB) $(GSM_OBJECTS)
			-rm $(RMFLAGS) $(LIB)/$(SHLIBGSM)
			$(LD) $(LFLAGS) -shared -Wl,-soname=$(SHLIBGSM) \
				$(GSM_OBJECTS) -o $(LIB)/$(SHLIBGSM)
			$(LN) -sf $(SHLIBGSM) $(LIB)/libgsm.so

$(GSM_INSTALL_LIB)/$(SHLIBGSM):	$(LIB)/$(SHLIBGSM)
		-rm $@
		cp $? $@
		chmod 755 $@
		$(LN) -sf $(SHLIBGSM) $(GSM_INSTALL_LIB)/libgsm.so
EOF

max_log_init gsm ${GSM_VER} "blfs (shared)" ${BUILDLOGS} ${LOG}
(
   make CC="${CC-gcc} ${ARCH_CFLAGS} -ansi -pedantic" \
        CCFLAGS="-c -O2 -pipe ${TGT_CFLAGS} -fPIC -DNeedFunctionPrototypes=1" \
        addtst &&
   make CC="${CC-gcc} ${ARCH_CFLAGS} -ansi -pedantic" \
        CCFLAGS="-c -O2 -pipe ${TGT_CFLAGS} -fPIC -DNeedFunctionPrototypes=1" \
) >> ${LOGFILE} 2>&1 &&
echo " o Build OK" &&

min_log_init ${INSTLOGS} &&
make INSTALL_ROOT=/usr \
     GSM_INSTALL_LIB=/usr/${libdirname} \
     GSM_INSTALL_INC=/usr/include \
     GSM_INSTALL_MAN=/usr/share/man \
   install \
   >> ${LOGFILE} 2>&1 &&
echo " o ALL OK" || barf

