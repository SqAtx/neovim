--- nvim -V1 -es --clean +"lua require('src.gen.gen_help_html').gen('./one_doc', './pdf_docs')" +q && typst compile pdf_docs/usr_01.typ
--- nvim -V1 -es --clean +"lua require('doc_to_json').main()" +q
--- nvim -V1 -es --clean +"lua require('doc_to_json').main()" +q && echo "" && jq . 1.json

local M = {}

--- Opens `fname` (or `text`, if given) in a buffer and gets a treesitter parser for the buffer contents.
---
--- @param fname string :help file to parse
--- @param text string? :help file contents
--- @return vim.treesitter.LanguageTree, integer (lang_tree, bufnr)
local function parse_buf(fname, text)
  local buf ---@type integer

  if text then
    vim.cmd('split new') -- Text contents.
    vim.api.nvim_put(vim.split(text, '\n'), '', false, false)
    vim.cmd('setfiletype help')
    buf = vim.api.nvim_get_current_buf()
  elseif type(fname) == 'string' then
    vim.cmd('split ' .. vim.fn.fnameescape(fname)) -- Filename.
    vim.cmd('setfiletype help')
    buf = vim.api.nvim_get_current_buf()
  else
    -- Left for debugging
    ---@diagnostic disable-next-line: no-unknown
    buf = fname
    vim.cmd('sbuffer ' .. tostring(fname)) -- Buffer number.
  end
  local lang_tree = assert(vim.treesitter.get_parser(buf, nil, { error = false }))
  lang_tree:parse()
  return lang_tree, buf
end

local function tofile(fname, text)
  local f = io.open(fname, 'w')
  if not f then
    error(('failed to write: %s'):format(f))
  else
    f:write(text)
    f:close()
  end
end

---@param node TSNode
---@param buf integer
---@return table
local function tsnode_to_table(node, buf)
  local t = {
    range = {node:range(false)},
    type = node:type(),
  }

  if node:child_count() > 0 then
    t.children = {}
    for child, _ in node:iter_children() do
      if child:named() then
        table.insert(t.children, tsnode_to_table(child, buf))
      end
    end
  else
    t.text = vim.treesitter.get_node_text(node, buf)
  end

  return t
end

function M.main()
  -- print('Hello, World!\n')
  local lang_tree, buf = parse_buf('usr_01.txt', nil)
  print('buf ' .. buf)

  -- TODO why can there be several trees?
  for nb, tree in ipairs(lang_tree:trees()) do
    print(nb)
    local t = tsnode_to_table(tree:root(), buf)
    tofile(nb .. '.json', vim.json.encode(t))
  end

end

return M
