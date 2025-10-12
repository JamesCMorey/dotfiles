-- markdown_link_nav.lua
-- Minimal Markdown link navigation (Enter = follow, Backspace = go back)
-- Follows first [text](file.md) link on the current line.

local M = {}
local link_stack = {}

-- Extract first markdown link target on the current line
local function find_link_in_line()
  local line = vim.api.nvim_get_current_line()
  -- Match markdown link syntax: [text](target)
  local link = line:match("%[[^%]]-%]%(([^)]+)%)")
  if not link or link == "" then
    return nil
  end
  return link
end

-- Follow markdown link
function M.follow_link()
  local link = find_link_in_line()
  if not link then
    vim.notify("No markdown link found on this line", vim.log.levels.WARN)
    return
  end

  -- Resolve relative path
  local current_dir = vim.fn.expand("%:p:h")
  local path = vim.fn.fnamemodify(current_dir .. "/" .. link, ":p")

  if vim.fn.filereadable(path) == 1 then
    table.insert(link_stack, vim.api.nvim_buf_get_name(0))
    vim.cmd("edit " .. vim.fn.fnameescape(path))
  else
    vim.notify("File not found: " .. link, vim.log.levels.ERROR)
  end
end

-- Go back up the link stack
function M.go_back()
  local prev = table.remove(link_stack)
  if prev and vim.fn.filereadable(prev) == 1 then
    vim.cmd("edit " .. vim.fn.fnameescape(prev))
  else
    vim.notify("No previous file in stack", vim.log.levels.WARN)
  end
end

return M

