---@param node TSNode
---@return table
local function get_parent_method(node)
  if node == nil then
    return { found = false }
  end
  if node:type() == "compilation_unit" then
    return { found = false }
  end
  if node:type() ~= "method_declaration" then
    return get_parent_method(node:parent())
  end
  if node:type() == "method_declaration" then
    local child
    for c in node:iter_children() do
      if c:type() == "identifier" then
        child = c
      end
    end
    return { found = true, node = child }
  end
end

vim.api.nvim_create_user_command("Test", function(opts)
  local node = vim.treesitter.get_node(nil)
  local result = get_parent_method(node)
  local found = result["found"]
  if not found then
    vim.notify("No method found", "warn")
  else
    local m_name = vim.treesitter.get_node_text(result["node"], 0)
    print(m_name)
  end
end, { nargs = 0 })
