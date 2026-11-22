local function highlight(name)
  return vim.api.nvim_get_hl(0, { name = name, link = false })
end

local ok, err = pcall(function()
  vim.opt.runtimepath:prepend(vim.fn.getcwd())
  vim.opt.runtimepath:append(vim.fn.getcwd() .. "/after")
  local checks = {
    { "last-light", "dark", 0x0D1015, 0xD2CABB },
    { "first-light", "light", 0xF3EDD3, 0x3B3833 },
    { "last-light", "dark", 0x0D1015, 0xD2CABB },
  }
  for _, check in ipairs(checks) do
    local name, mode, bg, fg = unpack(check)
    vim.cmd.colorscheme(name)
    assert(vim.g.colors_name == name and vim.o.background == mode)
    assert(highlight("Normal").bg == bg and highlight("Normal").fg == fg)
    local visual = highlight("Visual")
    assert(visual.fg == fg and visual.bg and visual.bg ~= bg)
    assert(visual.bg ~= highlight("StatusLine").bg)
    assert(highlight("Folded").bg == bg)
    assert(highlight("Search").bg ~= highlight("CurSearch").bg)
    assert(highlight("BlinkCmpLabelMatch").bold)
    assert(highlight("@org.hyperlink.desc.org").underline)
    assert(highlight("@org.headline.level1").bold)
    assert(highlight("@property.yaml").fg ~= highlight("Normal").fg)
    assert(highlight("RenderMarkdownTableHead").fg ~= highlight("RenderMarkdownTableRow").fg)
    assert(highlight("RenderMarkdownCodeInline").fg == highlight("String").fg)
    assert(highlight("@diff.minus").bg == highlight("DiffDelete").bg)
    for i = 0, 15 do
      assert(vim.g["terminal_color_" .. i]:match("^#%x%x%x%x%x%x$"))
    end
    print("PASS: " .. name .. " (" .. mode .. ")")
  end

  require("sundial").setup({
    transparent = true,
    styles = { comments = { italic = true } },
    on_colors = function(colors)
      colors.fg = "#EEEEEE"
    end,
    on_highlights = function(groups)
      groups.OilDir = { fg = "#123456" }
    end,
  })
  vim.cmd.colorscheme("last-light")
  assert(not highlight("Normal").bg and highlight("Normal").fg == 0xEEEEEE)
  assert(highlight("Comment").italic and highlight("OilDir").fg == 0x123456)
  require("sundial").setup()
  vim.cmd.colorscheme("last-light")
  assert(highlight("Normal").fg == 0xD2CABB)
  assert(highlight("OilDir").fg == 0x819FB7)
  print("PASS: options and hooks work without mutating the default palette")
end)
if not ok then
  vim.api.nvim_err_writeln(tostring(err))
  vim.cmd.cquit()
end
vim.cmd.qa()
