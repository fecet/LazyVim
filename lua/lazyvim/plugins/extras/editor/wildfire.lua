return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      incremental_selection = {
        enable = false,
      },
    },
    keys = {
      { "<c-space>", false },
    },
    dependencies = {
      {
        "sustech-data/wildfire.nvim",
        lazy = true,
        opts = {},
      },
    },
  },
}
