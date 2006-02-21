#!/bin/bash
#
# Log and Error handling funcrions 
# -----------------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

#---------------------------------------
# Standard log initialization functions
#---------------------------------------

BRKLN='================================================================================' # Break line
export BRKLN


max_log_init() { # $1=pkg $2=vers or text $3=dynam|stat|init|some text
              # $4=<log-directory> $5=<log-filename>

    LOGFNAME="${5}-${DATE}"
    min_log_init ${4} ||
    return 1  # Control in mainline. Chg to exit for bail out!

    echo "### ${1} ${2} - ${3} - ${TS} ###"
    
}

min_log_init() { # $1=<log-directory>
    # If log start fails, error out w/message and return code
    TS=$(date)        # Save a call
    LOGFILE="${1}/${LOGFNAME}"
    echo -e "${SELF} - ${LOGFNAME} - ${TS}\n${BRKLN}" > ${LOGFILE} ||
    {
      echo "min_log_init: writing ${LOGFILE} fail. Space/permissions?" \
        &>/dev/tty
      return 2  # Control in mainline. Chg to exit for bail out!
    }
}


#---------------------------------------
# Standard error handling functions
#---------------------------------------
errmsg() {
   # Simply prints an error message, indicating which
   # logfile to look at.
   echo "XXXXXX NOT OK - CHECK LOG ${LOGFILE} XXXXXX"
}

barf() {
   # prints error message and exits
   errmsg
   exit 1
}

# Export functions
export -f max_log_init
export -f min_log_init
export -f errmsg
export -f barf

