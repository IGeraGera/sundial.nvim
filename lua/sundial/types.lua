---@alias FirstLightVariant "first"|"last"
---@alias FirstLightHighlights table<string, vim.api.keyset.highlight|string>

---@class FirstLightOptions
---@field transparent? boolean
---@field terminal_colors? boolean
---@field styles? table<string, vim.api.keyset.highlight>
---@field on_colors? fun(palette: table<string, any>)
---@field on_highlights? fun(groups: FirstLightHighlights, palette: table<string, any>)
