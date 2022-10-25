local status, mason = pcall(require, "mason")
if (not status) then return end
local status2, lspconfig = pcall(require, "mason-lspconfig")
if (not status2) then return end
local status3, coq = pcall(require, "coq")
if (not status3) then return end

mason.setup {}
lspconfig.setup {
  ensure_installed = {
    'tailwindcss',
    'csharp_ls',
    'dagger',
    'dockerls',
    'yamlls',
  }
}

local ensure = coq.lsp_ensure_capabilities

require 'lspconfig'.tailwindcss.setup(ensure())
require 'lspconfig'.dagger.setup(ensure())
require 'lspconfig'.dockerls.setup(ensure())
require 'lspconfig'.yamlls.setup {
  ensure {
    settings = {
      yaml = {
        customTags = {
          "!Base64 scalar",
          "!Cidr scalar",
          "!And sequence",
          "!Equals sequence",
          "!If sequence",
          "!Not sequence",
          "!Or sequence",
          "!Condition scalar",
          "!FindInMap sequence",
          "!GetAtt scalar",
          "!GetAtt sequence",
          "!GetAZs scalar",
          "!ImportValue scalar",
          "!Join sequence",
          "!Select sequence",
          "!Split sequence",
          "!Sub scalar",
          "!Transform mapping",
          "!Ref scalar",
        },
        schemas = {
          ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "**/*docker-compose.yml",
          ["https://raw.githubusercontent.com/instrumenta/kubernetes-json-schema/master/v1.18.0-standalone-strict/all.json"] = "**/kube-manifests/*",
        }
      }
    }
  }
}
require 'lspconfig'.tsserver.setup {
  filetypes = { "typescript", "typescriptreact", "typescript.tsx" },
  cmd = { "typescript-language-server", "--stdio" }
}

require 'lspconfig'.sumneko_lua.setup {
  settings = {
    Lua = {
      diagnostics = {
        -- Get the language server to recognize the 'vim' global
        globals = { 'vim' }
      },

      workspace = {
        -- Make the server aware of Neovim runtime files
        library = vim.api.nvim_get_runtime_file("", true),
        checkThirdParty = false
      }
    }
  }
}
