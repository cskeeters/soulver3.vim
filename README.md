# soulver3.vim

soulver3.vim lets you use vim / neovim as a front end to [Soulver 3](https://soulver.app/)'s CLI application.


# Demo

![demo](.github/gif_demo_soulver_vim.gif)

# Quickstart

To install and use this tool you'll need to complete the following steps.

1. Install `soulver` (CLI)
2. Install this plugin and it's dependency
3. Edit a file with `.soulver` or `soulver` file type

# Design / Modes of Operation

This plugin essentially, pipes the content of the buffer to `soulver` (the CLI), takes the output and puts it into a buffer loaded in a vertical split.

> If you want to understand how this works, you can create a `test.soulver` and run it through `soulver`.
>
> ```sh
> cat test.soulver | soulver
> ```

This plugin will
1. Enable scroll synchronization (scroll-binding)
2. Update the results on change or save (depending on the mode)
3. Close the *SoulveViewBuffer* when the `.soulver` buffer is unloaded

soulver3.vim operates in one of two modes:
- In *Live* mode, formulas are calculated in **real-time**.  This is the default.
- In *Save* mode, formulas are calculated by `soulver` **only when the buffer is saved**.

`soulver` is only fast on smallish files, but soulver3.vim now runs `soulver` asynchronously, so *Live* mode is likely the right choice.

> [!WARNING]
> `soulver` has a limited capacity and stops calculating at around 950 lines depending on the input.

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
Plug 'prabirshrestha/async.vim'
Plug 'Yohannfra/soulver3.vim'

" If custom path is required
-- let g:soulver_cli_path = "/custom/path/to/soulver"

" Optionally, start in save mode
-- :SoulverModeSave
```


### lazy.nvim

```lua
return {
    enabled = true,
    'cskeeters/soulver3.vim',
    lazy = true,
    ft="soulver",
    dependencies = {
        'prabirshrestha/async.vim'
    },
    init = function()
        -- vim.g.soulver_cli_path = "/opt/homebrew/bin/soulver"
    end,
    config = function()
        vim.keymap.set('n', '<localleader>l', [[<Cmd>SoulverModeLive<Cr>]], { desc="Soulver Mode Live" });
        vim.keymap.set('n', '<localleader>s', [[<Cmd>SoulverModeSave<Cr>]], { desc="Soulver Mode Save" });
        vim.keymap.set('n', '<localleader>o', [[<Cmd>SoulverModeOff<Cr>]],  { desc="Soulver Mode Off" });
    end
}
```

# Reference

## Settings

| Setting                    | Description             | Default     |
|----------------------------|-------------------------|-------------|
| `g:soulver_cli_path`       | Path to `soulver`       | will detect |


## Commands

| Command            | Description      |
|--------------------|------------------|
| `:SoulverModeLive` | Update real-time |
| `:SoulverModeSave` | Update on save   |
| `:SoulverModeOff`  | Disable Soulver  |

# Acknowledgments

Thanks to the Soulver team for providing a CLI :)
