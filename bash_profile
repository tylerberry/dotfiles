# Begin ~/.bash_profile                                              -*- Sh -*-

# Personal environment variables and startup programs.

# First of all, source my .bashrc.

if [ -f "$HOME/.bashrc" ] ; then
    source $HOME/.bashrc
fi

# Set MANPATH so it includes my private manpage directory if it exists.

if [ -d "$HOME/man" ]; then
    MANPATH=$HOME/man:$MANPATH
    export MANPATH
fi

# Bash customizations.

shopt -s checkhash     # Verify that cached commands exist before execution.
shopt -s checkwinsize  # Update LINES and COLUMNS as necessary.
shopt -s cmdhist       # Save multi-line commands in a single history entry.
shopt -s no_empty_cmd_completion  # Do not complete on nothing.

export HISTCONTROL=ignoredups
export HISTIGNORE="&:[bf]g:exit:clear"

# Preferred utility programs.

BROWSER=links
EDITOR=emacs
MAILER=mutt
PAGER="less -isR"
VISUAL=emacs
MAILREADER=mutt        # MAILREADER is used (badly) by Nethack.

export BROWSER EDITOR MAILER PAGER VISUAL MAILREADER

# Set up internationalization and localization.

LANG=en_US.UTF-8
LC_COLLATE=C           # POSIX sort order puts capital letters first.
LC_TIME=C
LESSCHARSET=utf-8
TZ=America/Denver

export LANG LC_COLLATE LC_TIME LESSCHARSET TZ

# Set up the Python interpreter.

if [[ -f "$HOME/.python.py" ]] ; then
    export PYTHONSTARTUP=$HOME/.python.py
fi

# Use ssh rather than the insecure rsh to connect to CVS servers.  Why isn't
# this the default, anyway?

export CVS_RSH=ssh

# Run site-local bash configuration.

if [ -f "$HOME/.bash_local" ] ; then
    source $HOME/.bash_local
fi

# End ~/.bash_profile
