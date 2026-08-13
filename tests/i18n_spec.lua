package.path = "./?.lua;./?/init.lua;" .. package.path

package.preload["gettext"] = function()
    local global_translations = {
        ["Language"] = "Idioma",
        ["Notifications"] = "Notificações",
        ["About"] = "Sobre",
        ["Navigation"] = "Navegação",
        ["Gray"] = "Cinza",
        ["Interval"] = "Intervalo",
        ["Close"] = "Fechar",
        ["Portuguese"] = "Português",
        ["English"] = "Inglês",
    }
    return setmetatable({ current_lang = "pt-BR" }, {
        __call = function(_, text) return global_translations[text] or text end,
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
for _, label in ipairs({
    "Language",
    "Notifications",
    "About",
    "Navigation",
    "Gray",
    "Interval",
    "Close",
    "Portuguese",
    "English",
}) do
    assert(i18n:translate(label) == label, "explicit English must bypass global translation: " .. label)
end

settings.language = "pt-BR"
assert(i18n:translate("Marker opacity") == "Opacidade do marcador", "explicit Portuguese translation")
assert(i18n:translate("Gray focus window") == "Cinza com janela de foco", "gray treatment translation")
assert(i18n:translate("Underline opacity") == "Opacidade do sublinhado", "underline opacity translation")
assert(i18n:translate("Visual focus settings") == "Configurações visuais do foco", "visual settings translation")
assert(i18n:translate("English") == "Inglês", "English language label translation")
for _, label in ipairs({
    "Visual treatment",
    "Continuous underline",
    "Gray other lines",
    "Gray focus window",
    "Thickness",
    "Underline",
    "Underline intensity",
    "Gray",
    "Clear lines",
    "Automatic advance",
    "On",
    "Off",
    "Interval",
    "Close",
}) do
    assert(i18n:translate(label) ~= label, "preview translation: " .. label)
end

print("i18n_spec: ok")
