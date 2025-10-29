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
