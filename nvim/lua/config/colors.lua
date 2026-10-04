---Shared colors referenced by several plugin specs,
---so highlights that must look alike are changed in one place.
local M = {}

---Bg of areas set apart from the code (pinned treesitter-context, folded lines).
---Slightly lifted from the black code bg so they stand out without being as loud as NormalFloat.
M.overlay_bg = '#262427'

---Bg of the code area and the panels that must blend into it.
---Defined once here so every plugin spec paints the same black.
M.code_bg = '#000000'

---Whether the black code bg is wanted at all, flipped by :BlackBgToggle.
---Kept separate from the colorscheme check so the choice survives colorscheme changes.
M.enabled = true

---True only while monokai-pro is the colorscheme and the black bg is enabled.
---The black bg is a monokai-pro customization, so other themes must keep their own bg.
---@return boolean
function M.is_active()
    return M.enabled and vim.g.colors_name == 'monokai-pro'
end

---Replaces only the bg of a group, keeping the fg and attributes the theme gave it.
---@param group string
local function set_bg_keep_fg(group)
    local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
    -- An undefined group is skipped, otherwise a bg-only definition would hide the plugin's default links
    if next(hl) == nil then
        return
    end
    hl.bg = M.code_bg
    vim.api.nvim_set_hl(0, group, hl)
end

---Paints the code bg onto the groups that monokai-pro's `override` cannot reach.
---Plugins such as navic and snacks make monokai-pro apply its own highlights when they are first
---required, bypassing `override`, so their configs call this again after `require`.
---Does nothing unless is_active() holds.
function M.apply_code_bg()
    if not M.is_active() then
        return
    end
    -- navic icons define only fg and inherit WinBar's bg, so keep it equal to Normal
    for _, group in ipairs({ 'WinBar', 'WinBarNC' }) do
        set_bg_keep_fg(group)
    end
    -- The body has no theme color and would otherwise link to the gray NormalFloat
    vim.api.nvim_set_hl(0, 'SnacksPicker', { bg = M.code_bg })
    for _, group in ipairs({ 'SnacksPickerBorder', 'SnacksPickerTitle', 'SnacksPickerPrompt', 'SnacksPickerInputBorder' }) do
        set_bg_keep_fg(group)
    end
end

-- Plugin highlights are rebuilt on every colorscheme load, so the bg is reapplied each time
vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('BlackBgColorScheme', { clear = true }),
    callback = function()
        M.apply_code_bg()
    end,
})

---Toggles the black code bg.
---override_scheme (editor / tab background) is only evaluated while monokai-pro loads,
---so monokai-pro is reloaded to reflect the change; other themes are left untouched.
vim.api.nvim_create_user_command('BlackBgToggle', function()
    M.enabled = not M.enabled
    local state = M.enabled and 'enabled' or 'disabled'
    if vim.g.colors_name == 'monokai-pro' then
        vim.cmd('colorscheme monokai-pro')
        vim.notify('Black background ' .. state)
    else
        vim.notify('Black background ' .. state .. ' (applies only with monokai-pro)')
    end
end, { desc = 'Toggle the black code background (monokai-pro only)' })

return M
