local Hooks = {}

local function delete_buffer()
  if not vim.t.lazygit or not vim.t.lazygit.bufnr then
    return
  end
  local bufnr = vim.t.lazygit.bufnr
  vim.t.lazygit.bufnr = nil
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end
end

local function close_window()
  if not vim.t.lazygit or not vim.t.lazygit.winid then
    return
  end
  local winid = vim.t.lazygit.winid
  vim.t.lazygit.winid = nil
  if vim.api.nvim_win_is_valid(winid) then
    vim.api.nvim_win_close(winid, true)
  end
end

local function on_exit()
  delete_buffer()
  close_window()
  vim.t.lazygit = nil
  if Hooks.on_leave then
    Hooks.on_leave()
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

local function lazygit(opts, path)
  if not vim.t.lazygit then
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

    vim.fn.termopen(cmd, { on_exit = on_exit })
    vim.cmd('startinsert')

    vim.t.lazygit = { bufnr = bufnr, winid = winid, hidden = false }
    if Hooks.on_enter then
      Hooks.on_enter(bufnr, winid)
    end
  else
    close_window()
    if Hooks.on_leave then
      Hooks.on_leave()
    end
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
    lazygit(config.opts, args.args)
  end, { nargs = '?', desc = 'Open lazygit', complete = 'dir' })

  Hooks.on_enter = config.on_enter
  Hooks.on_leave = config.on_leave
end

return { setup = setup }
