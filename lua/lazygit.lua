local api = vim.api

api.nvim_set_var('lazygit_loaded', false)

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
  hide_map = '<c-q>',
}

---@class Private
local Private = {
  state = State.Closed,
  bufnr = -1,
  winid = -1,
  prev_winid = -1,
  config = DefaultConfig,
}

--@class Public
local Public = {}

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
---@param gitdir string|nil
function Private:create_buffer(gitdir)
  self.bufnr = api.nvim_create_buf(false, true)
  api.nvim_win_set_buf(self.winid, self.bufnr)

  vim.fn.termopen('lazygit -p ' .. gitdir, {
    on_exit = function()
      self:delete_buffer()
      self.state = State.Closed
    end,
  })
  api.nvim_buf_set_option(self.bufnr, 'bufhidden', 'hide')
  api.nvim_buf_set_option(self.bufnr, 'filetype', 'lazygit')
  api.nvim_buf_set_var(self.bufnr, 'lazygit_dir', gitdir)
  api.nvim_set_var('lazygit_loaded', true)
  if self.config.hide_map then
    vim.keymap.set('t', self.config.hide_map, function()
      Public.hide()
    end)
  end
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
  self.prev_winid = api.nvim_get_current_win()
  local opts = {
    relative = 'editor',
    col = math.floor((1 - self.config.width) / 2 * vim.o.columns),
    row = math.floor((1 - self.config.height) / 2 * vim.o.lines),
    width = math.floor(self.config.width * vim.o.columns),
    height = math.floor(self.config.height * vim.o.lines),
    border = self.config.border,
    style = 'minimal',
  }
  self.winid = api.nvim_open_win(0, true, opts)
  api.nvim_win_set_option(
    self.winid,
    'winhighlight',
    'NormalFloat:LazyGitNormal,FloatBorder:LazyGitBorder'
  )
  api.nvim_win_set_option(self.winid, 'sidescrolloff', 0)
  api.nvim_win_set_option(self.winid, 'number', false)
end

function Private.get_root(path)
  return vim.fs.dirname(vim.fs.find('.git', {
    path = path,
    upward = true,
    type = 'directory',
  })[1])
end

function Public.open(path)
  if path then
    Private:delete_buffer()
    -- Needed so on_exit does not close a new lazygit instance
    vim.wait(1000, function()
      return Private.state == State.Closed
    end, 50)
  end
  if Private.state ~= State.Opened then
    Private:create_window()
    if Private.state == State.Closed then
      local dir = path ~= '' and path or vim.loop.cwd()
      local gitdir = Private.get_root(dir)
      if not gitdir then
        vim.notify('Lazygit: not a git repo', vim.log.levels.ERROR)
        Private:delete_window()
        return
      end
      Private:create_buffer(gitdir)
    end
    Private:post_open_setup()
    Private.state = State.Opened
  end
end

---Setup the plugin
---@param opts DefaultConfig|nil
function Public.setup(opts)
  Private.config = vim.tbl_extend('force', Private.config, opts or {})
  api.nvim_create_user_command('Lazygit', function(arg)
    local path
    if arg.args ~= '' then
      path = arg.args
    end
    Public.open(path)
  end, { nargs = '?', complete = 'dir', desc = 'Open lazygit' })
  api.nvim_set_hl(0, 'LazyGitNormal', { link = 'NormalFloat', default = true })
  api.nvim_set_hl(0, 'LazyGitBorder', { link = 'FloatBorder', default = true })
end

---Edit git files
---`Should called from GIT_EDITOR env variable`
function Public.git_editor()
  local bufnr = api.nvim_win_get_buf(Private.winid)
  if api.nvim_win_is_valid(Private.prev_winid) then
    local opts = {
      'number',
      'relativenumber',
      'sidescrolloff',
      'cursorline',
      'foldcolumn',
      'spell',
      'list',
      'signcolumn',
      'colorcolumn',
    }
    for _, v in ipairs(opts) do
      opts[v] = api.nvim_win_get_option(Private.prev_winid, v)
    end

    api.nvim_win_set_buf(Private.prev_winid, bufnr)

    for _, v in ipairs(opts) do
      api.nvim_win_set_option(Private.prev_winid, v, opts[v])
    end
    Public.hide()
  end
end

---Edit file
---`Should be called from lazygit config`
---@param path string
function Public.edit_file(path)
  local dir = api.nvim_buf_get_var(Private.bufnr, 'lazygit_dir')
  if api.nvim_win_is_valid(Private.prev_winid) then
    api.nvim_set_current_win(Private.prev_winid)
    Public.hide()
  end
  api.nvim_cmd({
    cmd = 'edit',
    args = { dir .. '/' .. path },
  }, {})
end

---Hide lazygit window
function Public.hide()
  Private:delete_window()
  Private.state = State.Hidden
end

return Public
