local os = require"os"
local builtin = require "telescope.builtin"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local pickers = require "telescope.pickers"
local actions = require "telescope.actions"
local Path = require("plenary.path")
local fd = builtin.find_files
local recent_file = builtin.oldfiles
local util = require("vscodews.util")
package.path = package.path .. ';' .. "?/.lua" .. ';' .. "?/init.lua"
package.cpath = package.cpath .. ';' .. os.getenv("HOME") .. "/.luarocks/lib/lua/5.1/?.so"


--- @class FileSearcher
--- @field search_only_project boolean
--- @field workspace_folders WorkspaceFolder[]
--- @field current_libs string[]
local M = {
  search_only_project = false,
  workspace_folders = {},
  config_root = nil,
  type_project_root_func_map = {
  },
  path_display = {
  },
  current_libs= {}
}
function M.register_file_type_path_display(file_type, func)
  M.path_display[file_type] = func
end

function M.register_file_type_project_root_func(file_type, func)
  M.type_project_root_func_map[file_type] = func
end

-- read map from config file, if not exist, use the default map
function M.find_file_at_cursor()
  local word = vim.fn.expand('<cword>')
  local opts = M.create_default_opts()
  opts.search_file = word

  M.search_file(opts)
end

function M.find_file_with_input()
  local text = vim.fn.input('Search file: ')
  local opts = M.create_default_opts()
  opts.search_file = text
  M.search_file(opts)
end


function M.toggle_search_only_project()
  M.search_only_project = not M.search_only_project
end

function M.auto_change_lib()
  if M.search_only_project then
    M.current_libs = M.workspace_folders
  else
    M.current_libs = {}
  end
end

function M.find_file()
  local opts = M.create_default_opts()
  M.search_file(opts)
end

function M.search_file(opt)
  opt.search_dirs = M.get_search_folder()
  opt.prompt_prefix = '🔍'
  fd(opt)
  opt = {}
end


M.custom_path_display = function(_, path)
  local tail = require("telescope.utils").path_tail(path)
  -- get path ext
  local ext = vim.fn.fnamemodify(path, ":e")
  if M.path_display ~= nil then
    local custom_path_func = M.path_display[ext] or M.path_display["default"]
    if custom_path_func ~= nil then
      return custom_path_func(path)
    end
  end
  return string.format("%s (%s)", tail, path)
end


function M.find_recent_files()
  local opts = {
    include_current_session=true,
    cwd_only=false,
    -- layout_strategy='vertical',
    layout_strategy='horizontal',
    layout_config={width=0.9, height=0.9},
    preview_cutoff=60,
    path_display = M.custom_path_display,
    -- TODO: it's not support by current telescope version, i change it locally to support this option
    search_dirs = M.get_search_folder(),
    prompt_title = 'Recent Files in workspace'
  }
  M.current_file_type = vim.fn.expand('%:e')
  recent_file(opts)
end

function M.lsp_implementations()
  local opts = {
    path_display = M.custom_path_display
  }
  M.current_file_type = vim.fn.expand('%:e')
  builtin.lsp_implementations(opts)
end

function M.lsp_references()
  local opts = {
    path_display = M.custom_path_display
  }
  M.current_file_type = vim.fn.expand('%:e')
  builtin.lsp_references(opts)
end


function M.find_text(text, opts)
  if opts == nil then
    opts = {}
  end
  local current_file_type= vim.fn.expand('%:e')
  if opts.prompt_title == nil then
    if text ~= nil then
      opts.prompt_title = 'Find Text' .. ' ' .. text .. " in workspace"
    else
      opts.prompt_title = 'Find Text in workspace'
    end
  end
  if opts.prompt_prefix == nil then
    opts.prompt_prefix = current_file_type .. '🔍'
  end
  opts.search = text
  opts.search_dirs = M.get_search_folder()
  opts.rg_opts = {"--after-context=3", "--before-context=3"}
  builtin.grep_string(opts)
end

local f_text = M.find_text
function M.find_text_at_cursor()
  -- get the word under the cursor
  local word = vim.fn.expand('<cword>')
  -- local word = vim.fn.expand('<cWORD>')
  -- get current already highlighted text
  -- local highlighted_text = vim.fn.getreg('/')
  -- copy table from global opt to local opt
  f_text(word, M.create_default_opts())
end

function M.find_text_with_input()
  local text = vim.fn.input('Search text: ')
  f_text(text, M.create_default_opts())
end

function M.create_default_opts()
  local opt = {}
  opt.prompt_prefix = '🔍'
  opt.path_display = M.custom_path_display
  M.current_file_type = vim.fn.expand('%:e')
  return opt
end

function M.get_search_folder()
  local menu_items = {}
  local index =  0
  local offset = 1
  menu_items[index + 1] = index .. ": All workspace folders"
  -- add config root
  if M.config_root ~= nil then
    index = index + 1
    offset = offset + 1
    menu_items[index + 1] = index.. ": Config Root: " .. M.config_root
  end
  for _, folder in pairs(M.workspace_folders) do
    index = index + 1
    menu_items[index + 1] = index .. ". ".. folder.name .. ": " ..folder.path
  end
  menu_items[index + 1]  = index ..". All Recent Files"
  local choice = vim.fn.inputlist(menu_items)
  if choice == nil or choice <= 0 or choice > index  then
    return vim.tbl_map(function(folder) return folder.path end, M.workspace_folders)
  end
  if M.config_root ~= nil and choice == 1 then
    return {M.config_root}
  end

  if choice == index  then
    return nil
  end
  local actual_index_in_workspace = choice - offset + 1
  return {M.workspace_folders[actual_index_in_workspace].path}
end

function M.find_text_in_selection()
  local lines = vim.fn.getregion(vim.fn.getpos('.'), vim.fn.getpos('v'), { type = vim.fn.mode() })
  for _, v in pairs(lines) do
    print("region line is " .. v)
  end
  local line_content = table.concat(lines, '\n')
  local text_show_in_head = line_content
  if #lines > 1 then
    text_show_in_head = lines[1]
  end
  local opts = M.create_default_opts();
  opts.prompt_title = 'Find Text ' .. text_show_in_head .. ' in workspace'
  f_text(line_content, opts)
end


function M.get_pro_root_dir()
  local current_file_type= vim.fn.expand('%:e')
  local project_root_func = M.type_project_root_func_map[current_file_type] or M.type_project_root_func_map["default"]
  if project_root_func ~= nil then
    return project_root_func()
  end
  return nil
end

function M.telescope_find_definition()
  local opts = M.create_default_opts()
  opts.path_display = M.custom_path_display
  opts.prompt_title = 'Find Definition in workspace'
  builtin.lsp_definitions(opts)
end

function M.find_java_definitioin_with_grit()
  local text = vim.fn.expand('<cword>')
  local grit_method_del_search = "method_declaration(name=$method_name,body=$method_body) where { $method_name <:  `" .. text .. "` }"
  local cmd_pattern = 'grit apply %s --language java'
  local cmd = string.format(cmd_pattern, grit_method_del_search)
  local opts = M.create_default_opts()
  local args = {
    cmd,
    'apply',
    grit_method_del_search,
    "--language",
    "java"
  }
  pickers
  .new(opts, {
    prompt_title = "Live Grep",
    -- finder = live_grepper,
    finder = finders.new_oneshot_job(args, opts),
    previewer = conf.file_previewer(opts),
    -- TODO: It would be cool to use `--json` output for this
    -- and then we could get the highlight positions directly.
    -- sorter = sorters.highlighter_only(opts),
    attach_mappings = function(_, map)
      map("i", "<c-space>", actions.to_fuzzy_refine)
      return true
    end,
    push_cursor_on_edit = true,
  })
  :find()

end

function M.find_definition()
  local text = vim.fn.expand('<cword>')
  local opts = M.create_default_opts()
  local current_file_type= vim.fn.expand('%:e')
  -- check if type_asso_definition_map has the current file type
  -- if yes, set the search pattern to the pattern
  -- if no, set the search pattern to the text
  if M.type_asso_definition_map[current_file_type] ~= nil then
    opts.search = string.format(M.type_asso_definition_map[current_file_type], text, text, text, text)
    opts.use_regex = true
    opts.addition_args = {"-e"}
  else
    opts.search = text
  end
  opts.prompt_title = 'Find Definition' .. ' ' .. text .. " in workspace"
  f_text(text, opts)
end


M.read_json_file = function (file_path)
  if not vim.fn.filereadable(file_path) then
    return nil
  end
  local file = io.open(file_path, "r")
  if file == nil then
    return nil
  end
  io.input(file)
  local content = io.read()
  io.close(file)
  local cfg = vim.json.decode(content)
  return cfg
end



---@param folders WorkspaceFolder[]
function M.init_search_lib(folders)
  M.current_libs = {}
  for _, folder in pairs(folders) do
    table.insert(M.current_libs, folder.path)
  end
end

function M.init_config(file_path)
  local cfg = M.read_json_file(file_path)
  if cfg ~= nil then
    M.type_assoc_pro_map = cfg.type_assoc_pro_map or M.type_assoc_pro_map
    M.type_asso_definition_map = cfg.type_asso_definition_map or M.type_asso_definition_map
    M.workspace_folders = cfg.folders or M.workspace_folders
  end
end

function M.register_autocmd()
  -- vim.cmd('augroup file')
  -- vim.cmd('autocmd!')
  -- vim.cmd('autocmd BufEnter * lua require("vscodews.file").auto_change_pro()')
  -- vim.cmd('augroup END')
  vim.api.nvim_create_user_command('ToggleSearchOnlyProject', 'lua require("file").toggle_search_only_project()', {bang = true})
end

function M.register_keymap()
  vim.api.nvim_set_var('mapleader', ',')
  local function opts(desc)
    return { desc = "🔍Lsp workspace " .. desc , noremap = true, silent = true}
  end
  vim.keymap.set('n', '<leader>fr', M.lsp_references, opts("Show references"))
  vim.keymap.set('n', '<leader>ft', M.find_text_in_selection, opts("Find text in selection"))
  vim.keymap.set('n', '<leader>ff', M.find_file_at_cursor, opts("Find file at cursor"))
  vim.keymap.set('n', '<leader>fd', M.find_file_with_input, opts("Find file with input"))
  vim.keymap.set('n', '<leader>fe', M.find_recent_files, opts("Find recent files"))
  vim.keymap.set('n', '<leader>fi', M.lsp_implementations, opts("Find implementations"))
  vim.keymap.set('n', '<leader>fw', M.find_text_at_cursor, opts("Find text at cursor"))
  vim.keymap.set('n', '<leader>fs', M.find_text_with_input, opts("Find text with input"))
  vim.keymap.set('v', '<leader>fw', M.find_text_in_selection, opts("Find text in selection"))
  vim.keymap.set('n', 'gd', M.telescope_find_definition, opts("Find definition"))
end

function M.setup(opts)
  if opts == nil then
    opts = {}
  else
    if opts.search_only_project ~= nil then
      M.search_only_project = opts.search_only_project
    end
  end
  if opts.folders ~= nil then
    M.workspace_folders = opts.folders
    M.init_search_lib(M.workspace_folders)
  end
  if opts.config_root ~= nil then
    M.config_root = opts.config_root
  end
  M.register_autocmd()
  M.register_keymap()
end
return M
