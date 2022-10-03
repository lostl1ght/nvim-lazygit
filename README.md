# nvim-lazygit

A plugin that allows using [lazygit](https://github.com/jesseduffield/lazygit) inside Neovim
and avoids nested instances.

### Table of contents
* [Requirements](#requirements)
* [Installation](#installation)
* [Configuration](#configuration)
    * [Values](#values)
    * [External](#external)
    * [Highlight](#highlight)
* [Usage](#usage)
* [Acknowledgement](#acknowledgement)

## Requirements

* Neovim 0.8 (for Neovim 0.7 see [0.7-compat](https://github.com/lostl1ght/nvim-lazygit/tree/0.7-compat) branch)
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
  tag = '*',
  cmd = 'LazyGit'
})
```

Until Neovim releases `--remote-wait` and `+<cmd>` [neovim-remote](https://github.com/mhinz/neovim-remote)
must be installed too.

```bash
pip install neovim-remote
```

## Configuration

Default `setup` values:

```lua
{
  width = 0.9,
  height = 0.9,
  border = 'none',
}
```

### Values

`width` and `height` are technically any in `[0;1]` but do not make them too small.

`border` is one of `{'none', 'single', 'double', 'rounded', 'solid', 'shadow'}` or see `:h nvim_open_win()`
for custom definitions.

### External

To avoid nested Neovim instances set up the following variables:

bash/zsh:
```bash
if [[ -n "$NVIM" ]]; then
  alias nvim="nvim --server $NVIM --remote"
  export GIT_EDITOR="nvr --servername $NVIM --remote-wait +'lua require\"lazygit\"._edit_commit()'"
else
  export GIT_EDITOR="nvim"
fi
```

fish:
```fish
if set -q NVIM
  alias nvim "nvim --server $NVIM --remote"
  set -gx GIT_EDITOR "nvr --servername $NVIM --remote-wait +'lua require\"lazygit\"._edit_commit()'"
else
  set -gx GIT_EDITOR "nvim"
end
```

And configure lazygit:
```yaml
os:
  editCommandTemplate: >-
    if [[ -n $NVIM ]]; then
      nvr --servername $NVIM --remote +'lua require"lazygit"._edit_file{{filename}}'
    else
      nvim {{filename}}
    fi
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

Inside lazygit press `edit` (`e` by default) to open a file in current Neovim instance.

Inside lazygit press `commitChangesWithEditor` (`C` by default) to open a `gitcommit` buffer
in current Neovim instance, write commit message, save the buffer then unload this buffer
(`:bd[elete]`) to return to lazygit.

## Acknowledgement

Heavily inspired by [lazygit.nvim](https://github.com/kdheepak/lazygit.nvim).
