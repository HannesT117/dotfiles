set relativenumber

" filetype plugins
filetype plugin on
filetype indent on

" Turn on file / command completion 
set wildmenu
" Ignore compiled files
set wildignore=*.o,*~,*.pyc,*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store

" === Search

set ignorecase " Ignore
set hlsearch " Highlight results
set incsearch " Incremental highlighting

" === Regex handling (use very magic) 
:nnoremap / /\v
:cnoremap %s/ %s/\v
set regexpengine=0 " set regex engine automatically

" === GUI
set showmatch " Highlight corresponding brackets
syntax enable " Syntax highlighting

" Visual mode pressing * or # searches for the current selection
vnoremap <silent> * :<C-u>call VisualSelection('', '')<CR>/<C-R>=@/<CR><CR>
vnoremap <silent> # :<C-u>call VisualSelection('', '')<CR>?<C-R>=@/<CR><CR>
