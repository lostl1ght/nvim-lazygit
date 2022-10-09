# [Unreleased]

#### Added
- Neovim 0.7 compatibility branch

#### Changed
- Renamed command to `Lazygit`
- Renamed `_edit_file` to `edit_file`
- Renamed `_edit_commit` to `git_editor`

#### Fixed
- Add else clause in readme for setting `GIT_EDITOR`
- Editing files when not in the root of a repo

#### Updated

# [v0.2.0]

#### Changed
- Removed auto commands, now the window is closed manually from code
- Default `width` and `height` are now 0.9
- Use `vim.fs` instead of `vim.fn.system`

#### Fixed
- `set ft=` when switching edited files

#### Updated
- Minimum required Neovim version is now 0.8.0

# [v0.1.0]

#### Added
- The first version, a baseline for all the future updates
