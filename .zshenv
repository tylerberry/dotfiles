#!/bin/zsh

# Step 1: Detect if we're on macOS
if [[ "$(/usr/bin/uname)" == "Darwin" ]]; then

  # Step 2: Use dscl to find the correct username and home directory
  correct_user=$(/usr/bin/dscl . -search /Users UniqueID $(id -u) | /usr/bin/awk 'NR==1 {print $1}')
  correct_home=$(/usr/bin/dscl . -read /Users/$correct_user NFSHomeDirectory | /usr/bin/awk '{print $2}')

  # Step 3: Update USER and HOME environment variables if they are incorrect
  if [[ "${USER}" != "${correct_user}" || "${HOME}" != "${correct_home}" ]]; then
    export USER="${correct_user}"
    export HOME="${correct_home}"

    echo "WARNING: Mismatched environment detected."
    echo "WARNING: Environment variables USER and HOME fixed to '${correct_user}' and '${correct_home}'."

    if [[ -r "${correct_home}/.zshenv" ]]; then
      echo "WARNING: Loading configuration file: ${correct_home}/.zshenv"
      source "${correct_home}/.zshenv"
    fi

    # Terminate the script
    return
  fi
fi

export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:=${HOME}/.config}
export ZDOTDIR=${ZDOTDIR:=${XDG_CONFIG_HOME}/zsh}
[[ -r "${ZDOTDIR}/.zshenv" ]] && source $ZDOTDIR/.zshenv
