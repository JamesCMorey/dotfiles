-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.keymap.set("i", "kj", "<Esc>")

---[[ QOL ]]---
-- Buffer & Tab management
vim.keymap.set("n", "<tab>", "<cmd>:bn<CR>")
vim.keymap.set("n", "<s-tab>", "<cmd>:bp<CR>")
vim.keymap.set("n", "<leader>x", "<cmd>:bd<CR>")

-- Window Movement
-- Function to handle context-aware window switching
local function smart_win_move(key)
	return function()
		if vim.bo.buftype == "terminal" and vim.fn.mode() == "t" then
			-- In terminal-insert mode: exit first, then move
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true), "n", true)
		end
		-- Always then do the window move
		vim.cmd("wincmd " .. key)

		if vim.bo.buftype == "terminal" then
			vim.cmd("startinsert")
		end
	end
end

vim.keymap.set({ "n", "t" }, "<leader>wh", smart_win_move("h"), { desc = "Move to left window" })
vim.keymap.set({ "n", "t" }, "<leader>wj", smart_win_move("j"), { desc = "Move to lower window" })
vim.keymap.set({ "n", "t" }, "<leader>wk", smart_win_move("k"), { desc = "Move to upper window" })
vim.keymap.set({ "n", "t" }, "<leader>wl", smart_win_move("l"), { desc = "Move to right window" })

-- Terminal
vim.keymap.set("n", "<leader>h", "<cmd>:belowright 12split | terminal<CR>a")
vim.keymap.set("n", "<leader>v", "<cmd>:belowright 55vs | terminal<CR>a")

-- File Exploration
vim.keymap.set("n", "<leader>e", "<cmd>:Explore<CR>")
vim.keymap.set("n", "<leader>f", "<cmd>:lua MiniFiles.open()<CR>")
vim.keymap.set("n", "<leader>r", "<cmd>:NvimTreeFocus<CR>")

-- Misc
vim.keymap.set("n", "<esc><esc>", "<cmd>:nohlsearch<CR>")
vim.keymap.set("i", "\\l", "λ")

---[[ CODE ]]---
-- LSP
vim.keymap.set("n", "gd", "<cmd>:lua vim.lsp.buf.definition()<CR>")
vim.keymap.set("n", "gb", "<C-t>")

-- Lint File
vim.keymap.set("n", "<leader>p", function()
	vim.lsp.buf.format()
end, { desc = "Format buffer with LSP (clangd/clang-format)" })

-- Commenting
vim.keymap.set("n", "<leader>/", "gcc", { remap = true })
vim.keymap.set("v", "<leader>/", "gc", { remap = true })

-- Markdown link following behavior
vim.keymap.set("n", "<leader>l", "/\\[[^]]*\\](\\([^)]*\\))<CR>zz<cmd>:nohlsearch<CR>", { silent = true, desc = "Next markdown link" })
vim.keymap.set("n", "<leader>h", "?\\[[^]]*\\](\\([^)]*\\))<CR>zz<cmd>:nohlsearch<CR>", { silent = true, desc = "Previous markdown link" })

-- Load the module and apply only to md files
local nav = require("jamesmorey.md-links")
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.keymap.set("n", "<CR>", nav.follow_link, { buffer = true, silent = true, desc = "Follow markdown link" })
    vim.keymap.set("n", "<BS>", nav.go_back, { buffer = true, silent = true, desc = "Go back in link stack" })
  end,
})

