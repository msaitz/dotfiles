set tabstop=2 shiftwidth=2 expandtab autoindent number
set mouse=ar mousemodel=extend
set clipboard=unnamedplus
syntax on
filetype indent plugin on
map <C-x> :NERDTreeToggle<CR>

let g:airline_theme='one'
"colorscheme one
"set background=dark 
colo delek

call plug#begin()
"Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --no-bash' }
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'scrooloose/nerdTree'
Plug 'rakr/vim-one'
"Plug 'neoclide/coc.nvim', {'tag': '*', 'do': { -> coc#util#install()}}
"Plug 'tpope/vim-endwise'
"Plug 'davidhalter/jedi'
"Plug 'SirVer/ultisnips'
"Plug 'honza/vim-snippets'
"Plug 'deoplete-plugins/deoplete-jedi'
"Plug 'terryma/vim-multiple-cursors'
call plug#end()

"fzf stuff
if has("nvim")
    " Escape inside a FZF terminal window should exit the terminal window
    " rather than going into the terminal's normal mode.
    autocmd FileType fzf tnoremap <buffer> <Esc> <Esc>
endif

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

" Enable FZF Rg preview window
command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always --smart-case '.shellescape(<q-args>), 1,
  \   fzf#vim#with_preview(), <bang>0)

