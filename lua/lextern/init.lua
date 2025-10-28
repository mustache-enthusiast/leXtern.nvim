local M = {}

-- Default configuration
local default_config = {
  figures_dir = "figures",  -- Relative to tex file, or absolute path
  template_path = vim.fn.stdpath('config') .. '/lextern/template.svg',
}

-- This will hold the actual config (defaults merged with user settings)
M.config = {}

function M.setup(opts)
  opts = opts or {}
  
  -- Merge user options with defaults
  -- vim.tbl_deep_extend merges tables, "force" means user opts override defaults
  M.config = vim.tbl_deep_extend("force", default_config, opts)
  
  print("leXtern.nvim loaded!")
end

return M
