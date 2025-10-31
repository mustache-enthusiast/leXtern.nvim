
vim.api.nvim_create_user_command('LexternTestSanitize', function(opts)
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
vim.api.nvim_create_user_command('LexternTestFiguresDir', function()
  local utils = require('lextern.utils')
  local dir = utils.get_figures_dir()
  
  if dir == nil then
    print("No figures directory found (no file open)")
  else
    print(string.format("Figures directory: %s", dir))
  end
end, { nargs = 0 })

-- Test figure_path
vim.api.nvim_create_user_command('LexternTestFiguresPath', function(opts)
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
vim.api.nvim_create_user_command('LexternTestOpen', function(opts)
  local utils = require('lextern.utils')
  
  local filepath = opts.args
  if filepath == "" then
    print("Usage: :LexternTestOpen <filepath>")
    return
  end
  
  utils.open_inkscape(filepath)
  print(string.format("Opening Inkscape with: %s", filepath))
end, { nargs = 1 })

-- Test insert_at_cursor
vim.api.nvim_create_user_command('LexternTestInsert', function(opts)
  local utils = require('lextern.utils')
  local text = opts.args
  
  if text == "" then
    text = "\\incfig{test-figure}"
  end
  
  utils.insert_at_cursor(text)
end, { nargs = '?' })  -- '?' = optional argument


-- Test list_figures
vim.api.nvim_create_user_command('LexternTestList', function()
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
vim.api.nvim_create_user_command('LexternTestGetTemplate', function(opts)
  local utils = require('lextern.utils')
  local template_name = opts.args
  
  if template_name == "" then
    print("Usage: :LexternTestGetTemplate <template_name>")
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
vim.api.nvim_create_user_command('LexternTestWriteTemplate', function()
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
vim.api.nvim_create_user_command('LexternTestGenerateFigure', function(opts)
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
vim.api.nvim_create_user_command('LexternTestRegister', function(opts)
  local utils = require('lextern.utils')
  local text = opts.args
  
  if text == "" then
    text = "Test content\nLine 2\nLine 3"
  end
  
  utils.copy_to_register(text)
  print('✓ Copied to register "')
  print('Try: press p to paste')
end, { nargs = '?' })

-- Test export function
vim.api.nvim_create_user_command('LexternTestExport', function(opts)
  local utils = require('lextern.utils')
  local svg_path = opts.args
  
  if svg_path == "" then
    print("Usage: :LexternTestExport <path-to-svg>")
    return
  end
  
  print("Exporting: " .. svg_path)
  local success, err = utils.export_svg_to_pdf_latex(svg_path)
  
  if success then
    print("✓ Export successful!")
    print("  Check for .pdf and .pdf_tex files")
  else
    print("✗ Export failed: " .. err)
  end
end, { nargs = 1 })


-- Test SVG metadata round-trip with Inkscape
vim.api.nvim_create_user_command('LexternTestMetadata', function()
  local utils = require('lextern.utils')
  
  -- Create test SVG from template
  local test_svg = "/tmp/metadata-test.svg"
  utils.write_template(test_svg, "template.svg")
  
  -- Write metadata
  print("Writing metadata...")
  local success = utils.write_svg_metadata(test_svg, {
    caption = "Test Caption with $\\alpha$",
    equation = "$e^{i\\pi} + 1 = 0$"
  })
  
  if not success then
    print("✗ Failed to write metadata")
    return
  end
  
  -- Read it back
  print("Reading metadata...")
  local meta = utils.read_svg_metadata(test_svg)
  print("Caption: " .. (meta.caption or "NOT FOUND"))
  print("Equation: " .. (meta.equation or "NOT FOUND"))
  
  -- Open in Inkscape
  print("\nNow opening in Inkscape...")
  print("1. Make a small change (draw something)")
  print("2. Save and close")
  print("3. Run :lexternTestMetadataVerify")
  
  utils.open_inkscape(test_svg)
end, { nargs = 0 })

-- Verify metadata survived Inkscape
vim.api.nvim_create_user_command('LexternTestMetadataVerify', function()
  local utils = require('lextern.utils')
  local test_svg = "/tmp/metadata-test.svg"
  
  local meta = utils.read_svg_metadata(test_svg)
  
  if meta.caption and meta.equation then
    print("✓ SUCCESS! Metadata survived Inkscape")
    print("Caption: " .. meta.caption)
    print("Equation: " .. meta.equation)
  else
    print("✗ FAILED! Metadata was lost")
    print("Caption: " .. (meta.caption or "MISSING"))
    print("Equation: " .. (meta.equation or "MISSING"))
  end
end, { nargs = 0 })
