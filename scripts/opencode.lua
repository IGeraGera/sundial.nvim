-- Generate the OpenCode TUI themes from the palettes.
-- Run from the repository root:
--   nvim --headless -u NONE -n -i NONE -l scripts/opencode.lua
vim.opt.runtimepath:prepend(vim.fn.getcwd())

local palette = require("sundial.colors")
local mix = require("sundial.util").mix
local out = "extras/opencode"

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

---Build a nine-step hue scale in the mode's contrast direction.
---@param c table
---@param base string
---@param variant "last"|"first"
---@return table
local function ramp(c, base, variant)
  local dark = variant == "last"
  local edge = dark and "#FFFFFF" or "#000000"
  local steps = {
    mix(base, edge, dark and 0.55 or 0.45),
    mix(base, edge, dark and 0.35 or 0.25),
    mix(base, edge, dark and 0.15 or 0.10),
    base,
    mix(base, c.bg, 0.30),
    mix(base, c.bg, 0.62),
    mix(base, c.bg, 0.80),
    mix(base, c.bg, 0.90),
    mix(base, c.bg, 0.95),
  }
  local scale = {}
  for index, value in ipairs(steps) do
    scale[tostring(index * 100)] = value
  end
  return scale
end

---@param c table
---@param variant "last"|"first"
---@return table
local function hues(c, variant)
  local neutral = {
    c.fg,
    c.fg_muted,
    c.comment,
    c.border,
    c.bg_visual,
    c.bg_selection,
    variant == "first" and c.bg_panel or c.bg_line,
    variant == "first" and c.bg_line or c.bg_panel,
    c.bg,
  }
  local gray = {}
  for index, value in ipairs(neutral) do
    gray[tostring(index * 100)] = value
  end
  return {
    gray = gray,
    red = ramp(c, c.rose, variant),
    orange = ramp(c, c.amber, variant),
    yellow = ramp(c, c.gold, variant),
    green = ramp(c, c.green, variant),
    cyan = ramp(c, c.teal, variant),
    blue = ramp(c, c.blue, variant),
    purple = ramp(c, c.lavender, variant),
    accent = "$hue.yellow",
    interactive = "$hue.blue",
    neutral = "$hue.gray",
  }
end

---@return table
local function base()
  return {
    categorical = { "accent", "purple", "green", "blue", "red" },
    text = {
      base = "$hue.neutral.100",
      muted = "$hue.neutral.200",
      faint = "$hue.neutral.300",
      action = {
        primary = {
          base = "$text.base",
          ["$disabled"] = "$text.faint",
          ["$focused"] = "$text.base",
          ["$selected"] = "$hue.interactive.200",
        },
        secondary = {
          base = "$text.muted",
          ["$hovered"] = "$text.base",
          ["$focused"] = "$hue.interactive.200",
        },
        destructive = {
          base = "$hue.neutral.900",
          ["$disabled"] = "$text.faint",
        },
      },
      formfield = {
        base = "$text.base",
        ["$hovered"] = "$hue.interactive.400",
        ["$focused"] = "$hue.interactive.400",
        ["$pressed"] = "$hue.interactive.400",
        ["$disabled"] = "$text.faint",
        ["$selected"] = "$hue.interactive.400",
      },
      feedback = {
        error = { base = "$hue.red.400" },
        warning = { base = "$hue.yellow.400" },
        success = { base = "$hue.green.400" },
        info = { base = "$hue.blue.400" },
      },
    },
    background = {
      base = "$hue.neutral.900",
      raised = {
        base = "$hue.neutral.800",
        high = "$hue.neutral.700",
        max = "$hue.neutral.600",
      },
      action = {
        primary = {
          base = "transparent",
          ["$hovered"] = "$background.raised.base",
          ["$focused"] = "$hue.interactive.600",
          ["$selected"] = "$background.raised.max",
        },
        secondary = {
          base = "transparent",
          ["$hovered"] = "$background.raised.base",
        },
        destructive = { base = "$hue.red.400" },
      },
      formfield = { base = "$background.base" },
      feedback = {
        error = { base = "$background.base" },
        warning = { base = "$background.base" },
        success = { base = "$background.base" },
        info = { base = "$background.base" },
      },
    },
    border = { base = "$hue.neutral.400" },
    scrollbar = { base = "$hue.neutral.400" },
    diff = {
      text = {
        added = "$hue.green.400",
        removed = "$hue.red.400",
        context = "$hue.neutral.200",
        hunkHeader = "$text.faint",
      },
      background = {
        added = "$hue.green.900",
        removed = "$hue.red.900",
        context = "$background.raised.base",
      },
      highlight = {
        added = "$hue.green.300",
        removed = "$hue.red.300",
      },
      lineNumber = {
        text = "$text.faint",
        background = {
          added = "$hue.green.900",
          removed = "$hue.red.900",
        },
      },
    },
    syntax = {
      comment = "$hue.neutral.300",
      keyword = "$hue.red.400",
      ["function"] = "$hue.green.400",
      variable = "$hue.neutral.100",
      string = "$hue.orange.400",
      number = "$hue.purple.400",
      type = "$hue.blue.400",
      operator = "$hue.neutral.200",
      punctuation = "$hue.neutral.200",
    },
    markdown = {
      text = "$hue.neutral.100",
      heading = "$hue.blue.400",
      link = "$hue.cyan.400",
      linkText = "$hue.cyan.400",
      code = "$hue.orange.400",
      blockQuote = "$hue.neutral.300",
      emphasis = "$hue.purple.400",
      strong = "$hue.yellow.400",
      horizontalRule = "$hue.neutral.300",
      listItem = "$hue.blue.400",
      listEnumeration = "$hue.cyan.400",
      image = "$hue.cyan.400",
      imageText = "$hue.cyan.400",
      codeBlock = "$hue.orange.400",
    },
    ["@dialog"] = {
      background = {
        base = "$background.raised.base",
        action = {
          primary = { ["$hovered"] = "$background.raised.max" },
          secondary = { ["$hovered"] = "$background.raised.max" },
        },
      },
    },
  }
end

---@param c table
---@return table
local function diff(c)
  return {
    text = {
      added = c.green,
      removed = c.rose,
      context = c.fg_muted,
      hunkHeader = c.comment,
    },
    background = {
      added = c.diff_add,
      removed = c.diff_delete,
      context = c.bg_panel,
    },
    highlight = {
      added = mix(c.green, c.fg, 0.3),
      removed = mix(c.rose, c.fg, 0.3),
    },
    lineNumber = {
      text = c.comment,
      background = {
        added = mix(c.diff_add, c.green, 0.12),
        removed = mix(c.diff_delete, c.rose, 0.12),
      },
    },
  }
end

---@param c table
---@return table
local function feedback(c)
  return {
    error = { base = mix(c.bg, c.rose, 0.16) },
    warning = { base = mix(c.bg, c.gold, 0.16) },
    success = { base = mix(c.bg, c.green, 0.16) },
    info = { base = mix(c.bg, c.blue, 0.16) },
  }
end

---@param c table
---@param variant "last"|"first"
---@return table
local function mode(c, variant)
  local result = {
    hue = hues(c, variant),
    text = { muted = variant == "last" and c.slate or c.slate_deep },
    diff = diff(c),
    scrollbar = { base = mix(c.bg, c.border, 0.45) },
    background = { feedback = feedback(c) },
  }
  if variant == "first" then
    result.background.raised = {
      base = "$hue.neutral.800",
      high = mix(c.bg_panel, c.bg_selection, 0.5),
      max = "$hue.neutral.600",
    }
    result["@dialog"] = {
      background = { base = "$hue.neutral.800" },
    }
  end
  return result
end

for _, spec in ipairs({
  { style = "last", name = "last-light", mode = "dark" },
  { style = "first", name = "first-light", mode = "light" },
}) do
  local c = palette(spec.style)
  local theme = {
    ["$schema"] = "https://opencode.ai/theme.json",
    base = base(),
  }
  theme[spec.mode] = mode(c, spec.style)
  local path = ("%s/%s.json"):format(out, spec.name)
  vim.fn.writefile(vim.split(json(theme), "\n"), path)
  print("wrote " .. path)
end
