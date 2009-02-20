#!/bin/bash

FILENAME=$1

if [ "${FILENAME}" = ""  ]; then
  echo "To Calculate the proper file size use the following command."
  echo "$0 filename"
  exit 255
else
  FILESIZE=$(stat -c%s ${FILENAME})
  ((size=${FILESIZE}/1024))
  FILEMD5SUM=$(md5sum ${FILENAME})

  echo "${size} KB"
  echo "${FILEMD5SUM}"
fi
