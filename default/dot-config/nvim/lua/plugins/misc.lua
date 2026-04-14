return {
	-- Visual
	{ "webhooked/kanso.nvim" },
	{ "nvim-tree/nvim-web-devicons", opts = {} },

	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter").setup {}

			local langs = { "c", "cpp", "lua", "python", "bash", "csv", "awk", "go", "scheme" }

			-- Block during headless so the Docker build waits for parsers to compile
			if #vim.api.nvim_list_uis() == 0 then
				require("nvim-treesitter").install(langs):wait(300000)
			else
				require("nvim-treesitter").install(langs)
			end

			vim.api.nvim_create_autocmd("FileType", {
				pattern = langs,
				callback = function()
					vim.treesitter.start()
					vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end,
			})

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

	-- Misc.
	{ 'mbbill/undotree' },
}
