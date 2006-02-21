#!/bin/bash

if [ -z ${SCRIPTS} ]; then exit 1 ;fi

ln -s native-bzip2.sh		${SCRIPTS}/native-scripts/native-bzip2-64.sh 
ln -s native-file.sh		${SCRIPTS}/native-scripts/native-file-64.sh 
ln -s native-flex.sh		${SCRIPTS}/native-scripts/native-flex-64.sh 
ln -s native-gettext.sh		${SCRIPTS}/native-scripts/native-gettext-64.sh 
ln -s native-glibc.sh		${SCRIPTS}/native-scripts/native-glibc-64.sh 
ln -s native-libtool.sh		${SCRIPTS}/native-scripts/native-libtool-64.sh 
ln -s native-ncurses.sh		${SCRIPTS}/native-scripts/native-ncurses-64.sh 
ln -s native-perl.sh		${SCRIPTS}/native-scripts/native-perl-64.sh 
ln -s native-procps.sh		${SCRIPTS}/native-scripts/native-procps-64.sh 
ln -s native-readline.sh	${SCRIPTS}/native-scripts/native-readline-64.sh 
ln -s native-shadow.sh		${SCRIPTS}/native-scripts/native-shadow-64.sh 
ln -s native-zlib.sh		${SCRIPTS}/native-scripts/native-zlib-64.sh 
ln -s temp-expect.sh		${SCRIPTS}/native-scripts/temp-expect-64.sh 
ln -s temp-perl.sh		${SCRIPTS}/native-scripts/temp-perl-64.sh 
ln -s temp-tcl.sh		${SCRIPTS}/native-scripts/temp-tcl-64.sh 
