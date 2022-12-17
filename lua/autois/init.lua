local M = {}

local dirname = function(path, n)
  local dir = path
  for _ = 1, n do
    dir = vim.fs.dirname(dir)
  end
  return dir
end

local cur_file_path = debug.getinfo(1, 'S').source:sub(2)
local macism_path = dirname(cur_file_path, 3) .. "/bin/macism"

M.setup = function(opts)
  if vim.fn.has("mac") ~= 1 then
    vim.notify("This plugin only work in macOS.")
    return
  end

  if vim.fn.executable(macism_path) ~= 1 then
    vim.notify(macism_path .. [[ is missing or non executable.]])
    return
  end

  opts = opts or {}
  local macism_func = function(args)
    table.insert(args, 1, macism_path)
    local result = vim.fn.system(args)
    return vim.trim(result, " ")
  end
  -- config
  local english_input_source = opts.english_input_source or "com.apple.keylayout.ABC"
  local non_english_input_source = opts.non_english_input_source or macism_func({ "!", english_input_source })
  local smart_detect = opts.smart_detect or "zh"



  -- set autocmd
  if smart_detect ~= "disable" then
    vim.api.nvim_create_autocmd({ "InsertEnter" }, {
      callback = function()
        local current_is = macism_func({})

        local target_is = english_input_source
        if smart_detect == "zh" then
          local index = vim.fn.col(".")
          local char = string.sub(vim.api.nvim_get_current_line(), index - 1, index - 1)
          if (char >= "\x80") then
            target_is = non_english_input_source
          end
        else
          target_is = vim.g["autois_pre_i_is"] or target_is
        end

        if current_is ~= target_is then
          macism_func({ target_is })
        end
      end,
    })
  end

  vim.api.nvim_create_autocmd({ "InsertLeave", "VimEnter" }, {
    callback = function()
      local current_is = macism_func({})
      vim.g["autois_pre_i_is"] = current_is

      if current_is ~= english_input_source then
        macism_func({ english_input_source })
      end
    end,
  })

  vim.api.nvim_create_user_command('AutoisCurrentInputSource', function()
    local current_is = macism_func({})
    vim.fn.system("pbcopy", current_is)
    vim.notify(current_is)
  end, {})
end

return M