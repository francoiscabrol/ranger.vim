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
if has('nvim')
  function! OpenRanger()
    let rangerCallback = { 'name': 'ranger' }
    function! rangerCallback.on_exit(id, code)
      Bclose!
      try
        if filereadable('/tmp/chosenfile')
          exec system('sed -ie "s/ /\\\ /g" /tmp/chosenfile')
          exec 'argadd ' . system('cat /tmp/chosenfile | tr "\\n" " "')
          exec 'edit ' . system('head -n1 /tmp/chosenfile')
          call system('rm /tmp/chosenfile')
        endif
      endtry
    endfunction
    enew
    call termopen('ranger --choosefiles=/tmp/chosenfile', rangerCallback)
    startinsert
  endfunction
else
  fun! OpenRanger()
    exec "silent !ranger --choosefiles=/tmp/chosenfile " . expand("%:p:h")
    if filereadable('/tmp/chosenfile')
      exec system('sed -ie "s/ /\\\ /g" /tmp/chosenfile')
      exec 'argadd ' . system('cat /tmp/chosenfile | tr "\\n" " "')            
      exec 'edit ' . system('head -n1 /tmp/chosenfile')
      call system('rm /tmp/chosenfile')
    endif
    redraw!
  endfun
endif

map <leader>f :call OpenRanger()<CR>
