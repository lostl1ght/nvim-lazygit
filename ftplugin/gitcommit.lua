if vim.api.nvim_get_var('lazygit_loaded') then
  local group = vim.api.nvim_create_augroup('LazyGitRemote', {})
  vim.api.nvim_create_autocmd('BufUnload', {
    group = group,
    buffer = 0,
    callback = function()
      vim.bo.bufhidden = 'wipe'
      vim.schedule(function()
        require('lazygit').open()
      end)
    end,
  })
end
