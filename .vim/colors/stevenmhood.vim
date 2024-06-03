" Vim color file
" Maintainer: Matthew Jimenez <mjimenez@ersnet.net>
" Last Change: 2005 Feb 25

" darkblack -- an alteration to the darkblue colorscheme by Bohdan Vlasyuk <bohdan@vstu.edu.ua>


set background=dark
hi clear
if exists("syntax_on")
 syntax reset
endif

let colors_name = "stevenmhood"

hi Normal       guifg=grey      guibg=black
hi ErrorMsg     guifg=white     guibg=lightblue                       ctermfg=white     ctermbg=lightblue
hi Visual       guifg=lightblue guibg=grey      gui=reverse           ctermfg=darkblue  ctermbg=lightgrey cterm=reverse
hi VisualNOS    guifg=lightblue guibg=grey      gui=reverse,underline ctermfg=darkblue  ctermbg=lightgrey cterm=reverse,underline
hi Todo         guifg=red       guibg=black                           ctermfg=red       ctermbg=black
hi Search       guifg=white     guibg=black                           ctermfg=white     ctermbg=black     cterm=underline         term=underline
hi IncSearch    guifg=black     guibg=gray                            ctermfg=black     ctermbg=gray

hi SpecialKey   guifg=cyan                                            ctermfg=darkcyan
hi Directory    guifg=cyan                                            ctermfg=cyan
hi Title        guifg=magenta                   gui=none              ctermfg=magenta                     cterm=bold
hi WarningMsg   guifg=red                                             ctermfg=red
hi WildMenu     guifg=yellow    guibg=black                           ctermfg=yellow    ctermbg=black     cterm=none              term=none
hi ModeMsg      guifg=lightblue                                       ctermfg=lightblue
hi MoreMsg                                                            ctermfg=darkgreen
hi Question     guifg=green                     gui=none              ctermfg=green                       cterm=none
hi NonText      guifg=lightcyan                                       ctermfg=lightcyan

hi StatusLine   guifg=lightblue guibg=gray      gui=none              ctermfg=black     ctermbg=darkgreen cterm=none term=none
hi StatusLineNC guifg=black     guibg=gray      gui=none              ctermfg=darkgreen ctermbg=black     cterm=none term=none
hi VertSplit    guifg=black     guibg=gray      gui=none              ctermfg=green     ctermbg=black     cterm=none term=none

hi Folded       guifg=darkgrey  guibg=black                           ctermfg=darkgrey  ctermbg=black     cterm=bold term=bold
hi FoldColumn   guifg=darkgrey  guibg=black                           ctermfg=darkgrey  ctermbg=black     cterm=bold term=bold
hi LineNr       guifg=green                                           ctermfg=green                       cterm=none

hi DiffAdd                      guibg=black                                             ctermbg=black     cterm=none term=none
hi DiffChange                   guibg=darkmagenta                                       ctermbg=magenta   cterm=none
hi DiffDelete   guifg=Blue      guibg=DarkCyan  gui=bold              ctermfg=lightblue ctermbg=cyan
hi DiffText                     guibg=Red       gui=bold                                ctermbg=red       cterm=bold
  
hi Cursor       guifg=black     guibg=lightgrey                       ctermfg=black     ctermbg=lightgrey
hi lCursor      guifg=black     guibg=darkgreen                       ctermfg=black     ctermbg=darkgreen

hi Comment      guifg=lightblue             ctermfg=lightblue
hi Constant     guifg=magenta               ctermfg=lightmagenta cterm=none
hi Special      guifg=Orange    gui=none    ctermfg=lightblue    cterm=none
hi Identifier   guifg=cyan                  ctermfg=lightcyan    cterm=none
hi Statement    guifg=yellow    gui=none    ctermfg=yellow       cterm=none
hi PreProc      guifg=magenta   gui=none    ctermfg=lightmagenta cterm=none
hi type         guifg=green     gui=none    ctermfg=lightgreen   cterm=none
hi Underlined                                                    cterm=underline term=underline
hi Ignore       guifg=black                 ctermfg=black
