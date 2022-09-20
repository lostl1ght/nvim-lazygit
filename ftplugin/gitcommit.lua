if vim.g.lazygit_loaded then
  local group = vim.api.nvim_create_augroup('LazyGitRemote', {})
  vim.api.nvim_create_autocmd('BufUnload', {
    group = group,
    buffer = 0,
    callback = function()
      vim.schedule(function()
        require('lazygit').open_lazygit()
      end)
    end,
  })
end
