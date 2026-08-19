-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/vonfig/keymaps.lua
-- Add any additional keymaps here
local function close_buffer_and_window()
  local buf_to_close = vim.api.nvim_win_get_buf(0)
  vim.api.nvim_win_close(0, nil)
  vim.api.nvim_buf_delete(buf_to_close, { force = true })
end

local map = LazyVim.safe_keymap_set
map(
  "n",
  "<leader>tp",
  '<cmd> let @*=expand("%:t")..":"..expand(line("."))<CR>',
  { desc = "copy current file and line" }
)
map({ "n", "t" }, "<leader>rw", "<cmd>Floaterminal<CR>", { desc = "Open/close last test run output" })
map("n", "<leader>rt", "<cmd>DotnetNoCacheTest<CR>", { desc = "Run dotnet test for method under the cursor" })
map(
  "n",
  "<leader>rd",
  "<cmd>DebugDotnetTest<CR>",
  { desc = "Run dotnet test ready to attach for debug on the method under the cursor" }
)
map("n", "<leader>ra", "<cmd>DotnetNoCacheTestAll<CR>", { desc = "Run all dotnet tests" })
map("n", "<leader>rb", "<cmd>DotnetBuild<CR>", { desc = "Run dotnet buid" })
map("n", "<leader>rr", "<cmd>DotnetRestore<CR>", { desc = "Run dotnet restore" })
map("n", "<leader>rc", "<cmd>DotnetClean<CR>", { desc = "Run dotnet clean" })
map("n", "<leader>rp", "<cmd>DotnetBuildProject<CR>", { desc = "Run dotnet build project of the current file" })
map("n", "<leader>n", "<cmd>Telescope notify<CR>", { desc = "Search notifications" })
map("n", "<leader>bq", close_buffer_and_window, { desc = "Force close the current buffer and window" })
map("n", "<leader>mp", "<cmd>MarkdownPreview<CR>", { desc = "Open MarkdownPreview" })
map("n", "<leader>ms", "<cmd>MarkdownPreviewStop<CR>", { desc = "MarkdownPreviewStop" })
map("n", "<leader><leader>", "<cmd>Telescope find_files hidden=true<cr>", { desc = "Find Files" })
map("t", "<esc><esc>", "<c-\\><c-n>", { desc = "Exit insert mode on a terminal" })
map("t", "q", "<c-\\><c-n>", { desc = "Exit insert mode on a terminal" })

map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code actions" })

map("n", "<leader>gd", "/<<<\\||||\\|>>>\\|===<CR>", { desc = "Search next git comfict marker" })
