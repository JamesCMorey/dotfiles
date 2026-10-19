return {
	-- Visual
	{ "webhooked/kanso.nvim" },
	{ "nvim-tree/nvim-web-devicons", opts = {} },

	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter").setup {}

			local langs = {
				"c", "cpp", "lua", "python", "bash", "csv", "awk", "go", "scheme",
				-- TypeScript / web
				"typescript", "tsx", "javascript", "jsdoc", "json", "html", "css", "yaml",
			}

			-- Block during headless so the Docker build waits for parsers to compile
			if #vim.api.nvim_list_uis() == 0 then
				require("nvim-treesitter").install(langs):wait(300000)
			else
				require("nvim-treesitter").install(langs)
			end

			-- FileType names differ from parser names (sh -> bash,
			-- typescriptreact -> tsx), so ask nvim which filetypes each parser serves
			local filetypes = {}
			for _, lang in ipairs(langs) do
				vim.list_extend(filetypes, vim.treesitter.language.get_filetypes(lang))
			end

			vim.api.nvim_create_autocmd("FileType", {
				pattern = filetypes,
				callback = function()
					-- pcall: a parser may still be compiling on first start
					if not pcall(vim.treesitter.start) then return end
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
			require("nvim-tree").setup {
				-- show files .gitignore lists (default hides them; `I` in the tree toggles live)
				filters = { git_ignored = false },
			}
		end,
	},

	{
		'MeanderingProgrammer/render-markdown.nvim',
		dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' },
		-- latex needs a parser + a converter this config doesn't install
		opts = { latex = { enabled = false } },
	},

	-- Misc.
	{ 'mbbill/undotree' },
}
