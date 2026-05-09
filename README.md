# notmux.nvim

Inspired by [neovim-killed-tmux](https://github.com/anakin4747/neovim-killed-tmux).

Neovim can do most of the features tmux can with the benefits of your configs
that you have fine-tuned for years, and the plugin ecosystem. Here are some of
the tmux features that Neovim can already do:

| tmux    | Neovim    |
| ------- | --------- |
| panes   | windows   |
| windows | tab pages |
| detach  | :detach   |
| attach  | :connect  |

This plugin adds these user commands:
- `:Detach [name]` detach the current session and (re)name it. You can omit the
name if it already has one.
- `:Attach [name]` attach to an existing session. The name can be omitted if
there is only one (named) session.
- `:Sessions` list active sessions.
- `:KillSession {name}` kill a session remotely.

## Installation
vim.pack:
```lua
vim.pack.add({ 'https://github.com/tunaflsh/notmux.nvim' })
require('notmux')
```
lazy.nvim:
```lua
{
    'tunaflsh/notmux.nvim',
    config = function()
        require('notmux')
    end
}
```
vim-plug:
```vim
Plug 'tunaflsh/notmux.nvim'
lua require('notmux')
```
