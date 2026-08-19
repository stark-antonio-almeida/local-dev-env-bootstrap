-- Globals
BUILD_DOTNET_COMMAND_NAME = "DotnetBuild"
CLEAN_DOTNET_COMMAND_NAME = "DotnetClean"
RESTORE_DOTNET_COMMAND_NAME = "DotnetRestore"
RUN_DOTNET_NO_CACHE_TEST_COMMAND_NAME = "DotnetNoCacheTest"
RUN_DOTNET_NO_CACHE_TEST_PATTERN_NAME = "DotnetNoCacheTestPattern"
RUN_DOTNET_NO_CACHE_TEST_ALL_COMMAND_NAME = "DotnetNoCacheTestAll"
DEBUG_DOTNET_TEST_COMMAND_NAME = "DebugDotnetTest"
TESTS_LIST_SPLIT_PATTERN = "The following Tests are available:\n"
BUILD_DOTNET_PROJECT_COMMAND_NAME = "DotnetBuildProject"

local state = {
  title = "Dotnet",
  verbosity = "n",
  floating = {
    buf = nil,
    win = -1,
  },
}

local valid_verbosity = {
  q = true,
  m = true,
  n = true,
  d = true,
  diag = true,
}

-- functions
local function verbosity_args()
  if not state.verbosity then
    return ""
  end

  return " -v " .. state.verbosity
end

local function create_floating_window(opts)
  opts = opts or {}
  local width = opts.width or math.floor(vim.o.columns * 0.8)
  local height = opts.height or math.floor(vim.o.lines * 0.8)

  -- Calculate the position to center the window
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  -- Create a buffer
  local buf = nil
  if opts.buf and vim.api.nvim_buf_is_valid(opts.buf) then
    buf = opts.buf
  else
    buf = vim.api.nvim_create_buf(false, true) -- No file, scratch buffer
    vim.api.nvim_buf_set_name(buf, "dotnet_run")
  end

  -- Define window configuration
  local win_config = {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    title = opts.title or " Dotnet ",
    title_pos = "center",
  }

  -- Create the floating window
  local win = vim.api.nvim_open_win(buf, true, win_config)

  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true

  vim.keymap.set("n", "q", function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_hide(win)
    end
  end, {
    buffer = buf,
    silent = true,
    nowait = true,
  })

  return { buf = buf, win = win, title = win_config.title }
end

local function set_terminal_title(command)
  state.title = string.format("(%s) %s", os.date("%H:%M:%S"), command)

  if not vim.api.nvim_win_is_valid(state.floating.win) then
    return
  end

  vim.api.nvim_win_set_config(
    state.floating.win,
    vim.tbl_extend("force", vim.api.nvim_win_get_config(state.floating.win), { title = state.title })
  )
end

local toggle_terminal = function()
  if not vim.api.nvim_win_is_valid(state.floating.win) then
    state.floating = create_floating_window({ buf = state.floating.buf, title = state.title })
  else
    vim.api.nvim_win_hide(state.floating.win)
  end
end

local function run_on_temp_buffer(title, cmd_str)
  if cmd_str == nil or cmd_str == "" then
    vim.notify("Empty cmd string stopping", vim.log.levels.ERROR, { title = title, timeout = 2000 })
    return
  end

  if not vim.api.nvim_win_is_valid(state.floating.win) then
    local last_buf = state.floating.buf
    state.floating = create_floating_window({ buf = -1, title = state.title })

    set_terminal_title(cmd_str)

    vim.fn.termopen(cmd_str, {
      on_exit = function()
        vim.notify("Done: " .. cmd_str, vim.log.levels.INFO, { title = title, timeout = 2000 })
      end,
    })
    vim.notify(cmd_str, vim.log.levels.INFO, { title = title, timeout = 6000 })
    vim.bo[state.floating.buf].filetype = "sh"

    if last_buf ~= -1 and last_buf ~= nil then
      vim.api.nvim_buf_delete(last_buf, { unload = true, force = true })
    end
  end
end

local function find_nearest_csproj()
  local current_file = vim.api.nvim_buf_get_name(0)

  if current_file == "" then
    return nil
  end

  local start_dir = vim.fs.dirname(current_file)

  local matches = vim.fs.find(function(name)
    return name:match("%.csproj$")
  end, {
    path = start_dir,
    upward = true,
    type = "file",
    limit = 1,
  })

  return matches[1]
end

--
---@param node TSNode | nil
---@return table
local function get_parent_node_for(node, type)
  if node == nil then
    return { found = false }
  end
  if node:type() == "compilation_unit" then
    return { found = false }
  end
  if node:type() ~= type then
    return get_parent_node_for(node:parent(), type)
  end
  if node:type() == type then
    local child
    for c in node:iter_children() do
      if c:type() == "identifier" then
        child = c
      end
    end
    return { found = true, node = child }
  end
  return { found = false }
end

local function get_current_method_name()
  vim.treesitter.get_parser(0):parse()
  local node = vim.treesitter.get_node(nil)
  local result = get_parent_node_for(node, "method_declaration")
  local found = result.found
  if not found then
    vim.notify("No method found", vim.log.levels.WARN)
    return nil
  else
    local text = vim.treesitter.get_node_text(result.node, 0)
    return text
  end
end

local function make_dotnet_test_no_cache()
  -- get current word. should be the methot name
  -- TODO: validate the method name is valid
  local wordUnderCursor = get_current_method_name()
  if wordUnderCursor == nil then
    print("here and not supposed to")
    return
  end
  return "dotnet test -c Debug --no-restore "
    .. verbosity_args()
    .. ' -l "console;verbosity=normal" --filter '
    .. wordUnderCursor
end

local function run_dotnet_test_no_cache()
  local to_execute = make_dotnet_test_no_cache()
  print(to_execute)
  run_on_temp_buffer("dotnet test", to_execute)
end

-- setup commands
local function setup()
  -- local dotnet = require("dap-dotnet")
  -- dotnet.setup()

  -- Create a floating window with default dimensions
  vim.api.nvim_create_user_command("Floaterminal", toggle_terminal, {})

  vim.api.nvim_create_user_command(RUN_DOTNET_NO_CACHE_TEST_COMMAND_NAME, run_dotnet_test_no_cache, { nargs = 0 })

  vim.api.nvim_create_user_command(RUN_DOTNET_NO_CACHE_TEST_ALL_COMMAND_NAME, function()
    run_on_temp_buffer("dotnet test", "dotnet test " .. verbosity_args())
  end, { nargs = 0 })

  vim.api.nvim_create_user_command(RUN_DOTNET_NO_CACHE_TEST_PATTERN_NAME, function(opts)
    local to_execute = "dotnet test --no-restore"
      .. verbosity_args()
      .. ' -l "console;verbosity=normal" --filter '
      .. opts.fargs[1]
    run_on_temp_buffer("dotnet test", to_execute)
    print(string.format("Running all tests for %s", opts.fargs[1]))
  end, { nargs = 1 })

  vim.api.nvim_create_user_command(BUILD_DOTNET_COMMAND_NAME, function()
    run_on_temp_buffer("dotnet build", "dotnet build" .. verbosity_args())
  end, { nargs = 0 })

  vim.api.nvim_create_user_command(RESTORE_DOTNET_COMMAND_NAME, function()
    run_on_temp_buffer("dotnet restore", "dotnet restore")
  end, { nargs = 0 })

  vim.api.nvim_create_user_command(CLEAN_DOTNET_COMMAND_NAME, function()
    run_on_temp_buffer("dotnet clean", "dotnet clean" .. verbosity_args())
  end, { nargs = 0 })

  -- vim.api.nvim_create_user_command(DEBUG_DOTNET_TEST_COMMAND_NAME, function()
  --   local to_execute = make_dotnet_test_no_cache() .. "-e COMPlus_JITMinOpts=1 -e VSTEST_RUNNER_DEBUG=1"
  --   run_on_temp_buffer("Debug test", to_execute)
  --   print(to_execute)
  -- end, { nargs = 0 })

  vim.api.nvim_create_user_command("DotnetFormat", function(opts)
    local pathName = string.sub(vim.fn.expand("%"), string.len(vim.fn.getcwd()) + 2)
    local command = "dotnet format --no-restore --severity "
      .. opts.fargs[1]
      .. " "
      .. verbosity_args()
      .. " --include "
      .. pathName
    run_on_temp_buffer(command, command)
  end, { nargs = 1 })

  vim.api.nvim_create_user_command(BUILD_DOTNET_PROJECT_COMMAND_NAME, function()
    local csproj = find_nearest_csproj()

    if not csproj then
      vim.notify("No .csproj found", vim.log.levels.WARN)
      return
    end

    run_on_temp_buffer("dotnet build", string.format('dotnet build "%s"', csproj))
  end, { nargs = 0 })

  vim.api.nvim_create_user_command("DotnetVerbosity", function(opts)
    local value = opts.args

    if not valid_verbosity[value] then
      vim.notify(string.format("Invalid verbosity '%s'. Valid values: q, m, n, d, diag", value), vim.log.levels.ERROR)
      return
    end

    state.verbosity = value

    vim.notify(string.format("Dotnet verbosity set to '%s'", value), vim.log.levels.INFO)
  end, {
    nargs = 1,
    complete = function()
      return { "q", "m", "n", "d", "diag" }
    end,
  })
end

setup()
