local function harpoon_component()
    local harpoon = require("harpoon.mark")
    local total_marks = harpoon.get_length()

    if total_marks == 0 then
        return ""
    end

    local current_mark = "—"

    local mark_idx = harpoon.get_current_index()
    if mark_idx ~= nil then
        current_mark = tostring(mark_idx)
    end

    return string.format("󱡅 %s/%d", current_mark, total_marks)
end

require('lualine').setup {
    options = {
        icons_enabled = true,
        component_separators = '',
        section_separators = { left = '', right = '' }
    },
    sections = {
        lualine_a = {},
        lualine_b = { harpoon_component, 'filename' },
        lualine_c = {},
        lualine_x = {'lsp_progress'},
        lualine_y = {
            'branch',
            'diff',
            'diagnostics'
        },
        lualine_z = { 'location', 'mode' }
    }
}
