---@alias SundialVariant "first"|"last"
---@alias SundialHighlights table<string, vim.api.keyset.highlight|string>

---@class SundialOptions
---@field transparent? boolean
---@field terminal_colors? boolean
---@field styles? table<string, vim.api.keyset.highlight>
---@field on_colors? fun(palette: table<string, any>)
---@field on_highlights? fun(groups: SundialHighlights, palette: table<string, any>)
