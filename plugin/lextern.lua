vim.api.nvim_create_user_command('LeXternTest', function(opts)
  local utils = require('lextern.utils')
  local input = opts.args
  local result = utils.sanitize_filename(input)
  
  if result == nil then
    print(string.format('"%s" -> nil (empty result)', input))
  else
    print(string.format('"%s" -> "%s"', input, result))
  end
end, { nargs = 1 })


-- Test get_figures_dir
vim.api.nvim_create_user_command('LeXternDir', function()
  local utils = require('lextern.utils')
  local dir = utils.get_figures_dir()
  
  if dir == nil then
    print("No figures directory found (no file open)")
  else
    print(string.format("Figures directory: %s", dir))
  end
end, { nargs = 0 })

-- Test get_template_path
vim.api.nvim_create_user_command('LeXternTemplate', function()
  local utils = require('lextern.utils')
  local template = utils.get_template_path()
  
  if template == nil then
    print("✗ Template not found!")
  else
    print(string.format("✓ Template found: %s", template))
  end
end, { nargs = 0 })

-- Test copy_template
vim.api.nvim_create_user_command('LeXternCopyTest', function()
  local utils = require('lextern.utils')
  local dest = "/tmp/test-figure.svg"
  
  local success = utils.copy_template(dest)
  
  if success then
    print(string.format("✓ Template copied to: %s", dest))
  else
    print("✗ Failed to copy template")
  end
end, { nargs = 0 })

-- Test figure_path
vim.api.nvim_create_user_command('LeXternPath', function(opts)
  local utils = require('lextern.utils')
  local dir = utils.get_figures_dir()
  
  if not dir then
    print("✗ No figures directory found")
    return
  end
  
  local filename = opts.args
  local path = utils.figure_path(dir, filename)
  
  if path then
    print(string.format('✓ Figure path: %s', path))
  else
    print(string.format('✗ Figure "%s.svg" does not exist', filename))
  end
end, { nargs = 1 })

-- Test open_inkscape
vim.api.nvim_create_user_command('LeXternOpen', function(opts)
  local utils = require('lextern.utils')
  
  local filepath = opts.args
  if filepath == "" then
    print("Usage: :LeXternOpen <filepath>")
    return
  end
  
  utils.open_inkscape(filepath)
  print(string.format("Opening Inkscape with: %s", filepath))
end, { nargs = 1 })

-- Test insert_at_cursor
vim.api.nvim_create_user_command('LeXternInsert', function(opts)
  local utils = require('lextern.utils')
  local text = opts.args
  
  if text == "" then
    text = "\\incfig{test-figure}"
  end
  
  utils.insert_at_cursor(text)
end, { nargs = '?' })  -- '?' = optional argument

-- Main create figure command
vim.api.nvim_create_user_command('LeXternCreate', function(opts)
  local lextern = require('lextern')
  
  local title = opts.args
  if title == "" then
    vim.ui.input({ prompt = "Figure title: " }, function(input)
      if input and input ~= "" then
        lextern.create_figure(input)
      end
    end)
  else
    lextern.create_figure(title)
  end
end, { nargs = '?' })

-- Test list_figures
vim.api.nvim_create_user_command('LeXternList', function()
  local utils = require('lextern.utils')
  local dir = utils.get_figures_dir()
  
  if not dir then
    print("✗ No figures directory found")
    return
  end
  
  local figures = utils.list_figures(dir)
  
  if #figures == 0 then
    print("No figures found in: " .. dir)
  else
    print("Figures found:")
    for _, fig in ipairs(figures) do
      print("  - " .. fig)
    end
  end
end, { nargs = 0 })

-- Edit figure command
vim.api.nvim_create_user_command('LeXternEdit', function()
  local lextern = require('lextern')
  lextern.edit_figure()
end, { nargs = 0 })

-- Test get_template
vim.api.nvim_create_user_command('LeXternTestGetTemplate', function(opts)
  local utils = require('lextern.utils')
  local template_name = opts.args
  
  if template_name == "" then
    print("Usage: :LeXternTestGetTemplate <template_name>")
    print("Examples: template.svg, preamble.tex, figure.tex")
    return
  end
  
  local content, err = utils.get_template(template_name)
  
  if not content then
    print("✗ Error: " .. err)
  else
    print("✓ Template found:")
    print(string.format("  Length: %d bytes", #content))
    print("  First 100 chars: " .. content:sub(1, 100))
  end
end, { nargs = 1 })

-- Test write_template
vim.api.nvim_create_user_command('LeXternTestWriteTemplate', function()
  local utils = require('lextern.utils')
  local dest = "/tmp/lextern-test-output.txt"
  
  local success, err = utils.write_template(dest, "preamble.tex")
  
  if not success then
    print("✗ Error: " .. err)
  else
    print("✓ Template written to: " .. dest)
    print("  Run: cat " .. dest)
  end
end, { nargs = 0 })

-- Test generate_figure_environment
vim.api.nvim_create_user_command('LeXternTestGenerateFigure', function(opts)
  local utils = require('lextern.utils')
  
  -- Default test values
  local filename = "test-figure"
  local caption = "Test Figure Caption"
  
  -- Or use args if provided
  if opts.args ~= "" then
    local parts = vim.split(opts.args, ",")
    filename = parts[1] or filename
    caption = parts[2] or caption
  end
  
  local result, err = utils.generate_figure_environment(filename, caption)
  
  if not result then
    print("✗ Error: " .. err)
  else
    print("✓ Generated figure environment:")
    print(result)
  end
end, { nargs = '?' })

-- Test copy_to_register
vim.api.nvim_create_user_command('LeXternTestRegister', function(opts)
  local utils = require('lextern.utils')
  local text = opts.args
  
  if text == "" then
    text = "Test content\nLine 2\nLine 3"
  end
  
  utils.copy_to_register(text)
  print('✓ Copied to register "')
  print('Try: press p to paste')
end, { nargs = '?' })

-- Preamble command
vim.api.nvim_create_user_command('LeXternPreamble', function()
  local lextern = require('lextern')
  lextern.preamble()
end, { nargs = 0 })


-- Add figure command
vim.api.nvim_create_user_command('LeXternAdd', function()
  local lextern = require('lextern')
  lextern.add_figure()
end, { nargs = 0 })
