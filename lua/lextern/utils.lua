local M = {}

-- Convert a figure title to a valid filename
-- Example: "My Figure Title!" -> "my-figure-title"
-- Returns sanitized filename or nil + error message
function M.sanitize_filename(title)
    local unicode_map = {
        ["à"] = "a", ["á"] = "a", ["â"] = "a", ["ã"] = "a", ["ä"] = "a", ["å"] = "a",
        ["è"] = "e", ["é"] = "e", ["ê"] = "e", ["ë"] = "e",
        ["ì"] = "i", ["í"] = "i", ["î"] = "i", ["ï"] = "i",
        ["ò"] = "o", ["ó"] = "o", ["ô"] = "o", ["õ"] = "o", ["ö"] = "o",
        ["ù"] = "u", ["ú"] = "u", ["û"] = "u", ["ü"] = "u",
        ["ñ"] = "n", ["ç"] = "c",
        ["À"] = "A", ["Á"] = "A", ["Â"] = "A", ["Ã"] = "A", ["Ä"] = "A", ["Å"] = "A",
        ["È"] = "E", ["É"] = "E", ["Ê"] = "E", ["Ë"] = "E",
        ["Ì"] = "I", ["Í"] = "I", ["Î"] = "I", ["Ï"] = "I",
        ["Ò"] = "O", ["Ó"] = "O", ["Ô"] = "O", ["Õ"] = "O", ["Ö"] = "O",
        ["Ù"] = "U", ["Ú"] = "U", ["Û"] = "U", ["Ü"] = "U",
        ["Ñ"] = "N", ["Ç"] = "C",
    }
    
    local result = title
    for unicode, ascii in pairs(unicode_map) do
        result = result:gsub(unicode, ascii)
    end
    
    -- Convert to lowercase
    result = result:lower()
    -- Replace spaces with hyphens
    result = result:gsub("%s+", "-")
    -- Remove special characters
    result = result:gsub("[^%w-]", "")
    -- Clean up multiple hyphens
    result = result:gsub("-+", "-")
    -- Remove leading/trailing hyphens
    result = result:gsub("^-+", "")
    result = result:gsub("-+$", "")
    
    if result == "" then
        return nil, "Invalid filename: result would be empty after sanitization"
    end
    
    return result
end

-- Get the figures directory path
-- Returns absolute path or nil + error message
function M.get_figures_dir()
    -- Try vimtex root first
    if vim.b.vimtex and vim.b.vimtex.root then
        local vimtex_root = vim.b.vimtex.root
        local figures_path = vim.fn.fnamemodify(vimtex_root .. "/figures", ":p")
        return figures_path
    end
    
    -- Fall back to current file's directory
    local current_file = vim.fn.expand("%:p")
    if current_file == "" then
        return nil, "No figures directory found: no file currently open"
    end
    
    local current_dir = vim.fn.fnamemodify(current_file, ":h")
    local figures_path = vim.fn.fnamemodify(current_dir .. "/figures", ":p")
    return figures_path
end

-- Find and read a template file from plugin runtime paths
-- Returns template content or nil + error message
function M.get_template(template_name)
    local template_path = nil
    local rtp = vim.api.nvim_list_runtime_paths()
    
    for _, path in ipairs(rtp) do
        if path:match("leXtern%.nvim") then
            local candidate_path = path .. "/templates/" .. template_name
            if vim.fn.filereadable(candidate_path) == 1 then
                template_path = candidate_path
                break
            end
        end
    end
    
    if not template_path then
        return nil, "Template not found in plugin runtime paths: " .. template_name
    end
    
    local template_file = io.open(template_path, "r")
    if not template_file then
        return nil, "Failed to read template file: " .. template_name
    end
    
    local template_content = template_file:read("*all")
    template_file:close()
    
    return template_content
end

-- Write template content to destination file
-- Returns true or nil + error message
function M.write_template(dest_path, template_name)
    local template_content, err = M.get_template(template_name)
    if not template_content then
        return nil, err
    end
    
    local target_file = io.open(dest_path, "w")
    if not target_file then
        return nil, "Failed to open file for writing: " .. dest_path
    end
    
    target_file:write(template_content)
    target_file:close()
    
    return true
end

-- Build full path to a figure file
function M.figure_path(figures_dir, filename)
    local fig_path = figures_dir .. "/" .. filename .. ".svg"
    return vim.fn.fnamemodify(fig_path, ":p")
end

-- Check if figure file exists
function M.figure_exists(target_file_path)
    return vim.fn.filereadable(target_file_path) == 1
end

-- Open Inkscape with the specified file
function M.open_inkscape(target_file_path)
    local open_command = string.format('inkscape "%s" &', target_file_path)
    vim.fn.system(open_command)
end

-- Insert text at cursor position as a new line
function M.insert_at_cursor(text)
    local lines = vim.split(text, "\n", { plain = true })
    vim.api.nvim_put(lines, 'l', true, true)
end

-- Get list of available figures in directory
function M.list_figures(figures_dir)
    local search_pattern = figures_dir .. "/*.svg"
    local svg_files_list = vim.fn.glob(search_pattern, false, true)
    local figures_list = {}
    
    for _, filepath in ipairs(svg_files_list) do
        local filename = vim.fn.fnamemodify(filepath, ":t:r")
        table.insert(figures_list, filename)
    end
    
    return figures_list
end

-- Generate figure environment from template with placeholders replaced
-- Returns generated LaTeX code or nil + error message
function M.generate_figure_environment(filename, caption)
    local template_content, err = M.get_template("figure.tex")
    if not template_content then
        return nil, err
    end
    
    -- Replace placeholders
    local result = template_content:gsub("FILENAME", filename)
    result = result:gsub("CAPTION", caption)
    
    return result
end

-- Copy text to specified register
function M.copy_to_register(text, register)
    register = register or '"'
    vim.fn.setreg(register, text)
end

-- Export SVG to PDF+LaTeX using Inkscape
-- Returns true or nil + error message
function M.export_svg_to_pdf_latex(svg_path)
    local pdf_path = svg_path:gsub("%.svg$", ".pdf")
    local cmd = string.format('inkscape "%s" --export-filename="%s" --export-latex',
        svg_path, pdf_path)
    
    local output = vim.fn.system(cmd)
    local exit_code = vim.v.shell_error
    
    if exit_code ~= 0 then
        return nil, "Inkscape export failed with code " .. exit_code .. ": " .. output
    end
    
    -- Verify both output files were created
    local pdf_tex_path = svg_path:gsub("%.svg$", ".pdf_tex")
    
    if vim.fn.filereadable(pdf_path) == 0 then
        return nil, "Export failed: PDF file not created at " .. pdf_path
    end
    
    if vim.fn.filereadable(pdf_tex_path) == 0 then
        return nil, "Export failed: PDF_TEX file not created at " .. pdf_tex_path
    end
    
    return true
end

-- Write metadata to SVG file
-- Returns true or nil + error message
function M.write_svg_metadata(svg_path, metadata)
    local file = io.open(svg_path, "r")
    if not file then
        return nil, "Failed to read SVG file: " .. svg_path
    end
    local content = file:read("*all")
    file:close()
    
    -- Build metadata XML
    local meta_attrs = {}
    for key, value in pairs(metadata) do
        -- Escape XML entities
        value = value:gsub("&", "&amp;")
        value = value:gsub('"', "&quot;")
        value = value:gsub("<", "&lt;")
        value = value:gsub(">", "&gt;")
        table.insert(meta_attrs, string.format('%s="%s"', key, value))
    end
    
    local lextern_metadata = string.format(
        '<lextern:data xmlns:lextern="https://github.com/lextern/lextern.nvim" %s />',
        table.concat(meta_attrs, " ")
    )
    
    -- Check if metadata section exists
    if content:match("<metadata") then
        -- Check if lextern metadata already exists
        if content:match("<lextern:data") then
            -- Replace existing lextern metadata
            content = content:gsub("<lextern:data.-%/>", lextern_metadata)
        else
            -- Insert into existing metadata section
            content = content:gsub("(<metadata[^>]*>)", "%1\n  " .. lextern_metadata)
        end
    else
        -- Create new metadata section after opening <svg> tag
        content = content:gsub("(<svg[^>]*>)", "%1\n<metadata>\n  " .. lextern_metadata .. "\n</metadata>")
    end
    
    -- Write back to file
    file = io.open(svg_path, "w")
    if not file then
        return nil, "Failed to write SVG file: " .. svg_path
    end
    file:write(content)
    file:close()
    
    return true
end

-- Read metadata from SVG file
-- Returns table of metadata (empty if none found), or nil + error message on file read failure
function M.read_svg_metadata(svg_path)
    local file = io.open(svg_path, "r")
    if not file then
        return nil, "Failed to read SVG file: " .. svg_path
    end
    local content = file:read("*all")
    file:close()
    
    -- Find lextern metadata
    local lextern_tag = content:match("<lextern:data[^>]*/>")
    if not lextern_tag then
        return {}  -- No metadata found, not an error
    end
    
    -- Parse attributes
    local metadata = {}
    for key, value in lextern_tag:gmatch('(%w+)="([^"]*)"') do
        if key ~= "xmlns:lextern" then
            -- Unescape XML entities
            value = value:gsub("&quot;", '"')
            value = value:gsub("&lt;", "<")
            value = value:gsub("&gt;", ">")
            value = value:gsub("&amp;", "&")
            metadata[key] = value
        end
    end
    
    return metadata
end

return M
