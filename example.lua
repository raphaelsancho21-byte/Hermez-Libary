local Hermez = loadstring(game:HttpGet("URL_DA_SUA_LIB"))()

local Window = Hermez:Window({
    Title = "Hermez Hub",
    Size = UDim2.fromOffset(560, 400),
})

local MainTab = Window:Tab({ Name = "Main" })
MainTab:Section({ Name = "Geral" })

MainTab:Button({
    Name = "Executar Script",
    Callback = function()
        print("Executado!")
    end,
})

MainTab:Toggle({
    Name = "Infinite Yield",
    Default = false,
    Flag = "infYield",
    Callback = function(state)
        print("Toggle:", state)
    end,
})

MainTab:Slider({
    Name = "WalkSpeed",
    Min = 16, Max = 200, Default = 16,
    Flag = "ws",
    Callback = function(value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
    end,
})

MainTab:Input({
    Name = "Player Name",
    Placeholder = "Digite o nome...",
    Flag = "player",
    Callback = function(text, enter)
        print("Input:", text, enter)
    end,
})

MainTab:Dropdown({
    Name = "Selecionar",
    Options = {"Opção 1", "Opção 2", "Opção 3"},
    Flag = "dropdown",
    Callback = function(opt)
        print("Selecionado:", opt)
    end,
})

Hermez:Notify({
    Title = "Hermez",
    Content = "Script carregado com sucesso!",
    Duration = 4,
})
