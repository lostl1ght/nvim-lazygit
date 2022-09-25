# nvim-lazygit

A plugin that allows using [lazygit](https://github.com/jesseduffield/lazygit) inside Neovim
and avoids nested instances.

### Table of contents
* [Requirements](#requirements)
* [Installation](#installation)
* [Configuration](#configuration)
    * [Highlight](#highlight)
* [Usage](#usage)
* [Acknowledgement](#acknowledgement)

## Requirements

* Neovim 0.7+
* python 3 and [neovim-remote](https://github.com/mhinz/neovim-remote)

## Installation

Any package manager is fine.

[packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use({
  'lostl1ght/nvim-lazygit',
  config = function()
    require('lazygit').setup({
      -- configuration or leave empty for defaults
    })
  end,
  cmd = 'LazyGit'
})
```

Until Neovim releases `--remote-wait` [neovim-remote](https://github.com/mhinz/neovim-remote)
must be installed too.

```bash
pip install neovim-remote

```

## Configuration

Default `setup` values:

```lua
{
  width = 1, -- width scaling factor [0;1]
  height = 1, -- height scaling factor [0;1]
  border = 'none' -- 'none', 'single', 'double',
                  -- 'rounded', 'solid', 'shadow'
                  -- or see :h nvim_open_win() for custom definitions
}
```

To avoid nested Neovim instances set up the following variables:

bash/zsh:
```bash
if [[ -n "$NVIM" ]]; then
  alias nvim="nvim --server $NVIM --remote"
  export EDITOR="nvim --server $NVIM --remote"
  export GIT_EDITOR="nvr --servername $NVIM --remote-wait"
else
  export EDITOR="nvim"
fi
```

fish:
```fish
if set -q NVIM
  alias nvim "nvim --server $NVIM --remote"
  set -gx EDITOR "nvim --server $NVIM --remote"
  set -gx GIT_EDITOR "nvr --servername $NVIM --remote-wait"
else
  set -gx EDITOR "nvim"
end
```

And configure lazygit:
```yaml
os:
  editCommand: '$EDITOR'
  editCommandTemplate: '{{editor}} {{filename}}'
promptToReturnFromSubprocess: false
```

### Highlight

`nvim-lazygit` defines the following highlight groups with their defaults:

* `LazyGitNormal` - linked to `NormalFloat`, defines fore- and background of the lazygit window.
* `LazyGitBorder` - linked to `FloatBorder`,  defines fore- and background of the lazygit window border.

## Usage

Open lazygit inside `cwd`:
```vim
:LaziGit
```

Or supply a path:
```vim
:LazyGit path/to/repo
```

Inside lazygit press `edit` (`e` by default) to open a file in current Neovim instance.

Inside lazygit press `commitChangesWithEditor` (`C` by default) to open a `gitcommit` buffer
in current Neovim instance, write commit message, save the buffer then unload this buffer
(`:bd[elete]`) to return to lazygit.

## Acknowledgement

Heavily inspired by [lazygit.nvim](https://github.com/kdheepak/lazygit.nvim).
