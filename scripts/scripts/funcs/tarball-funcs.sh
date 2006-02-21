#!/bin/bash
#
# Tarball handling functions for cross-lfs build
# -----------------------------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

# Check for stuff
#----------------

# Check for a grep which takes -E
for dir in "" /bin/ /usr/bin/ /usr/xpg4/bin/ /usr/local/bin/ ; do
   echo X | ${dir}grep -E X > /dev/null 2>&1 &&
   {
      export GREP="${dir}grep"
      break
   }
done

if [ "${GREP}" = "" ]; then
   echo "install a grep on the system that handles -E"
   exit 1
fi

fetch() {

   # find and fetch files with wget by using the google "I'm feeling lucky" search
   #------------------------------------------------------------------------------
   # Many, many thanks to Glenn Sommer <glemsom_at_hotpop.com> for this damn cool
   # bit of scriptage ;-)
   #
   # Probably a bit more sanity checking wouldn't go astray... but hey ;-)

   if [ -z "${1}" ]; then
      echo "fetch: error, no file specified" 2>&1
      return 1
   fi

   echo -n " o searching for ${1} tarball ... "

   # We search for "Index of" - hoping to catch some ftp server
   # And then we search for the filename
   google_lucky_search="http://www.google.com/search?hl=en&q=%22Index+of%22+${1}&btnI=I%27m+Feeling+Lucky&meta="

   location=`wget -c -U Mozilla ${google_lucky_search} 2>&1 | 
   grep Location | \
   head -n 1 | \
   sed -e 's/Location: \(.*\) \[following\].*$/\1/'`
   rm -f index.html

   if [ -z "${location}" ]; then
      echo "failed"
      return 1
   fi

   echo -e "found"
   echo " o retrieving ${location}${1}"
   wget -c ${location}${1} 2>&1

}

fetch_tarball() { # ${1} should be a package name w version
   for type in tar.bz2 tar.gz tgz tar.Z tar bleh; do
      # if the following is true, we failed in our mission
      if [ "${type}" = "bleh" ]; then return 1 ; fi
      fetch ${1}.${type}
      if [ "${?}" = "0" ]; then return 0 ; fi
   done
}

unpack_tarball() { # ${1}=<package-${PACKAGE_VER}> ${2}
   local pkgname=${1}
   shift
   local filelist="${@}"

   # Check if -no-remove option is set
   echo ${filelist} | grep \\-no-remove > /dev/null 2>&1 &&
   {
      local no_remove=Y
      filelist=`echo ${filelist} | sed 's@-no-remove@@g'`
   }

   # Easier add of .tgz

   # if PACKAGE_VER was not set for this package, warn but exit with no error.
   # this is so we can disable the build of a package by not exporting its
   # PACKAGE_VER variable in plfs-packages
   echo "${pkgname}" | ${GREP} -E \\-$ > /dev/null 2>&1
   if [ "${?}" = 0 ]; then
      echo "unpack_tarball: skipping script ${0}, package version not set"
      exit 0
   fi
   
   local archive=`ls -t ${TARBALLS}/${pkgname}* 2> /dev/null | \
      ${GREP} -E ${pkgname}.\(tgz\|tar.gz\|tar.bz2\|tar.Z\|tar\)$ | head -n 1`

   if [ -z ${archive} ]; then
      echo "unpack_tarball: unable to locate tarball for '${pkgname}' in ${TARBALLS} ... exiting"
      exit 1
   fi

   case ${archive} in
      *.gz | *.tgz )   local CAT="gzip -dc" ;;
      *.bz2 )          local CAT="bzcat"    ;;
      *.Z )            local CAT="zcat"     ;;
      *.tar )          local CAT="cat"      ;;
      * )   echo "unpack_tarball: unable to determine tarball type... exiting"
            exit 1 ;;
   esac

   # May as well provide a method for passing back the directory the tarball 
   # unpacks to.
   # Should save some trauma when a tarball doesn't extract to where is expected
   # ( usually package-${PACKAGE_VER} but not always... )
   # store in environment as PKGDIR.

   echo -e "\n${BRKLN}"
   echo -n "Checking tarball install directory... "
   export PKGDIR=`${CAT} ${archive} | tar -tf - | \
      head -n 1 | sed -e 's@^\./@@g' -e 's@/.*$@@g'`

   if [ -z ${PKGDIR} ]; then
      echo "Error: unable to determine tarball contents, exiting"
      exit 1
   else
      echo "${PKGDIR}"
   fi

   # If we are not doing a full unpack of the tarball, don't delete ${PKGDIR}
   if [ ! -z "${filelist}" ]; then
      # prepend ${PKGDIR} to each required file 
      filelist=`echo ${filelist} | \
         sed "s@\([-+_a-zA-Z0-9/.]* \?\)@${PKGDIR}/\1@g"`
   elif [ -d ${PKGDIR} -a ! "${no_remove}" = "Y" ]; then
      echo -n "Removing existing ${PKGDIR} directory... "
      rm -rf ${PKGDIR} && echo "DONE" || 
      echo "Error removing ${PKGDIR}... "; #return 1
   fi


   echo "Unpacking ${archive}"
   ${CAT} ${archive} | tar -xf - ${filelist} 2> /dev/null &&
   echo " o ${archive} unpacked successfully" ||
   {
      echo "unpack_tarball: unable to unpack tarball ${archive}... exiting"
      exit 1
   }

   return 0
}

check_tarballs () {
   # ${GREP}s through the either the calling script or the script(s)
   # passed as args for calls to unpack_tarball.
   # This function expects the scripts to be stored in ${SCRIPTS}.
   #
   # It will store the list of packages required in the list PKGS
   # All will have their variable components unexpanded.

   LIST=""
   ARGS="${@}"
   if [ ! -z "${ARGS}" ]; then
      for script in ${ARGS}; do
         if [ -f ${SCRIPTS}/${script} ]; then
            LIST="${LIST} ${SCRIPTS}/${script}"
         else
            echo "check_tarballs: build script ${SCRIPTS}/${script} not found... skipping" 1>&2
         fi
      done
   elif [ ! -z ${SELF} -a -f ${SCRIPTS}/${SELF} ]; then
      LIST=${SCRIPTS}/${SELF}
   fi

   test -z "${LIST}" &&
   {
      echo "check_tarballs: no build scripts found... exiting"
      exit 1
   }

   # Retrieve package defs from unpack_tarball calls into a list
   local PKGS="$( cat ${LIST} | \
                 ${GREP} -E '^[[:blank:]]*unpack_tarball (\w|-)*\${\w*}' | \
                 awk '{print $2}' | sort -u )"

   echo -e "\nChecking for required tarballs in ${TARBALLS}\n${BRKLN}"

   # loop through list
   for pkg in ${PKGS} ; do

      # check if the ${PKG_VER} variable is set in plfs-config
      # If not ignore the package
      ver_var=`echo ${pkg} | sed 's@.*\(${.*}\).*@\1@g'`
      eval ver=${ver_var}
      if [ -z ${ver} ]; then continue ; fi

      # do variable expansion on ${pkg}
      eval pkgname=${pkg}
      # check if this package is used
      check_pkg_used ${pkgname} || continue
      echo -n " o Looking for ${pkgname}... "
      # check for the existence of the tarball
      #local archive=`ls -t ${TARBALLS}/${pkgname}.@(tgz|tar.gz|tar.bz2) \
      #  2> /dev/null | head -n 1`
      local archive=`ls -t ${TARBALLS}/${pkgname}* 2> /dev/null | \
      ${GREP} -E ${pkgname}.\(tgz\|tar.gz\|tar.bz2\|tar.Z\|tar\)$ | head -n 1`

      if [ -z "${archive}" ]; then
         echo "not found"

         # Attempt to download it from the net
         cd ${TARBALLS}
         fetch_tarball ${pkgname} || {
            echo -e "XXXXXX NOT FOUND: Unable to locate tarball for '${pkgname}'  XXXXXX"
            exit 1
         }
      else
         echo -e "OK\n   Found: ${archive}"
      fi

   done
   echo -e " o ALL OK\n${BRKLN}\n"
}

# Following two functions are interim hacks for check_patches and
# check_tarballs to get around conditional packages/patches
# these will be revisited

check_pkg_used () {
   case ${1} in
      glibc-linuxthreads* )
         #test Y = "${USE_NPTL}" && return 1
         return 1
      ;;
      nptl-* )
         test Y = "${USE_NPTL}" || return 1
      ;;
      udev-* )
         test Y = "${UDEV}" || return 1
      ;;
   esac
   return 0
}

# Export functions
export -f check_tarballs
export -f fetch
export -f fetch_tarball
export -f unpack_tarball
export -f check_pkg_used

