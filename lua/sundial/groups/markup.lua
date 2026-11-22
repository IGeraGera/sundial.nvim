return function(c, opts, variant)
  local headings = { c.slate_deep, c.green, c.lavender, c.rose, c.amber, c.fg_muted }
  if variant == "first" then
    -- Small darkening so heading bands keep 4.5:1 on the panel tone.
    headings[2] = "#4E6628"
    headings[5] = "#83540F"
  end
  local g = {
    ["@markup.heading"] = "Title",
    ["@markup.heading.table.markdown"] = { fg = c.slate, bold = true },
    ["@markup.link.url"] = { fg = c.teal, underline = true },
    ["@markup.quote.markdown"] = { fg = c.fg_muted },
    ["@markup.raw"] = "String",
    ["@org.bullet.org"] = "Delimiter",
    ["@org.hyperlink.org"] = { fg = c.slate, underline = true },
    ["@org.hyperlink.desc.org"] = "@org.hyperlink.org",
    ["@org.hyperlink.url.org"] = "@org.hyperlink.org",
    ["@org.properties.org"] = "Comment",
    RenderMarkdownCode = { bg = c.bg_line },
    RenderMarkdownCodeBorder = { bg = c.bg_panel },
    RenderMarkdownCodeInline = { fg = c.amber, bg = c.bg_panel },
    RenderMarkdownQuote = { fg = c.teal },
    RenderMarkdownTableHead = { fg = c.slate },
    RenderMarkdownTableRow = { fg = c.border },
  }
  for level, fg in ipairs(headings) do
    local key = "@markup.heading." .. level .. ".markdown"
    g[key] = { fg = fg, bold = level <= 2 }
    g["RenderMarkdownH" .. level] = key
    g["RenderMarkdownH" .. level .. "Bg"] = { bg = c.bg_panel }
    if level <= 3 then
      g["@org.headline.level" .. level] = { fg = fg, bold = level <= 2 }
    end
  end
  return g
end
