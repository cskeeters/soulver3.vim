" Assouline Yohann
" April 2022

if exists('g:soulver_vim_loadded')
    finish
endif

let g:soulver_vim_loadded = 1

" If installed with `brew install soulver-cli`, initialize automatically
let brew_prefix = trim(system("brew --prefix"))
if brew_prefix != ""
    let g:soulver_cli_path = brew_prefix."/bin/soulver"
else
    let g:soulver_cli_path = get(g:, 'soulver_cli_path', "'/Applications/Soulver\ 3.app/Contents/MacOS/CLI/soulver'")
endif

command! SoulverModeLive :call s:Soulver3ModeLive()
command! SoulverModeSave :call s:Soulver3ModeSave()
command! SoulverModeOff :call s:Soulver3ModeOff()

autocmd FileType soulver setlocal commentstring=#\ %s

" Track BufDelete so that we can close associated SoulverViewBuffer
autocmd BufDelete * :call soulver3#BufDelete()

" These are not in autoload so that autoload isn't loaded until a .soulver file is opened
function! s:Soulver3ModeLive()
    augroup SoulverVimAutocomandGroup
        autocmd!
        autocmd BufRead,TextChanged,TextChangedP,TextChangedI *.soulver :call soulver3#Soulver()
    augroup END

    " Call for the current window only
    call soulver3#Soulver()
endfunction

function! s:Soulver3ModeSave()
    augroup SoulverVimAutocomandGroup
        autocmd!
        autocmd BufWritePost *.soulver :call soulver3#Soulver()
    augroup END

    " Call for the current window only
    call soulver3#Soulver()
endfunction

function! s:Soulver3ModeOff()
    augroup SoulverVimAutocomandGroup
        autocmd!
    augroup END

    " Close SoulverViewBuffers
    call soulver3#CloseViews()
endfunction

call s:Soulver3ModeLive()
