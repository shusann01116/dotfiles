local status, mason = pcall(require, "mason")
if (not status) then return end
local status2, lspconfig = pcall(require, "mason-lspconfig")
if (not status2) then return end

mason.setup {}
lspconfig.setup {
  ensure_installed = {
    'tailwindcss',
    'csharp-language-server',
  }
}

require 'lspconfig'.tailwindcss.setup {}
require 'lspconfig'.dagger.setup {}
require 'lspconfig'.dockerls.setup {}
require 'lspconfig'.yamlls.setup {
  settings = {
    yaml = {
      schemas = {
        ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "**/*docker-compose.yml",
        ["https://raw.githubusercontent.com/instrumenta/kubernetes-json-schema/master/v1.18.0-standalone-strict/all.json"] = "**/kube-manifests/*",
      }
    }
  }
}
