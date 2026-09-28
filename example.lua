--[[
    ============================================
    Hermez Library - Script de Exemplo v0.2.1
    ============================================
    Demonstra:
    • Window com hotkey "H"
    • Botão flutuante em mobile
    • Notificações (Info / Success / Warning / Error)
    • Todos os componentes: Button, Toggle, Slider,
      Input, Dropdown, Keybind
    • Keybind com Enable/Disable pelo script
    • Troca de hotkey em runtime
--]]

--==============================================================
-- CARREGAR A LIBRARY
--==============================================================
local Hermez = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/raphaelsancho21-byte/Hermez-Libary/main/hermez.lua"
))()

--==============================================================
-- CRIAR A JANELA
--==============================================================
local Window = Hermez:Window({
    Title = "Hermez Hub v0.2.1",
    Size = UDim2.fromOffset(560, 420),
    MinSize = Vector2.new(350, 280),
    MaxSize = Vector2.new(1000, 700),
    Hotkey = Enum.KeyCode.H,       -- tecla para abrir/fechar
    MobileButton = true,            -- botão "☰" aparece em mobile
})

-- Notify de boas-vindas
Hermez:Success("Bem-vindo", "Hermez carregada com sucesso!", 3)

--==============================================================
-- ABA PRINCIPAL
--==============================================================
local MainTab = Window:Tab({ Name = "Main" })
MainTab:Section({ Name = "Combate" })

-- Keybind com toggle Enable/Disable
local aimKey = MainTab:Keybind({
    Name = "Aim Assist",
    Default = Enum.KeyCode.E,
    Flag = "aimKey",
    Enabled = true,
    Callback = function(key)
        Hermez:Info("Aim Assist", "Tecla " .. tostring(key.Name) .. " pressionada")
    end,
})

-- Keybind começando desativado
local flyKey = MainTab:Keybind({
    Name = "Fly",
    Default = Enum.KeyCode.F,
    Flag = "flyKey",
    Enabled = false,
    Callback = function()
        Hermez:Info("Fly", "Fly ativado!")
    end,
})

-- Toggle que liga/desliga o aimKey pelo script
MainTab:Toggle({
    Name = "Aim Assist Ativado",
    Default = true,
    Flag = "aimEnabled",
    Callback = function(state)
        aimKey:SetEnabled(state)
        if state then
            Hermez:Success("Aim Assist", "Ativado")
        else
            Hermez:Warning("Aim Assist", "Desativado")
        end
    end,
})

MainTab:Toggle({
    Name = "Fly Ativado",
    Default = false,
    Flag = "flyEnabled",
    Callback = function(state)
        flyKey:SetEnabled(state)
    end,
})

MainTab:Section({ Name = "Ações" })

MainTab:Button({
    Name = "Reset Character",
    Callback = function()
        local char = game.Players.LocalPlayer.Character
        if char then
            char:BreakJoints()
            Hermez:Success("Character", "Resetado")
        end
    end,
})

--==============================================================
-- ABA DE NOTIFICAÇÕES
--==============================================================
local NotifyTab = Window:Tab({ Name = "Notificações" })
NotifyTab:Section({ Name = "Testar Notifies" })

NotifyTab:Button({
    Name = "Notify Info",
    Callback = function()
        Hermez:Info("Info", "Mensagem informativa", 3)
    end,
})

NotifyTab:Button({
    Name = "Notify Success",
    Callback = function()
        Hermez:Success("Sucesso", "Ação concluída!", 3)
    end,
})

NotifyTab:Button({
    Name = "Notify Warning",
    Callback = function()
        Hermez:Warning("Aviso", "Cuidado com isso", 4)
    end,
})

NotifyTab:Button({
    Name = "Notify Error",
    Callback = function()
        Hermez:Error("Erro", "Algo deu errado", 5)
    end,
})

NotifyTab:Button({
    Name = "Notify Customizado (Type)",
    Callback = function()
        Hermez:Notify({
            Title = "Custom",
            Content = "Notificação via Notify unificado",
            Duration = 4,
            Type = "success",
        })
    end,
})

NotifyTab:Section({ Name = "Hotkey" })

NotifyTab:Input({
    Name = "Trocar Hotkey (K, J, M...)",
    Placeholder = "Digite UMA letra...",
    Callback = function(text)
        if #text == 1 then
            local ok, key = pcall(function() return Enum.KeyCode[text:upper()] end)
            if ok and key then
                Window:SetHotkey(key)
                Hermez:Success("Hotkey", "Nova tecla: " .. text:upper())
            else
                Hermez:Error("Hotkey", "Tecla inválida")
            end
        else
            Hermez:Warning("Hotkey", "Digite apenas UMA letra")
        end
    end,
})

--==============================================================
-- ABA DE CONFIGURAÇÕES
--==============================================================
local ConfigTab = Window:Tab({ Name = "Config" })
ConfigTab:Section({ Name = "Player" })

ConfigTab:Slider({
    Name = "WalkSpeed",
    Min = 16, Max = 200, Default = 16, Decimals = 0,
    Flag = "ws",
    Callback = function(value)
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChildOfClass("Humanoid") then
            char:FindFirstChildOfClass("Humanoid").WalkSpeed = value
        end
    end,
})

ConfigTab:Slider({
    Name = "JumpPower",
    Min = 50, Max = 300, Default = 50, Decimals = 0,
    Flag = "jp",
    Callback = function(value)
        local char = game.Players.LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.JumpPower = value end
        end
    end,
})

ConfigTab:Section({ Name = "Seleções" })

ConfigTab:Dropdown({
    Name = "Modo",
    Options = { "Normal", "Hardcore", "Speedrun" },
    Flag = "mode",
    Callback = function(opt)
        Hermez:Info("Modo", "Alterado para: " .. tostring(opt))
    end,
})

ConfigTab:Input({
    Name = "Nome do Player",
    Placeholder = "Digite um nome...",
    Flag = "player",
    Callback = function(text, enter)
        if enter and text ~= "" then
            Hermez:Success("Player", "Buscando: " .. text)
        end
    end,
})

ConfigTab:Section({ Name = "Interface" })

ConfigTab:Toggle({
    Name = "Esconder Botão Mobile",
    Default = false,
    Callback = function(state)
        Window:SetMobileButtonVisible(not state)
        if state then
            Hermez:Warning("Mobile", "Botão escondido")
        else
            Hermez:Info("Mobile", "Botão visível")
        end
    end,
})

ConfigTab:Button({
    Name = "Testar Resize (Canto Inferior Direito)",
    Callback = function()
        Hermez:Info("Dica", "Arraste o ◢ no canto pra redimensionar")
    end,
})

--==============================================================
-- FIM
--==============================================================
Hermez:Info("Pronto", "Todos os componentes carregados!", 3)
