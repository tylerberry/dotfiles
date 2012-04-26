# .bashrc                                                            -*- Sh -*-

# Personal aliases and functions.

# If there exists an /etc/bashrc, it quite possibly sets up things that I want,
# such as a system-specific PATH.  So, source it.

if [[ -f "/etc/bashrc" ]] ; then
  source /etc/bashrc
fi

# Set PATH so it includes user's private binary directory if it exists.

if [[ -d "$HOME/bin" ]] ; then
  PATH=$HOME/bin:$PATH
fi

# Other adjustments to PATH.

PATH=/usr/local/bin:$PATH:/usr/games:/sbin:/usr/sbin:/usr/X11R6/bin:/opt/kde/bin

export PATH

# If we're not in an interactive shell at this point, we're done.

if [[ $- != *i* ]] ; then
  return
fi

# Use bash-completion if it's available, even if the system doesn't default to
# using it.

if [[ -f /etc/profile.d/bash-completion ]] ; then
  source /etc/profile.d/bash-completion
elif [[ -f /etc/bash-completion ]] ; then
  source /etc/bash-completion
elif [[ -f /etc/bash_completion ]] ; then
  source /etc/bash_completion
fi

# This is the recommended alias for GNU Which, modified to be smarter about it.

which_binary=`type -pa which | head -n 1`
if [[ -n "$which_binary" ]] ; then
  which_version=`$which_binary --version 2>&1 | head -n 1 | grep "GNU which"`

  if [[ -n "$which_version" ]] ; then
    function which
    {
      (alias; declare -f) | exec $which_binary --tty-only --read-alias \
        --read-functions --show-tilde --show-dot $@
    }
    export -f which
  fi
else
  # This is the best we can do on short notice. :)
  alias which='type -pa'
fi

# Colors for ls, etc.  Prefer ~/.dir_colors, then the system-wide versions.

dircolors_binary=`type -pa dircolors | head -n 1`
if [[ -n "$dircolors_binary" ]] ; then
  if [[ -f ~/.dir_colors ]] ; then
    eval `dircolors -b ~/.dir_colors`
  elif [[ -f /etc/DIR_COLORS ]] ; then
    eval `dircolors -b /etc/DIR_COLORS`
  elif [[ -f /etc/DIRCOLORS ]] ; then
    eval `dircolors -b /etc/DIRCOLORS`
  fi
fi

# Set the prompt.  We do this here because not all interactive shells are login
# shells, and some terminals (e.g. xterm) don't eval ~/.bash_profile.

use_color=false
safe_term=${TERM//[^[:alnum:]]/.}       # Sanitize TERM.

if [[ "${safe_term}" == "xterm.color" || "${safe_term}" == "xterm.xfree86" \
    || "${safe_term}" == "screen.xterm.xfree86" ]] ; then
  use_color=true
elif [[ -f /etc/DIR_COLORS ]] ; then
  grep -q "^TERM ${safe_term}" /etc/DIR_COLORS && use_color=true
elif [[ -n "$dircolors_binary" ]] ; then
  if dircolors --print-database | grep -q "^TERM ${safe_term}"; then
    use_color=true
  fi
fi

if [[ -z "$STY" ]] ; then               # Set by GNU Screen.
  if ${use_color} ; then
    if [[ $EUID == 0 ]] ; then
      PS1='\[\033[01;31m\]\h \[\033[01;34m\]\w \$ \[\033[00m\]'
    else
      PS1='\[\033[01;32m\]\u@\h \[\033[01;34m\]\w \$ \[\033[00m\]'
    fi
  else
    PS1='\u@\h \w \$ '
  fi
else
  if ${use_color} ; then
    if [[ $EUID == 0 ]] ; then
      PS1='\[\033[01;31m\]\u \[\033[01;34m\]\w \$ \[\033[00m\]'
    else
      PS1='\[\033[01;32m\]\u \[\033[01;34m\]\w \$ \[\033[00m\]'
    fi
  else
    PS1='\u \w \$ '
  fi
fi

# In-screen exit.

#exit ()
#{
#  if [ -z "$STY" -o "$SHLVL" != "2" ] ; then
#    builtin exit
#  else
#    ps h -o command --ppid `echo $STY | cut -d . -s -f 1` | perl -e \
#      '$count = 0;
#       $ppid = getppid;
#       $shells = "/etc/shells";
#       open (SHELLS,$shells) or exit 0;
#       while (<SHELLS>) {
#         chomp;
#         $okshell{$_}++;
#       }
#       close (SHELLS);
#
#       $_ = `ps h -o command --pid $ppid`;
#       chomp;
#       s/^-//;
#       $_ = '/bin/' . $_ unless m#^/#;
#       exit 0 unless exists $okshell{$_};
#
#       while (<>) {
#         chomp;
#         s/^-//;
#         $_ = '/bin/' . $_ unless m#^/#;
#         $count += 1 if exists $okshell{$_};
#       }
#       exit 1 if $count == 1;
#       exit 0;'
#    if [ "$?" == "1" ] ; then
#      screen -D
#    else
#      builtin exit
#    fi
#  fi
#}
#export -f exit

# Enable color support for ls.

ls --color=auto >/dev/null 2>&1
if [ "$?" == "0" ] ; then
  alias ls='ls --color=auto'
else
  ls -G >/dev/null 2>&1
  if [[ "$?" == "0" ]] ; then
    alias ls='ls -G'
  fi
fi

# Gentoo aliases

if [[ -f /etc/gentoo-release ]] ; then
  export LOCAL_ACCEPT_KEYWORDS="~x86"

  function emerge
  {
    sudo /usr/bin/emerge $@
  }
  export -f emerge

  function aemerge
  {
    export ACCEPT_KEYWORDS="$LOCAL_ACCEPT_KEYWORDS"
    sudo /usr/bin/emerge $@
    unset ACCEPT_KEYWORDS
  }
  export -f aemerge
fi

# Midnight Commander chdir enhancement
if [[ -f /usr/share/mc/mc.gentoo ]] ; then
  . /usr/share/mc/mc.gentoo
fi

# I don't like the annoying warning message.

alias nslookup='nslookup -sil'

# Some aliases you might find useful.

alias ll='ls -l'
alias la='ls -a'
alias lla='ls -la'

alias saffron='ssh tyler@saffron.thoughtlocker.net'
alias scootaloo='ssh tyler@50.116.22.21'

# Finally, launch GNU screen.

#screen_binary=`type -pa screen | head -n 1`
#if [ ! "$screen_binary" = "" -a ! -n "$WINDOW" ] ; then
#  screen
#fi

# End ~/.bashrc
