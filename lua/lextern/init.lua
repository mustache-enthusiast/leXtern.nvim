local M = {}

local utils = require('lextern.utils')

function M.setup(opts)
  opts = opts or {}
  print("leXtern.nvim loaded!")
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

    local copy_success = utils.copy_template(target_path)
    if not copy_success then
        vim.notify("Error: SVG template could not be created", vim.log.levels.ERROR)
        return nil
    end
    
    if not utils.figure_exists(target_path) then
        vim.notify("Error: '" .. target_path .. "'  was not created.", vim.log.levels.ERROR)
        return nil
    end
    local incfig_code = string.format("\\incfig{%s}", target_filename)
    utils.insert_at_cursor(incfig_code)

    utils.open_inkscape(target_path)

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

            utils.open_inkscape(target_path)
            vim.notify("Opening " .. target_file, vim.log.levels.INFO)
        end
    )
end

return M
