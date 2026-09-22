" OSC 52 clipboard-yank fallback for Vim without native clipboard support.

if has('nvim') || has('clipboard_working')
  finish
endif

if !exists('*OSCYankRegister')
  finish
endif

if exists('g:loaded_osc52_clipboard_fallback')
  finish
endif
let g:loaded_osc52_clipboard_fallback = 1


function! OSC52ClipboardYankBegin() abort
  let s:osc52_saved_z = getreginfo('z')
  let s:osc52_saved_unnamed = getreginfo('"')
  let s:osc52_pending = 1

  return '"zy'
endfunction


function! s:OSC52YankPost() abort
  if !get(s:, 'osc52_pending', 0)
        \ || v:event.operator !=# 'y'
        \ || v:event.regname !=# 'z'
    return
  endif

  let s:osc52_pending = 0

  try
    call OSCYankRegister('z')
  finally
    call setreg('z', s:osc52_saved_z)
    call setreg('"', s:osc52_saved_unnamed)
  endtry
endfunction


augroup OSC52ClipboardFallback
  autocmd!
  autocmd TextYankPost * call s:OSC52YankPost()
augroup END
