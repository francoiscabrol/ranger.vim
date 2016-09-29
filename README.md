Ranger.vim
==========

[Ranger](http://ranger.nongnu.org/) integration in vim and neovim

![Demo](./ranger.gif)

Installation
============

Install it with your favorite plugin manager. Example with vim-plug:

        Plug 'francoiscabrol/ranger.vim'

If you use neovim, you have to add the dependency to the plugin bclose.vim:

        Plug 'rbgrouleff/bclose.vim'

How to use it
=============

The default shortcut for opening Ranger is <leader>f (\f by default) 
To disable the default key mapping, add this line in your .vimrc or init.vim: `let g:ranger_map_keys = 0`

then you can add a new mapping with this line: `map <leader>f :Ranger<CR>`.

To open the selected file in a new tab, instead of the current tab (the default behaviour) - add this line in your .vimrc or init.vim: `let g:ranger_open_new_tab = 1`

The command for opening Ranger in the current file's directory is `:Ranger`. For opening Ranger in the current worspace, run `:RangerWorkingDirectory`
