#!/bin/bash
# Retrieve latest config.sub and config.guess with wget

DIR=`dirname ${0}`

mkdir -p ${DIR}/gnu-config-files
cd ${DIR}/gnu-config-files

wget \
 http://savannah.gnu.org/cgi-bin/viewcvs/*checkout*/config/config/config.guess \
 http://savannah.gnu.org/cgi-bin/viewcvs/*checkout*/config/config/config.sub

chmod 755 *

