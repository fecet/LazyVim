-- From MariaSolOs/dotfiles

local function close()
  local api = require("dropbar.api")
  local menu = api.get_current_dropbar_menu()
  while menu and menu.prev_menu do
    menu = menu.prev_menu
  end
  if menu then
    menu:close()
  end
end

return {
  {
    "Bekaboo/dropbar.nvim",
    event = "BufReadPre",
    -- lazy = false,
    keys = {
      {
        "go",
        function()
          require("dropbar.api").pick()
        end,
        desc = "Winbar pick",
      },
    },
    opts = {
      general = {
        enable = function(bufnr, winnr)
          -- default enable function
          return not vim.api.nvim_win_get_config(winnr).zindex
            and vim.bo[bufnr].buftype == ""
            and vim.bo[bufnr].filetype ~= ""
            and vim.api.nvim_buf_get_name(bufnr) ~= ""
            and not vim.wo[winnr].diff
        end,
      },
      bar = {
        sources = function(buf, _)
          local sources = require("dropbar.sources")
          local utils = require("dropbar.utils")
          if vim.bo[buf].ft == "markdown" then
            return {
              sources.path,
              utils.source.fallback({
                sources.treesitter,
                sources.markdown,
                sources.lsp,
              }),
            }
          end
          return {
            sources.path,
            utils.source.fallback({
              sources.lsp,
              sources.treesitter,
            }),
          }
        end,
      },
      menu = {
        win_configs = { border = "rounded" },
        keymaps = {
          -- Navigate back to the parent menu.
          ["h"] = "<C-w>c",
          -- Expands the entry if possible.
          ["l"] = function()
            local api = require("dropbar.api")
            local menu = api.get_current_dropbar_menu()
            if not menu then
              return
            end
            local cursor = vim.api.nvim_win_get_cursor(menu.win)
            local component = menu.entries[cursor[1]]:first_clickable(cursor[2])
            if component then
              menu:click_on(component, nil, 1, "l")
            end
          end,
          -- "Jump and close".
          ["<CR>"] = function()
            local api = require("dropbar.api")
            local menu = api.get_current_dropbar_menu()
            if not menu then
              return
            end
            local cursor = vim.api.nvim_win_get_cursor(menu.win)
            local entry = menu.entries[cursor[1]]
            local component = entry:first_clickable(entry.padding.left + entry.components[1]:bytewidth())
            if component then
              menu:click_on(component, nil, 1, "l")
            end
          end,
          -- Close the dropbar entirely with <esc> and q.
          ["q"] = close,
          ["<esc>"] = close,
        },
      },
    },
  },
}
