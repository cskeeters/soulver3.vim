" Assouline Yohann
" April 2022

let s:last_job = 0
let s:file_name = ""
let s:nb_empty_lines = 0
let s:soulver_output = []

function! s:Notify(msg)
    if has('nvim')
        lua vim.notify(vim.fn.eval('a:msg'))
    else
        echom a:msg
    endif
endfunction

function! s:CheckSoulver3Install()
    let l:basic_calc = " 21 + 21"
    let l:res = system('echo'.l:basic_calc.' | '. g:soulver_cli_path)
    return l:res == "42\n"
endfunction

function! s:CountLineToOffset(fc)
    let l:count = 0

    for l in a:fc
        if (l[0] == '#') || len(l) == 0
            let l:count += 1
        else
            break
        endif
    endfor

    return l:count
endfunction

function! s:handler(job_id, data, event_type)
    " Ignore updates from old jobs
    if a:job_id != s:last_job
        return
    endif

    if a:event_type == "stdout"
        " Each chunk has extra line since last line ends with \n
        call remove(a:data, -1)

        call extend(s:soulver_output, a:data)
    endif

    if a:event_type == "stderr"
        if len(a:data) == 0
            return
        endif

        if len(a:data) == 1
            if a:data[0] == ""
                return
            endif
            if a:data[0] == "\n"
                return
            endif

            echoerr "soulver SL stderr:"..a:data[0]
            return
        endif

        echoerr "soulver stderr:"
        echoerr join(a:data, "\n")
    endif

    if a:event_type == "exit"
        let l:soulver_buf_name = s:file_name . "_SoulverViewBuffer"

        let l:currentWindow=winnr()

        if bufwinid(l:soulver_buf_name) == -1
            :vnew
            :setlocal buftype=nofile
            :setlocal bufhidden=hide
            :setlocal noswapfile
            :setlocal filetype=soulver
            :setlocal nonumber norelativenumber

            " Assign name for this buffer
            :exe "file " . l:soulver_buf_name

            " Set focus back
            :exec l:currentWindow.."wincmd w"
        endif

        let l:empty_lines = []
        for i in range(s:nb_empty_lines)
            call add(l:empty_lines, "")
        endfor

        let l:bufnr = bufnr(l:soulver_buf_name, 0)
        let s:soulver_output = l:empty_lines + s:soulver_output

        " If buffer has more lines than our output, they would stay if not for this.
        call deletebufline(l:bufnr, 1, '$')

        call setbufline(l:bufnr, 1, s:soulver_output)
        call s:Notify("soulver finshed!")
    endif

    " echo a:job_id . ' ' . a:event_type
endfunction


function! soulver3#Soulver()
    if ! exists("g:soulver_cli_path")
        echoerr "g:soulver_cli_path not defined"
        return
    endif
    if s:CheckSoulver3Install() == 0
        echoerr "Basic calculation with soulver gave wrong result, check your installation"
        return
    endif

    if g:async_vim == 1
        " The function is available, safe to use
        " let g:job = async#job#start(['ls'])

        let l:file_content = getline(1,'$')
        let s:nb_empty_lines = s:CountLineToOffset(l:file_content)
        " let l:file_content_str = join(l:file_content, "\n")

        let s:last_job = 0 " Block all updates to soulver_output
        let s:soulver_output = [] " Initialize/reset

        let l:argv = [g:soulver_cli_path]
        let l:jobid = async#job#start(l:argv, {
            \ 'on_stdout': function('s:handler'),
            \ 'on_stderr': function('s:handler'),
            \ 'on_exit': function('s:handler'),
            \ 'normalize': 'array'
        \ })

        if l:jobid > 0
            let s:last_job = l:jobid
            let s:file_name = expand('%:t:r')
            call async#job#send(l:jobid, l:file_content, {'close_stdin': 1})

            call s:Notify("Running soulver...")
        else
            echoerr 'job for soulver failed to start'
        endif
    else
        " Fallback or error message
        echoerr "async.vim is not installed!"
    endif

endfunction

function! soulver3#LiveOn()
    call soulver3#Soulver()
    augroup SoulverVimAutocomandGroup
        autocmd TextChanged,TextChangedP,TextChangedI *.soulver :call soulver3#Soulver()
    augroup END
endfunction

function! soulver3#LiveOff()
    augroup SoulverVimAutocomandGroup
        autocmd!
    augroup END
endfunction
