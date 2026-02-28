# ~/.config/xdg/xdg_environment.sh                             -*- mode: sh -*-

export XDG_BIN_HOME="${XDG_BIN_DIR:-${HOME}/.local/bin}"

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
export XDG_CONFIG_DIRS="${XDG_CONFIG_DIRS:-/etc/xdg/}"

export XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
if [ ! -d "${XDG_DATA_HOME}" ]; then
  mkdir -p "${XDG_DATA_HOME}"
fi
export XDG_DATA_DIRS="${XDG_DATA_DIRS:-/usr/local/share/:/usr/share/}"

export XDG_STATE_HOME="${XDG_STATE_HOME:-${HOME}/.local/state}"
if [ ! -d "${XDG_STATE_HOME}" ]; then
  mkdir -p "${XDG_STATE_HOME}"
fi

# We want to handle several of the XDG directories on a per-OS basis in order
# to take advantage of various facilities provided by the OS. Specifically,
# XDG_CACHE_HOME, XDG_RUNTIME_DIR, and the various user document locations can
# use pre-existing directories on various OS.

case "$(uname -sr)" in
  Darwin*)
    # On Darwin, we try to make use of the Apple-provided user-specific cache
    # and temporary directories. For XDG_RUNTIME_DIR, we just use a
    # subdirectory of DARWIN_USER_TEMP_DIR, which *almost* has the right
    # semantics to meet the XDG spec. The only difference is that the directory
    # isn't guaranteed to be deleted on logout, but this is probably
    # unimportant.
    #
    # First of all, Macs are primarily single-user systems for most people, so
    # full logouts are unlikely in the first place. Second, XDG_RUNTIME_DIR is
    # honestly probably not doing much on a Mac, it's mostly here for
    # completeness, so this is 'good enough'.

    darwin_temp_dir="$(getconf DARWIN_USER_TEMP_DIR)"
    if [ ! -d "${darwin_temp_dir}/xdg" ]; then
      mkdir "${darwin_temp_dir}/xdg"

      # XDG mandates 0700 permissions for XDG_RUNTIME_DIR.
      chmod 0700 "${darwin_temp_dir}/xdg"
    fi
    export XDG_RUNTIME_DIR="$(realpath "${darwin_temp_dir}/xdg")"

    # For XDG_CACHE_DIR, we set up a symlink at ${HOME}/.cache to a
    # subdirectory in DARWIN_USER_CACHE_DIR.

    darwin_cache_dir="$(getconf DARWIN_USER_CACHE_DIR)"
    if [ ! -d "${darwin_cache_dir}/xdg" ]; then
      mkdir "${darwin_cache_dir}/xdg"
    fi

    # Make sure the .cache symlink is correct.
    if [ ! "${HOME}/.cache" -ef "${darwin_cache_dir}" ]; then
      rm "${HOME}/.cache"
    fi

    if [ ! -L "${HOME}/.cache" ]; then
      ln -s "$(realpath "${darwin_cache_dir}/xdg")" "${HOME}/.cache"
    fi
    export XDG_CACHE_HOME="${HOME}/.cache"

    # Most of the XDG desktop document location variables map onto pre-existing
    # Mac directories.

    export XDG_DESKTOP_DIR="${HOME}/Desktop"
    export XDG_DOCUMENTS_DIR="${HOME}/Documents"
    export XDG_DOWNLOAD_DIR="${HOME}/Downloads"
    export XDG_MUSIC_DIR="${HOME}/Music"
    export XDG_PICTURES_DIR="${HOME}/Pictures"
    export XDG_PUBLICSHARE_DIR="${HOME}/Public"
    export XDG_VIDEOS_DIR="${HOME}/Movies"

    export XDG_TEMPLATES_DIR="${HOME}/Documents/Templates"
    if [ ! -d "${XDG_TEMPLATES_DIR}" ]; then
      mkdir "${XDG_TEMPLATES_DIR}"
    fi

    # MacPorts will install things here.
    if [ -d "/opt/local/share" ]; then
      export XDG_DATA_DIRS="/opt/local/share:${XDG_DATA_DIRS}"
    fi
    ;;

  Linux*Microsoft*)
    # WSL2.
    export XDG_CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"
    ;;

  Linux*)
    # Normal Linux.
    export XDG_CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"
    ;;

  CYGWIN*|MINGW*|MINGW32*|MSYS*)
    # Non-WSL2 Windows.
    ;;

  *)
    ;;
esac

# Everything below is customizations for various tools to support (or at least
# better support) the XDG standard for where they stick files.

# AWS CLI.

export AWS_CONFIG_FILE="${XDG_CONFIG_HOME}/aws/config"
export AWS_SHARED_CREDENTIALS_FILE="${XDG_CONFIG_HOME}/aws/credentials"

# Cargo.
# See https://github.com/rust-lang/cargo/issues/1734.

export CARGO_HOME="${XDG_RUNTIME_DIR}/cargo-home"

if [ ! -e "${CARGO_HOME}" ] && hash cargo 2>/dev/null; then
  mkdir -p "${CARGO_HOME}"
  mkdir -p "${XDG_CONFIG_HOME}/cargo"
  
  for file in config.toml credentials.toml; do
    touch "${XDG_CONFIG_HOME}/cargo/${file}"
    ln -s "${XDG_CONFIG_HOME}/cargo/${file}" "${CARGO_HOME}/${file}"
  done
 
  for dir in git registry target; do
    mkdir -p "${XDG_CACHE_HOME}/cargo/${dir}"
    ln -s "${XDG_CACHE_HOME}/cargo/${dir}" "${CARGO_HOME}/${dir}"
  done

  for file in .global-cache .package-cache .package-cache-mutate; do
    touch "${XDG_CACHE_HOME}/cargo/${file}"
    ln -s "${XDG_CACHE_HOME}/cargo/${file}" "${CARGO_HOME}/${file}"
  done
 
  mkdir -p "${XDG_BIN_HOME}/cargo"
  ln -s "${XDG_BIN_HOME}/cargo" "${CARGO_HOME}/bin"
fi

# Docker.

export DOCKER_CONFIG="${XDG_CONFIG_HOME}/docker"

# K9S, a terminal UI for Kubernetes.

export K9SCONFIG="${XDG_CONFIG_HOME}/k9s"

# Kubernetes

export KUBECONFIG="${XDG_CONFIG_HOME}/kube/config"
export KUBECACHEDIR="${XDG_CACHE_HOME}/kube/cache"

# less, the pager with more.
#
# Some versions of less support XDG directly, but older versions of less are
# still out there.

export LESSKEY="${XDG_CONFIG_HOME}/less/keybinds"
export LESSHISTFILE="${XDG_STATE_HOME}/less/history"
if [ ! -d "${XDG_STATE_HOME}/less" ]; then
  mkdir "${XDG_STATE_HOME}/less"
fi

# Node package manager.

export NPM_CONFIG_USERCONFIG="${XDG_CONFIG_HOME}/npm/npmrc"

# Node version manager.

export NVM_DIR="${XDG_DATA_HOME}/nvm"

# Python.

export PYTHONSTARTUP="${XDG_CONFIG_HOME}/python/pythonstartup.py"

# Readline.

export INPUTRC="${XDG_CONFIG_HOME}/readline/inputrc"

# Vim and Neovim.

if hash vim 2>/dev/null; then
  vimrc_path="${XDG_CONFIG_HOME:-${HOME}/.config}/vim/vimrc"

  if [ -f "${vimrc_path}" ] && \
     [ "$(vim --clean -es +'exec "!echo" has("patch-9.1.0327")' +q)" -eq 0 ]; then
    export VIMINIT="set nocp | source ${vimrc_path}"
  fi
fi

# wget.

if hash wget 2>/dev/null; then
  if [ ! -r "${XDG_CONFIG_HOME}/wget/wgetrc" ]; then
    mkdir -p "${XDG_CONFIG_HOME}/wget"
    touch "${XDG_CONFIG_HOME}/wget/wgetrc"
  fi
  export WGETRC="${XDG_CONFIG_HOME}/wget/wgetrc"
  alias wget='wget --hsts-file="${XDG_CACHE_HOME}/wget/hsts"'
  if [ ! -d "${XDG_CACHE_HOME}/wget" ]; then
    mkdir -p "${XDG_CACHE_HOME}/wget"
  fi
fi

#export XAUTHORITY="${XDG_RUNTIME_DIR}/Xauthority"

# End ~/.config/xdg/xdg_environment.sh
