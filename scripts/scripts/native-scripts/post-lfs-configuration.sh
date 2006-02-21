#!/bin/bash

# post cross-lfs configuration
# ----------------------------
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
# $HeadURL$
#

# TODO: Add support somehow for multi-arch systems...
#       May just copy the multi-arch funcs script onto the host and use
#       that...

if [ ! -d /etc/default ]; then mkdir /etc/default ; fi

# OK, these defaults for useradd are probably peculiar to the script authors
# preferences (homedirs are generally nfs mounted)
if [ "${HOME_NFS_MOUNTED}" = "Y" ]; then
   HOMEDIR=/home/$( uname -n )
else
   HOMEDIR=/home
fi

if [ ! -d ${HOMEDIR} ]; then mkdir -p ${HOMEDIR} ; fi

cat > /etc/default/useradd << EOF
# Begin /etc/default/useradd

GROUP=100
HOME=${HOMEDIR}
INACTIVE=-1
EXPIRE=
SHELL=/bin/bash
SKEL=/etc/skel

# End /etc/default/useradd
EOF

if [ "${MULTIARCH}" = "Y" ]; then
multiarch_additions='
# The following from cross-lfs multiarch-funcs script

# From set_libdirname function...

# TODO: this will barf on mips if setting 64bit libs to go to */lib
#       but will work if setting
if [ -z "${BUILDENV}" ]; then
   BUILDENV=${DEFAULTENV}
   export BUILDENV
fi
if [ ! "${BUILDENV}" = "${LIBDIRENV}" ]; then
   case ${BUILDENV} in
      32 | o32 | n32 )   libdirname=lib32 ;;
      64 | o64 )         libdirname=lib64 ;;
      * )   echo "unknown buildenv ${BUILDENV}"; return 1
   esac
   LOG=`echo ${LOG} | sed "s@\.log@-${BUILDENV}&@"`
else
   libdirname=lib
fi

# Adjust PKG_CONFIG_PATH 
PKG_CONFIG_PATH=`echo "${PKG_CONFIG_PATH}" | \
                 sed -e "s@lib[36][124]@lib@g"  -e "s@lib@${libdirname}@g" `

# Adjust GNOME_LIBCONF_PATH
GNOME_LIBCONF_PATH=`echo "${GNOME_LIBCONF_PATH}" | \
                 sed -e "s@lib[36][124]@lib@g"  -e "s@lib@${libdirname}@g" `
'
fi

cat > /etc/profile << "EOF"
# Begin /etc/profile
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>
# modifications by Dagmar d'Surreal <rivyqntzne@pbzpnfg.arg>
 
# System wide environment variables and startup programs.
 
# System wide aliases and functions should go in /etc/bashrc.  Personal
# environment variables and startup programs should go into
# ~/.bash_profile.  Personal aliases and functions should go into
# ~/.bashrc.
 
# Functions to help us manage paths.  Second argument is the name of the
# path variable to be modified (default: PATH)
pathremove () {
	local IFS=':'
	local NEWPATH
	local DIR
	local PATHVARIABLE=${2:-PATH}
	for DIR in ${!PATHVARIABLE} ; do
		if [ "${DIR}" != "${1}" ] ; then
			NEWPATH=${NEWPATH:+$NEWPATH:}${DIR}
		fi
	done
	export ${PATHVARIABLE}="${NEWPATH}"
}
 
pathprepend () {
	pathremove ${1} ${2}
	local PATHVARIABLE=${2:-PATH}
	export ${PATHVARIABLE}="$1${!PATHVARIABLE:+:${!PATHVARIABLE}}"
}
 
pathappend () {
	pathremove ${1} ${2}
	local PATHVARIABLE=${2:-PATH}
	export ${PATHVARIABLE}="${!PATHVARIABLE:+${!PATHVARIABLE}:}$1"
}
 

# Set the initial path
export PATH=/bin:/usr/bin

if [ ${EUID} -eq 0 ] ; then
	pathappend /sbin:/usr/sbin
	unset HISTFILE
fi
 
# Setup some environment variables.
export HISTSIZE=1000
export HISTIGNORE="&:[bf]g:exit"
#export PS1="[\u@\h \w]\\$ "
export PS1='\u@\h:\w\$ '
 
for script in /etc/profile.d/*.sh ; do
	if [ -r ${script} ] ; then
		. ${script}
	fi
done
 
# Now to clean up
unset pathremove pathprepend pathappend 

EOF

if [ "${MULTIARCH}" = "Y" ]; then
   echo "${multiarch_additions}" >> /etc/profile
fi
echo "# End /etc/profile" >> /etc/profile

install --directory --mode=0755 --owner=root --group=root /etc/profile.d

cat > /etc/profile.d/dircolors.sh << "EOF"
# Setup for /bin/ls to support color, the alias is in /etc/bashrc.
if [ -f "/etc/dircolors" ] ; then
	eval $(dircolors -b /etc/dircolors)
 
	if [ -f "${HOME}/.dircolors" ] ; then
		eval $(dircolors -b ${HOME}/.dircolors)
	fi
fi
alias ls='ls --color=auto'
EOF

# This script adds several useful paths to the PATH and PKG_CONFIG_PATH
# environment variables.

cat > /etc/profile.d/extrapaths.sh << "EOF"
if [ -d /usr/local/lib/pkgconfig ] ; then
	pathappend /usr/local/lib/pkgconfig PKG_CONFIG_PATH
fi
if [ -d /usr/local/bin ]; then
	pathprepend /usr/local/bin
fi
if [ -d /usr/local/sbin -a $EUID -eq 0 ]; then
	pathprepend /usr/local/sbin
fi
for directory in $(find /opt/*/lib/pkgconfig -type d 2>/dev/null); do
	pathappend ${directory} PKG_CONFIG_PATH
done
for directory in $(find /opt/*/bin -type d 2>/dev/null); do
	pathappend ${directory}
done
if [ -d ~/bin ]; then
	pathprepend ~/bin
fi
#if [ $EUID -gt 99 ]; then
#	pathappend .
#fi
EOF

# This script sets up the default inputrc configuration file. 
# If the user does not have individual settings, it uses the global file.

cat > /etc/profile.d/readline.sh << "EOF"
# Setup the INPUTRC environment variable.
if [ -z "$INPUTRC" -a ! -f "$HOME/.inputrc" ] ; then
	INPUTRC=/etc/inputrc
fi
export INPUTRC
EOF


# Some applications need a specific TERM setting to support color.

cat > /etc/profile.d/tinker-term.sh << "EOF"
# This will tinker with the value of TERM in order to convince certain 
# apps that we can, indeed, display color in their window.
 
if [ -n "$COLORTERM" ]; then
	export TERM=xterm-color
fi
 
if [ "$TERM" = "xterm" ]; then
	export TERM=xterm-color
fi
EOF

# Setting the umask value is important for security. 
# Here the default group write permissions are turned off for system users 
# and when the user name and group name are not the same.

cat > /etc/profile.d/umask.sh << "EOF"
# By default we want the umask to get set.
if [ "$(id -gn)" = "$(id -un)" -a $EUID -gt 99 ] ; then
	umask 002
else
	umask 022
fi
EOF


# If X is installed, the PATH and PKG_CONFIG_PATH variables are also updated.

cat > /etc/profile.d/X.sh << "EOF"
if [ -x /usr/X11R6/bin/X ]; then
	pathappend /usr/X11R6/bin
fi
if [ -d /usr/X11R6/lib/pkgconfig ] ; then
	pathappend /usr/X11R6/lib/pkgconfig PKG_CONFIG_PATH
fi
EOF


# This script shows an example of a different way of setting the prompt.
# The normal variable, PS1, is supplemented by PROMPT_COMMAND. If set,
# the value of PROMPT_COMMAND is executed as a command prior to issuing 
# each primary prompt.

cat > /etc/profile.d/xterm-titlebars.sh << "EOF"
# The substring match ensures this works for "xterm" and "xterm-xfree86".
if [ "${TERM:0:5}" = "xterm" ]; then
	PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME} : ${PWD}\007"'
	export PROMPT_COMMAND
fi
EOF

if [ "${MULTIARCH}" = "Y" ]; then
cat > /etc/profile.d/multiarch-defaults.sh << EOF
# Set default ABI and which ABI goes into */lib
export DEFAULTENV="${DEFAULTENV}"
export LIBDIRENV="${LIBDIRENV}"

# Force each bash script invocation to use /etc/bashrc .
export BASH_ENV="/etc/bashrc"
EOF
fi

# Here is a base /etc/bashrc. 
# Comments in the file should explain everything you need.

cat > /etc/bashrc << "EOF"
# Begin /etc/bashrc 
# Written for Beyond Linux From Scratch 
# by James Robertson <jameswrobertson@earthlink.net>
# updated by Bruce Dubbs <bdubbs@linuxfromscratch.org>

# Make sure that the terminal is set up properly for each shell

if [ -f /etc/profile.d/tinker-term.sh ]; then
	source /etc/profile.d/tinker-term.sh
fi

if [ -f /etc/profile.d/xterm-titlebars.sh ]; then
	source /etc/profile.d/xterm-titlebars.sh
fi

# System wide aliases and functions.

# System wide environment variables and startup programs should go into
# /etc/profile.  Personal environment variables and startup programs
# should go into ~/.bash_profile.  Personal aliases and functions should
# go into ~/.bashrc

# Provides a colored /bin/ls command.  Used in conjunction with code in
# /etc/profile.

alias ls='ls --color=auto'

# Provides prompt for non-login shells, specifically shells started
# in the X environment. [Review the LFS archive thread titled
# PS1 Environment Variable for a great case study behind this script 
# addendum.]

#export PS1="[\u@\h \w]\\$ "
export PS1='\u@\h:\w\$ '

EOF

if [ "${MULTIARCH}" = "Y" ]; then
   echo "${multiarch_additions}" >> /etc/bashrc
fi
echo "# End /etc/bashrc" >> /etc/bashrc

if [ ! -d /etc/skel ]; then mkdir -p /etc/skel ; fi

# .bash_profile

cat > /etc/skel/.bash_profile << "EOF"
# Begin ~/.bash_profile
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>
# updated by Bruce Dubbs <bdubbs@linuxfromscratch.org>

# Personal environment variables and startup programs.

# Personal aliases and functions should go in ~/.bashrc.  System wide
# environment variables and startup programs are in /etc/profile.
# System wide aliases and functions are in /etc/bashrc.

append () {
	# First remove the directory
	local IFS=':'
	local NEWPATH
	for DIR in ${PATH}; do
		if [ "${DIR}" != "${1}" ]; then
			NEWPATH="${NEWPATH:+${NEWPATH}:}${DIR}"
		fi     
	done
  
	# Then append the directory
	export PATH="${NEWPATH}:${1}"
}

if [ -f "${HOME}/.bashrc" ] ; then
	source ${HOME}/.bashrc
fi

if [ -d "${HOME}/bin" ] ; then
	append ${HOME}/bin      
fi

unset append

# End ~/.bash_profile
EOF

# .bashrc

cat > /etc/skel/.bashrc << "EOF"
# Begin ~/.bashrc
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>

# Personal aliases and functions.

# Personal environment variables and startup programs should go in
# ~/.bash_profile.  System wide environment variables and startup
# programs are in /etc/profile.  System wide aliases and functions are
# in /etc/bashrc. 

if [ -f "/etc/bashrc" ] ; then
	source /etc/bashrc
fi

# End ~/.bashrc
EOF

# .bash_logout

cat > /etc/skel/.bash_logout << "EOF"
# Begin ~/.bash_logout
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>

# Personal items to perform on logout.

# End ~/.bash_logout
EOF

# .vimrc

cat > /etc/skel/.vimrc << "EOF"
" Begin .vimrc

set nocompatible
set bs=2
" set columns=80
set background=dark     " use colours which look good on a dark background
" set wrapmargin=8
set ruler

syntax on               " syntax highlighting
set hlsearch            " highlight last used search pattern

" End .vimrc
EOF

cp /etc/skel/{.bash_profile,.bashrc,.vimrc} /root

dircolors -p > /etc/dircolors

cat > /etc/shells << "EOF"
# Begin /etc/shells

/bin/sh
/bin/bash

# End /etc/shells
EOF


