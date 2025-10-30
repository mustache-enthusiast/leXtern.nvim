-- Main create figure command
vim.api.nvim_create_user_command('LexternCreate', function(opts)
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

-- Edit figure command
vim.api.nvim_create_user_command('LexternEdit', function()
  local lextern = require('lextern')
  lextern.edit_figure()
end, { nargs = 0 })

-- Add figure command
vim.api.nvim_create_user_command('LexternAdd', function()
  local lextern = require('lextern')
  lextern.add_figure()
end, { nargs = 0 })

-- Preamble command
vim.api.nvim_create_user_command('LexternPreamble', function()
  local lextern = require('lextern')
  lextern.preamble()
end, { nargs = 0 })

-- Watch command
vim.api.nvim_create_user_command('LexternWatch', function(opts)
  local lextern = require('lextern')
  local directory = opts.args ~= "" and opts.args or nil
  lextern.start_watcher(directory)
end, { nargs = '?' })

-- Stop watch command
vim.api.nvim_create_user_command('LexternWatchStop', function()
  local lextern = require('lextern')
  lextern.stop_watcher()
end, { nargs = 0 })

-- Status command
vim.api.nvim_create_user_command('LexternStatus', function()
  local lextern = require('lextern')
  lextern.watcher_status()
end, { nargs = 0 })


