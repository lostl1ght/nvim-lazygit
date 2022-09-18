local Opened = false

local function close_lazygit()
  Opened = false
  if vim.api.nvim_win_is_valid(0) then
    vim.api.nvim_win_close(0, true)
  end
end

local group = vim.api.nvim_create_augroup('LazyGitAugroup', {})
local function buf_autocmds(bufnr)
  vim.api.nvim_create_autocmd('BufLeave', {
    once = true,
    buffer = bufnr,
    group = group,
    callback = function()
      close_lazygit()
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

local function open_lazygit(path, width, height, border)
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

    local opts = {
      relative = 'editor',
      col = math.floor((1 - width) / 2 * vim.o.columns),
      row = math.floor((1 - height) / 2 * vim.o.lines),
      width = math.floor(width * vim.o.columns),
      height = math.floor(height * vim.o.lines),
      border = border,
    }

    local bufnr = vim.api.nvim_create_buf(true, true)
    local winid = vim.api.nvim_open_win(bufnr, true, opts)
    vim.api.nvim_win_set_buf(winid, bufnr)

    vim.fn.termopen(cmd, { on_exit = on_exit })
    vim.cmd('startinsert')

    vim.api.nvim_win_set_option(winid, 'sidescrolloff', 0)
    vim.api.nvim_win_set_option(winid, 'virtualedit', '')
    vim.api.nvim_win_set_option(winid, 'winhl', 'NormalFloat:LazyGitNormal')
    vim.api.nvim_buf_set_option(bufnr, 'bufhidden', 'wipe')
    buf_autocmds(bufnr)
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
