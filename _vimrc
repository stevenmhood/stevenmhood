set guifont=Courier_New:h10

set autoindent            " always set autoindenting on
set backspace=2           " allow backspacing over everything in insert mode
set expandtab             " Get rid of tabs altogether and replace with spaces
set foldcolumn=2          " set a column in case it's needed
set foldlevel=0           " show all folds initially
set foldmethod=indent     " use indent unless overridden
set guioptions-=m         " Remove menu
set guioptions-=T         " Remove toolbar
set hidden                " hide buffers, don't close
set history=50            " 50 lines of command history
set ignorecase            " case-insensitive matching
set incsearch             " incremental search
set laststatus=2          " always have status bar
set linebreak             " This displays long lines as wrapped at word boundries
set matchtime=10          " Time to flash the brack with showmatch
set nobackup              " Don't need funny filenames with ~ at the end!  Git will handle it.
set nocompatible          " Use Vim defaults (much better!)
set number                " show line numbers
set ruler                 " the ruler on the bottom is useful
set scrolloff=1           " don't let the cursor get too close to the edge
set shiftwidth=4          " Set indention level to be the same as softtabstop
set showcmd               " Show (partial) command in status line.
set showmatch             " Show matching brackets.
set softtabstop=4         " Why are tabs so big?  This fixes it
set textwidth=0           " Don't wrap words by default
set textwidth=120         " This wraps a line with a break when you reach 120 chars

set titlestring=vim\:\ %t%(\ %)%M
set whichwrap+=<,>,[,],h,l,~

colorscheme darkblue

syntax on

filetype plugin on
filetype indent on

" Temp directory and *.swp directory
let $TMPDIR='$HOME/vimfiles'
set directory=$HOME/vimfiles

set lines=70 columns=150

" Restore gitcommit textwidth
autocmd FileType gitcommit set tw=72
