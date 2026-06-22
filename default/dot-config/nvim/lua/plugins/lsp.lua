return {
	{
		"neovim/nvim-lspconfig",
		config = function()
			-- global diagnostic settings
			vim.diagnostic.config({
				virtual_text = {
					prefix = "●", -- could be ">>", "■", etc.
					spacing = 2,
				},
				signs = true,
				underline = true,
				update_in_insert = false,
			})

			vim.lsp.config("clangd", {
				cmd = { "clangd", "--fallback-style=llvm" },
			})
			vim.lsp.config("gopls", {})
			-- vim.lsp.config("jedi_language_server", {})

			vim.lsp.config("lua_ls", {
				settings = {
					Lua = {
						diagnostics = {
							globals = { "vim" },
						},
						workspace = {
							library = vim.api.nvim_get_runtime_file("", true),
							checkThirdParty = false,
						},
					},
				},
			})

			vim.lsp.enable({ "clangd", "gopls", "lua_ls" })
		end,
	},

	{ "mason-org/mason.nvim" },

	{
		"mason-org/mason-lspconfig.nvim",
		opts = {
			ensure_installed = { "lua_ls", "gopls", "clangd" },
		},
		dependencies = {
			{ "mason-org/mason.nvim", opts = {} },
			"neovim/nvim-lspconfig",
		},
	},
}
