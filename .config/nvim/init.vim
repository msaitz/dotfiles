set tabstop=2 shiftwidth=2 expandtab autoindent number
set mouse=ar mousemodel=extend
set clipboard=unnamedplus
set noshowmode
set termguicolors
syntax on
filetype indent plugin on

let g:terraform_align=1
let g:terraform_fmt_on_save=1

colorscheme onehalfdark

call plug#begin()
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'scrooloose/nerdTree'
Plug 'junegunn/goyo.vim'
Plug 'hashivim/vim-terraform'
Plug 'itchyny/lightline.vim'
Plug 'dense-analysis/ale'
Plug 'sheerun/vim-polyglot'
Plug 'ludovicchabant/vim-gutentags'
Plug 'jiangmiao/auto-pairs'
Plug 'mhinz/vim-signify'
Plug 'terryma/vim-multiple-cursors'
Plug 'vim-scripts/indentpython.vim'
Plug 'tpope/vim-fugitive'

" Themes
Plug 'sonph/onehalf'
Plug 'rakr/vim-one'
call plug#end()

" fzf stuff
if has("nvim")
    " Escape inside a FZF terminal window should exit the terminal window
    " rather than going into the terminal's normal mode.
    autocmd FileType fzf tnoremap <buffer> <Esc> <Esc>
endif

" Enable FZF Rg preview window
command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always --smart-case '.shellescape(<q-args>), 1,
  \   fzf#vim#with_preview(), <bang>0)

let mapleader = " "
nmap <Leader><Space> :GFiles<CR>
nmap <leader>f :GFiles<CR>
nmap <leader>F :Files<CR>
nmap <leader>b :Buffers<CR>
nmap <leader>h :History<CR>
nmap <leader>t :BTags<CR>
nmap <leader>T :Tags<CR>
nmap <leader>l :BLines<CR>
nmap <leader>L :Lines<CR>
nmap <leader>' :Marks<CR>
nmap <leader>/ :Rg<CR>
nmap <leader>H :Helptags!<CR>
nmap <leader>C :Commands<CR>
nmap <leader>c :Commits<CR>
nmap <leader>cb :BCommits<CR>
nmap <leader>g :Goyo<CR>
nmap <leader>w :w<CR>
nmap <leader>wr :w !sudo tee % > /dev/null<CR>
nmap <leader>q :q!<CR>
map <C-x> :NERDTreeToggle<CR>

let g:lightline = {
      \ 'colorscheme': 'jellybeans',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'gitbranch', 'readonly', 'filename', 'modified' ] ]
      \ },
      \ 'component_function': {
      \   'gitbranch': 'FugitiveHead'
      \ },
      \ }
