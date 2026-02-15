# Path additions for MacPorts.
export PATH="${HOME}/.local/bin:/opt/local/libexec/gnubin:/opt/local/bin:/opt/local/sbin:${PATH}"

# THIS NEEDS TO HAPPEN AFTER PATH IS SET UP.
source "${XDG_CONFIG_HOME}/xdg/xdg_environment.sh"
