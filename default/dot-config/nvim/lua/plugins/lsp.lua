return {
	{
		"neovim/nvim-lspconfig",
		dependencies = { "hrsh7th/cmp-nvim-lsp", "b0o/SchemaStore.nvim" },
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

			-- tell every server what nvim-cmp can complete (snippets, resolve, etc.)
			vim.lsp.config("*", {
				capabilities = require("cmp_nvim_lsp").default_capabilities(),
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

			-- TypeScript / JavaScript / TSX / JSX
			vim.lsp.config("vtsls", {})
			-- ESLint: attaches only where the project has an eslint config
			-- (fix on save: see jamesmorey/autocmd.lua)
			vim.lsp.config("eslint", {})
			-- JSON with schemas (package.json, tsconfig.json, ...)
			vim.lsp.config("jsonls", {
				settings = {
					json = {
						schemas = require("schemastore").json.schemas(),
						validate = { enable = true },
					},
				},
			})
			-- Tailwind's @theme/@apply/@custom-variant are not plain CSS
			vim.lsp.config("cssls", {
				settings = {
					css = { lint = { unknownAtRules = "ignore" } },
					scss = { lint = { unknownAtRules = "ignore" } },
					less = { lint = { unknownAtRules = "ignore" } },
				},
			})
			vim.lsp.config("html", {})
			vim.lsp.config("tailwindcss", {})

			vim.lsp.enable({
				"clangd", "gopls", "lua_ls",
				"vtsls", "eslint", "jsonls", "cssls", "html", "tailwindcss",
			})
		end,
	},

	{ "b0o/SchemaStore.nvim", lazy = true },

	{ "mason-org/mason.nvim" },

	{
		"mason-org/mason-lspconfig.nvim",
		opts = {
			ensure_installed = {
				"lua_ls", "gopls", "clangd",
				"vtsls", "eslint", "jsonls", "cssls", "html", "tailwindcss",
			},
		},
		dependencies = {
			{ "mason-org/mason.nvim", opts = {} },
			"neovim/nvim-lspconfig",
		},
	},
}
