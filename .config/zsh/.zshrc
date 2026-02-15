# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.config/zsh/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

if [[ -r "${XDG_CONFIG_HOME}/iterm2/shell_integration.zsh" ]]; then
  source "${XDG_CONFIG_HOME}/iterm2/shell_integration.zsh"
fi

# Store history in the correct XDG location.
HISTFILE="${XDG_STATE_HOME}/zsh/history"
if [[ ! -d "${XDG_STATE_HOME}/zsh" ]]; then
  mkdir "${XDG_STATE_HOME}/zsh"
fi

# Zim configuration and setup.

ZIM_CONFIG_FILE="${XDG_CONFIG_HOME}/zim/zimrc"
ZIM_HOME="${XDG_CACHE_HOME}/zim"

zstyle ':zim:zmodule' use 'degit'

# Download zimfw plugin manager if missing.

if [[ ! -e "${ZIM_HOME}/zimfw.zsh" ]]; then
  curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
    https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
fi

# Install missing modules and update ${ZIM_HOME}/init.zsh if missing or 
# outdated.

if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZIM_CONFIG_FILE:-${ZDOTDIR:-${HOME}}/.zimrc} ]]; then
  source ${ZIM_HOME}/zimfw.zsh init -q
fi

# Initialize Zim and modules.
source ${ZIM_HOME}/init.zsh

# Aliases.

alias ls='ls --color=auto'
alias dotfiles='git --git-dir="${XDG_DATA_HOME}/dotfiles" --work-tree="${HOME}"'

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh

# Initialize nvm on Mac OS X if installed.

[[ -r /opt/local/share/nvm/init-nvm.sh ]] && source /opt/local/share/nvm/init-nvm.sh

# ????????
#. "/private/var/folders/6j/fd70xl4157z4_150rf9rtmqr0000gn/T/xdg/cargo-home/env"
