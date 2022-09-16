local Hooks = {}
local Opened = false

local group = vim.api.nvim_create_augroup('LazyGitAugroup', {})
local function buf_autocmds(bufnr)
  vim.api.nvim_create_autocmd('BufLeave', {
    once = true,
    buffer = bufnr,
    group = group,
    callback = function(args)
      Opened = false
      if vim.api.nvim_win_is_valid(0) then
        vim.api.nvim_win_close(0, true)
      end
      if vim.api.nvim_buf_is_valid(args.buf) then
        vim.api.nvim_buf_delete(args.buf, { force = true })
      end
      if Hooks.on_leave then
        Hooks.on_leave()
      end
    end,
  })
end

local function on_exit()
  vim.api.nvim_exec_autocmds('BufLeave', { group = group })
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

local function open_lazygit(opts, path)
  if not Opened then
    Opened = true
    local cmd
    if not path then
      cmd = 'lazygit'
    else
      local gitdir = get_root(path)
      if gitdir then
        cmd = 'lazygit -p ' .. gitdir
      else
        vim.notify('Lazygit: not a git repo', vim.log.levels.ERROR)
        Opened = false
        return
      end
    end

    local bufnr = vim.api.nvim_create_buf(true, true)
    local winid = vim.api.nvim_open_win(bufnr, true, opts)
    vim.api.nvim_win_set_buf(winid, bufnr)

    vim.fn.termopen(cmd, { on_exit = on_exit })
    vim.cmd('startinsert')

    buf_autocmds(bufnr)

    if Hooks.on_enter then
      Hooks.on_enter(bufnr, winid)
    end
  end
end

local default_config = {
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
    open_lazygit(config.opts, args.args)
  end, { nargs = '?', desc = 'Open lazygit', complete = 'dir' })

  Hooks.on_enter = config.on_enter
  Hooks.on_leave = config.on_leave
end

return { setup = setup }
