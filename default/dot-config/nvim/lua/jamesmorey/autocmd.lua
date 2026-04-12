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
-- quit NERDTree and terminal in event code window is closed
-- ======================

local function is_nerdtree_buf(buf)
  local ft = vim.bo[buf].filetype
  local name = vim.api.nvim_buf_get_name(buf)
  return ft:lower() == "nerdtree" or name:match("NERD_tree_")
end

local function is_real_editor_buf(buf)
  -- "Real" = normal file buffer (not terminal, not nerdtree, not nofile/help/qf/etc)
  if vim.bo[buf].buftype ~= "" then return false end
  if is_nerdtree_buf(buf) then return false end
  local name = vim.api.nvim_buf_get_name(buf)
  return true
end

local function quit_if_only_aux_left()
  local wins = vim.api.nvim_list_wins()

  -- If any real editor window exists, do nothing
  for _, win in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(win)
    if is_real_editor_buf(buf) then
      return
    end
  end

  -- No real windows left: if what remains is only nerdtree/terminal/etc, quit
  vim.cmd("qa")
end

-- Trigger on window changes (this is the key vs BufEnter)
vim.api.nvim_create_autocmd({ "WinEnter", "WinClosed", "BufWinEnter" }, {
  callback = function()
    -- Defer slightly so window list reflects the post-close state
    vim.schedule(quit_if_only_aux_left)
  end,
})
