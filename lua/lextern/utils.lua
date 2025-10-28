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




return M
