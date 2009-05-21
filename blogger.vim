" metarw scheme: blogger
" Version: 1.2
" Copyright (C) 2009 ujihisa <http://ujihisa.blogspot.com/>
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
" Interface  "{{{1
" FIXME: metarw#blogger#complete NOT IMPLEMENTED!
"   The following metarw#blogger#complete() is just the copy from metarw-git
" script variables {{{2
let s:blogger_rb_command = printf('ruby %s/blogger.rb', expand('<sfile>:p:h'))
function! metarw#blogger#complete(arglead, cmdline, cursorpos)  "{{{2
  " a:arglead always contains "blogger:".
  let _ = s:parse_incomplete_fakepath(a:arglead)

  let candidates = []
  if _.path_given_p  " git:{commit-ish}:{path} -- complete {path}.
    for object in s:git_ls_tree(_.git_dir, _.commit_ish, _.leading_path)
      call add(candidates,
      \        printf('%s:%s%s:%s%s',
      \               _.scheme,
      \               _.git_dir_part,
      \               _.given_commit_ish,
      \               object.path,
      \               (object.type ==# 'tree' ? '/' : '')))
    endfor
    let head_part = printf('%s:%s%s:%s%s',
    \                      _.scheme,
    \                      _.git_dir_part,
    \                      _.given_commit_ish,
    \                      _.leading_path,
    \                      _.leading_path == '' ? '' : '/')
    let tail_part = _.last_component
  else  " git:{commit-ish} -- complete {commit-ish}.
    " sort by remote branches or not.
    for branch_name in s:git_branches(_.git_dir)
      call add(candidates,
      \        printf('%s:%s%s:', _.scheme, _.git_dir_part, branch_name))
    endfor
    let head_part = printf('%s:%s',
    \                      _.scheme,
    \                      _.git_dir_part)
    let tail_part = _.given_commit_ish
  endif

  return [candidates, head_part, tail_part]
endfunction




function! metarw#blogger#read(fakepath)  "{{{2
  let _ = s:parse_incomplete_fakepath(a:fakepath)
  if _.method == 'show'
    return ['read', printf('!%s show %s %s', s:blogger_rb_command, g:blogger_blogid, _.uri)]
  elseif _.method == 'list'
    let s:browse = []
    for entry in split(system(printf('%s list %s', s:blogger_rb_command, g:blogger_blogid)), "\n")
      let uri = split(entry, " -- ")[-1]
      let s:browse = add(s:browse, {
      \  'label': entry,
      \  'fakepath': 'blogger:' . uri})
    endfor
    return ['browse', s:browse]
  else
    " TODO: Detail information on error
    return ['error', '???']
  endif
endfunction




function! metarw#blogger#write(fakepath, line1, line2, append_p)  "{{{2
  let _ = s:parse_incomplete_fakepath(a:fakepath)
  if _.method == 'show'
    return ['write', printf('!%s update %s %s %s %s', s:blogger_rb_command, g:blogger_blogid, _.uri, g:blogger_email, g:blogger_pass)]
  elseif _.method == 'create'
    return ['write', printf('!%s create %s %s %s', s:blogger_rb_command, g:blogger_blogid, g:blogger_email, g:blogger_pass)]
  else
    " TODO: Detail information on error
    return ['error', '???']
  endif
endfunction



function! s:parse_incomplete_fakepath(incomplete_fakepath)  "{{{2
  " Return value '_' has the following items:
  "
  " Key                 Value
  " ------------------  -----------------------------------------
  " given_fakepath      same as a:incomplete_fakepath
  "
  " scheme              {scheme} part in a:incomplete_fakepath (always 'blogger')
  "
  " uri                 'blogger:...:{uri}' or nil
  " method              'create', 'list' or 'show'
  let _ = {}

  let fragments = split(a:incomplete_fakepath, ':', !0)
  if  len(fragments) <= 1
    echoerr 'Unexpected a:incomplete_fakepath:' string(a:incomplete_fakepath)
    throw 'metarw:blogger#e1'
  endif

  let _.given_fakepath = a:incomplete_fakepath
  let _.scheme = fragments[0]

  if len(fragments) < 2
    " error
  elseif fragments[1] == 'create'
    let _.method = 'create'
  elseif fragments[1] == 'list'
    let _.method = 'list'
  else
    let _.method = 'show'
    " {uri}
    let _.uri = join(fragments[1:-1], ":")
  endif

  return _
endfunction





" __END__  "{{{1
" vim: foldmethod=marker
