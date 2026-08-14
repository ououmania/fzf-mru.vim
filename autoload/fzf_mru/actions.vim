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

function! s:sink(delkey, Original, args, lines) abort
  if !empty(a:lines) && a:lines[0] ==# a:delkey
    if len(a:lines) > 1
      call fzf_mru#mrufiles#remove_display(a:lines[1:])
    endif
    " Reopen a refreshed MRU list instead of closing fzf.
    call call('fzf_mru#actions#mru', a:args)
    return
  endif
  call a:Original(a:lines)
endfunction

" Render a key-mapping hint for fzf's --footer, mirroring the style used by
" fzf.vim's own s:build_hint(): each entry is "C-KEY Description" with the key
" tinted magenta (ANSI 35), joined by two spaces. The standard open actions
" (Enter / C-X / C-V / C-T) are taken from g:fzf_action so they stay in sync
" with the user's configuration; a:extra lets callers append MRU-specific keys.
function! s:build_hint(extra) abort
  let entries = copy(a:extra)
  call add(entries, ['Enter', 'Open'])
  let actions = get(g:, 'fzf_action', {'ctrl-t': 'tab split', 'ctrl-x': 'split', 'ctrl-v': 'vsplit'})
  for [key, name, label] in [['ctrl-x', 'C-X', 'HSplit'], ['ctrl-v', 'C-V', 'VSplit'], ['ctrl-t', 'C-T', 'New tab']]
    let Cmd = get(actions, key, '')
    if type(Cmd) == type('') && Cmd ==# actions[key]
      call add(entries, [name, label])
    endif
  endfor
  let keys = []
  for [key, action] in entries
    call add(keys, "\x1b[35m".key."\x1b[m".' '.action)
  endfor
  return join(keys, '  ')
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
  " Explicitly (re)bind the delete key to accept, appended last so it wins
  " over any conflicting --bind the user may have set via $FZF_DEFAULT_OPTS.
  let opts .= ' --bind ' . shellescape(a:delkey . ':accept')

  " Document key mappings in the footer, consistent with fzf.vim's own
  " --footer hints. C-A (toggle-all) is our global binding; the delete key
  " is MRU-specific.
  let disp = substitute(a:delkey, 'ctrl-\(\w\)', 'C-\U\1', '')
  let opts .= ' --ansi --footer ' . shellescape(s:build_hint([['C-A', 'Toggle all'], [disp, 'Delete from mru']]))

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
  let l:Args = a:000
  let spec['sink*'] = {lines -> s:sink(delkey, l:Original, l:Args, lines)}
  call fzf#run(spec)
endfunction
