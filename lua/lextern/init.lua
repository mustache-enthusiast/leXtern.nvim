local M = {}
local utils = require('lextern.utils')

-- Default configuration
M.config = {
  -- Directory creation behavior: "ask" (default), "always", "never"
  dir_create_mode = "ask",
}

function M.setup(opts)
  opts = opts or {}

  -- Merge user config with defaults
  M.config = vim.tbl_deep_extend("force", M.config, opts)

  -- Auto-stop watcher on exit
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      local watcher = require('lextern.watcher')
      if watcher.is_watching() then
        watcher.stop_watch()
      end
    end,
  })
end

-- Silently ensure watcher is running (for auto-start)
-- Returns true if started, false if already running or failed
local function ensure_watcher_running()
  local watcher = require('lextern.watcher')
  
  if watcher.is_watching() then
    return false
  end
  
  local dir = utils.get_figures_dir()
  if dir then
    local success = watcher.start_watch(dir)
    return success or false
  end
  
  return false
end

function M.create_figure(title)
  local target_filename, err = utils.sanitize_filename(title)
  if not target_filename then
    vim.notify(err, vim.log.levels.ERROR)
    return nil
  end
  
  local target_dir, err = utils.get_figures_dir()
  if not target_dir then
    vim.notify(err, vim.log.levels.ERROR)
    return nil
  end
  
  local target_path = utils.figure_path(target_dir, target_filename)
  if utils.figure_exists(target_path) then
    vim.notify("Figure already exists: " .. target_filename .. ".svg", vim.log.levels.WARN)
    return nil
  end
  
  local success, err = utils.write_template(target_path, "template.svg")
  if not success then
    vim.notify(err, vim.log.levels.ERROR)
    return nil
  end
  
  -- Store original caption in metadata
  local meta_success, meta_err = utils.write_svg_metadata(target_path, {caption = title})
  if not meta_success then
    vim.notify(meta_err, vim.log.levels.WARN)
  end
  
  if not utils.figure_exists(target_path) then
    vim.notify("Figure file was not created: " .. target_path, vim.log.levels.ERROR)
    return nil
  end
  
  -- Generate figure environment
  local figure_env, err = utils.generate_figure_environment(target_filename, title)
  if not figure_env then
    vim.notify(err, vim.log.levels.ERROR)
    return nil
  end
  
  utils.insert_at_cursor(figure_env)
  utils.open_inkscape(target_path)
  ensure_watcher_running()  -- Silent auto-start
  
  vim.notify("Figure created: " .. target_filename .. ".svg", vim.log.levels.INFO)
  return true
end

function M.edit_figure()
  local target_dir, err = utils.get_figures_dir()
  if not target_dir then
    vim.notify(err, vim.log.levels.ERROR)
    return nil
  end
  
  local figures_list = utils.list_figures(target_dir)
  if #figures_list == 0 then
    vim.notify("No figures found in: " .. target_dir, vim.log.levels.INFO)
    return nil
  end
  
  vim.ui.select(figures_list,
    { prompt = "Select a figure:" },
    function(target_file, idx)
      if not target_file then
        return
      end
      
      local target_path = utils.figure_path(target_dir, target_file)
      utils.open_inkscape(target_path)
      ensure_watcher_running()  -- Silent auto-start
      
      -- Read caption from metadata, fallback to filename
      local metadata, err = utils.read_svg_metadata(target_path)
      if not metadata then
        vim.notify(err, vim.log.levels.WARN)
        metadata = {}
      end
      local caption = metadata.caption or target_file
      
      -- Copy figure code to register
      local figure_env, err = utils.generate_figure_environment(target_file, caption)
      if figure_env then
        utils.copy_to_register(figure_env)
        -- Delay notification to let selection UI fully close
        vim.defer_fn(function()
          vim.notify("Code copied to register - press 'p' to paste", vim.log.levels.INFO)
        end, 50)
      else
        vim.defer_fn(function()
          vim.notify(err, vim.log.levels.WARN)
        end, 50)
      end
    end
  )
end

function M.insert_figure()
  local target_dir, err = utils.get_figures_dir()
  if not target_dir then
    vim.notify(err, vim.log.levels.ERROR)
    return nil
  end
  
  local figures_list = utils.list_figures(target_dir)
  if #figures_list == 0 then
    vim.notify("No figures found in: " .. target_dir, vim.log.levels.INFO)
    return nil
  end
  
  vim.ui.select(figures_list,
    { prompt = "Select a figure:" },
    function(target_file, idx)
      if not target_file then
        return
      end
      
      local target_path = utils.figure_path(target_dir, target_file)
      
      -- Read caption from metadata
      local metadata, err = utils.read_svg_metadata(target_path)
      if not metadata then
        vim.notify(err, vim.log.levels.WARN)
        metadata = {}
      end
      local caption = metadata.caption or target_file
      
      local figure_env, err = utils.generate_figure_environment(target_file, caption)
      if figure_env then
        utils.copy_to_register(figure_env)
        -- Delay notification to let selection UI fully close
        vim.defer_fn(function()
          vim.notify("Code copied to register - press 'p' to paste", vim.log.levels.INFO)
        end, 50)
      else
        vim.defer_fn(function()
          vim.notify(err, vim.log.levels.ERROR)
        end, 50)
      end
    end
  )
end

-- Copy LaTeX preamble to register
function M.preamble()
  local preamble_content, err = utils.get_template("preamble.tex")
  if not preamble_content then
    vim.notify(err, vim.log.levels.ERROR)
    return nil
  end
  
  utils.copy_to_register(preamble_content)
  vim.notify("Preamble copied to register - press 'p' to paste", vim.log.levels.INFO)
  return true
end

-- Start file watcher (explicit command)
function M.start_watcher(directory)
  local watcher = require('lextern.watcher')
  
  -- Auto-detect directory if not provided
  if not directory then
    local err
    directory, err = utils.get_figures_dir()
    if not directory then
      vim.notify(err, vim.log.levels.ERROR)
      return nil
    end
  end
  
  local success, err = watcher.start_watch(directory)
  if not success then
    vim.notify(err, vim.log.levels.ERROR)
    return nil
  end
  
  vim.notify("Watching: " .. directory, vim.log.levels.INFO)
  return true
end

-- Stop file watcher (explicit command)
function M.stop_watcher()
  local watcher = require('lextern.watcher')
  
  local success, err = watcher.stop_watch()
  if not success then
    vim.notify(err, vim.log.levels.WARN)
    return nil
  end
  
  vim.notify("Watcher stopped", vim.log.levels.INFO)
  return true
end

-- Show watcher status (explicit command)
function M.watcher_status()
  local watcher = require('lextern.watcher')
  local status = watcher.get_status()
  
  if not status.watching then
    vim.notify("Watcher is not running", vim.log.levels.INFO)
  else
    vim.notify(string.format(
      "Watching: %s\nFiles exported: %d",
      status.directory,
      status.num_exports
    ), vim.log.levels.INFO)
  end
end

return M
