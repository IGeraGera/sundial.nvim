local mix = require("sundial.util").mix

return function(variant, customize)
  local c = vim.deepcopy(require("sundial.colors." .. variant))
  if customize then
    customize(c)
  end

  local light = variant == "first"
  local black = light and c.fg or c.bg
  local white = light and c.bg or c.fg
  c.terminal = { black, c.rose, c.green, c.gold, c.blue, c.lavender, c.teal, white, c.comment }
  local target = light and black or white
  for i = 2, 7 do
    c.terminal[#c.terminal + 1] = mix(c.terminal[i], target, 0.22)
  end
  c.terminal[16] = light and "#FFFFFF" or mix(white, "#FFFFFF", 0.25)
  return c
end
