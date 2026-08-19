local function setup()
  vim.api.nvim_create_user_command("OpenVS", function(opts)
    vim.fn.jobstart("devenv /Edit " .. vim.api.nvim_buf_get_name(0))
  end, { nargs = 0 })
end
setup()
