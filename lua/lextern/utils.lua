local M = {}

-- Convert a figure title to a valid filename
-- Example: "My Figure Title!" -> "my-figure-title"
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
        result =  result:gsub(unicode, ascii)
    end

    --convert to lowercase
    result = result:lower()

    --replace spaces with hyphens
    result = result:gsub("%s+", "-")

    --remove special characters
    result = result:gsub("[^%w-]", "")

    --clean up multiple hyphens
    result = result:gsub("-+", "-")

    --remove leading/trailing hyphens
    result = result:gsub("^-+", "")
    result = result:gsub("-+$", "")

    if result == "" then
        return nil
    end

    return result
end

function M.get_figures_dir()

    if vim.b.vimtex and vim.b.vimtex.root then
        local vimtex_root = vim.b.vimtex.root
        local figures_path = vim.fn.fnamemodify(vimtex_root .. "/figures", ":p")
        return figures_path
   end

   local current_file = vim.fn.expand ("%:p")

   if current_file == "" then
       return nil
    end

    local current_dir = vim.fn.fnamemodify(current_file, ":h")
    local figures_path = vim.fn.fnamemodify(current_dir .. "/figures", ":p")

    return figures_path
end



-- Find the path to the template.svg file
-- Returns absolute path to template, or nil if not found
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
        return nil, "Template not found: " .. template_name
    end

  local template_file = io.open(template_path, "r")
  if not template_file then
      return nil, "Could not open template: " .. template_name
    end

    local template_content = template_file:read("*all")
    template_file:close()
  
  return template_content
end


--Copy the template file to the necessary location

function M.write_template(dest_path, template_name)
    
    local template_content, err = M.get_template(template_name)
    if not template_content then
        return nil, err
    end

    local target_file = io.open(dest_path, "w")
    if not target_file then
        return nil, "target write destination in '" .. dest_path .. "' could not be opened"
    end

    target_file:write(template_content)
    target_file:close()

    return true
end

--Check for pre-existing files
function M.figure_path(figures_dir, filename)
    local fig_path = figures_dir .. "/" .. filename .. ".svg"
    return vim.fn.fnamemodify(fig_path, ":p")
end

function M.figure_exists(target_file_path)
    return vim.fn.filereadable(target_file_path)==1
end

--Open Inkscape in background
function M.open_inkscape(target_file_path)
    local open_command = string.format('inkscape "%s" &', target_file_path)
    vim.fn.system(open_command)
end

-- Insert text at cursor position as a new line
function M.insert_at_cursor(text)
    local lines = vim.split(text, "\n", { plain = true })
    vim.api.nvim_put(lines, 'l', true, true)
end

--get list of available figures
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
    -- FILENAME appears twice (in \incfig and \label)
    local result = template_content:gsub("FILENAME", filename)
    result = result:gsub("CAPTION", caption)
    
    return result
end

function M.copy_to_register(text, register)
    register = register or '"'
    vim.fn.setreg(register, text)
end


-- Export SVG to PDF+LaTeX using Inkscape
-- Returns true on success, or nil + error message
function M.export_svg_to_pdf_latex(svg_path)
  -- Construct the export command
  local cmd = string.format('inkscape "%s" --export-filename="%s" --export-latex',
    svg_path,
    svg_path:gsub("%.svg$", ".pdf")
  )
  
  -- Execute the command
  local output = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error
  
  if exit_code ~= 0 then
    return nil, "Inkscape export failed: " .. output
  end
  
  -- Verify both output files were created
  local pdf_path = svg_path:gsub("%.svg$", ".pdf")
  local pdf_tex_path = svg_path:gsub("%.svg$", ".pdf_tex")
  
  if vim.fn.filereadable(pdf_path) == 0 then
    return nil, "PDF file not created: " .. pdf_path
  end
  
  if vim.fn.filereadable(pdf_tex_path) == 0 then
    return nil, "PDF_TEX file not created: " .. pdf_tex_path
  end
  
  return true
end

return M
