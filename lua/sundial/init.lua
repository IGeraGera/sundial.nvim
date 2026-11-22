local config = require("sundial.config")

return {
  setup = config.setup,
  load = function(variant)
    variant = variant or (vim.o.background == "light" and "first" or "last")
    assert(variant == "first" or variant == "last", "expected 'first' or 'last'")
    return require("sundial.theme")(variant, config.get())
  end,
}
