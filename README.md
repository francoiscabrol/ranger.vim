Ranger.vim
==========

Ranger [](http://ranger.nongnu.org/) integration in vim and neovim

Installation
============

Install it with your favorite plugin manager. Example with vim-plug:

        Plug 'francoiscabrol/ranger.vim'

If you use neovim, you have to add the dependency to the plugin bclose.vim:

        Plug 'rbgrouleff/bclose.vim'

How to use it
=============

The default shortcut is <leade>f (\f by default) but you add a new mapping with this line:

        map <leader>f :call OpenRanger()<CR>
