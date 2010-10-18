" shymenu.vim -- Show the menu bar only when pressing an accel key
" @Author:      Thomas Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-11-12.
" @Last Change: 2008-11-18.
" @Revision:    132
" GetLatestVimScripts: 2437 0 shymenu.vim

if &cp || exists("loaded_shymenu")
    finish
endif
let loaded_shymenu = 3

let s:save_cpo = &cpo
set cpo&vim

if !exists('g:shymenu_emenu')
    " If true, use |:emenu| instead of the GUI menu.
    let g:shymenu_emenu = !has('gui_running')   "{{{2
endif

if !exists('g:shymenu_termalt')
    " If true, make alt-keys work on the terminal. Requires 
    " |g:shymenu_emenu| to be true.
    let g:shymenu_termalt = !has('gui_running') "{{{2
endif

if !exists('g:shymenu_wildcharm')
    if &wildcharm == 0
        " The value of 'wildcharm' as string.
        let g:shymenu_wildcharm = '<c-t>'   "{{{2
        exec 'set wildcharm='. g:shymenu_wildcharm
    elseif g:shymenu_emenu
        let g:shymenu_wildcharm = nr2char(&wildcharm) "{{{2
        " echoerr 'Please set g:shymenu_wildcharm. ShyMenu was not loaded'
        " finish
    endif
endif

if !exists('g:shymenu_modes')
    " A string that defines the modes for which the maps should be 
    " defined. On international keyboards, the alt-maps could conflict 
    " with special characters, which is why insert mode maps are 
    " disabled by default:
    "   n ... normal mode
    "   i ... insert mode
    let g:shymenu_modes = 'n'   "{{{2
endif

if !exists('g:shymenu_winpos_fullscreen')
    " If the output of |:winpos| matches this pattern, we assume the 
    " window is in fullscreen mode.
    let g:shymenu_winpos_fullscreen = '-\d$'   "{{{2
endif

if !exists('g:shymenu_items')
    " Custom menus (eg. buffer-local menus) that are not detected by 
    " shymenu.
    " Format: {KEY: NAME}
    let g:shymenu_items = {}  "{{{2
endif

if !exists('g:shymenu_blacklist')
    " An array of single-letter strings. Don't create maps for these 
    " keys.
    let g:shymenu_blacklist = []   "{{{2
endif

if !exists('g:shymenu_lines')
    " Increase/decrease 'lines' when hiding/showing the menu bar in 
    " order to maintain the overall window size.
    let g:shymenu_lines = 1   "{{{2
endif

function! s:ShyMenuCollect() "{{{3
    redir => itemss
    silent menu
    redir END
    let items = split(itemss, '\n')
    call filter(items, 'v:val =~ ''^\d''')
    let s:shymenu_items = copy(g:shymenu_items)
    for item in items
        let ml = matchlist(item, '^\(\d\+\)\s\+\(.*\)$')
        if get(ml, 1) > 1
            let key = matchstr(ml[2], '&\zs.')
            if empty(key)
                let key = ml[2][0]
            endif
            let key = tolower(key)
            if index(g:shymenu_blacklist, key) == -1
                let name0 = substitute(ml[2], '&', '', 'g')
                " TLogVAR key, name0
                let s:shymenu_items[key] = name0
            else
                " TLogVAR key
            endif
        endif
    endfor
endf
call s:ShyMenuCollect()

augroup ShyMenu
    autocmd!
augroup END

function! s:ShowMenu() "{{{3
    return &guioptions =~# 'm'
endf

let s:show_menu = s:ShowMenu()

function! s:IsFullScreen() "{{{3
    redir => winp
    silent winpos
    redir END
    return winp =~ g:shymenu_winpos_fullscreen
endf

function! s:InstallAutocmd() "{{{3
    autocmd ShyMenu BufEnter,BufWinEnter,CursorMoved,CursorMovedI,CursorHold,CursorHoldI,FocusGained * if s:show_menu | call ShyMenu(0) | endif
endf

function! s:UninstallAutocmd() "{{{3
    autocmd! ShyMenu
endf

function! s:SetTopLine(lineno) "{{{3
    if line('w0') != a:lineno
        let pos = getpos('.')
        exec 'keepjumps norm! '. a:lineno .'zt'
        call setpos('.', pos)
    endif
endf

function! s:SetMenu(mode) "{{{3
    if a:mode
        let topline = line('w0') + g:shymenu_lines
        if !s:IsFullScreen()
            let &lines -= g:shymenu_lines
        endif
        set guioptions+=m
        let s:show_menu = 1
        call s:InstallAutocmd()
    else
        let topline = line('w0') - g:shymenu_lines
        set guioptions-=m
        if !s:IsFullScreen()
            let &lines += g:shymenu_lines
        endif
        let s:show_menu = 0
        call s:UninstallAutocmd()
    endif
    call s:SetTopLine(topline)
    redraw
endf


" Set menu bar visibility.
" mode:
"   -1 ... toggle
"    0 ... hide
"    1 ... show
function! ShyMenu(mode) "{{{3
    if a:mode == -1
        if s:ShowMenu()
            call s:SetMenu(0)
        else
            call s:SetMenu(1)
        endif
    elseif a:mode
        if !s:ShowMenu()
            call s:SetMenu(1)
        endif
    else
        if s:ShowMenu()
            call s:SetMenu(0)
        endif
    endif
endf

let s:ttogglemenu = 0

function! s:ShyMenuInstall() "{{{3
    for [key, item] in items(s:shymenu_items)
        if g:shymenu_emenu
            if g:shymenu_modes =~ 'n'
                exec 'noremap <m-'. key .'> :emenu '. item .'.'. g:shymenu_wildcharm
            endif
            if g:shymenu_modes =~ 'i'
                exec 'inoremap <m-'. key .'> <c-o>:emenu '. item .'.'. g:shymenu_wildcharm
            endif
            let s:ttogglemenu = 0
            if g:shymenu_termalt
                exec 'set <m-'.key.'>='.key
            endif
        else
            if g:shymenu_modes =~ 'n'
                exec 'noremap <silent> <m-'. key .'> :call ShyMenu(1)\|simalt '. key .'<cr>'
            endif
            if g:shymenu_modes =~ 'i'
                exec 'inoremap <silent> <m-'. key .'> <c-o>:call ShyMenu(1)\|simalt '. key .'<cr>'
            endif
            let s:ttogglemenu = 1
        endif
    endfor
endf

autocmd ShyMenu VimEnter * call s:ShyMenuInstall()


let &cpo = s:save_cpo
unlet s:save_cpo


finish
CHANGES:
0.1
- Initial release

0.2
- g:shymenu_modes: Disable insert mode maps by default (conflict with 
international characters)

0.3
- Typos (thanks AS Budden)
- Correct line offset if necessary
- Set g:shymenu_wildcharm from &wildcharm

