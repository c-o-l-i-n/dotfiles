return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      -- JavaScript/TypeScript
      javascript = { "prettier" },
      javascriptreact = { "prettier" },
      typescript = { "prettier" },
      typescriptreact = { "prettier" },

      -- Web
      html = { "prettier" },
      css = { "prettier" },
      scss = { "prettier" },
      less = { "prettier" },

      -- Markup/Config
      json = { "prettier" },
      jsonc = { "prettier" },
      yaml = { "prettier" },
      markdown = { "prettier" },
      ["markdown.mdx"] = { "prettier" },

      -- GraphQL
      graphql = { "prettier" },

      -- Vue
      vue = { "prettier" },

      -- Svelte
      svelte = { "prettier" },

      -- Astro
      astro = { "prettier" },

      -- Angular
      angular = { "prettier" },

      -- Handlebars
      handlebars = { "prettier" },

      -- XML/SVG
      xml = { "prettier" },
      svg = { "prettier" },

      -- Flow
      flow = { "prettier" },

      -- TOML (with plugin)
      toml = { "prettier" },

      -- PHP (with plugin)
      php = { "prettier" },

      -- Ruby (with plugin)
      ruby = { "prettier" },

      -- Java (with plugin)
      java = { "prettier" },

      -- Shell script
      sh = { "shfmt" },
      bash = { "shfmt" },
      zsh = { "shfmt" },
    },
  },
}
