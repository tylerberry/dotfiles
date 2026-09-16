# Make every Windows .exe known to syntax highlighting (no aliases, no pollution, no first-time red)
# Register every Windows .exe in PATH for syntax highlighting (no aliases, no pollution)
if [[ -n $WSL_DISTRO_NAME ]]; then
  local dir exe base
  for dir in ${(s.:.)PATH}; do
    [[ -d "$dir" ]] || continue
    for exe in "$dir"/*.exe(N); do
      [[ -x "$exe" ]] || continue
      base=${exe:t:r}
      [[ -z $commands[$base] ]] && commands[$base]="$exe"
    done
  done
fi

setopt HASH_EXECUTABLES_ONLY
zstyle ':completion:*:complete:-command-::commands' ignored-patterns \
  '*.(dll|DLL|sys|$SYS|drv|DRV|mof|MOF|efi|EFI|ini|INI|vbs|VBS|mui|MUI|tlb|TLB|ttc|TTC|ttf|TTF|ico|ICO|cpl|CPL|scr|SCR|acm|ACM|ax|AX|ocx|OCX|inf|INF|cat|CAT|manifest|MANIFEST|pdb|PDB|exp|EXP|ilk|ILK|obj|OBJ|nls|NLS)'

sudo() {
  local arg target resolved

  for arg in "$@"; do
    if [[ $arg == --* ]]; then
      command sudo "$@"
      return
    fi
  done

  (( $# )) || {
    command sudo
    return
  }

  target=$1

  if [[ $target == */* ]]; then
    [[ -f $target ]] && resolved=$target
  else
    resolved=${commands[$target]}
  fi

  if [[ -n $resolved && ${resolved:l} == *.exe ]]; then
    command sudo.exe "$@"
    return
  fi

  command sudo "$@"
}
