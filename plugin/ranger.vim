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
    let rangerCallback = {
          \'name': 'ranger',
          \'edit_cmd': a:edit_cmd,
          \'previous_alternate': bufnr('#'),
          \'previous_buffer': bufnr('%')
          \}
    function! rangerCallback.on_exit(job_id, code, event)
      let ranger_buf = bufnr('%')
      let from_dir_buffer = isdirectory(fnamemodify(bufname(self.previous_buffer), ':p'))
      " If ranger opened in a tab we can safely close the window
      " We'll delete the buffer when the function ends
      if exists('w:used_a_tab') | close! | endif
      try
        if filereadable(s:choice_file_path)
          let files = readfile(s:choice_file_path)
          " We'll open a file (or more), '% (before ranger)' should become '#',
          " we'll open the last file after visiting '% (before ranger)',
          " unless opening files in a new tab
          if len(files) > 1
            " open all files but the last, so we can set alternate before
            " opening the last
            for f in files[0:-2]
              exec self.edit_cmd . f
            endfor
          endif
          if self.previous_alternate > 0
            execute 'buffer ' . self.previous_alternate
          endif

          if !from_dir_buffer
            execute 'buffer ' . self.previous_buffer
            execute self.edit_cmd . files[-1]
          else
            " previous_buffer was a directory: don't make it the alternate
            " but use previous_alternate ?????????????????????????????????
            execute self.edit_cmd . files[-1]
            execute 'bdelete! ' . self.previous_buffer
          endif
          call delete(s:choice_file_path)
        else
          " Not opening any files, '% (before ranger)' & '# (before ranger)' should remain the same
          " the old alternate may not exist e.g. only one buffer exists
          if self.previous_alternate > 0
            execute 'buffer ' . self.previous_alternate
          endif
          " visit the previous buffer if it's not a directory
          if !from_dir_buffer
            execute 'buffer ' . self.previous_buffer
          else
            " previous_buffer was a directory
            execute 'bdelete! ' . self.previous_buffer
          endif
        endif
      endtry
      execute 'bdelete! ' . ranger_buf
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

