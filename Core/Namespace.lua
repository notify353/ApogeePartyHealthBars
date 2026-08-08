-- Root namespace and guarded module registry. WoW executes TOC files in order,
-- so registration failures should be immediate and name the missing boundary.
ApogeePartyHealthBars = ApogeePartyHealthBars or {}
local Addon = ApogeePartyHealthBars

local domains = {
    Core = {},
    Actions = {},
    Runtime = {},
    Integrations = {},
    Bootstrap = {},
}

for name, modules in pairs(domains) do
    Addon[name] = Addon[name] or modules
end

function Addon.Define(domain, name, module, legacyGlobal)
    assert(type(domain) == "string" and type(name) == "string",
        "invalid module identity")
    assert(type(module) == "table", "module must be a table: " .. domain .. "." .. name)
    local registry = assert(Addon[domain], "unknown module domain: " .. domain)
    assert(registry[name] == nil, "duplicate module: " .. domain .. "." .. name)
    registry[name] = module
    if legacyGlobal then
        assert(type(legacyGlobal) == "string", "invalid legacy module alias")
        assert(_G[legacyGlobal] == nil or _G[legacyGlobal] == module,
            "legacy module alias collision: " .. legacyGlobal)
        _G[legacyGlobal] = module
    end
    return module
end

function Addon.Require(domain, name)
    local registry = assert(Addon[domain], "unknown module domain: " .. tostring(domain))
    return assert(registry[name], "missing module: " .. domain .. "." .. tostring(name))
end

