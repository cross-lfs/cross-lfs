#!/bin/sh

# TODO: need to handle blfs config options
QT_INSTALL_SELF_CONTAINED=Y
USE_MYSQL=Y
USE_PGSQL=Y
USE_UNIXODBC=Y

if [ "Y" = "${QT_INSTALL_SELF_CONTAINED}" ]; then
   export QTDIR=/opt/qt
else
   export QTDIR=/usr
fi

