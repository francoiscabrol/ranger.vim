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
if exists('g:ranger_choice_file')
  if empty(glob(g:ranger_choice_file))
    let s:choice_file_path = g:ranger_choice_file
  else
    echom "Message from *Ranger.vim* :"
    echom "You've set the g:ranger_choice_file variable."
    echom "Please use the path for a file that does not already exist."
    echom "Using /tmp/chosenfile for now..."
  endif
endif

if !exists('s:choice_file_path')
  let s:choice_file_path = '/tmp/chosenfile'
endif

if has('nvim')
  function! OpenRangerIn(path, edit_cmd)
    let currentPath = expand(a:path)
    let rangerCallback = {
          \'name': 'ranger',
          \'edit_cmd': a:edit_cmd,
          \'oldAltBuffer': bufnr('#'),
          \'oldBuffer': bufnr('%'),
          \'oldPath': expand('%')
          \}
    function! rangerCallback.on_exit(job_id, code, event)
      " Store the ranger buffer number for later
      let rangerBuff = bufnr('%')
      "if ranger was closed regularly by selecting a file or quitting
      if a:code == 0
        try
          "try to read the file containing the chosen files list
          if filereadable(s:choice_file_path)
            "Open all the selected files
            for f in readfile(s:choice_file_path)
              exec self.edit_cmd . f
            endfor
            "delete the temporary file
            call delete(s:choice_file_path)
            "store the last opened buffer number for later
            let a:newFileBuff = bufnr('%')
            "if the old buffer was a directory
            if isdirectory(self.oldPath)
              "Then it should remove this buffer
              silent! execute 'bdelete! '. self.oldBuffer
            else
              "but else it should select the old and then the last buffer to
              "set correctly the alternate buffer
              silent! execute 'buffer '. self.oldBuffer
              silent! execute 'buffer '.a:newFileBuff
            endif
          else
            "Then check if the previous buffer is a directory
            "it means that ranger ran while opening vim
            if isdirectory(self.oldPath)
              "Then it should remove this previous buffer
              silent! execute 'bdelete! '. self.oldBuffer
              if self.oldAltBuffer
                "select the old alternate buffer (before opening ranger)
                silent! execute 'buffer '. self.oldAltBuffer
              else
                "or open a new empty one
                enew
              endif
            "but in any other case
            else
              "Select the old alternate buffer (before opening ranger)
              silent! execute 'buffer '. self.oldAltBuffer
              "Then move back to the previous buffer
              silent! execute 'buffer '. self.oldBuffer
            endif
          endif
        endtry
        "finally it remove the ranger's buffer
        execute 'bdelete! '.rangerBuff
      "if ranger was close by 'bd'
      else
        silent! execute 'bdelete! '. self.oldBuffer
        enew
        execute 'bdelete! '.rangerBuff
      endif
    endfunction
    enew
    if isdirectory(currentPath)
      call termopen('ranger --choosefiles=' . s:choice_file_path . ' "' . currentPath . '"', rangerCallback)
    else
      call termopen('ranger --choosefiles=' . s:choice_file_path . ' --selectfile="' . currentPath . '"', rangerCallback)
    endif
    startinsert
  endfunction
else
  function! OpenRangerIn(path, edit_cmd)
    let currentPath = expand(a:path)
    if isdirectory(currentPath)
      silent exec '!ranger --choosefiles=' . s:choice_file_path . ' "' . currentPath . '"'
    else
      silent exec '!ranger --choosefiles=' . s:choice_file_path . ' --selectfile="' . currentPath . '"'
    endif
    if filereadable(s:choice_file_path)
      for f in readfile(s:choice_file_path)
        exec a:edit_cmd . f
      endfor
      call delete(s:choice_file_path)
    endif
    redraw!
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


  " Open Ranger
  call OpenRangerIn(path, 'edit')
endfunction

" To open ranger when vim load a directory
if exists('g:ranger_replace_netrw') && g:ranger_replace_netrw
  augroup ReplaceNetrwByRangerVim
    autocmd VimEnter * silent! autocmd! FileExplorer
    autocmd StdinReadPre * let s:std_in=1
    autocmd BufEnter * if isdirectory(expand("%")) | call OpenRangerOnVimLoadDir("%") | endif
  augroup END
endif

if !exists('g:ranger_map_keys') || g:ranger_map_keys
  map <leader>f :Ranger<CR>
endif
