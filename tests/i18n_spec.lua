package.path = "./?.lua;./?/init.lua;" .. package.path

package.preload["gettext"] = function()
    return setmetatable({ current_lang = "pt-BR" }, {
        __call = function(_, text) return text end,
    })
end

local I18n = require("lib/i18n")

local settings = { language = "auto" }
function settings:get(key)
    return self[key]
end

local i18n = I18n:new(settings)
assert(i18n:translate("Line focus") == "Foco de linha", "automatic Portuguese translation")

settings.language = "en"
assert(i18n:translate("Line focus") == "Line focus", "explicit English translation")

settings.language = "pt-BR"
assert(i18n:translate("Marker opacity") == "Opacidade do marcador", "explicit Portuguese translation")

print("i18n_spec: ok")
