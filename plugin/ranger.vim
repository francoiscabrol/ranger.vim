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
      if ranger_buf == self.previous_buffer
        " this line kept for now to get an error if the logic fails to avoid
        " using the ranger buffer for the alternate file or tries to visit it.
        let self.previous_buffer = -1
        let ranger_ate_buffer = 1
      endif
      let from_dir_buffer = exists('w:alternate_buffer')
      " If ranger opened in a tab we can safely close the window
      " We'll delete the buffer when the function ends
      if exists('w:used_a_tab') | close! | endif
      try
        if filereadable(s:choice_file_path)
          let files = readfile(s:choice_file_path)
          call delete(s:choice_file_path)
        endif
      endtry

      if !exists('l:files') || self.edit_cmd ==# 'tabedit ' && !exists('w:used_a_tab')
        let should_visit_previous = 1
      endif

      if exists('l:should_visit_previous') && !exists('l:ranger_ate_buffer')
        if from_dir_buffer
          exec 'buffer ' . w:alternate_buffer
        else
          exec 'buffer ' . self.previous_buffer
        endif
      endif

      if from_dir_buffer
        exec 'bdelete! ' . self.previous_buffer
      endif

      if self.edit_cmd ==# 'edit ' && exists('l:files')
        for f in files
          exec self.edit_cmd . f
        endfor
      endif

      " deleting ranger buffer now, if the alternate file logic tries to use
      " it we will get an error, so we learn were improvements are needed
      exec 'bdelete! ' . ranger_buf

      if !exists('w:used_a_tab')
        if self.edit_cmd ==# 'tabedit '
          let @# = self.previous_alternate

        elseif from_dir_buffer
          let @# = w:alternate_buffer
          unlet w:alternate_buffer

        elseif !exists('l:files')
          if exists('l:ranger_ate_buffer')
            " this is a weird one, the result of using ranger when vim's buffer
            " list is 'empty', vim always has at least the [No Name] buffer,
            " when the user subsequently opens an actual buffer this old
            " [No Name] buffer gets 'eaten'. If ranger replaces that
            " buffer and the user does not choose a file, vim will end up in a
            " state where once again there is only the [No Name] buffer,
            " except it will have a 'bufnr' 1 higher than the one before
            " using ranger did.
            let @# = ranger_buf + 1
          else
            let @# = self.previous_alternate
          endif

        elseif exists('l:files')
          if exists('l:ranger_ate_buffer')
            " A last resort, we can't set a sensible alternate, to not get an
            " error, we use the buffer we end up in as with 'the weird one'
            let @# = @%
          else
            let @# = self.previous_buffer
          endif
        endif
      endif

      " when opening files in a new tab, we do this only now, after setting
      " the alternate file to avoid jumping windows for setting that alternate
      " in the previous window. Perhaps there is a way to open the files
      " earlier and while being in the new tab set the alternate for that old
      " window but I haven't yet found a way to do that.
      if self.edit_cmd ==# 'tabedit ' && exists('l:files')
        for f in files
          exec self.edit_cmd . f
        endfor
      endif
    endfunction
    " if the user likes it, open a tab, only when not 'editing' a directory
    " (netrw replacement)
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
command! RangerCurrentFileExistingOrNewTab call OpenRangerIn("%", 'tab drop ')
command! RangerCurrentDirectoryNewTab call OpenRangerIn("%:p:h", 'tabedit ')
command! RangerCurrentDirectoryExistingOrNewTab call OpenRangerIn("%:p:h", 'tab drop ')
command! RangerWorkingDirectoryNewTab call OpenRangerIn(".", 'tabedit ')
command! RangerWorkingDirectoryExistingOrNewTab call OpenRangerIn(".", 'tab drop ')
command! RangerNewTab RangerCurrentDirectoryNewTab

" For retro-compatibility
function! OpenRanger()
  Ranger
endfunction

" Open Ranger in the directory passed by argument
function! OpenRangerOnVimLoadDir(argv_path)
  let path = expand(a:argv_path)
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

