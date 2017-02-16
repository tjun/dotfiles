syntax on

set expandtab
set tabstop=4
set shiftwidth=2
set softtabstop=0
set autoread
set backspace=indent,eol,start

" 表示
set number
" set list
set showmatch
set showcmd
set smartindent
set autoindent

set incsearch
set wrapscan
set ignorecase
set smartcase
set hlsearch
nmap <Esc><Esc> :nohlsearch<CR><Esc>

set wildmenu
set wildchar=<tab>
set wildmode=list:full
set history=1000
set complete+=k

set encoding=utf-8
autocmd FileType make setlocal noexpandtab

"set backup
"set backupdir=$HOME/.vim-backup
" let &directory = &backupdir

nnoremap j gj
nnoremap k gk
" カーソル行をハイライト
set cursorline
" カレントウィンドウにのみ罫線を引く
augroup cch
  autocmd! cch
  autocmd WinLeave * set nocursorline
  autocmd WinEnter,BufRead * set cursorline
augroup END

:hi clear CursorLine
:hi CursorLine gui=underline
highlight CursorLine ctermbg=black guibg=black
" 保存時に行末の空白を除去する
autocmd BufWritePre * :%s/\s\+$//ge
" 保存時にtabをスペースに変換する
"autocmd BufWritePre * :%s/\t/  /g

set nocompatible
filetype off

set rtp+=~/.vim/vundle.git/
call vundle#rc()

Bundle 'Shougo/neocomplcache'
Bundle 'Shougo/unite.vim'
Bundle 'vim-ruby/vim-ruby'
Bundle 'sudo.vim'

filetype plugin indent on
syntax enable

" 挿入モードでのカーソル移動
inoremap <C-n> <Down>
inoremap <C-p> <Up>
inoremap <C-b> <Left>
inoremap <C-f> <Right>

" insertモードから抜ける
inoremap <silent> jj <ESC>
inoremap <silent> <C-j> j
inoremap <silent> kk <ESC>
inoremap <silent> <C-k> k
