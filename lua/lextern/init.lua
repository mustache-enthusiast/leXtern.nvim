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

    local success, err = utils.write_template(target_path, "template.svg")
    if not success then
        vim.notify("Error: " .. (err or "SVG template could not be created"), vim.log.levels.ERROR)
        return nil
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

            -- Copy figure code to register for easy pasting
            local figure_env, err = utils.generate_figure_environment(target_file, target_file)
            if figure_env then
                utils.copy_to_register(figure_env)
                vim.notify("Figure opened. Code copied to register - press 'p' to paste.", vim.log.levels.INFO)
            else
                vim.notify("Figure opened (code generation failed: " .. err .. ")", vim.log.levels.WARN)
            end
        end
    )
end


function M.add_figure()
    
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

            -- Copy figure code to register for easy pasting
            local figure_env, err = utils.generate_figure_environment(target_file, target_file)
            if figure_env then
                utils.copy_to_register(figure_env)
                vim.notify("Code copied to register - press 'p' to paste.", vim.log.levels.INFO)
            else
                vim.notify("Ccode generation failed: " .. err .. ")", vim.log.levels.WARN)
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

return M
