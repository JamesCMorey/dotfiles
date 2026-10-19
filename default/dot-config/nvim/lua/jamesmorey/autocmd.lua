-- Helper: check for project config
local function has_config(bufnr, patterns) return vim.fs.root(bufnr, patterns) ~= nil
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

-- ESLint fixes on save. The eslint server attaches only where the project has
-- an eslint config (nvim-lspconfig's root_dir), so this is per-project too.
local eslint_group = vim.api.nvim_create_augroup("jm_eslint_fix_on_save", { clear = true })
vim.api.nvim_create_autocmd("LspAttach", {
	group = eslint_group,
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if not client or client.name ~= "eslint" then return end
		vim.api.nvim_clear_autocmds({ group = eslint_group, buffer = args.buf })
		vim.api.nvim_create_autocmd("BufWritePre", {
			group = eslint_group,
			buffer = args.buf,
			command = "silent! LspEslintFixAll",
		})
	end,
})

-- Prevent terminal from being included in buffer list
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    vim.opt_local.buflisted = false
  end,
})

-- Close terminal without showing errorcodes
vim.api.nvim_create_autocmd("TermClose", {
	pattern = "*",
	callback = function(args)
		vim.cmd("silent! bdelete! " .. args.buf)
	end,
})

-- ======================
-- :q in the last code window also closes the file tree, terminals and other
-- aux windows, so nvim exits instead of leaving them behind.
-- (QuitPre, not WinEnter: `nvim <dir>`, :checkhealth and :help + :only must
-- not quit nvim.)
-- ======================

local function is_real_editor_buf(buf)
  -- "Real" = normal file buffer (not terminal, file tree, nofile/help/qf/etc)
  if vim.bo[buf].buftype ~= "" then return false end
  local ft = vim.bo[buf].filetype:lower()
  return ft ~= "nvimtree" and ft ~= "nerdtree"
end

vim.api.nvim_create_autocmd("QuitPre", {
  callback = function()
    local cur = vim.api.nvim_get_current_win()
    if not is_real_editor_buf(vim.api.nvim_win_get_buf(cur)) then return end

    local aux = {}
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if win ~= cur then
        if is_real_editor_buf(vim.api.nvim_win_get_buf(win)) then
          return -- another code window stays open: plain :q
        end
        table.insert(aux, win)
      end
    end

    for _, win in ipairs(aux) do
      pcall(vim.api.nvim_win_close, win, true)
    end
  end,
})
