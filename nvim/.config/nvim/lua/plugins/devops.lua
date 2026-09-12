return {
  -- Helm Chart support
  {
    "towolf/vim-helm",
    ft = "helm",
  },

  -- TreeSitter parsers for IaC, Containers and Cloud
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, {
          "terraform",
          "hcl",
          "yaml",
          "json",
          "dockerfile",
          "bash",
          "python",
          "go",
          "gomod",
          "make",
          "markdown",
          "markdown_inline",
          "lua",
        })
      end
    end,
  },

  -- Mason: Automated installer for LSPs, formatters & linters
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "terraform-ls",
        "tflint",
        "ansible-language-server",
        "ansible-lint",
        "yaml-language-server",
        "dockerfile-language-server",
        "docker-compose-language-service",
        "bash-language-server",
        "shellcheck",
        "shfmt",
        "pyright",
        "gopls",
      })
    end,
  },
}
