-- ==============================================================================
-- Omakase Theme Integration for LazyVim
-- Synchronizes colorscheme with ~/.config/omakase_theme
-- ==============================================================================

local theme_file = vim.fn.expand("~/.config/omakase_theme")
local active_theme = "tokyonight"

if vim.fn.filereadable(theme_file) == 1 then
  local lines = vim.fn.readfile(theme_file)
  if #lines > 0 and lines[1] ~= "" then
    active_theme = vim.trim(lines[1])
  end
end

local theme_map = {
  tokyonight = "tokyonight-night",
  catppuccin = "catppuccin-mocha",
  gruvbox = "gruvbox",
  kanagawa = "kanagawa-wave",
}

local colorscheme = theme_map[active_theme] or "tokyonight-night"

return {
  -- Theme plugins
  { "folke/tokyonight.nvim", lazy = false, priority = 1000 },
  { "catppuccin/nvim", name = "catppuccin", lazy = false, priority = 1000 },
  { "ellisonleao/gruvbox.nvim", lazy = false, priority = 1000 },
  { "rebelot/kanagawa.nvim", lazy = false, priority = 1000 },

  -- Configure LazyVim to load active colorscheme
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = colorscheme,
    },
  },
}
