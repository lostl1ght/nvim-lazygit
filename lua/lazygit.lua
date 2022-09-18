_LazyGitLoaded = false
_LazyGitBufnr = nil
_LazyGitConfig = nil

local function on_exit()
  _LazyGitLoaded = false
  vim.bo[_LazyGitBufnr].bufhidden = 'wipe'
  local winid = vim.fn.bufwinid(_LazyGitBufnr)
  _LazyGitBufnr = nil
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
    col = math.floor((1 - _LazyGitConfig.width) / 2 * vim.o.columns),
    row = math.floor((1 - _LazyGitConfig.height) / 2 * vim.o.lines),
    width = math.floor(_LazyGitConfig.width * vim.o.columns),
    height = math.floor(_LazyGitConfig.height * vim.o.lines),
    border = _LazyGitConfig.border,
  }

  if not _LazyGitBufnr then
    _LazyGitBufnr = vim.api.nvim_create_buf(false, true)
    buf_autocmds(_LazyGitBufnr)
    vim.bo[_LazyGitBufnr].bufhidden = 'hide'
  end
  local winid = vim.api.nvim_open_win(_LazyGitBufnr, true, opts)
  vim.wo[winid].winhl = 'NormalFloat:LazyGitNormal,FloatBorder:LazyGitBorder'
  vim.wo[winid].sidescrolloff = 0
  vim.wo[winid].virtualedit = ''

  if not _LazyGitLoaded then
    vim.fn.termopen(cmd, { on_exit = on_exit })
    _LazyGitLoaded = true
  end

  vim.cmd('startinsert')
end

local default_config = {
  width = 1,
  height = 1,
  border = 'single',
}

local function setup(opts)
  _LazyGitConfig = vim.tbl_deep_extend('force', default_config, opts or {})
  vim.api.nvim_create_user_command('LazyGit', function(args)
    open_lazygit(args.args)
  end, { nargs = '?', desc = 'Open lazygit', complete = 'dir' })
  vim.api.nvim_set_hl(0, 'LazyGitNormal', { link = 'NormalFloat', default = true })
  vim.api.nvim_set_hl(0, 'LazyGitBorder', { link = 'FloatBorder', default = true })
end

return { setup = setup, open_lazygit = open_lazygit }
