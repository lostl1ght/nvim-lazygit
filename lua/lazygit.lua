vim.g.lazygit_opened = false
local Winid
local Bufnr

local function on_exit()
  vim.g.lazygit_opened = false
  if vim.api.nvim_win_is_valid(Winid) then
    vim.api.nvim_win_close(Winid, true)
  end
end

local group = vim.api.nvim_create_augroup('LazyGitAugroup', {})
local function buf_autocmds(bufnr)
  vim.api.nvim_create_autocmd('BufLeave', {
    once = true,
    buffer = bufnr,
    group = group,
    callback = on_exit,
  })
end

local function get_root(path)
  local dir = vim.fn.fnamemodify(vim.fn.resolve(vim.fn.expand(path)), ':p:h')
  local cmd = string.format('cd %s && git rev-parse --show-toplevel', dir)
  local gitdir = vim.fn.system(cmd)
  if gitdir:match('^fatal:.*') then
    return nil
  end
  return gitdir
end

local function open_lazygit(path, width, height, border)
  if not vim.g.lazygit_opened then
    vim.g.lazygit_opened = true
    local cmd
    if not path then
      cmd = 'lazygit'
    else
      local gitdir = get_root(path)
      if gitdir then
        cmd = 'lazygit -p ' .. gitdir
      else
        vim.notify('Lazygit: not a git repo', vim.log.levels.ERROR)
        vim.g.lazygit_opened = false
        return
      end
    end

    local opts = {
      relative = 'editor',
      col = math.floor((1 - width) / 2 * vim.o.columns),
      row = math.floor((1 - height) / 2 * vim.o.lines),
      width = math.floor(width * vim.o.columns),
      height = math.floor(height * vim.o.lines),
      border = border,
    }

    Bufnr = vim.api.nvim_create_buf(false, true)
    Winid = vim.api.nvim_open_win(Bufnr, true, opts)
    vim.api.nvim_win_set_buf(Winid, Bufnr)

    vim.fn.termopen(cmd, { on_exit = on_exit })
    vim.cmd('startinsert')

    vim.api.nvim_win_set_option(Winid, 'sidescrolloff', 0)
    vim.api.nvim_win_set_option(Winid, 'virtualedit', '')
    vim.api.nvim_win_set_option(Winid, 'winhl', 'NormalFloat:LazyGitNormal')
    vim.api.nvim_buf_set_option(Bufnr, 'bufhidden', 'wipe')
    buf_autocmds(Bufnr)
  end
end

local default_config = {
  width = 1,
  height = 1,
  border = 'single',
}

local function setup(opts)
  local config = vim.tbl_deep_extend('force', default_config, opts or {})
  vim.api.nvim_create_user_command('LazyGit', function(args)
    open_lazygit(args.args, config.width, config.height, config.border)
  end, { nargs = '?', desc = 'Open lazygit', complete = 'dir' })
  vim.api.nvim_set_hl(0, 'LazyGitNormal', { link = 'NormalFloat', default = true })
end

return { setup = setup }
