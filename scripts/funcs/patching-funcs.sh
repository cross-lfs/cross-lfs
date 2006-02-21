#!/bin/bash
#
# Patching functions for cross-lfs 
# ---------------------------------
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
      export GREP="${path}grep"
      break
   }
done

if [ "${GREP}" = "" ]; then
   echo "install a grep on the system that handles -E"
   exit 1
fi

apply_patch () { # ${1}=<package-${PATCH_VER}> ${2}= patch flag (defaults to -Np1)
   local patchname=${1}
   local patchflags=${2}

   local patch=`ls -t ${PATCHES}/${patchname}.* 2> /dev/null | \
      ${GREP} -E ${patchname}.\(patch\|patch.gz\|patch.bz2\)$ | head -n 1`
      

   test -e ${PATCHES}/${patchname} || 
   test -z ${patch} &&
    {
       echo "apply_patch: unable to locate patch '${patchname}' in ${PATCHES} ... exiting"
       exit 1
    }

   test -z ${patchflags} && patchflags='-Np1'

   case ${patch} in
      *.patch.gz )   local CAT="gzip -dc" ;;
      *.patch.bz2 )  local CAT="bzcat"    ;;
      *.patch )      local CAT="cat"      ;;
      * )   echo "apply_patch: unable to determine patch type... exiting"
            exit 1 ;;
   esac

   echo "Applying ${patch}"
   
   ${CAT} ${patch} | patch ${patchflags} 2> /dev/null

   # PIPESTATUS not available under bash 1.14.7 (RH 6.2)
   #if [ "${PIPESTATUS[*]}" = "0 0" ]
   if [ 0 = "${?}" ]; then
      echo " o ${patch} applied successfully"
   else
      echo "apply_patch: unable to apply patch ${patch}... exiting"
      exit 1
   fi
}

# Export functions
export -f apply_patch

