vim.g.lazygit_loaded = false
local Opened = false
local Bufnr
local Winid
local PrevWinid
local Config

local api = vim.api
local fn = vim.fn

local function on_exit()
  Opened = false
  vim.g.lazygit_loaded = false
  if api.nvim_win_is_valid(Winid) then
    api.nvim_win_close(Winid, true)
  end
  if api.nvim_buf_is_valid(Bufnr) then
    api.nvim_buf_set_var(Bufnr, 'bufhidden', 'wipe')
    api.nvim_buf_delete(Bufnr, { force = true })
  end
end

local function get_root(path)
  return vim.fs.dirname(vim.fs.find('.git', {
    path = path,
    upward = true,
    type = 'directory',
  })[1])
end

local function open(path)
  if Opened then
    on_exit()
  else
    Opened = true
    PrevWinid = api.nvim_get_current_win()

    if not vim.g.lazygit_loaded then
      Bufnr = api.nvim_create_buf(false, true)
    end

    local opts = {
      relative = 'editor',
      col = math.floor((1 - Config.width) / 2 * vim.o.columns),
      row = math.floor((1 - Config.height) / 2 * vim.o.lines),
      width = math.floor(Config.width * vim.o.columns),
      height = math.floor(Config.height * vim.o.lines),
      border = Config.border,
    }
    Winid = api.nvim_open_win(Bufnr, true, opts)
    api.nvim_win_set_option(Winid, 'winhl', 'NormalFloat:LazyGitNormal,FloatBorder:LazyGitBorder')
    api.nvim_win_set_option(Winid, 'sidescrolloff', 0)

    if not vim.g.lazygit_loaded then
      local dir = path ~= '' and path or vim.loop.cwd()
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
      api.nvim_buf_set_option(Bufnr, 'bufhidden', 'hide')
      api.nvim_buf_set_option(Bufnr, 'filetype', 'lazygit')
      vim.g.lazygit_loaded = true
    end

    -- because *sometimes* terminal slides to the left for no reason
    -- this seems to fix that
    api.nvim_win_set_cursor(Winid, { 1, 0 })
    vim.schedule(function()
      api.nvim_exec('startinsert!', false)
    end)
  end
end

local default_config = {
  width = 0.9,
  height = 0.9,
  border = 'none',
}

local function setup(opts)
  Config = vim.tbl_extend('force', default_config, opts or {})
  api.nvim_create_user_command('LazyGit', function()
    open()
  end, { nargs = 0, desc = 'Open lazygit' })
  api.nvim_set_hl(0, 'LazyGitNormal', { link = 'NormalFloat', default = true })
  api.nvim_set_hl(0, 'LazyGitBorder', { link = 'FloatBorder', default = true })
end

local function set_prev_win()
  Opened = false
  local bufnr = api.nvim_win_get_buf(Winid)
  if api.nvim_win_is_valid(PrevWinid) then
    api.nvim_win_set_buf(PrevWinid, bufnr)
  end
  if api.nvim_win_is_valid(Winid) then
    api.nvim_win_close(Winid, true)
  end
end

local function _edit_file(path)
  api.nvim_cmd({ cmd = 'edit', args = { path } }, {})
  set_prev_win()
end

return {
  setup = setup,
  open = open,
  _edit_file = _edit_file,
  _edit_commit = set_prev_win,
}
