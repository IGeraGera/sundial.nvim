-- sun.lua: where the light comes from, and how long it stays.
local M = {}

local swatches = {
  day = { "#fdf6e3", "#d2cabb" },
  civil = { "#c49254", "#8b6a45" },
  nautical = { "#536170", "#293541" },
  night = { "#0d1015", "#171c23" },
}

--- Solar altitude for a latitude, declination, and local hour.
function M.altitude(lat, decl, hour)
  local hour_angle = math.rad(15 * (hour - 12))
  local sin = math.sin(lat) * math.sin(decl)
  sin = sin + math.cos(lat) * math.cos(decl) * math.cos(hour_angle)
  return math.deg(math.asin(sin))
end

local CIVIL, NAUTICAL = -6, -18

-- TODO: polar day and night break every assumption below.
function M.phase(altitude)
  if altitude > 12 then
    return "day"
  elseif altitude > CIVIL then
    return "civil"
  elseif altitude > NAUTICAL then
    return "nautical"
  end
  return "night"
end

--- Pick the swatch that belongs to the current phase.
function M.swatch(phase, alpha)
  local pair = swatches[phase] or swatches.day
  return { fg = pair[1], bg = pair[2], alpha = alpha or 1.0 }
end

return M
