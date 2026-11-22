local mix = require("sundial.util").mix

return function(c, opts, variant)
  local bg = opts.transparent and "NONE" or c.bg
  local g = {
    Normal = { fg = c.fg, bg = bg },
    NormalNC = "Normal",
    NormalFloat = { fg = c.fg, bg = c.bg_panel },
    FloatBorder = { fg = c.comment, bg = c.bg_panel },
    FloatTitle = { fg = c.slate, bold = true },
    CursorLine = { bg = c.bg_line },
    CursorColumn = "CursorLine",
    ColorColumn = "CursorLine",
    CursorLineNr = { fg = c.gold, bg = c.bg_line },
    LineNr = { fg = c.comment },
    Whitespace = { fg = variant == "last" and c.bg_selection or mix(c.bg, c.border, 0.5) },
    NonText = "Whitespace",
    SignColumn = { bg = bg },
    Folded = { bg = bg },
    FoldColumn = "LineNr",
    EndOfBuffer = { fg = c.bg },
    WinSeparator = { fg = c.bg_selection },
    StatusLine = { fg = c.fg, bg = c.bg_selection },
    StatusLineNC = { fg = c.fg_muted, bg = c.bg_panel },
    Visual = { bg = c.bg_selection },
    Search = { fg = c.fg, bg = c.bg_search },
    CurSearch = { fg = c.bg, bg = c.gold, bold = true },
    IncSearch = "CurSearch",
    Substitute = "CurSearch",
    Pmenu = "NormalFloat",
    PmenuSel = "StatusLine",
    PmenuMatch = { fg = c.completion, bold = true },
    PmenuMatchSel = "PmenuMatch",
    Directory = { fg = c.slate },
    WinBar = { fg = c.fg_muted, bg = c.bg_panel },
    WinBarNC = { fg = c.comment, bg = c.bg_panel },
    MsgArea = { fg = c.fg_muted },
    ModeMsg = { fg = c.fg, bold = true },
    MsgSeparator = "WinSeparator",
    MoreMsg = { fg = c.green, bold = true },
    Question = { fg = c.blue, bold = true },
    WarningMsg = { fg = c.gold },
    ErrorMsg = { fg = c.rose, bold = true },
    DiffText = { bg = c.bg_selection },
    diffLine = "Comment",
    diffFile = { fg = c.fg_muted },
    diffIndexLine = "diffFile",
  }
  local statuses = { Error = c.rose, Warn = c.gold, Info = c.blue, Hint = c.teal, Ok = c.green }
  for name, fg in pairs(statuses) do
    g["Diagnostic" .. name] = { fg = fg }
    g["DiagnosticUnderline" .. name] = { sp = fg, undercurl = true }
    g["DiagnosticVirtualText" .. name] = "Diagnostic" .. name
  end
  for _, change in ipairs({
    { "Add", "Added", "plus", c.green, c.diff_add },
    { "Delete", "Removed", "minus", c.rose, c.diff_delete },
    { "Change", "Changed", "delta", c.blue, c.diff_change },
  }) do
    local action, status, capture, fg, tint = unpack(change)
    g["Diff" .. action] = { bg = tint }
    g[status] = { fg = fg }
    g["diff" .. status] = { fg = status == "Changed" and c.slate or fg, bg = tint }
    g["@diff." .. capture] = "diff" .. status
  end
  return g
end
