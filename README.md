# soulver3.vim

soulver3.vim lets you use vim / neovim as a front end to [Soulver 3](https://soulver.app/)'s CLI application.


# Demo

![demo](.github/gif_demo_soulver_vim.gif)

# Quickstart

To install and use this tool you'll need to complete the following steps.

1. Install `soulver` (CLI)
2. Install this plugin
3. Edit a file with `.soulver` or `soulver` filetype
4. Optionally, enable *Live* mode with `:SoulverLiveOn`
5. Optionally, enable synchronous scrolling (`:windo set scrollbind`)

# Design / Modes of Operation

This plugin essentially, pipes the content of the buffer to soulver (the CLI), takes the output and puts it into a buffer loaded in a vertical split.

> If you want to understand how this works, you can create a `test.soulver` and run it through `soulver`.
>
> ```sh
> cat test.soulver | soulver
> ```

soulver3.vim runs `soulver` synchronously and `soulver` is not always blazingly fast.  Small files calculate fairly quickly, but a 1000 line file might take 2-3 seconds to calculate.

To accommodate both scenarios, soulver3.vim operates in one of two modes:
- In *Basic* mode, formulas are calculated by `soulver` **only when the buffer is saved**.
- In *Live* mode, formulas are calculated in **real-time**.

*Basic* mode is for large files and is the default.  *Live* mode is for small files and must be enabled with `:SoulverLiveOn`, which can be mapped.

# Installation

## Install the CLI

```sh
brew install soulver-cli
```

The CLI is also included in the official app available at [website](https://soulver.app/) and on the [App Store](https://apps.apple.com/us/app/soulver-3/id1508732804).  In this case the CLI will be located here: `/Applications/Soulver 3.app/Contents/MacOS/CLI/soulver`.

## Install/Configure the plugin

Install **soulver3.vim** with your favorite plugin manager

### VimPlug

```vim
Plug 'Yohannfra/soulver3.vim'
let g:soulver_cli_path = "/opt/homebrew/bin/soulver"
" let g:soulver_cli_path = "/Applications/Soulver\ 3.app/Contents/MacOS/CLI/soulver"
" let g:soulver_update_on_save = 0 # Set to zero to disable update on save
```


### lazy.nvim

```lua
return {
    'Yohannfra/soulver3.vim',
    lazy = true,
    ft="soulver",
    init = function()
        -- vim.g.soulver_cli_path = "/custom/path/to/soulver"
        -- vim.g.soulver_update_on_save = 0 -- Set to 0 to disable update on save

        vim.api.nvim_create_autocmd("BufReadPost", {
            pattern = "*.soulver",
            callback = function()
                vim.cmd("Soulver")
                -- vim.cmd("SoulverLiveOn")
            end,
            desc = "Start Soulver",
        })
    end,
    config = function()
        vim.keymap.set('n', '<leader>S', [[<Cmd>Soulver<Cr>]], { desc="Run Soulver" });
        vim.keymap.set('n', '<leader><leader>s', [[<Cmd>SoulverLiveOn<Cr>]], { desc="Enable Soulver Live" });
        vim.keymap.set('n', '<leader><leader>S', [[<Cmd>SoulverLiveOff<Cr>]], { desc="Disable Soulver Live" });
    end
}
```

# Reference

## Settings

| Setting                    | Description             | Default     |
|----------------------------|-------------------------|-------------|
| `g:soulver_cli_path`       | Path to `soulver`       | will detect |
| `g:soulver_update_on_save` | Update values upon save | 1           |


## Commands

| Command          | Description                                  |
|------------------|----------------------------------------------|
| `:Soulver`        | Start Basic Mode for the current buffer [^1] |
| `:SoulverLiveOn`  | Enable Live Mode                             |
| `:SoulverLiveOff` | Disable Live Mode                            |

[^1]: Not required for files with `.soulver` extension.

# Acknowledgments

Thanks to the Soulver team for providing a CLI :)
