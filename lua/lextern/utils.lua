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
function M.get_template_path()
  -- Get the plugin's installation directory from Neovim's runtimepath
  local rtp = vim.api.nvim_list_runtime_paths()
  
  for _, path in ipairs(rtp) do
    if path:match("leXtern%.nvim") then
      local template_path = path .. "/templates/template.svg"
      
      -- Check if the template actually exists
      if vim.fn.filereadable(template_path) == 1 then
        return template_path
      end
    end
  end
  
  -- Template not found
  return nil
end


--Copy the .svg file to the necessary location

function M.copy_template(dest_path)
    
    local template_path = M.get_template_path()
    if not template_path then
        return nil
    end

    local template_file = io.open(template_path, "r")
    if not template_file then
        return nil
    end
    local template_content = template_file:read("*all")
    template_file:close()

    local target_file = io.open(dest_path, "w")
    if not target_file then
        return nil
    end
    target_file:write(template_content)
    target_file:close()

    return true
end

--Check for pre-existing files
function M.figure_path(figures_dir, filename)
    local fig_path = figures_dir .. "/" .. filename .. ".svg"
    if vim.fn.filereadable(fig_path) == 0 then
        return nil
    end
    return vim.fn.fnamemodify(fig_path, ":p")
end

return M
