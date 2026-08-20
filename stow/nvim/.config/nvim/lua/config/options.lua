-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.lazyvim_picker = "telescope"
vim.g.snacks_animate = false
vim.opt.fileformat = "unix"
-- vim.opt.fileformat = "unix"
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    if vim.bo.fileformat == "dos" then
      vim.bo.fileformat = "unix"
    end
  end,
})
