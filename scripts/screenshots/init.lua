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

local mode = vim.env.SHOT_MODE
if mode == "comparison" or mode == "editing" then
  vim.opt.laststatus = 0
  vim.opt.cursorline = false
  vim.opt.number = mode == "editing"
  if mode == "editing" then
    vim.opt.signcolumn = "yes:1"
    vim.api.nvim_create_autocmd("BufReadPost", {
      once = true,
      pattern = "phase.lua",
      callback = function()
        local buf = vim.api.nvim_get_current_buf()
        local ns = vim.api.nvim_create_namespace("sundial.demo")
        vim.api.nvim_buf_set_text(buf, 3, 14, 3, 15, { ">=" })
        vim.api.nvim_buf_set_text(buf, 5, 20, 5, 25, { "CIVLL" })
        vim.api.nvim_buf_set_extmark(buf, ns, 3, 14, {
          end_col = 16,
          hl_group = "DiffText",
          hl_mode = "combine",
          sign_text = "~",
          sign_hl_group = "GitSignsChange",
        })
        vim.diagnostic.set(ns, buf, {
          {
            lnum = 5,
            col = 20,
            end_col = 25,
            severity = vim.diagnostic.severity.ERROR,
            message = "Unknown name",
          },
        }, { virtual_text = { prefix = "!", spacing = 2 }, signs = false })
        vim.fn.setreg("/", '"night"')
        vim.opt.hlsearch = true
        vim.v.hlsearch = 1
      end,
    })
  end
  return
end

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
