---Shared colors referenced by several plugin specs,
---so highlights that must look alike are changed in one place.
local M = {}

---Bg of areas set apart from the code (pinned treesitter-context, folded lines).
---Slightly lifted from the black code bg so they stand out without being as loud as NormalFloat.
M.overlay_bg = '#262427'

return M
