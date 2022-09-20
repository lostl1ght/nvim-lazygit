vim.g.lazygit_loaded = false
local Bufnr = nil
local Config = nil

local function on_exit()
  vim.g.lazygit_loaded = false
  vim.api.nvim_buf_set_var(Bufnr, 'bufhidden', 'wipe')
  local winid = vim.fn.bufwinid(Bufnr)
  Bufnr = nil
  if vim.api.nvim_win_is_valid(winid) then
    vim.api.nvim_win_close(winid, true)
  end
end

local function buf_autocmds(bufnr)
  local group = vim.api.nvim_create_augroup('LazyGitBuffer', {})
  vim.api.nvim_create_autocmd({ 'WinLeave', 'BufDelete', 'BufLeave' }, {
    buffer = bufnr,
    group = group,
    callback = function(args)
      local winid = vim.fn.bufwinid(args.buf)
      if vim.api.nvim_win_is_valid(winid) then
        vim.api.nvim_win_close(winid, true)
      end
    end,
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

local function open_lazygit(path)
  local dir = path or vim.fn.getcwd()
  local gitdir = get_root(dir)
  local cmd
  if gitdir then
    cmd = 'lazygit -p ' .. gitdir
  else
    vim.notify('Lazygit: not a git repo', vim.log.levels.ERROR)
    return
  end

  local opts = {
    relative = 'editor',
    col = math.floor((1 - Config.width) / 2 * vim.o.columns),
    row = math.floor((1 - Config.height) / 2 * vim.o.lines),
    width = math.floor(Config.width * vim.o.columns),
    height = math.floor(Config.height * vim.o.lines),
    border = Config.border,
  }

  if not Bufnr then
    Bufnr = vim.api.nvim_create_buf(true, true)
    buf_autocmds(Bufnr)
    vim.api.nvim_buf_set_option(Bufnr, 'bufhidden', 'hide')
    vim.api.nvim_buf_set_option(Bufnr, 'filetype', 'lazygit')
  end

  local winid = vim.api.nvim_open_win(Bufnr, true, opts)
  vim.api.nvim_win_set_option(winid, 'winhl', 'NormalFloat:LazyGitNormal,FloatBorder:LazyGitBorder')
  vim.api.nvim_win_set_option(winid, 'sidescrolloff', 0)
  vim.api.nvim_win_set_option(winid, 'virtualedit', '')

  if not vim.g.lazygit_loaded then
    vim.fn.termopen(cmd, { on_exit = on_exit })
    vim.g.lazygit_loaded = true
  end

  vim.api.nvim_feedkeys('0', 'n', false)
  vim.cmd('startinsert')
end

local default_config = {
  width = 1,
  height = 1,
  border = 'none',
}

local function setup(opts)
  Config = vim.tbl_deep_extend('force', default_config, opts or {})
  vim.api.nvim_create_user_command('LazyGit', function(args)
    open_lazygit(args.args)
  end, { nargs = '?', desc = 'Open lazygit', complete = 'dir' })
  vim.api.nvim_set_hl(0, 'LazyGitNormal', { link = 'NormalFloat', default = true })
  vim.api.nvim_set_hl(0, 'LazyGitBorder', { link = 'FloatBorder', default = true })
end

return { setup = setup, open_lazygit = open_lazygit }
