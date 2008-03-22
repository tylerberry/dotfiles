" .vimrc - configuration file for vim - VI iMproved 
"
" Copyright (C) 2004 Tyler Berry
" Time-stamp: <2004-10-19 21:11:53 loki>
"
" Based on /etc/vimrc from the Debian distribution as well as /etc/vimrc from
" the Beyond Linux From Scratch project, with additions from Mike Urman's
" .vimrc among others'.
"
" This file is free software; you can redistribute it and/or modify it under
" the terms of the GNU General Public License as published by the Free Software
" Foundation; either version 2, or (at your option) any later version.
"
" This file is distributed in the hope that it will be useful, but WITHOUT ANY
" WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
" A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
"
" You should have received a copy of the GNU General Public License along with
" GNU Emacs; type C-h C-c inside GNU Emacs to view the license.  Otherwise,
" write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
" Boston, MA 02111-1307, USA.

" Based on /etc/vimrc from the Debian distribution as well as /etc/vimrc from
" BLFS.

" We strongly prefer running vim in vim mode; otherwise we would have just
" installed vi.  If you disagree, feel free to change this.

set nocompatible
set backspace=indent,eol,start

" In my opinion, vim's idea of what "looks good" against a dark background is
" nuts.

" set background=dark

" Enable syntax highlighting.

syntax on

" Here are some defaults for the editor that we happen to like.

set noautoindent  " Automatically indent to depth of previous line.
set nobackup      " Do not create backup files.
set ruler         " Display the location ruler at the bottom of the screen.
set textwidth=72  " Wrap at 72 columns by default.

" Tab characteristics that we happen to like.

set expandtab     " Replace tabs with space characters.
set shiftwidth=2  " Indent to mod 2 when you hit the tab key.
set softtabstop=2 " Interpret <TAB> as an indent-to rather than an insert-tab.
set tabstop=4     " If you see a \t, indent 4 spaces.

" Use UTF-8 by default.

set tenc=utf-8
set enc=utf-8

" viminfo preserves state between different sessions of vim.

set viminfo='20,\"50

" This is an increase in the size of the history buffers from an original size
" of 20.

set history=50

" Enable automatic file type detection.

if has("autocmd")
  filetype on
  filetype plugin on
  filetype indent on
endif

" Spellchecking keysyms, for regular documents and mail/news respectively.

map ^T :w!<CR>:!aspell check %<CR>:e! %<CR>

map ^R \1\2<CR>:e! %<CR>
map \1 :w!<CR>
map \2 :!newsbody -qs -n % -p aspell check \%f<CR>

" Some of the following significantly change the behavior of vim as compared to
" vi.  If you prefer a more compatible editor, you might want to turn some of
" these off.

set autowrite     " Automatically save before commands like :next and :make.
set ignorecase    " Do case insensitive matching.
set incsearch     " Do incremental searches.
set showcmd       " Show (partial) command in status line.
set showmatch     " Show matching brackets.
