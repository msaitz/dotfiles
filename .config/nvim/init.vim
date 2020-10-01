"""" msaitz nvim config
syntax on
set noshowmode
set linebreak
set tabstop=2 shiftwidth=2 expandtab autoindent
set number
set mouse=ar mousemodel=extend
set clipboard=unnamedplus
set termguicolors
set encoding=utf8
filetype indent plugin on

let g:terraform_align=1
let g:terraform_fmt_on_save=1
let g:vim_markdown_folding_disabled = 1
let g:fzf_preview_window = 'right:60%'
let g:kite_tab_complete=1
let g:lightline = {
      \ 'colorscheme': 'wombat',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'gitbranch', 'readonly', 'filename', 'modified' ] ]
      \ },
      \ 'component_function': {
      \   'gitbranch': 'FugitiveHead',
      \   'filename': 'RelativeFilepath'
      \ },
      \ }

function! RelativeFilepath()
  return expand('%:~:.')
endfunction


colorscheme onehalfdark

""" Plugins
call plug#begin()
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
"Plug 'scrooloose/nerdTree'
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
Plug 'mhinz/vim-startify'
"Plug 'neoclide/coc.nvim', {'tag': '*', 'do': { -> coc#util#install()}}

""" Themes config
Plug 'sonph/onehalf'
call plug#end()

" fzf stuff
if has("nvim")
    " Escape inside a FZF terminal window should exit the terminal window
    " rather than going into the terminal's normal mode.
    autocmd FileType fzf tnoremap <buffer> <Esc> <Esc>
endif

""" Key bindings
let mapleader = " "

" Git
nmap <leader>gdf :Gvdiffsplit<CR>
nmap <leader>gs :GFiles?<CR>
nmap <leader>c :Commits<CR>
nmap <leader>cb :BCommits<CR>
nmap <leader>gt :SignifyToggle<CR>

" fzf
nmap <Leader><Space> :GFiles<CR>
nmap <leader>f :Files<CR>
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

" Tag navigation
nmap <leader>gd <C-]>
nmap <leader>gb <C-O>

" Extra bingings
"map <C-x> :NERDTreeToggle<CR>
nmap <leader>g :Goyo<CR>
nmap <leader>tt :vsp<CR>
nmap <leader>w :w<CR>
nmap <leader>wr :w !sudo tee % > /dev/null<CR>
nmap <leader>q :q!<CR>

""" Custom functionality
" Enable FZF Rg preview window
command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always --smart-case --hidden '.shellescape(<q-args>), 1,
  \   fzf#vim#with_preview(), <bang>0)

command! -bang -nargs=? -complete=dir Files
    \ call fzf#vim#files(<q-args>, fzf#vim#with_preview({'options': ['--layout=reverse', '--info=inline']}), <bang>0)

command! -bang -nargs=? -complete=dir GFiles
    \ call fzf#vim#gitfiles(<q-args>, fzf#vim#with_preview({'options': ['--layout=reverse', '--info=inline']}), <bang>0)

" Ensure exiting when in goyo mode exits vim
function! s:goyo_enter()
  let b:quitting = 0
  let b:quitting_bang = 0
  autocmd QuitPre <buffer> let b:quitting = 1
  cabbrev <buffer> q! let b:quitting_bang = 1 <bar> q!
endfunction

function! s:goyo_leave()
  if b:quitting && len(filter(range(1, bufnr('$')), 'buflisted(v:val)')) == 1
    if b:quitting_bang
      qa!
    else
      qa
    endif
  endif
endfunction

autocmd! User GoyoEnter call <SID>goyo_enter()
autocmd! User GoyoLeave call <SID>goyo_leave()
