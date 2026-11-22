local M = {}

function M.mix(base, tint, strength)
  local result = {}
  for channel = 2, 6, 2 do
    local a = tonumber(base:sub(channel, channel + 1), 16)
    local b = tonumber(tint:sub(channel, channel + 1), 16)
    result[#result + 1] = ("%02x"):format(math.floor(a + (b - a) * strength + 0.5))
  end
  return "#" .. table.concat(result)
end

return M
