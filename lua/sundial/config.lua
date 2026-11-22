local options = {}
local M = {}

---@param user? SundialOptions
function M.setup(user)
  options = vim.deepcopy(user or {})
end

function M.get()
  return vim.tbl_deep_extend("force", {
    transparent = false,
    terminal_colors = true,
    styles = { comments = {}, keywords = {}, functions = {}, variables = {} },
  }, options)
end

return M
