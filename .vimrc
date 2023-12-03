syntax on
set t_Co=256

set tags+=./tags;/
set nocompatible

set enc=utf-8
set fenc=utf-8
set termencoding=utf-8

filetype plugin indent off
set smartindent
set autoindent
set tabstop=8
set shiftwidth=8

set textwidth=80
set colorcolumn=81
set cursorline
set nospell
set nu rnu

" trailing whitespaces
" autocmd BufWinEnter <buffer> match Error /\s\+$/
" autocmd InsertEnter <buffer> match Error /\s\+\%#\@<!$/
" autocmd InsertLeave <buffer> match Error /\s\+$/
" autocmd BufWinLeave <buffer> call clearmatches()

highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/
autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
autocmd InsertLeave * match ExtraWhitespace /\s\+$/
autocmd BufWinLeave * call clearmatches()

inoremap kj <ESC>
inoremap {<CR> {<CR>}<esc>O
