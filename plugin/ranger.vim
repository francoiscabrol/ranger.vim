" Copyright (c) 2015 François Cabrol
"
" MIT License
"
" Permission is hereby granted, free of charge, to any person obtaining
" a copy of this software and associated documentation files (the
" "Software"), to deal in the Software without restriction, including
" without limitation the rights to use, copy, modify, merge, publish,
" distribute, sublicense, and/or sell copies of the Software, and to
" permit persons to whom the Software is furnished to do so, subject to
" the following conditions:
"
" The above copyright notice and this permission notice shall be
" included in all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
" EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
" MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
" NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
" LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
" OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
" WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


" ================ Ranger =======================
scriptencoding utf-8

if exists('g:ranger_choice_file')
  if empty(glob(g:ranger_choice_file))
    let s:choice_file_path = g:ranger_choice_file
  else
    echom 'Message from *Ranger.vim* :'
    echom "You've set the g:ranger_choice_file variable."
    echom 'Please use the path for a file that does not already exist.'
    echom 'Using /tmp/chosenfile for now...'
  endif
endif

if exists('g:ranger_command_override')
  let s:ranger_command = g:ranger_command_override
else
  let s:ranger_command = 'ranger'
endif

if !exists('s:choice_file_path')
  let s:choice_file_path = '/tmp/chosenfile'
endif

" Run Ranger in a new tab, only if set by user
let g:tabbed_ranger = get(g:, 'tabbed_ranger', 0)

let g:debug_ranger = get(g:, 'debug_ranger', 0)
function! s:debugmessage(mes)
  if g:debug_ranger
    redraw | echohl Keyword | echomsg a:mes | echohl None
  else
    return
  endif
endfunction

if has('nvim')
  function! OpenRangerIn(path, edit_cmd)
    let currentPath = expand(a:path)
    let rangerCallback = {
          \'name': 'ranger',
          \'edit_cmd': a:edit_cmd,
          \'previous_alternate': bufnr('#'),
          \'previous_buffer': bufnr('%')
          \}
    function! rangerCallback.on_exit(job_id, code, event)
      call <SID>debugmessage('alt before: ' . bufname(self.previous_alternate))
      call <SID>debugmessage('current before: ' . bufname(self.previous_buffer))
      let ranger_buf = bufnr('%')
      if ranger_buf == self.previous_buffer
        let self.previous_buffer = -1
        let ranger_ate_buffer = 1
        call <SID>debugmessage('ranger ate buffer')
      endif
      let from_dir_buffer = exists('w:alternate_buffer')
      " If ranger opened in a tab we can safely close the window
      " We'll delete the buffer when the function ends
      if exists('w:used_a_tab') | close! | endif
      try
        if filereadable(s:choice_file_path)
          let files = readfile(s:choice_file_path)
        endif
      endtry

      if !exists('l:files') || self.edit_cmd ==# 'tabedit ' && !exists('w:used_a_tab')
        let should_visit_previous = 1
      endif

      if exists('l:should_visit_previous') && !exists('l:ranger_ate_buffer')
        if from_dir_buffer
          call <SID>debugmessage('visit buffer: ' . bufname(self.previous_alternate))
          exec 'buffer ' . self.previous_alternate
        else
          call <SID>debugmessage('visit buffer: ' . bufname(self.previous_buffer))
          exec 'buffer ' . self.previous_buffer
        endif
      endif

      if from_dir_buffer
        call <SID>debugmessage('delete buffer: ' . bufname(self.previous_buffer))
        exec 'bdelete! ' . self.previous_buffer
      endif

      if self.edit_cmd ==# 'edit ' && exists('l:files')
        for f in files
          exec self.edit_cmd . f
        endfor
      endif

      call <SID>debugmessage('ranger_buf: ' . ranger_buf)
      let ranger_buf_name = bufname(ranger_buf)
      exec 'bdelete! ' . ranger_buf

      if !exists('w:used_a_tab')

        if self.edit_cmd ==# 'tabedit '
          let @# = self.previous_alternate
          call <SID>debugmessage('alt: tabedit')

        elseif from_dir_buffer
          let @# = w:alternate_buffer
          unlet w:alternate_buffer
          call <SID>debugmessage('alt: from_dir_buffer')

        elseif !exists('l:files')
          if exists('l:ranger_ate_buffer')
            let @# = ranger_buf + 1
            call <SID>debugmessage('alt: ranger_buf + 1')
          else
            let @# = self.previous_alternate
            call <SID>debugmessage('alt: no files')
          endif

        elseif exists('l:files')
          if exists('l:ranger_ate_buffer')
            let @# = @%
            call <SID>debugmessage('alt: current')
          else
            let @# = self.previous_buffer
            call <SID>debugmessage('alt: files')
          endif

        else
          call <SID>debugmessage("don't know what to do")
        endif
      endif

      call <SID>debugmessage('set alt from logic: ' . @#)

      if self.edit_cmd ==# 'tabedit ' && exists('l:files')
        for f in files
          exec self.edit_cmd . f
        endfor
      endif

      call delete(s:choice_file_path)
    endfunction
    " if the user likes it, open a tab, only when not 'editing' a directory
    if g:tabbed_ranger && !isdirectory(fnamemodify(bufname('%'), ':p'))
      tabnew
      let w:used_a_tab = 1
    else
      enew
    endif
    if isdirectory(currentPath)
      call termopen(s:ranger_command . ' --choosefiles=' . s:choice_file_path . ' "' . currentPath . '"', rangerCallback)
      " should disable 'OpenRangerOnVimLoadDir()' kicking in for this buffer
      let b:ranger_buf = 1
    else
      call termopen(s:ranger_command . ' --choosefiles=' . s:choice_file_path . ' --selectfile="' . currentPath . '"', rangerCallback)
      let b:ranger_buf = 1
    endif
    startinsert
  endfunction
else
  function! OpenRangerIn(path, edit_cmd)
    let currentPath = expand(a:path)
    if isdirectory(currentPath)
      silent exec '!' . s:ranger_command . ' --choosefiles=' . s:choice_file_path . ' "' . currentPath . '"'
    else
      silent exec '!' . s:ranger_command . ' --choosefiles=' . s:choice_file_path . ' --selectfile="' . currentPath . '"'
    endif
    if filereadable(s:choice_file_path)
      for f in readfile(s:choice_file_path)
        exec a:edit_cmd . f
      endfor
      call delete(s:choice_file_path)
    endif
    redraw!
    " reset the filetype to fix the issue that happens
    " when opening ranger on VimEnter (with `vim .`)
    filetype detect
  endfun
endif

" For backwards-compatibility (deprecated)
if exists('g:ranger_open_new_tab') && g:ranger_open_new_tab
  let s:default_edit_cmd='tabedit '
else
  let s:default_edit_cmd='edit '
endif

command! RangerCurrentFile call OpenRangerIn("%", s:default_edit_cmd)
command! RangerCurrentDirectory call OpenRangerIn("%:p:h", s:default_edit_cmd)
command! RangerWorkingDirectory call OpenRangerIn(".", s:default_edit_cmd)
command! Ranger RangerCurrentFile

" To open the selected file in a new tab
command! RangerCurrentFileNewTab call OpenRangerIn("%", 'tabedit ')
command! RangerCurrentDirectoryNewTab call OpenRangerIn("%:p:h", 'tabedit ')
command! RangerWorkingDirectoryNewTab call OpenRangerIn(".", 'tabedit ')
command! RangerNewTab RangerCurrentDirectoryNewTab

" For retro-compatibility
function! OpenRanger()
  Ranger
endfunction

" Open Ranger in the directory passed by argument
function! OpenRangerOnVimLoadDir(argv_path)
  let path = expand(a:argv_path)
  " Delete empty buffer created by vim after opening file,
  " in the callback, so we can use 'bdelete'
  " Set alternate to the directory buffer
  let w:alternate_buffer = bufnr('#')
  call OpenRangerIn(path, 'edit ')
endfunction

" To open ranger when vim load a directory
if exists('g:ranger_replace_netrw') && g:ranger_replace_netrw
  augroup ReplaceNetrwByRangerVim
    autocmd VimEnter * silent! autocmd! FileExplorer
    autocmd BufEnter * if !exists('b:ranger_buf') && isdirectory(expand("%")) | call OpenRangerOnVimLoadDir("%") | endif
  augroup END
endif

if !exists('g:ranger_map_keys') || g:ranger_map_keys
  map <leader>f :Ranger<CR>
endif

