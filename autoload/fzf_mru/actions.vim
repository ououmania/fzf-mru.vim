" =============================================================================
" File:          autoload/fzf_mru/mrufiles.vim
" Description:   Most Recently Used Files
" Author:        Pawel Bogut <github.com/pbogut>
" =============================================================================

function! fzf_mru#actions#params(params)
  let params = a:params
  if (len(params) && params[0] != '-')
    let params = '-q ' . shellescape(params)
  endif

  return params
endfunction

function! fzf_mru#actions#options() abort
  let options = '--prompt "MRU>" '
  if !empty(get(g:, 'fzf_mru_no_sort', 0))
    let options .= '--no-sort '
  endif
  return options
endfunction

function! s:sink(delkey, Original, lines) abort
  if !empty(a:lines) && a:lines[0] ==# a:delkey
    if len(a:lines) > 1
      call fzf_mru#mrufiles#remove_display(a:lines[1:])
    endif
    return
  endif
  call a:Original(a:lines)
endfunction

function! s:inject_opts(options, delkey) abort
  let opts = a:options
  if opts !~# '--multi\>'
    let opts .= ' --multi'
  endif
  if opts =~# '--expect='
    let opts = substitute(opts, '\(--expect=\S*\)', '\1,' . escape(a:delkey, '\&~'), '')
  else
    let opts .= ' --expect=' . a:delkey
  endif
  return opts
endfunction

function! fzf_mru#actions#mru(...) abort
  let params = fzf_mru#actions#params(get(a:, 001, ''))
  let options = extend(
        \   {
        \     'source': fzf_mru#mrufiles#source(),
        \     'options': fzf_mru#actions#options() . params,
        \   },
        \   get(a:, 002, {})
        \ )

  let extra = extend(copy(get(g:, 'fzf_layout', {'down': '~40%'})), options)

  let spec = fzf#wrap('name', extra, 0)
  let delkey = get(g:, 'fzf_mru_delete_key', 'ctrl-d')
  let spec.options = s:inject_opts(spec.options, delkey)
  let l:Original = spec['sink*']
  let spec['sink*'] = {lines -> s:sink(delkey, l:Original, lines)}
  call fzf#run(spec)
endfunction
