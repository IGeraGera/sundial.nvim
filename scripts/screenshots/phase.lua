local CIVIL = -6

local function phase(altitude)
  if altitude > 0 then
    return "day"
  elseif altitude > CIVIL then
    return "twilight"
  end
  return "night"
end

return phase
