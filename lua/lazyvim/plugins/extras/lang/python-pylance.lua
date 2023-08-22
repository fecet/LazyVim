local function extract_method()
  local lsp_util = require("vim.lsp.util")
  local range_params = lsp_util.make_given_range_params(nil, nil, 0, {})
  local arguments = { vim.uri_from_bufnr(0):gsub("file://", ""), range_params.range }
  local params = {
    command = "pylance.extractMethod",
    arguments = arguments,
  }
  vim.lsp.buf.execute_command(params)
end

local function extract_variable()
  local lsp_util = require("vim.lsp.util")
  local range_params = lsp_util.make_given_range_params(nil, nil, 0, {})
  local arguments = { vim.uri_from_bufnr(0):gsub("file://", ""), range_params.range }
  local params = {
    command = "pylance.extractVarible",
    arguments = arguments,
  }
  vim.lsp.buf.execute_command(params)
end

local function organize_imports()
  local params = {
    command = "pyright.organizeimports",
    arguments = { vim.uri_from_bufnr(0) },
  }
  vim.lsp.buf.execute_command(params)
end

local function on_workspace_executecommand(err, result, ctx)
  if ctx.params.command:match("WithRename") then
    ctx.params.command = ctx.params.command:gsub("WithRename", "")
    vim.lsp.buf.execute_command(ctx.params)
  end
  if result then
    if result.label == "Extract Method" then
      local old_value = result.data.newSymbolName
      local file = vim.tbl_keys(result.edits.changes)[1]
      local range = result.edits.changes[file][1].range.start
      local params = { textDocument = { uri = file }, position = range }
      local client = vim.lsp.get_client_by_id(ctx.client_id)
      local bufnr = ctx.bufnr
      local prompt_opts = {
        prompt = "New Method Name: ",
        default = old_value,
      }
      if not old_value:find("new_var") then
        range.character = range.character + 5
      end
      vim.ui.input(prompt_opts, function(input)
        if not input or #input == 0 then
          return
        end
        params.newName = input
        local handler = client.handlers["textDocument/rename"] or vim.lsp.handlers["textDocument/rename"]
        client.request("textDocument/rename", params, handler, bufnr)
      end)
    end
  end
end
-- require("completion.providers.python")
local root_files = {
  "pyproject.toml",
  "setup.py",
  "setup.cfg",
  "requirements.txt",
  "Pipfile",
  "pyrightconfig.json",
  "environment.yml",
}

return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers.pyright = false
      local index = require("mason-registry.index")
      local sources = require("mason-registry.sources")
      index["pylance"] = "lazyvim.plugins.extras.lang.provid"
      sources.set_registries({ "lua:mason-registry.index" })
      local util = require("lspconfig.util")
      local configs = require("lspconfig.configs")
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = false
      configs["pylance"] = {
        default_config = {
          filetypes = { "python" },
          root_dir = util.root_pattern(unpack(root_files)),
          cmd = { "pylance", "--stdio" },
          single_file_support = true,
          capabilities = capabilities,
          on_init = function(client)
            if vim.env.VIRTUAL_ENV then
              local path = require("mason-core.path")
              client.config.settings.python.pythonPath = path.join(vim.env.VIRTUAL_ENV, "bin", "python")
            else
              client.config.settings.python.pythonPath = vim.fn.exepath("python3")
                or vim.fn.exepath("python")
                or "python"
            end
          end,
          before_init = function() end,
          on_new_config = function(new_config, new_root_dir)
            new_config.settings.python.pythonPath = vim.fn.exepath("python") or vim.fn.exepath("python3") or "python"
          end,
          settings = {
            editor = { formatOnType = false },
            python = {
              analysis = {
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "openFilesOnly",
                -- typeCheckingMode = "basic",
                typeCheckingMode = "basic",
                indexing = false,
                inlayHints = {
                  variableTypes = true,
                  functionReturnTypes = true,
                  callArgumentNames = true,
                  pytestParameters = true,
                },
              },
            },
          },
          handlers = {
            ["workspace/executeCommand"] = on_workspace_executecommand,
          },
        },
        commands = {
          PylanceExtractMethod = {
            extract_method,
            description = "Extract Method",
          },
          PylanceExtractVarible = {
            extract_variable,
            description = "Extract Variable",
          },
          PylanceOrganizeImports = {
            organize_imports,
            description = "Organize Imports",
          },
        },
      }
      -- opts.servers.pylance = {}
    end,
    -- setup = {
    --   pylance = {},
    -- },
  },
  {
    "wookayin/semshi",
    enabled=false,
    -- event = { "LspAttach", "BufReadPost" },
    -- cond = function()
    --   local clients = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })
    --   print(vim.inspect(clients))
    --   return not vim.tbl_contains(clients, "pylance")
    -- end,
  },
}
