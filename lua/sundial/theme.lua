local palette = require("sundial.colors")
local modules = { "editor", "syntax", "markup", "plugins" }

return function(variant, opts)
  local colors = palette(variant, opts.on_colors)
  local highlights = {}
  for _, module in ipairs(modules) do
    local groups = require("sundial.groups." .. module)(colors, opts, variant)
    for name, spec in pairs(groups) do
      highlights[name] = spec
    end
  end
  if opts.on_highlights then
    opts.on_highlights(highlights, colors)
  end

  local name = variant == "first" and "first-light" or "last-light"
  vim.g.colors_name = nil
  vim.o.background = variant == "first" and "light" or "dark"
  vim.cmd.highlight("clear")
  vim.o.termguicolors = true
  for group, spec in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, type(spec) == "string" and { link = spec } or spec)
  end
  if opts.terminal_colors then
    for i, color in ipairs(colors.terminal) do
      vim.g["terminal_color_" .. (i - 1)] = color
    end
  end
  vim.g.colors_name = name
end
