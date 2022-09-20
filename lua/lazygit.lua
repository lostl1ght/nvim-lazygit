vim.g.lazygit_loaded = false
local Bufnr = nil
local Opened = false
local Config = nil

local api = vim.api
local fn = vim.fn

local function on_exit()
  Opened = false
  vim.g.lazygit_loaded = false
  api.nvim_buf_set_var(Bufnr, 'bufhidden', 'wipe')
  local winid = fn.bufwinid(Bufnr)
  Bufnr = nil
  if api.nvim_win_is_valid(winid) then
    api.nvim_win_close(winid, true)
  end
end

local function buf_autocmds(bufnr)
  local group = api.nvim_create_augroup('LazyGitBuffer', {})
  api.nvim_create_autocmd({ 'WinLeave', 'BufDelete', 'BufLeave' }, {
    buffer = bufnr,
    group = group,
    callback = function(args)
      Opened = false
      local winid = fn.bufwinid(args.buf)
      if api.nvim_win_is_valid(winid) then
        api.nvim_win_close(winid, true)
      end
    end,
  })
end

local function get_root(path)
  local dir = fn.fnamemodify(fn.resolve(fn.expand(path)), ':p:h')
  local cmd = string.format('cd %s && git rev-parse --show-toplevel', dir)
  local gitdir = fn.system(cmd)
  if gitdir:match('^fatal:.*') then
    return nil
  end
  return gitdir
end

local function open_lazygit(path)
  if Opened then
    on_exit()
  else
    Opened = true
    if not Bufnr then
      Bufnr = api.nvim_create_buf(false, true)
      buf_autocmds(Bufnr)
      api.nvim_buf_set_option(Bufnr, 'bufhidden', 'hide')
      api.nvim_buf_set_option(Bufnr, 'filetype', 'lazygit')
    end

    local opts = {
      relative = 'editor',
      col = math.floor((1 - Config.width) / 2 * vim.o.columns),
      row = math.floor((1 - Config.height) / 2 * vim.o.lines),
      width = math.floor(Config.width * vim.o.columns),
      height = math.floor(Config.height * vim.o.lines),
      border = Config.border,
    }
    local winid = api.nvim_open_win(Bufnr, true, opts)
    api.nvim_win_set_option(winid, 'winhl', 'NormalFloat:LazyGitNormal,FloatBorder:LazyGitBorder')
    api.nvim_win_set_option(winid, 'sidescrolloff', 0)
    api.nvim_win_set_option(winid, 'virtualedit', '')

    if not vim.g.lazygit_loaded then
      local dir = path or fn.getcwd()
      local gitdir = get_root(dir)
      local cmd
      if gitdir then
        cmd = 'lazygit -p ' .. gitdir
      else
        Opened = false
        vim.notify('Lazygit: not a git repo', vim.log.levels.ERROR)
        on_exit()
        return
      end
      fn.termopen(cmd, { on_exit = on_exit, width = opts.width })
      vim.g.lazygit_loaded = true
    end

    vim.cmd('startinsert')
  end
end

local default_config = {
  width = 0.9,
  height = 0.9,
  border = 'none',
}

local function setup(opts)
  Config = vim.tbl_deep_extend('force', default_config, opts or {})
  api.nvim_create_user_command('LazyGit', function(args)
    open_lazygit(args.args)
  end, { nargs = '?', desc = 'Open lazygit', complete = 'dir' })
  api.nvim_set_hl(0, 'LazyGitNormal', { link = 'NormalFloat', default = true })
  api.nvim_set_hl(0, 'LazyGitBorder', { link = 'FloatBorder', default = true })
end

return { setup = setup, open_lazygit = open_lazygit }
