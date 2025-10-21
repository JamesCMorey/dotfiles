-- markdown_link_nav.lua
-- Minimal Markdown link navigation:
--   <Enter>     = follow link (creates file if missing)
--   <Backspace> = go back up the stack
--   ]l / [l     = move between links

local M = {}
local link_stack = {}

-- Extract first markdown link target from the current line
local function find_link_in_line()
  local line = vim.api.nvim_get_current_line()
  -- Match [text](target.md)
  local link = line:match("%[[^%]]-%]%(([^)]+)%)")
  if not link or link == "" then
    return nil
  end
  return link
end

-- Follow the markdown link on the current line
function M.follow_link()
  local link = find_link_in_line()
  if not link then
    vim.notify("No markdown link found on this line", vim.log.levels.WARN)
    return
  end

  -- Resolve relative path to absolute path
  local current_dir = vim.fn.expand("%:p:h")
  local path = vim.fn.fnamemodify(current_dir .. "/" .. link, ":p")

  -- If file doesn't exist, create it (only for .md)
  if vim.fn.filereadable(path) == 0 then
    local ext = vim.fn.fnamemodify(path, ":e")
    if ext == "md" or ext == "" then
      vim.fn.writefile({}, path)  -- create empty file
      vim.notify("Created new file: " .. path, vim.log.levels.INFO)
    else
      vim.notify("File not found and not markdown: " .. link, vim.log.levels.ERROR)
      return
    end
  end

  table.insert(link_stack, vim.api.nvim_buf_get_name(0))
  vim.cmd("edit " .. vim.fn.fnameescape(path))
end

-- Go back up the stack
function M.go_back()
  local prev = table.remove(link_stack)
  if prev and vim.fn.filereadable(prev) == 1 then
    vim.cmd("edit " .. vim.fn.fnameescape(prev))
  else
    vim.notify("No previous file in stack", vim.log.levels.WARN)
  end
end

-- Jump to next or previous markdown link in file
function M.seek_link(forward)
  local direction = forward and "/" or "?"
  vim.cmd(direction .. "\\[[^]]*\\](\\([^)]*\\))" .. "<CR>zz")
end

return M

