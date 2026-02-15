" Assouline Yohann
" April 2022

let s:last_job = 0
let s:file_name = ""
let s:nb_empty_lines = 0
let s:soulver_output = []
let s:bufnr = 0 " .soulver
let s:bufnr_map = {} " .soulver -> SoulverViewBuffer

function! soulver3#Notify(msg)
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
        " Check to make sure the user didn't bdelete the source
        if bufwinid(s:bufnr) == -1
            call soulver3#Notify("soulver finished, but cancelled")
            return
        endif

        let l:soulver_buf_name = s:file_name . "_SoulverViewBuffer"

        " This will be -1 if the buffer doesn't exist
        let l:bufnr = bufnr(l:soulver_buf_name, 0)

        let l:currentWindow=winnr()

        :setlocal scrollbind

        " See if our SoulverViewBuffer is loaded in any window.
        if bufwinid(l:soulver_buf_name) == -1

            " Create a vertical split for SoulverViewBuffer
            " We will have to reset focus later
            :vnew

            " Only create a new buffer if it doesn't
            if l:bufnr == -1
                " Modify this empty buffer to serve as SoulverViewBuffer
                :setlocal buftype=nofile
                :setlocal bufhidden=hide
                :setlocal noswapfile
                :setlocal filetype=soulver
                :setlocal nonumber norelativenumber
                :setlocal scrollbind

                " Assign name for this buffer
                :exe "file " . l:soulver_buf_name
                let l:bufnr = bufnr(l:soulver_buf_name, 0)

                " Store an association so we can sync close
                let s:bufnr_map[s:bufnr] = l:bufnr
            else
                " Load SoulverViewBuffer into this split
                :exe "buffer "..l:bufnr
            endif

            " Set focus back to the input
            :exec l:currentWindow.."wincmd w"
        endif

        let l:empty_lines = []
        for i in range(s:nb_empty_lines)
            call add(l:empty_lines, "")
        endfor

        let s:soulver_output = l:empty_lines + s:soulver_output

        " If buffer has more lines than our output, they would stay if not for this.
        call deletebufline(l:bufnr, 1, '$')

        call setbufline(l:bufnr, 1, s:soulver_output)

        " One-time scroll sync since buffer has changed.
        syncbind

        call soulver3#Notify("soulver finshed!")
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

        let s:bufnr = bufnr()
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

            call soulver3#Notify("Running soulver...")
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

function! soulver3#BufDelete()
    let l:bufnr = expand('<abuf>')

    for nr in keys(s:bufnr_map)
        if l:bufnr == nr
            " User closed .soulver, close SoulverViewBuffer

            " Don't delete immediately since we're handling a BufDelete command
            " exe "bdelete! "..s:bufnr_map[nr]

            " Schedule deleting of associated SoulverViewBuffer
            call timer_start(0, { tid -> bufloaded(s:bufnr_map[nr]) && execute('bwipeout! ' . s:bufnr_map[nr]) })
        endif
        if l:bufnr == s:bufnr_map[nr]
            " User closed SoulverViewBuffer
        endif
    endfor
endfunction
