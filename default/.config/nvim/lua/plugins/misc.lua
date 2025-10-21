return {
	-- Visual
	{ "marko-cerovac/material.nvim" },
	{ "nvim-tree/nvim-web-devicons", opts = {} },

	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter.configs").setup {
				ensure_installed = { "c", "cpp", "lua", "python", "bash", "csv", "awk" },
				highlight = { enable = true },
				indent = {
					enable = true,
					disable = {},  -- make sure Python is included
				},
			}

			-- Make absolutely sure the old vim indent script never loads
			vim.g.did_indent_python = 1
		end,
	},


	{
		'akinsho/bufferline.nvim',
		version = "*",
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
				options = { use_as_default_explorer = false },
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
		dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' },
		opts = {},
	},
}

