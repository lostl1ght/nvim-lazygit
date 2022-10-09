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

# Neovim 0.7 compatibility branch

## Requirements

* Neovim 0.7
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
  branch = '0.7-compat',
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
  hide_map = '<c-q>'
}
```

### Values

`width` and `height` are technically any in `[0;1]` but do not make them too small.

`border` is one of `{'none', 'single', 'double', 'rounded', 'solid', 'shadow'}` or see `:h nvim_open_win()`
for custom definitions.

`hide_map` should me somthing using `ctrl` or `alt` modifiers so that the window is not getting hidden
whenever typing a commit text or `nil` to disable.

### External

To avoid nested Neovim instances set up the following variables:

bash/zsh:
```bash
if [[ -n "$NVIM" ]]; then
  alias nvim="nvim --server $NVIM --remote"
  export EDITOR="nvim --server $NVIM --remote"
  export GIT_EDITOR="nvr --servername $NVIM --remote-wait +'lua require\"lazygit\".commit()'"
else
  export EDITOR="nvim"
  export GIT_EDITOR="nvim"
fi
```

fish:
```fish
if set -q NVIM
  alias nvim "nvim --server $NVIM --remote"
  set -gx EDITOR "nvim --server $NVIM --remote"
  set -gx GIT_EDITOR "nvr --servername $NVIM --remote-wait +'lua require\"lazygit\".commit()'"
else
  set -gx EDITOR "nvim"
  set -gx GIT_EDITOR "nvim"
end
```

And update lazygit configuration:
```yaml
os:
  editCommandTemplate: >-
    if [[ -n "$NVIM" ]]; then
      nvr --servername $NVIM --remote +'lua require"lazygit".edit{{filename}}'
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
:Lazigit
```

Inside lazygit press `edit` (`e` by default) to open a file in current Neovim instance.

Inside lazygit press `commitChangesWithEditor` (`C` by default) to open a `gitcommit` buffer
in current Neovim instance, write commit message, save the buffer then unload this buffer
(`:bd[elete]`) to return to lazygit.

## Acknowledgement

Heavily inspired by [lazygit.nvim](https://github.com/kdheepak/lazygit.nvim).
