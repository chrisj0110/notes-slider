# notes-slider

## Purpose

Slide in a window to take notes

## How To Use

Here is how you can install and configure it using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
return {
    "chrisj0110/notes-slider",
    config = function()
        require('notes-slider').setup({
            scratch_file_prefix = "scratch-", -- default is "scratch-"
            scratch_file_extension = "md", -- default is "txt"
            scratch_file_dir = "~/bin", -- default is $HOME
        })

        -- how you split windows is up to you. Below is how I have mine setup.

        vim.opt.equalalways = false -- Disable automatic resizing of splits

        -- if you want to use the current tmux session name in the file name, call open_notes_using_tmux_session_name():

        -- horizontal split on top:
        vim.api.nvim_set_keymap('n', '[s', ':aboveleft split | wincmd K | resize 15<CR>:lua require("notes-slider").open_notes_using_tmux_session_name()<CR>', { noremap = true, silent = true })

        -- vertical split on right:
        vim.api.nvim_set_keymap('n', ']s', ':vsplit | wincmd R | vertical resize 70<CR>:lua require("notes-slider").open_notes_using_tmux_session_name()<CR>', { noremap = true, silent = true })

        -- open in current window:
        vim.api.nvim_set_keymap('n', '-s', ':lua require("notes-slider").open_notes_using_tmux_session_name()<CR>', { noremap = true, silent = true })

        -- or if you don't want to automatically use the tmux name, pass in your own part of the file name (see setup() above for the rest of the file path)
        -- vim.api.nvim_set_keymap('n', '[s', ':aboveleft split | wincmd K | resize 15<CR>:lua require("notes-slider").open_notes("abc")<CR>', { noremap = true, silent = true })
        -- vim.api.nvim_set_keymap('n', ']s', ':vsplit | wincmd R | vertical resize 70<CR>:lua require("notes-slider").open_notes("abc")<CR>', { noremap = true, silent = true })
        -- vim.api.nvim_set_keymap('n', '-s', ':lua require("notes-slider").open_notes("abc")<CR>', { noremap = true, silent = true })
    end
}
```

Note: in earlier versions this supported splitting windows in a variety of ways, but now I'm leaving that for you to configure, and this plugin just focuses on opening the proper file.
