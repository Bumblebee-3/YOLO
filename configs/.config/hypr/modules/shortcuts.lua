local home = os.getenv("HOME")
local keys, defaults, custom = {}, {}, {}
for line in io.lines(home .. "/.config/hypr/modules/shortcuts.tsv") do
    local id, _, key = line:match("^([^\t]+)\t([^\t]+)\t(.*)$")
    if key == "-" then key = "" end
    keys[id], defaults[id] = key, key
end

local file = io.open(home .. "/.config/yolo/keybindings.tsv")
if file then
    for line in file:lines() do
        local id, key, name, command = line:match("^([^\t]+)\t([^\t]*)\t([^\t]+)\t(.+)$")
        if id then
            table.insert(custom, {key = key, name = name, command = command})
        else
            id, key = line:match("^([^\t]+)\t([^\t]*)$")
            if id then keys[id] = key end
        end
    end
    file:close()
end

local M = {}
function M.bind(id, action, options)
    local key = keys[id]
    if key and key ~= "" then
        if options and options.ignore_mods and key ~= defaults[id] then options.ignore_mods = false end
        hl.bind(key, action, options or {})
    end
end

function M.bind_custom()
    for _, item in ipairs(custom) do
        if item.key ~= "" then
            hl.bind(item.key, hl.dsp.exec_cmd(item.command), {description = item.name})
        end
    end
end
return M
