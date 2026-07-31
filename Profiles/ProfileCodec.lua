local C = ApogeePartyHealthBars_C

ApogeePartyHealthBars_ProfileCodec = {}
local Codec = ApogeePartyHealthBars_ProfileCodec

local PREFIX = "APHB1:"
local MAX_ENCODED_BYTES = 256 * 1024
local MAX_DECOMPRESSED_BYTES = 1024 * 1024

local function trim(value)
    return type(value) == "string" and value:match("^%s*(.-)%s*$") or ""
end

local function encodingApi()
    return C_EncodingUtil, Enum and Enum.CompressionMethod,
        Enum and Enum.Base64Variant, Enum and Enum.CompressionLevel
end

function Codec.Encode(profile, addonVersion, author, exportedAt)
    if type(profile) ~= "table" or type(profile.payload) ~= "table" then
        return nil, "Profile data is unavailable."
    end
    local api, compression, base64, level = encodingApi()
    if not api or not compression or not base64 then
        return nil, "This WoW client does not provide profile sharing support."
    end
    local envelope = {
        format = "ApogeePartyHealthBars",
        formatVersion = 1,
        profileSchemaVersion = C.PROFILE_PAYLOAD_VERSION,
        addonVersion = tostring(addonVersion or "unknown"),
        author = trim(author) ~= "" and trim(author) or "Unknown",
        exportedAt = tonumber(exportedAt) or 0,
        profileName = profile.name,
        classToken = profile.classToken,
        payload = profile.payload,
    }
    local ok, result = pcall(function()
        local serialized = assert(api.SerializeCBOR(envelope))
        local compressed = assert(api.CompressString(serialized, compression.Deflate,
            level and level.OptimizeForSize or nil))
        local encoded = assert(api.EncodeBase64(compressed, base64.StandardUrlSafe))
        return PREFIX .. encoded
    end)
    if not ok or type(result) ~= "string" then
        return nil, "Could not encode this profile."
    end
    if #result > MAX_ENCODED_BYTES then
        return nil, "This profile is too large to share."
    end
    return result
end

function Codec.Decode(text)
    text = trim(text)
    if #text == 0 then return nil, "Paste a profile string first." end
    if #text > MAX_ENCODED_BYTES then return nil, "The profile string is too large." end
    if text:sub(1, #PREFIX) ~= PREFIX then
        return nil, "This is not an Apogee Party Health Bars profile string."
    end
    local api, compression, base64 = encodingApi()
    if not api or not compression or not base64 then
        return nil, "This WoW client does not provide profile sharing support."
    end
    local ok, envelope = pcall(function()
        local decoded = assert(api.DecodeBase64(text:sub(#PREFIX + 1), base64.StandardUrlSafe))
        local inflated = assert(api.DecompressString(decoded, compression.Deflate))
        assert(#inflated <= MAX_DECOMPRESSED_BYTES, "decompressed profile is too large")
        return assert(api.DeserializeCBOR(inflated))
    end)
    if not ok or type(envelope) ~= "table" then
        return nil, "The profile string is damaged or incomplete."
    end
    if envelope.format ~= "ApogeePartyHealthBars" or tonumber(envelope.formatVersion) ~= 1 then
        return nil, "This profile uses an unsupported share format."
    end
    local payloadVersion = tonumber(envelope.profileSchemaVersion)
    if not payloadVersion or payloadVersion > C.PROFILE_PAYLOAD_VERSION then
        return nil, "This profile was created by a newer, incompatible addon version."
    end
    if type(envelope.profileName) ~= "string" or type(envelope.classToken) ~= "string"
        or type(envelope.payload) ~= "table" then
        return nil, "The profile string is missing required data."
    end
    if envelope.profileName:match("^%s*$") or #envelope.profileName > 160
        or envelope.profileName:find("[%c]") then
        return nil, "The profile string contains an invalid profile name."
    end
    if #envelope.classToken > 20 or not envelope.classToken:match("^[A-Z]+$") then
        return nil, "The profile string contains an invalid class."
    end
    if envelope.author ~= nil and (type(envelope.author) ~= "string"
        or #envelope.author > 320 or envelope.author:find("[%c]")) then
        return nil, "The profile string contains invalid author metadata."
    end
    if envelope.addonVersion ~= nil and (type(envelope.addonVersion) ~= "string"
        or #envelope.addonVersion > 64 or envelope.addonVersion:find("[%c]")) then
        return nil, "The profile string contains invalid version metadata."
    end
    local internalVersion = tonumber(envelope.payload.schemaVersion)
    if internalVersion and internalVersion > C.PROFILE_PAYLOAD_VERSION then
        return nil, "This profile payload was created by a newer, incompatible addon version."
    end
    return envelope
end

Codec.PREFIX = PREFIX
Codec.MAX_ENCODED_BYTES = MAX_ENCODED_BYTES
Codec.MAX_DECOMPRESSED_BYTES = MAX_DECOMPRESSED_BYTES
