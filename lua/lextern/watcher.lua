-- File watcher for auto-exporting SVG to PDF+LaTeX
local M = {}
local utils = require('lextern.utils')

-- Watcher state
local state = {
  watching = false,
  directory = nil,
  handle = nil,
  last_export = {},  -- filename -> timestamp (for debouncing)
}

-- Debounce time in milliseconds
local DEBOUNCE_MS = 100

-- Check if a file should be exported (debouncing)
local function should_export(filename)
  local now = vim.loop.now()
  local last = state.last_export[filename] or 0
  
  if now - last < DEBOUNCE_MS then
    return false  -- Too soon, ignore
  end
  
  state.last_export[filename] = now
  return true
end

-- Handle file system events
local function on_change(err, filename, events)
  if err then
    vim.notify("Watcher error: " .. err, vim.log.levels.ERROR)
    return
  end
  
  -- filename might be nil on some platforms, ignore if so
  if not filename then
    return
  end
  
  -- Only process .svg files
  if not filename:match("%.svg$") then
    return
  end
  
  -- Debounce: ignore rapid successive events
  if not should_export(filename) then
    return
  end
  
  -- Build full path
  local svg_path = state.directory .. "/" .. filename
  
  -- Export the file
  vim.schedule(function()
    local success, err = utils.export_svg_to_pdf_latex(svg_path)
    
    if success then
      vim.notify(string.format("Exported: %s", filename), vim.log.levels.INFO)
    else
      vim.notify(string.format("Export failed for %s: %s", filename, err), vim.log.levels.ERROR)
    end
  end)
end

-- Start watching a directory
function M.start_watch(directory)
  -- Validate directory exists
  if vim.fn.isdirectory(directory) == 0 then
    return nil, "Directory does not exist: " .. directory
  end
  
  -- Check if already watching
  if state.watching then
    if state.directory == directory then
      return nil, "Already watching: " .. directory
    else
      return nil, "Already watching another directory: " .. state.directory
    end
  end
  
  -- Create watcher handle
  local handle = vim.loop.new_fs_event()
  if not handle then
    return nil, "Failed to create watcher handle"
  end
  
  -- Start watching
  local success, watch_err = handle:start(directory, {}, on_change)
  
  if not success then
    handle:close()
    return nil, "Failed to start watcher: " .. (watch_err or "unknown error")
  end
  
  -- Update state
  state.watching = true
  state.directory = directory
  state.handle = handle
  state.last_export = {}
  
  return true
end

-- Stop watching
function M.stop_watch()
  if not state.watching then
    return nil, "Not currently watching"
  end
  
  -- Stop and close the handle
  if state.handle then
    state.handle:stop()
    state.handle:close()
  end
  
  -- Clear state
  state.watching = false
  state.directory = nil
  state.handle = nil
  state.last_export = {}
  
  return true
end

-- Check if watching
function M.is_watching()
  return state.watching
end

-- Get current status
function M.get_status()
  if not state.watching then
    return {
      watching = false,
    }
  end
  
  return {
    watching = true,
    directory = state.directory,
    num_exports = vim.tbl_count(state.last_export),
  }
end

return M
