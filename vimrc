call plug#begin()

Plug 'bfrg/vim-cpp-modern'
Plug 'preservim/nerdtree'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'mbbill/undotree'

"Plug 'vim/colorschemes'
"Plug 'preservim/vim-markdown'
"Plug 'vimwiki/vimwiki'
"Plug 'bling/vim-bufferline'
"Plug 'chriskempson/base16-vim'
"Plug 'aklt/plantuml-syntax'
"Plug 'tyru/open-browser.vim'
"Plug 'weirongxu/plantuml-previewer.vim'
"Plug 'mattn/calendar-vim'
"Plug 'manuelmayr/C0Vim'
"Plug 'https://github.com/ryanoasis/vim-devicons'
"Plug 'lervag/vimtex'
"Plug 'lervag/vimtex', { 'tag': 'v2.15' }
"
call plug#end()

" VIMWIKI START
"let g:vimwiki_list = [{ 'path': '~/files', 'syntax': 'markdown', 'ext': '.md', 'diary_rel_path': 'Log'}]
let wiki = {}
let wiki.path = '~/files'
let wiki.syntax = 'markdown'
let wiki.ext = '.md'
let wiki.diary_rel_path = 'Log'
let g:vimwiki_markdown_link_ext = 1

" Code block syntax highlighting
let g:vimwiki_folding = 'expr'
let g:vimwiki_syntax = 'default'
let g:vimwiki_code_highlight = 1

" Make it so that the syntax highlighting is triggered immediatly and the file
" doesn't need to be reopened or have filetype=vimwiki set to refresh syntax
autocmd BufRead,BufNewFile *.md set filetype=vimwiki
autocmd BufWritePost,BufReadPost *.md set filetype=vimwiki

let g:vimwiki_list = [wiki]

au BufNewFile ~/files/*.md :silent 0r !~/.vim/bin/basic-template.py '%'
au BufNewFile ~/files/Log/*.md :silent 0r !~/.vim/bin/log-template.py '%'

" VIMWIKI END

set backspace=indent,eol,start
"let g:NERDTreeDirArrowExpandable="+"
"let g:NERDTreeDirArrowCollapsible="~"
set encoding=UTF-8

if !exists('g:syntax_on')
		syntax enable
endif

" colorscheme sorbet
"set t_Co=256
"let base16colorspace=256
"colorscheme base16-espresso
"set termguicolors
"highlight Normal ctermbg=NONE
"highlight nonText ctermbg=NONE
set cursorline
set nu rnu
set ruler
set incsearch
set nowrap

set tags+=./tags;/
set nocompatible

set enc=utf-8
set fenc=utf-8
set termencoding=utf-8

"autocmd Filetype tex setl updatetime=1
autocmd FileType * set nocindent
hi! link TODO Boolean
set smartindent
set sw=4 ts=4 expandtab

set textwidth=80
set colorcolumn=81
" set spell
set tabpagemax=20

" make vim . go to netrw
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) | execute 'Explore' | endif

let mapleader = ' '
" Window Navigation
" requires 'w' to be pressed twice to switch pane
nnoremap <leader>wg <C-W><C-W>l

" NERDTree
nnoremap <leader>g <C-W>w
nnoremap <leader>t :NERDTree<CR>

" Buffer Navigation
nnoremap <leader>b :w<CR>:Buf<CR>
nnoremap <leader>n :bn!<CR>
nnoremap <leader>p :bp!<CR>
nnoremap <leader>d :bd<CR>

" close all buffers except the current one
nnoremap <leader>cb :%bd\|e#\|bd#<CR>

" Misc Remaps
nnoremap <leader>h :Header <C-r>=input("Title: ")<CR><CR>
nnoremap <leader>f :w<CR>:Files<CR>
nnoremap <leader>g :w<CR>:RG<CR>
nnoremap <leader>s :source ~/.vimrc<CR>
"nnoremap <leader>dn :VimwikiDiaryNextDay<CR>
"nnoremap <leader>dp :VimwikiDiaryPrevDay<CR>
inoremap {<CR> {<CR>}<esc>O
inoremap kj <ESC>
nnoremap <ESC><ESC> :nohl<CR>
xnoremap rn :s/[0-9]*\./0./<CR>gvg<C-a>
nmap <leader>l :LLPStartPreview<cr>
nnoremap <leader>e :Explore<CR>

" fuzzy finder
nnoremap <leader>sb :w<CR>:Buffers<CR>
nnoremap <leader>sf :w<CR>:Files<CR>
nnoremap <leader>sg :w<CR>:RG<CR>

set backup
set backupdir=~/.vim/backup//

set undofile
set undodir=~/.vim/undodir//

set directory=~/.vim/swp//

" delete trailing white space upon write
autocmd BufWritePre * :%s/\s\+$//e

function! InsertDynamicHeader(title)
    " Define total width (optional, can be fixed or calculated based on title length)
    let l:total_width = max([76, len(a:title) + 20]) " Ensure at least 20 padding
    let l:divider = repeat("*", l:total_width)

    " Calculate padding
    let l:title_length = len(a:title)
    let l:total_padding = l:total_width - l:title_length " Account for borders
    let l:left_padding = repeat(" ", l:total_padding / 2)
    let l:right_padding = repeat(" ", l:total_padding - len(l:left_padding))

    " Construct header
    let l:header = "/*" . l:left_padding . a:title . l:right_padding . "*/"
    call append('.', "/*" . l:divider . "*/")
    call append('.', l:header)
    call append('.', "/*" . l:divider . "*/")
endfunction

command! -nargs=1 Header call InsertDynamicHeader(<q-args>)

"function! InsertCenteredHeader(title)
"    let l:divider = repeat("*", 78)
"    let l:title_length = len(a:title)
"    let l:total_padding = 78 - l:title_length - 29*2
"    let l:left_padding = repeat(" ", l:total_padding / 2)
"    let l:right_padding = repeat(" ", l:total_padding - len(l:left_padding))
"    let l:header = "/*****************************" . l:left_padding . a:title . l:right_padding . "*****************************/"
"    call append('.', '/'.l:divider.'/')
"    call append('.', l:header)
"    call append('.', '/'.l:divider.'/')
"endfunction
"
"command! -nargs=1 Header call InsertCenteredHeader(<q-args>)
