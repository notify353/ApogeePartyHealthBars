-- The generated Stats source body remains inert whether admitted or denied.
local path, name = arg[1], arg[2]
for _, admitted in ipairs({false, true}) do
    local calls = 0
    local ns = {__ApogeeFamilyAdmission=function(caller)
        assert(caller == name); calls = calls + 1; return admitted
    end}
    local env = {type=type}
    setmetatable(env, {__index=function(_, key) error("Unexpected API read: "..key) end,
        __newindex=function(_, key) error("Unexpected global write: "..key) end})
    local chunk=assert(loadfile(path)); setfenv(chunk, env); chunk(name, ns)
    assert(calls == 1)
    for key in pairs(ns) do assert(key == "__ApogeeFamilyAdmission") end
    chunk("WrongName", ns)
    assert(calls == 1, "Wrong identity reached admission")
end
print("PASS generated Stats baseline: guarded, no APIs, globals or namespace effects")
