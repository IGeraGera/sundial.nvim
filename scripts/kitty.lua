-- Generate the Kitty themes from the palettes so they cannot drift.
-- Run from the repository root:
--   nvim --headless -u NONE -n -i NONE -l scripts/kitty.lua
vim.opt.runtimepath:prepend(vim.fn.getcwd())

local palette = require("sundial.colors")
local out = "extras/kitty"

vim.fn.mkdir(out, "p")

for _, spec in ipairs({
  { style = "last", name = "last-light" },
  { style = "first", name = "first-light" },
}) do
  local c = palette(spec.style)
  local lines = {
    ("# Sundial: %s"):format(spec.name),
    ("background %s"):format(c.bg),
    ("foreground %s"):format(c.fg),
    ("cursor %s"):format(c.fg),
    ("cursor_text_color %s"):format(c.bg),
    ("selection_background %s"):format(c.bg_selection),
    ("selection_foreground %s"):format(c.fg),
    ("url_color %s"):format(c.teal),
    ("active_border_color %s"):format(c.border),
    ("inactive_border_color %s"):format(c.bg_selection),
    ("bell_border_color %s"):format(c.gold),
    ("tab_bar_background %s"):format(c.bg_panel),
    ("active_tab_background %s"):format(c.bg),
    ("active_tab_foreground %s"):format(c.slate),
    ("inactive_tab_background %s"):format(c.bg_panel),
    ("inactive_tab_foreground %s"):format(c.fg_muted),
    "",
  }
  for index = 0, 15 do
    lines[#lines + 1] = ("color%d %s"):format(index, c.terminal[index + 1])
  end
  local path = ("%s/%s.conf"):format(out, spec.name)
  vim.fn.writefile(lines, path)
  print("wrote " .. path)
end
