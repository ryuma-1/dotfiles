---Shared colors referenced by several plugin specs,
---so highlights that must look alike are changed in one place.
local M = {}

---Bg of areas set apart from the code (pinned treesitter-context, folded lines).
---Slightly lifted from the black code bg so they stand out without being as loud as NormalFloat.
M.overlay_bg = '#262427'

---Bg of the code area and the panels that must blend into it.
---Defined once here so every plugin spec paints the same black.
M.code_bg = '#000000'

---Bg of the bufferline tabs other than the selected one, and of the empty area beside them.
---A fixed gray because some themes' own TabLine bg (tokyonight, iceberg) is black or nearly so.
M.tab_bg = '#1c1c1f'

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
    ['iceberg'] = true,
    ['github_dark'] = true,
    ['github_dark_default'] = true,
    ['github_dark_dimmed'] = true,
    ['github_dark_high_contrast'] = true,
    ['github_dark_colorblind'] = true,
    ['github_dark_tritanopia'] = true,
}

---Listed colorschemes that have no hook for overriding their palette, so apply_code_bg() repaints
---their highlights after loading instead. Their names are already in M.themes.
---@type table<string, boolean>
local repainted_themes = {
    ['iceberg'] = true,
    ['github_dark'] = true,
    ['github_dark_default'] = true,
    ['github_dark_dimmed'] = true,
    ['github_dark_high_contrast'] = true,
    ['github_dark_colorblind'] = true,
    ['github_dark_tritanopia'] = true,
}

---True only while a colorscheme in M.themes is loaded with a dark 'background' and the black bg is enabled.
---The black bg is a customization of the listed themes, so others must keep their own bg.
---'background' is checked because iceberg reports the same name for its light variant.
---@return boolean
function M.is_active()
    return M.enabled and M.themes[vim.g.colors_name] == true and vim.o.background == 'dark'
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

---Does for the themes in repainted_themes what monokai-pro's override and tokyonight's on_colors do:
---every group drawn on the theme's code bg, plus the floats, sidebars and gutter, is moved onto the black code bg,
---and folded lines / the pinned treesitter-context get the overlay bg.
local function repaint_theme()
    local normal_bg = vim.api.nvim_get_hl(0, { name = 'Normal', link = false }).bg
    for group, hl in pairs(vim.api.nvim_get_hl(0, {})) do
        -- Links follow their target, so only groups that define the theme's code bg themselves are changed
        if not hl.link and hl.bg ~= nil and hl.bg == normal_bg then
            set_bg_keep_fg(group)
        end
    end
    -- Floats, sidebars and the gutter use their own shade in these themes; tint.nvim already marks unfocused windows
    for _, group in ipairs({ 'NormalNC', 'NormalFloat', 'NormalSB', 'FloatBorder', 'WinBar', 'WinBarNC',
        'LineNr', 'SignColumn', 'FoldColumn' }) do
        set_bg_keep_fg(group)
    end
    for _, group in ipairs({ 'Folded', 'TreesitterContext' }) do
        local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
        hl.bg = M.overlay_bg
        vim.api.nvim_set_hl(0, group, hl)
    end
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
    if repainted_themes[vim.g.colors_name] then
        repaint_theme()
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

---Rewrites a reversed TabLineFill (iceberg) into swapped fg/bg without reverse, which looks the same.
---Nvim combines the tabline's highlight groups with TabLineFill, so the reverse leaked into every
---bufferline tab and drew its text color as the background.
local function unreverse_tabline_fill()
    local hl = vim.api.nvim_get_hl(0, { name = 'TabLineFill', link = false })
    if not hl.reverse then
        return
    end
    hl.fg, hl.bg = hl.bg, hl.fg
    hl.ctermfg, hl.ctermbg = hl.ctermbg, hl.ctermfg
    hl.reverse = nil
    if hl.cterm then
        hl.cterm.reverse = nil
    end
    vim.api.nvim_set_hl(0, 'TabLineFill', hl)
end

-- Plugin highlights are rebuilt on every colorscheme load, so the bg is reapplied each time
vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('BlackBgColorScheme', { clear = true }),
    callback = function()
        unreverse_tabline_fill()
        M.apply_code_bg()
    end,
})

---Toggles the black code bg.
---The theme hooks (monokai-pro's override_scheme, tokyonight's on_colors) are only evaluated while the
---theme loads, and the repainted themes need their original colors back when disabling,
---so a listed colorscheme is reloaded to reflect the change; other themes are left untouched.
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
