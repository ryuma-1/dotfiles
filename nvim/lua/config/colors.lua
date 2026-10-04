---Shared colors referenced by several plugin specs,
---so highlights that must look alike are changed in one place.
local M = {}

---Default bg of areas set apart from the code (pinned treesitter-context, folded lines).
---Slightly lifted from the black code bg so they stand out without being as loud as NormalFloat.
M.overlay_bg = '#262427'

---Bg of the code area and the panels that must blend into it.
---Defined once here so every plugin spec paints the same black.
M.code_bg = '#000000'

---Whether the black code bg is wanted at all, flipped by :BlackBgToggle.
---Kept separate from the colorscheme check so the choice survives colorscheme changes.
M.enabled = true

---Colorschemes that receive the black code bg, keyed by `vim.g.colors_name`.
---Matched exactly because tokyonight reports its variant (e.g. tokyonight-night),
---which also keeps the light variant tokyonight-day out of the list.
---@type table<string, boolean>
M.themes = {
    ['monokai-pro'] = true,
    ['tokyonight-night'] = true,
    ['tokyonight-storm'] = true,
    ['tokyonight-moon'] = true,
}

---True only while a colorscheme in M.themes is loaded and the black bg is enabled.
---The black bg is a customization of the listed themes, so others must keep their own bg.
---@return boolean
function M.is_active()
    return M.enabled and M.themes[vim.g.colors_name] == true
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

---Paints the code bg and the overlay bg onto the groups that the theme's own options cannot reach.
---monokai-pro reapplies its own highlights when navic, ufo or snacks are first required, bypassing its
---`override` hook, so their configs call this again after `require`. For the other listed themes
---it fills the plugin groups (WinBar, Snacks pickers, UfoFoldedBg) that their options do not cover.
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
    -- Folded lines drawn by ufo share the Folded bg that each theme sets itself
    -- (monokai-pro in `override`, tokyonight in `on_highlights`).
    -- Reapplied on every colorscheme load because ufo's config only runs once,
    -- which used to leave the theme's black UfoFoldedBg after switching back to monokai-pro
    vim.api.nvim_set_hl(0, 'UfoFoldedBg', { bg = M.overlay_bg })
end

-- Plugin highlights are rebuilt on every colorscheme load, so the bg is reapplied each time
vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('BlackBgColorScheme', { clear = true }),
    callback = function()
        M.apply_code_bg()
    end,
})

---Toggles the black code bg.
---The theme hooks (monokai-pro's override_scheme, tokyonight's on_colors) are only evaluated while the
---theme loads, so a listed colorscheme is reloaded to reflect the change; other themes are left untouched.
vim.api.nvim_create_user_command('BlackBgToggle', function()
    M.enabled = not M.enabled
    local state = M.enabled and 'enabled' or 'disabled'
    local name = vim.g.colors_name
    if name and M.themes[name] then
        vim.cmd.colorscheme(name)
        vim.notify('Black background ' .. state)
    else
        local names = vim.tbl_keys(M.themes)
        table.sort(names)
        vim.notify('Black background ' .. state .. ' (no effect on ' .. tostring(name)
            .. ', it applies only to: ' .. table.concat(names, ', ') .. ')')
    end
end, { desc = 'Toggle the black code background (listed colorschemes only)' })

return M
