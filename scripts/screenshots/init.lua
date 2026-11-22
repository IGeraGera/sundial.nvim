-- Screenshot harness for the README.
-- Loads the theme straight from the repo, so no install is needed.
local home = vim.env.HOME
local cache = vim.env.SHOT_CACHE or (home .. "/.cache/sundial-screenshots")
local repo = vim.env.SHOT_REPO or vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")

vim.opt.packpath:prepend(cache .. "/data/nvim/site")
vim.opt.runtimepath:prepend(repo)
vim.cmd("packloadall")

vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.signcolumn = "no"
vim.opt.cursorline = true
vim.opt.cursorlineopt = "line"
vim.opt.laststatus = 3
vim.opt.showtabline = 0
vim.opt.fillchars = { eob = " " }
vim.opt.scrolloff = 0
vim.opt.sidescrolloff = 0
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.undofile = false
vim.opt.shadafile = "NONE"
vim.opt.showmode = false
vim.opt.ruler = false
vim.opt.showcmd = false
vim.opt.mouse = ""
vim.opt.helpheight = 0
vim.opt.report = 9999
vim.opt.more = false
vim.opt.confirm = false
vim.opt.shortmess:append("I")
vim.opt.sessionoptions = ""

vim.g.mapleader = " "

-- No parsers are installed here; stop the runtime ftplugin from raising (and
-- blocking the UI with an error prompt).
vim.treesitter.start = function() end
vim.cmd("syntax on")

vim.cmd.colorscheme(vim.env.SHOT_SCHEME or "last-light")

require("mini.statusline").setup({
  set_vim_settings = false,
  use_icons = true,
})

require("telescope").setup({
  defaults = {
    layout_strategy = "bottom_pane",
    layout_config = {
      height = 0.3,
      prompt_position = "top",
    },
    sorting_strategy = "ascending",
    path_display = function(_, path)
      local parts = vim.split(path, "/")
      local count = #parts
      if count >= 3 then
        return parts[count - 1] .. "/" .. parts[count]
      end
      return path
    end,
  },
})

if vim.env.SHOT_MODE == "telescope" then
  vim.defer_fn(function()
    require("telescope.builtin").git_files({
      prompt_title = "open a module",
      cwd = repo,
      -- Scope the picker to the theme itself so the counter does not drift
      -- when tests, scripts, or README images are added.
      file_ignore_patterns = { "^scripts/", "^assets/", "^tests/", "^after/" },
    })
  end, 700)
end
