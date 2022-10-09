vim.g.lazygit_loaded = false
local api = vim.api

---@enum State
local State = {
  Closed = 0,
  Hidden = 1,
  Opened = 2,
}

---@class DefaultConfig
local DefaultConfig = {
  width = 0.9,
  height = 0.9,
  border = 'none',
}

---@class Private
local Private = {
  state = State.Closed,
  bufnr = -1,
  winid = -1,
  prev_winid = -1,
  config = DefaultConfig,
}

---Delete terminal buffer
function Private:delete_buffer()
  if api.nvim_buf_is_valid(self.bufnr) then
    api.nvim_buf_set_var(self.bufnr, 'bufhidden', 'wipe')
    api.nvim_buf_delete(self.bufnr, { force = true })
  end
  self.bufnr = -1
end

---Delete floating window
function Private:delete_window()
  if api.nvim_win_is_valid(self.winid) then
    api.nvim_win_close(self.winid, true)
  end
  self.winid = -1
end

---Create a buffer and open the terminal
---@param path string|nil
---@return boolean result true if success
function Private:create_buffer(path)
  if not api.nvim_buf_is_valid(self.bufnr) then
    local dir = path ~= '' and path or vim.loop.cwd()
    local gitdir = self.get_root(dir)
    local cmd
    if gitdir then
      cmd = 'lazygit -p ' .. gitdir
    else
      vim.notify('Lazygit: not a git repo', vim.log.levels.ERROR)
      self:delete_window()
      return false
    end

    self.bufnr = api.nvim_create_buf(false, true)
    api.nvim_win_set_buf(self.winid, self.bufnr)

    vim.fn.termopen(cmd, {
      on_exit = function()
        self:delete_buffer()
        self.state = State.Closed
      end,
    })
    api.nvim_buf_set_option(self.bufnr, 'bufhidden', 'hide')
    api.nvim_buf_set_option(self.bufnr, 'filetype', 'lazygit')
    api.nvim_buf_set_var(self.bufnr, 'lazygit_dir', gitdir)
    api.nvim_set_var('lazygit_loaded', true)
  end
  return true
end

---Set buffer, cursor, start insert mode
function Private:post_open_setup()
  api.nvim_win_set_buf(self.winid, self.bufnr)
  -- because *sometimes* terminal slides to the left for no reason
  -- this seems to fix that
  api.nvim_win_set_cursor(self.winid, { 1, 0 })
  vim.schedule(function()
    api.nvim_set_current_win(self.winid)
    api.nvim_cmd({ cmd = 'startinsert' }, {})
  end)
end

function Private:create_window()
  Private.prev_winid = api.nvim_get_current_win()
  local opts = {
    relative = 'editor',
    col = math.floor((1 - Private.config.width) / 2 * vim.o.columns),
    row = math.floor((1 - Private.config.height) / 2 * vim.o.lines),
    width = math.floor(Private.config.width * vim.o.columns),
    height = math.floor(Private.config.height * vim.o.lines),
    border = Private.config.border,
  }
  Private.winid = api.nvim_open_win(0, true, opts)
  api.nvim_win_set_option(
    Private.winid,
    'winhl',
    'NormalFloat:LazyGitNormal,FloatBorder:LazyGitBorder'
  )
  api.nvim_win_set_option(Private.winid, 'sidescrolloff', 0)
  api.nvim_win_set_option(Private.winid, 'number', false)
end

function Private.get_root(path)
  return vim.fs.dirname(vim.fs.find('.git', {
    path = path,
    upward = true,
    type = 'directory',
  })[1])
end

local Public = {}

function Public.open(path)
  if path then
    Private:delete_buffer()
    -- Needed so on_exit does not close a new lf instance
    vim.wait(1000, function()
      return Private.state == State.Closed
    end, 50)
  end
  if Private.state ~= State.Opened then
    Private:create_window()
    if Private:create_buffer(path) then
      Private:post_open_setup()
      Private.state = State.Opened
    end
  end
end

function Public.setup(opts)
  Private.config = vim.tbl_extend('force', Private.config, opts or {})
  api.nvim_create_user_command('LazyGit', function()
    Public.open()
  end, { nargs = 0, desc = 'Open lazygit' })
  api.nvim_set_hl(0, 'LazyGitNormal', { link = 'NormalFloat', default = true })
  api.nvim_set_hl(0, 'LazyGitBorder', { link = 'FloatBorder', default = true })
end

function Public.commit()
  Private.state = State.Hidden
  local bufnr = api.nvim_win_get_buf(Private.winid)
  if api.nvim_win_is_valid(Private.prev_winid) then
    local nu = api.nvim_win_get_option(Private.prev_winid, 'number')
    local siso = api.nvim_win_get_option(Private.prev_winid, 'sidescrolloff')

    api.nvim_win_set_buf(Private.prev_winid, bufnr)

    api.nvim_win_set_option(Private.prev_winid, 'number', nu)
    api.nvim_win_set_option(Private.prev_winid, 'sidescrolloff', siso)
  end
  Public:hide()
end

function Public.edit(path)
  local dir = api.nvim_buf_get_var(Private.bufnr, 'lazygit_dir')
  api.nvim_cmd({
    cmd = 'edit',
    args = { dir .. '/' .. path },
  }, {})
  -- Reusing function for edititng commits
  Public.commit()
end

---Hide lazygit window
function Public:hide()
  Private:delete_window()
  Private.state = State.Hidden
end

return Public
