--- nvim -V1 -es --clean +"lua require('json_to_typ').main()" +q && typst compile 1.typ
---
local M = {}

local function fromfile(fname)
  local f = io.open(fname, 'r')
  local text = ""
  if not f then
    error(('failed to write: %s'):format(f))
  else
    text = f:read("*a")
    f:close()
  end
  return text
end

local function print_node(n)
  for k, v in pairs(n) do
    if k == "text" then
      print(v)
      return
    end

    if k == "children" then
      for _, c in ipairs(v) do
        print_node(c)
      end
    end
  end
  return ''
end

function M.main()
  local json = fromfile("1.json")
  local table = vim.json.decode(json)
  print_node(table)
end

return M
