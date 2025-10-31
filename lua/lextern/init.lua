local M = {}

local utils = require('lextern.utils')

function M.setup(opts)
  opts = opts or {}

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

-- Returns true if watcher was just started, false if already running
local function ensure_watcher_running()
  local watcher = require('lextern.watcher')
  
  -- Check if already watching
  if watcher.is_watching() then
    return false  -- Already running
  end
  
  -- Auto-start watcher
  local dir = utils.get_figures_dir()
  if dir then
    local success = watcher.start_watch(dir)
    return success or false  -- Return true if started successfully
  end
  
  return false
end

function M.create_figure(title)

    local target_filename = utils.sanitize_filename(title)
    if not target_filename then
        vim.notify("Error: '" .. title .. "' is not a valid file name.", vim.log.levels.WARN)
        return nil
    end

    local target_dir = utils.get_figures_dir()
    if not target_dir then
        vim.notify("Error: target directory not found.", vim.log.levels.WARN)
        return nil
    end

    local target_path = utils.figure_path(target_dir, target_filename)
    if utils.figure_exists(target_path) then
        vim.notify("Error: '" .. target_path .. "' already exists.", vim.log.levels.WARN)
        return nil
    end

    local success, err = utils.write_template(target_path, "template.svg")
    if not success then
        vim.notify("Error: " .. (err or "SVG template could not be created"), vim.log.levels.ERROR)
        return nil
    end

    -- Store original caption in metadata
    local meta_success = utils.write_svg_metadata(target_path, {caption = title})
    if not meta_success then
        -- Non-fatal: continue even if metadata write fails
        vim.notify("Warning: Could not write caption metadata", vim.log.levels.WARN)
    end

    if not utils.figure_exists(target_path) then
        vim.notify("Error: '" .. target_path .. "'  was not created.", vim.log.levels.ERROR)
        return nil
    end

    -- Generate full figure environment
    local figure_env, err = utils.generate_figure_environment(target_filename, title)
    if not figure_env then
        vim.notify("Error: " .. err, vim.log.levels.ERROR)
        return nil
    end

    utils.insert_at_cursor(figure_env)

    utils.open_inkscape(target_path)

    local watcher_started = ensure_watcher_running()
    if watcher_started then
        vim.notify("Figure created. Watcher started.", vim.log.levels.INFO)
    end

    return true

end


function M.edit_figure()
    
    local target_dir = utils.get_figures_dir()
    if not target_dir then
        vim.notify("Error: target directory not found.", vim.log.levels.WARN)
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

            vim.notify("Opening " .. target_file, vim.log.levels.INFO)
            utils.open_inkscape(target_path)
            ensure_watcher_running()

            -- Try to read caption from metadata, fallback to filename
            local metadata = utils.read_svg_metadata(target_path)
            local caption = metadata.caption or target_file

            -- Copy figure code to register for easy pasting
            local figure_env, err = utils.generate_figure_environment(target_file, caption)
            if figure_env then
                utils.copy_to_register(figure_env)
                local watcher_started = ensure_watcher_running()
                if watcher_started then
                    vim.notify("Figure opened. Code copied to register. Watcher started.", vim.log.levels.INFO)
                else
                    vim.notify("Figure opened. Code copied to register - press 'p' to paste.", vim.log.levels.INFO)
                end
            else
                vim.notify("Figure opened (code generation failed: " .. err .. ")", vim.log.levels.WARN)
            end
        end
    )
end


function M.insert_figure()
    
    local target_dir = utils.get_figures_dir()
    if not target_dir then
        vim.notify("Error: target directory not found.", vim.log.levels.WARN)
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
        
            -- Need this to read metadata
            local target_path = utils.figure_path(target_dir, target_file)
        
            -- Read caption from metadata
            local metadata = utils.read_svg_metadata(target_path)
            local caption = metadata.caption or target_file
        
            local figure_env, err = utils.generate_figure_environment(target_file, caption)
            if figure_env then
                utils.copy_to_register(figure_env)
                vim.notify("Code copied to register - press 'p' to paste.", vim.log.levels.INFO)
            else
                vim.notify("Code generation failed: " .. err, vim.log.levels.ERROR)
            end
        end
)
end

-- Copy LaTeX preamble to register
function M.preamble()
  local preamble_content, err = utils.get_template("preamble.tex")
  
  if not preamble_content then
    vim.notify("Error: " .. err, vim.log.levels.ERROR)
    return nil
  end
  
  utils.copy_to_register(preamble_content)
  vim.notify("Preamble copied to register - press 'p' to paste", vim.log.levels.INFO)
  
  return true
end

-- Start file watcher
function M.start_watcher(directory)
  local watcher = require('lextern.watcher')
  
  -- Auto-detect directory if not provided
  if not directory then
    directory = utils.get_figures_dir()
    if not directory then
      vim.notify("Error: Could not find figures directory", vim.log.levels.ERROR)
      return nil
    end
  end
  
  local success, err = watcher.start_watch(directory)
  
  if not success then
    vim.notify("Error: " .. err, vim.log.levels.ERROR)
    return nil
  end
  
  vim.notify(string.format("Watching: %s", directory), vim.log.levels.INFO)
  return true
end

-- Stop file watcher
function M.stop_watcher()
  local watcher = require('lextern.watcher')
  
  local success, err = watcher.stop_watch()
  
  if not success then
    vim.notify("Error: " .. err, vim.log.levels.WARN)
    return nil
  end
  
  vim.notify("Watcher stopped", vim.log.levels.INFO)
  return true
end

-- Show watcher status
function M.watcher_status()
  local watcher = require('lextern.watcher')
  local status = watcher.get_status()
  
  if not status.watching then
    vim.notify("Watcher is not running", vim.log.levels.INFO)
  else
    vim.notify(string.format(
      "Watching: %s\nExported files: %d",
      status.directory,
      status.num_exports
    ), vim.log.levels.INFO)
  end
end

return M
