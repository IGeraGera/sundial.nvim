-- Generate the VS Code / Hermes themes from the palettes.
-- Run from the repository root:
--   nvim --headless -u NONE -n -i NONE -l scripts/vscode.lua
vim.opt.runtimepath:prepend(vim.fn.getcwd())

local palette = require("sundial.colors")
local mix = require("sundial.util").mix
local out = "extras/vscode"

vim.fn.mkdir(out, "p")

---Pretty-print a JSON-compatible Lua table.
---@param value any
---@param indent? string
---@return string
local function json(value, indent)
  indent = indent or ""
  if type(value) ~= "table" then
    return vim.json.encode(value)
  end
  local next_indent = indent .. "  "
  local parts = {}
  if #value > 0 then
    for _, item in ipairs(value) do
      parts[#parts + 1] = next_indent .. json(item, next_indent)
    end
    return "[\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "]"
  end
  local keys = vim.tbl_keys(value)
  table.sort(keys)
  for _, key in ipairs(keys) do
    parts[#parts + 1] = next_indent .. vim.json.encode(key) .. ": " .. json(value[key], next_indent)
  end
  return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}"
end

---@param c table
---@param variant "last"|"first"
---@return table
local function workbench(c, variant)
  local selection = mix(c.bg_panel, c.slate, 0.24)
  local indent = mix(c.bg, c.border, 0.35)
  local whitespace = mix(c.bg, c.border, 0.5)
  local scrollbar = mix(c.bg, c.border, 0.45)
  local error_bg = mix(c.bg, c.rose, 0.16)
  local warn_bg = mix(c.bg, c.gold, 0.16)
  local find_alt = mix(c.bg, c.gold, 0.22)
  local hover = mix(c.bg_panel, c.slate, 0.12)
  local colors = {
    foreground = c.fg,
    descriptionForeground = c.fg_muted,
    errorForeground = c.rose,
    focusBorder = c.slate,
    ["widget.border"] = c.border,
    ["widget.shadow"] = mix(c.bg, c.fg, 0.12),
    ["selection.background"] = c.bg_selection,
    ["sash.hoverBorder"] = c.slate,
    ["disabledForeground"] = c.comment,

    ["editor.background"] = c.bg,
    ["editor.foreground"] = c.fg,
    ["editorCursor.foreground"] = c.fg,
    ["editor.selectionBackground"] = c.bg_selection,
    ["editor.inactiveSelectionBackground"] = mix(c.bg, c.bg_selection, 0.6),
    ["editor.lineHighlightBackground"] = c.bg_line,
    ["editorLineNumber.foreground"] = c.comment,
    ["editorLineNumber.activeForeground"] = c.gold,
    ["editorGutter.background"] = c.bg,
    ["editorWhitespace.foreground"] = whitespace,
    ["editorIndentGuide.background1"] = indent,
    ["editorIndentGuide.activeBackground1"] = mix(c.bg, c.border, 0.65),
    ["editorRuler.foreground"] = indent,
    ["editor.findMatchBackground"] = c.bg_search,
    ["editor.findMatchHighlightBackground"] = find_alt,
    ["editor.findRangeHighlightBackground"] = mix(c.bg, c.bg_selection, 0.5),
    ["editor.wordHighlightBackground"] = mix(c.bg, c.slate, 0.14),
    ["editor.wordHighlightStrongBackground"] = mix(c.bg, c.slate, 0.22),
    ["editorLink.activeForeground"] = c.teal,
    ["editorBracketMatch.background"] = mix(c.bg, c.slate, 0.18),
    ["editorBracketMatch.border"] = c.slate,
    ["editorError.foreground"] = c.rose,
    ["editorWarning.foreground"] = c.gold,
    ["editorInfo.foreground"] = c.blue,
    ["editorHint.foreground"] = c.teal,
    ["editorOverviewRuler.border"] = c.bg_panel,
    ["editorWidget.background"] = c.bg_panel,
    ["editorWidget.border"] = c.border,
    ["editorHoverWidget.background"] = c.bg_panel,
    ["editorHoverWidget.border"] = c.border,
    ["editorSuggestWidget.background"] = c.bg_panel,
    ["editorSuggestWidget.border"] = c.border,
    ["editorSuggestWidget.selectedBackground"] = selection,

    ["sideBar.background"] = c.bg_panel,
    ["sideBar.foreground"] = c.fg_muted,
    ["sideBar.border"] = c.border,
    ["sideBarSectionHeader.background"] = c.bg_panel,
    ["sideBarSectionHeader.foreground"] = c.fg,
    ["sideBarTitle.foreground"] = c.fg,
    ["activityBar.background"] = c.bg,
    ["activityBar.foreground"] = c.fg,
    ["activityBar.inactiveForeground"] = c.comment,
    ["activityBar.border"] = c.border,
    ["activityBarBadge.background"] = c.slate,
    ["activityBarBadge.foreground"] = c.bg,

    ["statusBar.background"] = c.bg_selection,
    ["statusBar.foreground"] = c.fg,
    ["statusBar.border"] = c.border,
    ["statusBar.noFolderBackground"] = c.bg_panel,
    ["statusBarItem.hoverBackground"] = mix(c.bg_selection, c.slate, 0.2),
    ["titleBar.activeBackground"] = c.bg_panel,
    ["titleBar.activeForeground"] = c.fg,
    ["titleBar.inactiveBackground"] = c.bg_panel,
    ["titleBar.inactiveForeground"] = c.comment,
    ["titleBar.border"] = c.border,

    ["tab.activeBackground"] = c.bg,
    ["tab.activeForeground"] = c.fg,
    ["tab.inactiveBackground"] = c.bg_panel,
    ["tab.inactiveForeground"] = c.fg_muted,
    ["tab.border"] = c.bg_panel,
    ["tab.activeBorderTop"] = c.slate,
    ["tab.activeBorder"] = c.bg,
    ["editorGroupHeader.tabsBackground"] = c.bg_panel,
    ["editorGroup.border"] = c.border,

    ["panel.background"] = c.bg_panel,
    ["panel.border"] = c.border,
    ["panelTitle.activeForeground"] = c.fg,
    ["panelTitle.inactiveForeground"] = c.fg_muted,

    ["terminal.background"] = c.bg,
    ["terminal.foreground"] = c.fg,
    ["terminal.ansiBlack"] = c.terminal[1],
    ["terminal.ansiRed"] = c.terminal[2],
    ["terminal.ansiGreen"] = c.terminal[3],
    ["terminal.ansiYellow"] = c.terminal[4],
    ["terminal.ansiBlue"] = c.terminal[5],
    ["terminal.ansiMagenta"] = c.terminal[6],
    ["terminal.ansiCyan"] = c.terminal[7],
    ["terminal.ansiWhite"] = c.terminal[8],
    ["terminal.ansiBrightBlack"] = c.terminal[9],
    ["terminal.ansiBrightRed"] = c.terminal[10],
    ["terminal.ansiBrightGreen"] = c.terminal[11],
    ["terminal.ansiBrightYellow"] = c.terminal[12],
    ["terminal.ansiBrightBlue"] = c.terminal[13],
    ["terminal.ansiBrightMagenta"] = c.terminal[14],
    ["terminal.ansiBrightCyan"] = c.terminal[15],
    ["terminal.ansiBrightWhite"] = c.terminal[16],

    ["list.activeSelectionBackground"] = selection,
    ["list.activeSelectionForeground"] = c.fg,
    ["list.inactiveSelectionBackground"] = mix(c.bg_panel, c.slate, 0.14),
    ["list.hoverBackground"] = hover,
    ["list.highlightForeground"] = c.completion,
    ["list.focusOutline"] = c.slate,
    ["list.errorForeground"] = c.rose,
    ["list.warningForeground"] = c.gold,

    ["input.background"] = c.bg_line,
    ["input.foreground"] = c.fg,
    ["input.border"] = c.border,
    ["inputOption.activeBorder"] = c.slate,
    ["dropdown.background"] = c.bg_panel,
    ["dropdown.border"] = c.border,
    ["dropdown.foreground"] = c.fg,
    ["quickInput.background"] = c.bg_panel,
    ["quickInput.foreground"] = c.fg,
    ["quickInputList.focusBackground"] = selection,
    ["quickInputList.focusForeground"] = c.fg,
    ["menu.background"] = c.bg_panel,
    ["menu.foreground"] = c.fg,
    ["menu.selectionBackground"] = selection,
    ["menu.selectionForeground"] = c.fg,
    ["menu.border"] = c.border,
    ["button.background"] = c.slate,
    ["button.foreground"] = c.bg,
    ["button.hoverBackground"] = mix(c.slate, c.fg, 0.15),
    ["badge.background"] = c.slate,
    ["badge.foreground"] = c.bg,
    ["progressBar.background"] = c.slate,
    ["scrollbarSlider.background"] = scrollbar,
    ["scrollbarSlider.hoverBackground"] = mix(c.bg, c.border, 0.6),
    ["scrollbarSlider.activeBackground"] = mix(c.bg, c.border, 0.75),

    ["gitDecoration.addedResourceForeground"] = c.green,
    ["gitDecoration.modifiedResourceForeground"] = c.blue,
    ["gitDecoration.deletedResourceForeground"] = c.rose,
    ["gitDecoration.untrackedResourceForeground"] = c.teal,
    ["gitDecoration.conflictingResourceForeground"] = c.gold,
    ["gitDecoration.ignoredResourceForeground"] = c.comment,
    ["diffEditor.insertedLineBackground"] = c.diff_add,
    ["diffEditor.removedLineBackground"] = c.diff_delete,
    ["diffEditor.insertedTextBackground"] = mix(c.bg, c.green, 0.2),
    ["diffEditor.removedTextBackground"] = mix(c.bg, c.rose, 0.2),
    ["diffEditor.border"] = c.border,
    ["notifications.background"] = c.bg_panel,
    ["notifications.foreground"] = c.fg,
    ["notifications.border"] = c.border,
    ["breadcrumb.foreground"] = c.fg_muted,
    ["breadcrumb.background"] = c.bg,
    ["breadcrumb.focusForeground"] = c.fg,
    ["editorError.background"] = error_bg,
    ["editorWarning.background"] = warn_bg,
  }
  if variant == "first" then
    colors["editor.lineHighlightBackground"] = c.bg_line
  end
  return colors
end

---@param c table
---@return table
local function tokens(c)
  return {
    { scope = { "comment", "punctuation.definition.comment" }, settings = { foreground = c.comment } },
    {
      scope = { "keyword", "storage", "storage.type", "storage.modifier", "keyword.control" },
      settings = { foreground = c.rose },
    },
    {
      scope = { "string", "punctuation.definition.string", "string.quoted", "string.template" },
      settings = { foreground = c.amber },
    },
    {
      scope = { "constant.numeric", "constant.language", "constant.character", "constant.other" },
      settings = { foreground = c.lavender },
    },
    { scope = { "constant", "support.constant", "variable.language" }, settings = { foreground = c.copper } },
    {
      scope = { "variable", "variable.other", "variable.other.readwrite", "meta.object-literal.key" },
      settings = { foreground = c.fg },
    },
    { scope = { "variable.parameter" }, settings = { foreground = c.fg_muted } },
    {
      scope = { "entity.name.function", "support.function", "meta.function-call" },
      settings = { foreground = c.green },
    },
    {
      scope = {
        "entity.name.type",
        "entity.name.class",
        "support.type",
        "support.class",
        "entity.other.inherited-class",
      },
      settings = { foreground = c.blue },
    },
    { scope = { "entity.name.tag" }, settings = { foreground = c.rose } },
    { scope = { "entity.other.attribute-name" }, settings = { foreground = c.gold } },
    { scope = { "entity.name.namespace", "entity.name.module" }, settings = { foreground = c.slate } },
    {
      scope = { "punctuation", "meta.brace", "punctuation.separator", "punctuation.terminator" },
      settings = { foreground = c.fg_muted },
    },
    { scope = { "keyword.operator" }, settings = { foreground = c.fg_muted } },
    { scope = { "meta.preprocessor", "keyword.control.import" }, settings = { foreground = c.copper } },
    { scope = { "invalid", "invalid.illegal" }, settings = { foreground = c.rose } },
    { scope = { "markup.heading" }, settings = { foreground = c.blue, fontStyle = "bold" } },
    { scope = { "markup.bold" }, settings = { fontStyle = "bold" } },
    { scope = { "markup.italic" }, settings = { fontStyle = "italic" } },
    { scope = { "markup.inline.raw", "markup.fenced_code.block" }, settings = { foreground = c.amber } },
    { scope = { "markup.underline.link", "string.other.link" }, settings = { foreground = c.teal } },
    { scope = { "markup.inserted" }, settings = { foreground = c.green } },
    { scope = { "markup.deleted" }, settings = { foreground = c.rose } },
    { scope = { "markup.changed" }, settings = { foreground = c.gold } },
  }
end

---@param c table
---@return table
local function semantic(c)
  return {
    ["class"] = { foreground = c.blue },
    ["interface"] = { foreground = c.blue },
    ["enum"] = { foreground = c.blue },
    ["type"] = { foreground = c.blue },
    ["typeParameter"] = { foreground = c.lavender },
    ["namespace"] = { foreground = c.slate },
    ["function"] = { foreground = c.green },
    ["method"] = { foreground = c.green },
    ["variable"] = { foreground = c.fg },
    ["parameter"] = { foreground = c.fg_muted },
    ["property"] = { foreground = c.slate },
    ["keyword"] = { foreground = c.rose },
    ["string"] = { foreground = c.amber },
    ["number"] = { foreground = c.lavender },
    ["comment"] = { foreground = c.comment },
    ["macro"] = { foreground = c.copper },
    ["enumMember"] = { foreground = c.gold },
    ["*.deprecated"] = { fontStyle = "strikethrough" },
  }
end

for _, spec in ipairs({
  { style = "last", name = "Last Light", kind = "dark" },
  { style = "first", name = "First Light", kind = "light" },
}) do
  local c = palette(spec.style)
  local theme = {
    ["$schema"] = "vscode://schemas/color-theme",
    name = spec.name,
    type = spec.kind,
    semanticHighlighting = true,
    colors = workbench(c, spec.style),
    tokenColors = tokens(c),
    semanticTokenColors = semantic(c),
  }
  local path = ("%s/%s.json"):format(out, spec.style .. "-light")
  vim.fn.writefile(vim.split(json(theme), "\n"), path)
  print("wrote " .. path)
end
