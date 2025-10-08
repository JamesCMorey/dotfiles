-- Helper: check for project config
local function has_config(bufnr, patterns)
	return vim.fs.root(bufnr, patterns) ~= nil
end

local fmt_configs = {
	c = { ".clang-format" },
	cpp = { ".clang-format" },
	lua = { "stylua.toml", ".stylua.toml" },
	python = { "pyproject.toml", ".ruff.toml" },
}

-- Auto-format on save if project config exists
vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = { "*.c", "*.cpp", "*.h", "*.lua", "*.py" },

	callback = function(args)
		local ft = vim.bo[args.buf].filetype
		local configs = fmt_configs[ft]
		if configs and has_config(args.buf, configs) then
			vim.lsp.buf.format({ bufnr = args.buf })
		end
	end,
})

-- Close terminal without showing errorcodes
vim.api.nvim_create_autocmd("TermClose", {
	pattern = "*",
	callback = function(args)
		vim.cmd("silent! bdelete! " .. args.buf)
	end,
})
