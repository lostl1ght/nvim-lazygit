local function clear_on_leave()
  if vim.t.lazygit_bufs == nil then
    return
  end

  local winid = vim.t.lazygit_bufs.winid
  if vim.api.nvim_win_is_valid(winid) then
    vim.api.nvim_win_close(winid, true)
  end

  local bufnr = vim.t.lazygit_bufs.bufnr
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end
  vim.t.lazygit_bufs = nil
end

local group = vim.api.nvim_create_augroup('LazyGitAugroup', {})
local function buf_autocmds(bufnr)
  vim.api.nvim_create_autocmd({ 'WinLeave', 'BufLeave' }, {
    once = true,
    buffer = bufnr,
    group = group,
    callback = function()
      if vim.t.lazygit_opened then
        vim.t.lazygit_opened = false
        vim.api.nvim_exec_autocmds('User', { group = 'LazyGitAugroup', pattern = 'LazyGitLeave' })
      end
    end,
  })
end

local function on_exit()
  if vim.t.lazygit_opened then
    vim.t.lazygit_opened = false
    vim.api.nvim_exec_autocmds('User', { group = 'LazyGitAugroup', pattern = 'LazyGitLeave' })
  end
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

local function lazygit(opts, on_enter, path)
  if not vim.t.lazygit_opened then
    local cmd
    if not path then
      cmd = 'lazygit'
    else
      local gitdir = get_root(path)
      if gitdir then
        cmd = 'lazygit -p ' .. gitdir
      else
        vim.notify('Lazygit: not a git repo', vim.log.levels.ERROR)
        return
      end
    end

    local bufnr = vim.api.nvim_create_buf(true, true)
    local winid = vim.api.nvim_open_win(bufnr, true, opts)
    vim.api.nvim_win_set_buf(winid, bufnr)
    vim.t.lazygit_bufs = { bufnr = bufnr, winid = winid }
    buf_autocmds(bufnr)

    vim.fn.termopen(cmd, { on_exit = on_exit })
    vim.cmd('startinsert')

    if on_enter then
      on_enter(bufnr, winid)
    end
    vim.t.lazygit_opened = true
  else
    vim.t.lazygit_opened = false
    vim.api.nvim_exec_autocmds('User', { group = 'LazyGitAugroup', pattern = 'LazyGitLeave' })
  end
end

local default_config = {
  env_name = 'NEOVIM_LAZYGIT',
  opts = {
    relative = 'editor',
    col = math.floor(0.05 * vim.o.columns),
    row = math.floor(0.05 * vim.o.lines),
    width = math.floor(0.9 * vim.o.columns),
    height = math.floor(0.9 * vim.o.lines),
    border = 'single',
  },
  on_enter = nil,
  on_leave = nil,
}

local function setup(opts)
  local config = vim.tbl_deep_extend('force', default_config, opts or {})
  vim.env[config.env_name] = vim.v.servername

  vim.api.nvim_create_user_command('LazyGit', function(args)
    lazygit(config.opts, config.on_enter, args.args)
  end, { nargs = '?', desc = 'Open lazygit', complete = 'dir' })

  vim.api.nvim_create_autocmd('User', {
    pattern = 'LazyGitLeave',
    group = group,
    callback = function()
      clear_on_leave()
      if config.on_leave then
        config.on_leave()
      end
    end,
  })
end

return { setup = setup }
