#!/bin/bash

if [ -z ${SCRIPTS} ]; then exit 1 ;fi

ln -s target-bzip2.sh	${SCRIPTS}/target-scripts/target-bzip2-64.sh 
ln -s target-gettext.sh	${SCRIPTS}/target-scripts/target-gettext-64.sh 
ln -s target-ncurses.sh	${SCRIPTS}/target-scripts/target-ncurses-64.sh 
ln -s target-zlib.sh	${SCRIPTS}/target-scripts/target-zlib-64.sh 
