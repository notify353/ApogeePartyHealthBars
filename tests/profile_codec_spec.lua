ApogeePartyHealthBars_C = { PROFILE_PAYLOAD_VERSION = 2 }
Enum = {
    CompressionMethod = { Deflate = 1 },
    CompressionLevel = { OptimizeForSize = 2 },
    Base64Variant = { StandardUrlSafe = 3 },
}
local serializedValue
C_EncodingUtil = {
    SerializeCBOR = function(value) serializedValue = value; return "serialized" end,
    CompressString = function(value, method, level)
        assert(value == "serialized" and method == 1 and level == 2)
        return "compressed"
    end,
    EncodeBase64 = function(value, variant)
        assert(value == "compressed" and variant == 3); return "encoded"
    end,
    DecodeBase64 = function(value, variant)
        assert(value == "encoded" and variant == 3); return "compressed"
    end,
    DecompressString = function(value, method)
        assert(value == "compressed" and method == 1); return "serialized"
    end,
    DeserializeCBOR = function(value) assert(value == "serialized"); return serializedValue end,
}

dofile("ApogeePartyHealthBars_ProfileCodec.lua")
local codec = ApogeePartyHealthBars_ProfileCodec
local profile = {
    name = "Raid",
    classToken = "PRIEST",
    payload = { schemaVersion = 2, settings = { enabled = true }, actions = {} },
}
local text = assert(codec.Encode(profile, "0.38.0", "Healer - Realm", 12345))
assert(text == "APHB1:encoded", "share string prefix or encoding changed")
local envelope = assert(codec.Decode(text))
assert(envelope.profileName == "Raid" and envelope.classToken == "PRIEST"
    and envelope.author == "Healer - Realm" and envelope.addonVersion == "0.38.0"
    and envelope.exportedAt == 12345,
    "share metadata did not round-trip")
assert(not codec.Decode("not-a-profile"), "invalid prefix was accepted")
assert(not codec.Decode("APHB1:" .. string.rep("x", codec.MAX_ENCODED_BYTES)),
    "oversized share string was accepted")

serializedValue.profileSchemaVersion = 3
assert(not codec.Decode(text), "future payload schema was accepted")
serializedValue.profileSchemaVersion = 2
serializedValue.classToken = "PRIEST|TInterface\\Icons\\INV_Misc_QuestionMark:64|t"
assert(not codec.Decode(text), "invalid class metadata reached the import preview")
serializedValue.classToken = "PRIEST"
serializedValue.profileName = string.rep("x", 161)
assert(not codec.Decode(text), "oversized profile name reached the import preview")
serializedValue.profileName = "Raid"
serializedValue.author = "Bad\nAuthor"
assert(not codec.Decode(text), "control characters in author metadata were accepted")
serializedValue.author = "Healer - Realm"
serializedValue.payload.schemaVersion = 3
assert(not codec.Decode(text), "future internal payload schema bypassed envelope validation")
serializedValue.payload.schemaVersion = 2
C_EncodingUtil.DecodeBase64 = function() error("bad data") end
assert(not codec.Decode(text), "damaged encoded data was accepted")

print("PASS compressed versioned profile share codec")
