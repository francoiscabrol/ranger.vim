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
  let s:choice_file_path = tempname()
endif

" Run Ranger in a new tab, only if set by user
let g:tabbed_ranger = get(g:, 'tabbed_ranger', 0)

if has('nvim')
  function! OpenRangerIn(path, edit_cmd)
    let currentPath = expand(a:path)
    let previous_buffer = expand('%')
    let rangerCallback = {
          \'name': 'ranger',
          \'edit_cmd': a:edit_cmd,
          \'previous_alternate': expand('#'),
          \'previous_buffer': previous_buffer
          \}
    function! rangerCallback.on_exit(job_id, code, event)
      try
        " If ranger opened in a tab we can safely close the window
        " We'll delete the buffer when the function ends
        if exists('b:used_a_tab') | close! | endif
        " remember the ranger buffer so we can delete it after it has left
        " the window, this avoids 'bdelete' closing the window
        let ranger_buf = expand('%')
        if filereadable(s:choice_file_path)
          let files = readfile(s:choice_file_path)
          " We'll open a file (or more), '% (before ranger)' should become '#',
          " we'll open the last file after visiting '% (before ranger)',
          " unless opening files in a new tab
          for f in files[0:-2]
            exec self.edit_cmd . f
          endfor
          if self.edit_cmd ==# 'edit '
            execute 'buffer ' . self.previous_buffer
          endif
          execute self.edit_cmd . files[-1]
          "clean up
          call delete(s:choice_file_path)
        else
          " Not opening any files, '% (before ranger)' & '# (before ranger)' should remain the same
          execute 'buffer ' . self.previous_alternate
          execute 'buffer ' . self.previous_buffer
        endif
        execute 'bdelete! ' . bufnr(ranger_buf)
      endtry
    endfunction
    " if the user likes it, open a tab for ranger unless they 'edit' a directory
    " for example when opening vim with directory arg (netrw replace)
    " also only uses the tab feature when at least two buffers exist
    if g:tabbed_ranger && !isdirectory(previous_buffer) && !len(tabpagebuflist()) < 2 | tabnew | else | enew | endif
    " remove any previous directory buffer for fear of ending up in recursive
    " automatic ranger opening nightmare
    if isdirectory(previous_buffer) | execute 'bdelete! ' . bufnr(previous_buffer) | endif
    if isdirectory(currentPath)
      call termopen(s:ranger_command . ' --choosefiles=' . s:choice_file_path . ' "' . currentPath . '"', rangerCallback)
    else
      call termopen(s:ranger_command . ' --choosefiles=' . s:choice_file_path . ' --selectfile="' . currentPath . '"', rangerCallback)
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
  " Delete empty buffer created by vim
  " after opening file so we can use 'bdelete'
  call OpenRangerIn(path, 'edit ')
endfunction

" To open ranger when vim load a directory
if exists('g:ranger_replace_netrw') && g:ranger_replace_netrw
  augroup ReplaceNetrwByRangerVim
    autocmd VimEnter * silent! autocmd! FileExplorer
    autocmd BufEnter * if isdirectory(expand("%")) | call OpenRangerOnVimLoadDir("%") | endif
  augroup END
endif

if !exists('g:ranger_map_keys') || g:ranger_map_keys
  map <leader>f :Ranger<CR>
endif

