local minimum = 4.5

local function luminance(rgb)
  local function linear(shift)
    local channel = bit.band(bit.rshift(rgb, shift), 0xff) / 255
    return channel <= 0.04045 and channel / 12.92 or ((channel + 0.055) / 1.055) ^ 2.4
  end
  return 0.2126 * linear(16) + 0.7152 * linear(8) + 0.0722 * linear(0)
end

local function highlight(name)
  return vim.api.nvim_get_hl(0, { name = name, link = false, create = false })
end

-- Name the group that supplies each channel, including when the foreground
-- group (e.g. Comment) leaves the background to the surrounding editor state.
local pairs_to_check = {
  { "Normal", "Normal" },
  { "Comment", "Normal" },
  { "Comment", "CursorLine" },
  { "Visual", "Visual" },
  { "Search", "Search" },
  { "CurSearch", "CurSearch" },
  { "PmenuSel", "PmenuSel" },
  { "PmenuMatchSel", "PmenuSel" },
}

for _, severity in ipairs({ "Error", "Warn", "Info", "Hint", "Ok" }) do
  for _, fill in ipairs({ "DiffAdd", "DiffChange", "DiffDelete", "DiffText" }) do
    local diagnostic = "DiagnosticVirtualText" .. severity
    pairs_to_check[#pairs_to_check + 1] = { diagnostic, fill }
  end
end

local function hex(value)
  return value and ("#%06X"):format(value) or "unset"
end

vim.opt.runtimepath:prepend(vim.fn.getcwd())
local failures = {}
for _, scheme in ipairs({ "last-light", "first-light" }) do
  vim.cmd.colorscheme(scheme)
  local count_before = #failures
  for _, pair in ipairs(pairs_to_check) do
    local fg_group, bg_group = unpack(pair)
    local fg, bg = highlight(fg_group).fg, highlight(bg_group).bg
    local ratio
    if fg and bg then
      local a, b = luminance(fg), luminance(bg)
      ratio = (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05)
    end
    if not ratio or ratio < minimum then
      failures[#failures + 1] = ("%s: %s fg %s on %s bg %s: %s (need %.1f:1)"):format(
        scheme,
        fg_group,
        hex(fg),
        bg_group,
        hex(bg),
        ratio and ("%.4f:1"):format(ratio) or "unavailable",
        minimum
      )
    end
  end
  if #failures == count_before then
    print(("PASS: %s (%d text pairs at %.1f:1 or better)"):format(scheme, #pairs_to_check, minimum))
  end
end

if #failures > 0 then
  vim.api.nvim_err_writeln(table.concat(failures, "\n"))
  vim.cmd.cquit()
end
vim.cmd.qa()
