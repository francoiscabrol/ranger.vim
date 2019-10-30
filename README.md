Ranger.vim
==========

[Ranger](https://ranger.github.io/) integration in vim and neovim

![Demo](./ranger.gif)

Installation
------------

Install it with your favorite plugin manager. Example with vim-plug:

        Plug 'francoiscabrol/ranger.vim'

If you use neovim, you have to add the dependency to the plugin bclose.vim:

        Plug 'rbgrouleff/bclose.vim'

How to use it
-------------

The default shortcut for opening Ranger is `<leader>f` (\f by default)
To disable the default key mapping, add this line in your .vimrc or init.vim: `let g:ranger_map_keys = 0`

then you can add a new mapping with this line: `map <leader>f :Ranger<CR>`.

The command for opening Ranger in the current file's directory is `:Ranger`.
Vim will open the selected file in the current window. To open the selected
file in a new tab instead use `:RangerNewTab`.

For opening Ranger in the current workspace, run `:RangerWorkingDirectory`.
Vim will open the selected file in the current window.
`:RangerWorkingDirectoryNewTab` will open the selected file in a new tab instead.

List of commands:
```
Ranger // open current file by default
RangerCurrentFile // Default Ranger behaviour
RangerCurrentDirectory
RangerWorkingDirectory

// open always in new tabs
RangerNewTab
RangerCurrentFileNewTab
RangerCurrentDirectoryNewTab
RangerWorkingDirectoryNewTab

// open tab, when existant or in new tab when not existant
RangerCurrentFileExistingOrNewTab
RangerCurrentDirectoryExistingOrNewTab
RangerWorkingDirectoryExistingOrNewTab
```

The old way to make vim open the selected file in a new tab was to add
`let g:ranger_open_new_tab = 1` in your .vimrc or init.vim. That way is still
supported but deprecated.

### Opening ranger instead of netrw when you open a directory
If you want to see vim opening ranger when you open a directory (ex: nvim ./dir or :edit ./dir), please add this in your .(n)vimrc.
```
let g:NERDTreeHijackNetrw = 0 // add this line if you use NERDTree
let g:ranger_replace_netrw = 1 // open ranger when vim open a directory
```

In order for this to work you need to install the bclose.vim plugin (see above).

### Setting an other path for the temporary file
Ranger.vim uses a temporary file to store the path that was chosen, `/tmp/chosenfile` by default.
This can be a problem if you do not have write permissions for the `/tmp` directory, for example on Android.
There is a configuration variable for this called `g:ranger_choice_file`, this must be set to the
path for a file that doesn't yet exist (this file is created when choosing a file and removed afterwards).

### Setting a custom ranger command
By default ranger is opened with the command `ranger` but you can set an other custom command by setting the `g:ranger_command_override` variable in your .(n)vimrc.

For instance if you want to display the hidden files by default you can write:
```
let g:ranger_command_override = 'ranger --cmd "set show_hidden=true"'
```

## Common issues

### Using fish shell (issue #42)
Solution: if you use something else than bash or zsh you should probably need to add this line in your .vimrc:
`set shell=bash`
