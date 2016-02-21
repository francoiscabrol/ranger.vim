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
if !exists('g:ranger_path')
    let g:ranger_path = 'ranger'
endif

if has('nvim')
    function! OpenRanger(dir)
        let currentPath = expand(a:dir)
        let tmp_file_path = tempname()
        let rangerCallback = { 'name': 'ranger' , 'tmp_file_path': tmp_file_path}
        function! rangerCallback.on_exit(id, code)
            bdelete!
            if filereadable(self.tmp_file_path)
                for f in readfile(self.tmp_file_path)
                    exec 'edit '. f
                endfor
                call delete(self.tmp_file_path)
            endif
        endfunction
        tabnew
        call termopen(g:ranger_path . ' ' . '--choosefiles=' . shellescape(tmp_file_path) . ' ' . currentPath, rangerCallback)
        startinsert
    endfunction
else
    function! OpenRanger(dir)
        let currentPath = expand(a:dir)
        let tmp_file_path = tempname()
        exec 'silent !' . g:ranger_path . ' --choosefiles=' . shellescape(tmp_file_path) . ' ' .currentPath
        if filereadable(tmp_file_path)
            for f in readfile(tmp_file_path)
                exec 'edit '. f
            endfor
            call delete(tmp_file_path)
        endif
        redraw!
    endfunction
endif

map <leader>f :call OpenRanger('%:p:h')<CR>
map <leader>F :call OpenRanger('')<CR>
