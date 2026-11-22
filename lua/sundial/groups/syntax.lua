return function(c, opts)
  local function styled(fg, kind)
    return vim.tbl_extend("force", { fg = fg }, opts.styles[kind])
  end
  local g = {
    Comment = styled(c.comment, "comments"),
    Statement = styled(c.rose, "keywords"),
    Function = styled(c.green, "functions"),
    Identifier = styled(c.fg, "variables"),
    Delimiter = { fg = c.fg_muted },
    Operator = "Delimiter",
    PreProc = { fg = c.copper },
    String = { fg = c.amber },
    Special = { fg = c.teal },
    Number = { fg = c.lavender },
    Constant = "Number",
    Type = { fg = c.blue },
    Title = { fg = c.blue, bold = true },
    Error = { fg = c.rose },
    Todo = { fg = c.gold, bold = true },
    ["@variable"] = "Identifier",
    ["@property"] = "Identifier",
    ["@property.yaml"] = { fg = c.slate },
    ["@punctuation.bracket"] = "Delimiter",
    ["@punctuation.delimiter"] = "Delimiter",
    ["@variable.builtin.python"] = "Statement",
    ["@lsp.type.selfParameter.python"] = "Statement",
    ["@lsp.typemod.selfParameter.definition.python"] = "Statement",
    ["@lsp.mod.definition"] = {},
  }
  for _, kind in ipairs({ "function", "method" }) do
    local capture = kind == "function" and "@function.call" or "@function.method.call"
    g[capture] = "Identifier"
    g["@lsp.type." .. kind] = capture
    for _, declaration in ipairs({ "definition", "declaration" }) do
      g["@lsp.typemod." .. kind .. "." .. declaration] = "Function"
    end
  end
  return g
end
