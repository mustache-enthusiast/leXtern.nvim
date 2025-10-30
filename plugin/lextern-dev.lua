
vim.api.nvim_create_user_command('lexternTestSanitize', function(opts)
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
vim.api.nvim_create_user_command('lexternTestFiguresDir', function()
  local utils = require('lextern.utils')
  local dir = utils.get_figures_dir()
  
  if dir == nil then
    print("No figures directory found (no file open)")
  else
    print(string.format("Figures directory: %s", dir))
  end
end, { nargs = 0 })

-- Test figure_path
vim.api.nvim_create_user_command('lexternTestFiguresPath', function(opts)
  local utils = require('lextern.utils')
  local dir = utils.get_figures_dir()
  
  if not dir then
    print("✗ No figures directory found")
    return
  end
  
  local filename = opts.args
  local path = utils.figure_path(dir, filename)
 print(string.format('✓ Figure path: %s', path))

    -- Optionally check if it exists
    if utils.figure_exists(path) then
        print("  (exists)")
    else
        print("  (does not exist)")
    end 
end, { nargs = 1 })


-- Test open_inkscape
vim.api.nvim_create_user_command('lexternTestOpen', function(opts)
  local utils = require('lextern.utils')
  
  local filepath = opts.args
  if filepath == "" then
    print("Usage: :lexternTestOpen <filepath>")
    return
  end
  
  utils.open_inkscape(filepath)
  print(string.format("Opening Inkscape with: %s", filepath))
end, { nargs = 1 })

-- Test insert_at_cursor
vim.api.nvim_create_user_command('lexternTestInsert', function(opts)
  local utils = require('lextern.utils')
  local text = opts.args
  
  if text == "" then
    text = "\\incfig{test-figure}"
  end
  
  utils.insert_at_cursor(text)
end, { nargs = '?' })  -- '?' = optional argument


-- Test list_figures
vim.api.nvim_create_user_command('lexternTestList', function()
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


-- Test get_template
vim.api.nvim_create_user_command('lexternTestGetTemplate', function(opts)
  local utils = require('lextern.utils')
  local template_name = opts.args
  
  if template_name == "" then
    print("Usage: :lexternTestGetTemplate <template_name>")
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
vim.api.nvim_create_user_command('lexternTestWriteTemplate', function()
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
vim.api.nvim_create_user_command('lexternTestGenerateFigure', function(opts)
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
vim.api.nvim_create_user_command('lexternTestRegister', function(opts)
  local utils = require('lextern.utils')
  local text = opts.args
  
  if text == "" then
    text = "Test content\nLine 2\nLine 3"
  end
  
  utils.copy_to_register(text)
  print('✓ Copied to register "')
  print('Try: press p to paste')
end, { nargs = '?' })
