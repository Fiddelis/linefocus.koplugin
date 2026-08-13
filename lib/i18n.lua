local GetText = require("gettext")

local PORTUGUESE = {
    ["Line focus"] = "Foco de linha",
    ["Toggle line focus"] = "Ativar/desativar foco de linha",
    ["Preview and configure"] = "Visualizar e configurar",
    ["Visual pattern"] = "Padrão visual",
    ["Underline only"] = "Somente sublinhado",
    ["Dim other lines"] = "Clarear outras linhas",
    ["Spotlight focus window"] = "Janela de foco",
    ["Hatch other lines"] = "Listras nas outras linhas",
    ["Checkerboard other lines"] = "Quadriculado nas outras linhas",
    ["Focus marker"] = "Marcador de foco",
    ["Underline"] = "Sublinhado",
    ["Band"] = "Faixa",
    ["Band and underline"] = "Faixa e sublinhado",
    ["No marker"] = "Sem marcador",
    ["Line thickness"] = "Espessura da linha",
    ["Marker opacity"] = "Opacidade do marcador",
    ["Pattern opacity"] = "Opacidade do padrão",
    ["Spotlight radius"] = "Raio da janela de foco",
    ["Swipe navigation"] = "Navegação por deslize",
    ["Swipe only"] = "Somente deslize",
    ["Taps only"] = "Somente toques",
    ["Swipe and taps"] = "Deslizes e toques",
    ["Disabled"] = "Desativado",
    ["Tap navigation zones"] = "Áreas de toque",
    ["Above / below focus"] = "Acima/abaixo do foco",
    ["Top / bottom halves"] = "Metades superior/inferior",
    ["Left / right halves"] = "Metades esquerda/direita",
    ["Page edges"] = "Bordas da página",
    ["Tap anywhere to advance"] = "Toque em qualquer lugar para avançar",
    ["Notifications"] = "Notificações",
    ["Language"] = "Idioma",
    ["Automatic"] = "Automático",
    ["Português"] = "Português",
    ["English"] = "English",
    ["Automatic advance"] = "Avanço automático",
    ["Advance automatically"] = "Avançar automaticamente",
    ["Automatic advance interval"] = "Intervalo do avanço automático",
    ["About"] = "Sobre",
    ["Set"] = "Definir",
    ["Preview"] = "Pré-visualização",
    ["Pattern"] = "Padrão",
    ["Marker"] = "Marcador",
    ["Opacity"] = "Opacidade",
    ["Close"] = "Fechar",
    ["On"] = "Ativado",
    ["Off"] = "Desativado",
    ["Line focus enabled"] = "Foco de linha ativado",
    ["Line focus disabled"] = "Foco de linha desativado",
    ["Line focus: move to next line"] = "Foco de linha: avançar uma linha",
    ["Line focus: move to previous line"] = "Foco de linha: voltar uma linha",
    ["Line focus: toggle"] = "Foco de linha: ativar/desativar",
    ["enable"] = "ativar",
    ["disable"] = "desativar",
    ["Tap a line to move focus, or tap the marker again to exit."] = "Toque em uma linha para mover o foco ou toque no marcador novamente para sair.",
    ["Configurable line focus preview"] = "Pré-visualização configurável do foco de linha",
    ["Line Focus for KOReader"] = "Foco de linha para o KOReader",
    ["Configurable line focus overlay with dimming patterns and gesture navigation."] = "Sobreposição configurável de foco de linha com padrões de escurecimento e navegação por gestos.",
    ["Project:"] = "Projeto:",
    ["Settings:"] = "Configurações:",
}

local I18n = {}

function I18n:new(settings)
    local object = { settings = settings }
    setmetatable(object, self)
    self.__index = self
    return object
end

function I18n:getLanguage()
    local configured = self.settings and self.settings:get("language") or "auto"
    if configured == "pt-BR" or configured == "en" then
        return configured
    end

    local current = GetText.current_lang or ""
    return current:match("^pt") and "pt-BR" or "en"
end

function I18n:translate(text)
    if self:getLanguage() == "pt-BR" then
        return PORTUGUESE[text] or text
    end
    return GetText(text)
end

return I18n
