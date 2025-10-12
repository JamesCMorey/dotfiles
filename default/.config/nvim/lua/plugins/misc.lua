
return {
	-- Visual

	{ "marko-cerovac/material.nvim" },
	{ "nvim-tree/nvim-web-devicons", opts = {} },
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter.configs").setup {
				ensure_installed = { "c", "cpp", "lua" },
				highlight = { enable = true },
			}
		end,
	},
	{
		'akinsho/bufferline.nvim', version = "*",
		dependencies = 'nvim-tree/nvim-web-devicons',
		config = function()
			require("bufferline").setup({})
		end,
	},

	-- Navigation
	{
		"nvim-mini/mini.files",
		version = false,
		config = function()
			require("mini.files").setup({
				options = {use_as_default_explorer = false },
			})
		end
	},
	{
		"nvim-tree/nvim-tree.lua",
		version = "*",
		lazy = false,
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			require("nvim-tree").setup {}
		end,
	},

	{
		'MeanderingProgrammer/render-markdown.nvim',
		dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' },        -- if you use standalone mini plugins
		-- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
		---@module 'render-markdown'
		---@type render.md.UserConfig
		opts = {},
	}
}
