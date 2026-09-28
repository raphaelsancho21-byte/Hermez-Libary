--[[
    Hermez Library v1.1
    Minimalist Black Theme UI Library for Roblox
    + Animações + Mobile + Resize responsivo
--]]

local Hermez = {}
Hermez.__index = Hermez

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

--==============================================================
-- TEMA
--==============================================================
local Theme = {
    Background = Color3.fromRGB(15, 15, 15),
    BackgroundSecondary = Color3.fromRGB(22, 22, 22),
    BackgroundTertiary = Color3.fromRGB(30, 30, 30),
    Border = Color3.fromRGB(40, 40, 40),
    Text = Color3.fromRGB(240, 240, 240),
    TextDimmed = Color3.fromRGB(140, 140, 140),
    Accent = Color3.fromRGB(255, 255, 255),
    AccentDark = Color3.fromRGB(200, 200, 200),
    Success = Color3.fromRGB(80, 200, 120),
    Danger = Color3.fromRGB(220, 80, 80),
    Font = Enum.Font.Gotham,
    FontBold = Enum.Font.GothamBold,
    CornerRadius = UDim.new(0, 6),
}

--==============================================================
-- UTILITÁRIOS
--==============================================================
local function create(className, properties)
    local instance = Instance.new(className)
    for k, v in pairs(properties or {}) do
        instance[k] = v
    end
    return instance
end

local function tween(instance, time, properties, style, direction)
    local t = TweenService:Create(
        instance,
        TweenInfo.new(
            time,
            style or Enum.EasingStyle.Quad,
            direction or Enum.EasingDirection.Out
        ),
        properties
    )
    t:Play()
    return t
end

local function getParent()
    if RunService:IsStudio() then
        return LocalPlayer:WaitForChild("PlayerGui")
    end
    local parent = CoreGui
    if gethui then
        local ok, result = pcall(gethui)
        if ok and result then parent = result end
    end
    return parent
end

--==============================================================
-- DRAGGABLE (mouse + touch)
--==============================================================
local function makeDraggable(frame, dragTarget)
    dragTarget = dragTarget or frame
    local dragging, dragInput, dragStart, startPos

    dragTarget.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragTarget.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

--==============================================================
-- RESIZE HANDLE (como o Rayfield)
--==============================================================
local function makeResizable(main, minSize, maxSize, onResize)
    -- Área de detecção no canto inferior direito
    local handle = create("TextButton", {
        Name = "ResizeHandle",
        Size = UDim2.fromOffset(22, 22),
        Position = UDim2.new(1, -22, 1, -22),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 5,
        Parent = main,
    })
    -- Símbolo "◢" indicando resize
    local grip = create("TextLabel", {
        Size = UDim2.fromOffset(22, 22),
        BackgroundTransparency = 1,
        Text = "◢",
        TextColor3 = Theme.TextDimmed,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        ZIndex = 6,
        Parent = handle,
    })

    local resizing = false
    local startSize, startInputPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            startSize = main.AbsoluteSize
            startInputPos = input.Position
            tween(grip, 0.15, { TextColor3 = Theme.Accent })
        end
    end)

    handle.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - startInputPos
            local newX = math.clamp(startSize.X + delta.X, minSize.X, maxSize.X)
            local newY = math.clamp(startSize.Y + delta.Y, minSize.Y, maxSize.Y)
            main.Size = UDim2.fromOffset(newX, newY)
            if onResize then onResize(newX, newY) end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            if resizing then
                resizing = false
                tween(grip, 0.15, { TextColor3 = Theme.TextDimmed })
            end
        end
    end)

    handle.MouseEnter:Connect(function()
        tween(grip, 0.15, { TextColor3 = Theme.Text })
    end)
    handle.MouseLeave:Connect(function()
        tween(grip, 0.15, { TextColor3 = Theme.TextDimmed })
    end)
end

--==============================================================
-- WINDOW
--==============================================================
function Hermez:Window(config)
    config = config or {}
    local title = config.Title or "Hermez"
    local size = config.Size or (IsMobile and UDim2.fromOffset(340, 300) or UDim2.fromOffset(520, 380))
    local minSize = config.MinSize or Vector2.new(300, 250)
    local maxSize = config.MaxSize or Vector2.new(1200, 800)

    local gui = create("ScreenGui", {
        Name = "Hermez_" .. HttpService:GenerateGUID(false),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = getParent(),
    })

    -- Botão flutuante (abrir/fechar)
    local toggleBtn = create("TextButton", {
        Name = "Toggle",
        Size = UDim2.fromOffset(IsMobile and 55 or 45, IsMobile and 55 or 45),
        Position = UDim2.new(0, 20, 0.5, IsMobile and -27 or -22),
        BackgroundColor3 = Theme.BackgroundSecondary,
        Text = "H",
        TextColor3 = Theme.Accent,
        Font = Theme.FontBold,
        TextSize = IsMobile and 24 or 20,
        AutoButtonColor = false,
        Parent = gui,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = toggleBtn })
    create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = toggleBtn })

    -- Container principal (com animação)
    local main = create("Frame", {
        Name = "Main",
        Size = UDim2.fromOffset(0, 0), -- animação de abertura
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = gui,
    })
    create("UICorner", { CornerRadius = Theme.CornerRadius, Parent = main })
    create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = main })

    -- Topbar
    local topbar = create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Theme.BackgroundSecondary,
        BorderSizePixel = 0,
        Parent = main,
    })
    create("UICorner", { CornerRadius = Theme.CornerRadius, Parent = topbar })
    create("Frame", {
        Size = UDim2.new(1, 0, 0, 8),
        Position = UDim2.new(0, 0, 1, -8),
        BackgroundColor3 = Theme.BackgroundSecondary,
        BorderSizePixel = 0,
        Parent = topbar,
    })

    create("TextLabel", {
        Size = UDim2.new(1, -90, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Theme.Text,
        Font = Theme.FontBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topbar,
    })

    local minimizeBtn = create("TextButton", {
        Size = UDim2.fromOffset(24, 24),
        Position = UDim2.new(1, -60, 0.5, -12),
        BackgroundColor3 = Theme.BackgroundTertiary,
        Text = "−",
        TextColor3 = Theme.TextDimmed,
        Font = Theme.FontBold,
        TextSize = 16,
        AutoButtonColor = false,
        Parent = topbar,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = minimizeBtn })

    local closeBtn = create("TextButton", {
        Size = UDim2.fromOffset(24, 24),
        Position = UDim2.new(1, -32, 0.5, -12),
        BackgroundColor3 = Theme.BackgroundTertiary,
        Text = "×",
        TextColor3 = Theme.TextDimmed,
        Font = Theme.FontBold,
        TextSize = 14,
        AutoButtonColor = false,
        Parent = topbar,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = closeBtn })

    -- Sidebar
    local sidebar = create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 130, 1, -50),
        Position = UDim2.new(0, 10, 0, 45),
        BackgroundColor3 = Theme.BackgroundSecondary,
        BorderSizePixel = 0,
        Parent = main,
    })
    create("UICorner", { CornerRadius = Theme.CornerRadius, Parent = sidebar })

    local tabList = create("ScrollingFrame", {
        Size = UDim2.new(1, -10, 1, -10),
        Position = UDim2.new(0, 5, 0, 5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Border,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = sidebar,
    })
    create("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = tabList,
    })

    -- Container de páginas
    local pages = create("Frame", {
        Name = "Pages",
        Size = UDim2.new(1, -160, 1, -50),
        Position = UDim2.new(0, 150, 0, 45),
        BackgroundTransparency = 1,
        Parent = main,
    })

    local window = {
        Gui = gui,
        Main = main,
        Tabs = {},
        CurrentTab = nil,
        Flags = {},
    }

    makeDraggable(main, topbar)

    --============ RESIZE ============
    local function layoutOnResize(w, h)
        -- Sidebar mantém 130, resto acompanha
        sidebar.Size = UDim2.new(0, 130, 1, -50)
        pages.Size = UDim2.new(1, -160, 1, -50)
    end
    makeResizable(main, minSize, maxSize, layoutOnResize)

    --============ ANIMAÇÕES DE ABERTURA ============
    local targetSize = size
    local opened = true

    local function openWindow()
        if opened then return end
        opened = true
        main.Visible = true
        tween(main, 0.35, {
            Size = targetSize,
        }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        tween(main, 0.25, { BackgroundTransparency = 0 })
        for _, t in pairs(window.Tabs) do
            tween(t.Button, 0.15, { TextTransparency = 0 })
        end
    end

    local function closeWindow()
        if not opened then return end
        opened = false
        local closeTween = tween(main, 0.2, {
            Size = UDim2.fromOffset(targetSize.X.Offset, 0),
        }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        closeTween.Completed:Connect(function()
            main.Visible = false
        end)
    end

    -- Abre com animação
    main.Size = UDim2.fromOffset(targetSize.X.Offset, 0)
    tween(main, 0.4, { Size = targetSize }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    --============ MINIMIZE ============
    local minimized = false
    minimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            tween(main, 0.3, {
                Size = UDim2.fromOffset(main.AbsoluteSize.X, 40),
            }, Enum.EasingStyle.Quad)
        else
            tween(main, 0.3, {
                Size = UDim2.fromOffset(main.AbsoluteSize.X, targetSize.Y.Offset),
            }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        end
    end)
    minimizeBtn.MouseEnter:Connect(function()
        tween(minimizeBtn, 0.15, { BackgroundColor3 = Theme.Border })
    end)
    minimizeBtn.MouseLeave:Connect(function()
        tween(minimizeBtn, 0.15, { BackgroundColor3 = Theme.BackgroundTertiary })
    end)

    closeBtn.MouseButton1Click:Connect(closeWindow)
    closeBtn.MouseEnter:Connect(function()
        tween(closeBtn, 0.15, { BackgroundColor3 = Theme.Danger })
        closeBtn.TextColor3 = Theme.Text
    end)
    closeBtn.MouseLeave:Connect(function()
        tween(closeBtn, 0.15, { BackgroundColor3 = Theme.BackgroundTertiary })
        closeBtn.TextColor3 = Theme.TextDimmed
    end)

    toggleBtn.MouseButton1Click:Connect(function()
        if opened then
            closeWindow()
        else
            openWindow()
        end
    end)
    toggleBtn.MouseEnter:Connect(function()
        tween(toggleBtn, 0.2, {
            BackgroundColor3 = Theme.BackgroundTertiary,
            Size = UDim2.fromOffset(toggleBtn.AbsoluteSize.X + 4, toggleBtn.AbsoluteSize.Y + 4),
        })
    end)
    toggleBtn.MouseLeave:Connect(function()
        tween(toggleBtn, 0.2, {
            BackgroundColor3 = Theme.BackgroundSecondary,
            Size = UDim2.fromOffset(IsMobile and 55 or 45, IsMobile and 55 or 45),
        })
    end)

    --==========================================================
    -- TAB
    --==========================================================
    function window:Tab(tabConfig)
        tabConfig = tabConfig or {}
        local tabName = tabConfig.Name or "Tab"

        local btn = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = Theme.BackgroundSecondary,
            Text = "  " .. tabName,
            TextColor3 = Theme.TextDimmed,
            Font = Theme.Font,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            TextTransparency = 1, -- animação
            Parent = tabList,
        })
        create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = btn })

        local page = create("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Theme.Border,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Visible = false,
            Parent = pages,
        })
        create("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = page,
        })
        create("UIPadding", {
            PaddingRight = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 8),
            Parent = page,
        })

        local tab = {
            Name = tabName,
            Button = btn,
            Page = page,
            Window = window,
        }

        -- Animação de troca de página
        local function activate()
            for _, t in pairs(window.Tabs) do
                if t.Page.Visible then
                    tween(t.Page, 0.15, { BackgroundTransparency = 1 })
                    t.Page.Visible = false
                end
                tween(t.Button, 0.15, {
                    BackgroundColor3 = Theme.BackgroundSecondary,
                    TextColor3 = Theme.TextDimmed,
                })
            end
            page.Visible = true
            page.Position = UDim2.new(0, 8, 0, 0)
            tween(page, 0.2, { Position = UDim2.new(0, 0, 0, 0) })
            tween(btn, 0.15, {
                BackgroundColor3 = Theme.BackgroundTertiary,
                TextColor3 = Theme.Text,
            })
            window.CurrentTab = tab
        end

        btn.MouseButton1Click:Connect(activate)
        btn.MouseEnter:Connect(function()
            if window.CurrentTab ~= tab then
                tween(btn, 0.15, { BackgroundColor3 = Theme.BackgroundTertiary })
            end
        end)
        btn.MouseLeave:Connect(function()
            if window.CurrentTab ~= tab then
                tween(btn, 0.15, { BackgroundColor3 = Theme.BackgroundSecondary })
            end
        end)

        table.insert(window.Tabs, tab)
        if #window.Tabs == 1 then
            activate()
        end

        --======================================================
        -- COMPONENTES DO TAB
        --======================================================

        function tab:Section(sectionConfig)
            sectionConfig = sectionConfig or {}
            local sectionName = sectionConfig.Name or "Section"

            local sectionFrame = create("Frame", {
                Size = UDim2.new(1, 0, 0, 26),
                BackgroundTransparency = 1,
                Parent = page,
            })
            create("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = sectionName:upper(),
                TextColor3 = Theme.TextDimmed,
                Font = Theme.FontBold,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = sectionFrame,
            })
            return sectionFrame
        end

        function tab:Button(btnConfig)
            btnConfig = btnConfig or {}
            local btnName = btnConfig.Name or "Button"
            local callback = btnConfig.Callback or function() end

            local button = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundColor3 = Theme.BackgroundSecondary,
                Text = btnName,
                TextColor3 = Theme.Text,
                Font = Theme.Font,
                TextSize = 13,
                AutoButtonColor = false,
                Parent = page,
            })
            create("UICorner", { CornerRadius = Theme.CornerRadius, Parent = button })
            create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = button })

            button.MouseEnter:Connect(function()
                tween(button, 0.15, { BackgroundColor3 = Theme.BackgroundTertiary })
                tween(button, 0.15, { Size = UDim2.new(1, 0, 0, 34) })
            end)
            button.MouseLeave:Connect(function()
                tween(button, 0.15, { BackgroundColor3 = Theme.BackgroundSecondary })
                tween(button, 0.15, { Size = UDim2.new(1, 0, 0, 32) })
            end)
            button.MouseButton1Click:Connect(function()
                -- efeito de clique
                tween(button, 0.08, { BackgroundColor3 = Theme.Border })
                task.delay(0.1, function()
                    tween(button, 0.15, { BackgroundColor3 = Theme.BackgroundTertiary })
                end)
                pcall(callback)
            end)

            return button
        end

        function tab:Toggle(toggleConfig)
            toggleConfig = toggleConfig or {}
            local toggleName = toggleConfig.Name or "Toggle"
            local default = toggleConfig.Default or false
            local callback = toggleConfig.Callback or function() end
            local flag = toggleConfig.Flag

            local state = default

            local container = create("Frame", {
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundColor3 = Theme.BackgroundSecondary,
                Parent = page,
            })
            create("UICorner", { CornerRadius = Theme.CornerRadius, Parent = container })
            create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = container })

            create("TextLabel", {
                Size = UDim2.new(1, -70, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = toggleName,
                TextColor3 = Theme.Text,
                Font = Theme.Font,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = container,
            })

            local switch = create("Frame", {
                Size = UDim2.fromOffset(36, 18),
                Position = UDim2.new(1, -48, 0.5, -9),
                BackgroundColor3 = Theme.BackgroundTertiary,
                Parent = container,
            })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = switch })

            local dot = create("Frame", {
                Size = UDim2.fromOffset(14, 14),
                Position = UDim2.new(0, 2, 0.5, -7),
                BackgroundColor3 = Theme.TextDimmed,
                Parent = switch,
            })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })

            local clickBtn = create("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                Parent = container,
            })

            local function update()
                if state then
                    tween(switch, 0.2, { BackgroundColor3 = Theme.Accent })
                    tween(dot, 0.2, {
                        Position = UDim2.new(1, -16, 0.5, -7),
                        BackgroundColor3 = Theme.Background,
                    }, Enum.EasingStyle.Back)
                else
                    tween(switch, 0.2, { BackgroundColor3 = Theme.BackgroundTertiary })
                    tween(dot, 0.2, {
                        Position = UDim2.new(0, 2, 0.5, -7),
                        BackgroundColor3 = Theme.TextDimmed,
                    }, Enum.EasingStyle.Back)
                end
            end

            update()
            if flag then window.Flags[flag] = state end

            clickBtn.MouseButton1Click:Connect(function()
                state = not state
                if flag then window.Flags[flag] = state end
                update()
                pcall(callback, state)
            end)

            return {
                Set = function(_, value)
                    state = value
                    if flag then window.Flags[flag] = state end
                    update()
                    pcall(callback, state)
                end,
                Get = function()
                    return state
                end,
            }
        end

        function tab:Slider(sliderConfig)
            sliderConfig = sliderConfig or {}
            local sliderName = sliderConfig.Name or "Slider"
            local min = sliderConfig.Min or 0
            local max = sliderConfig.Max or 100
            local default = sliderConfig.Default or min
            local callback = sliderConfig.Callback or function() end
            local flag = sliderConfig.Flag
            local decimals = sliderConfig.Decimals or 0

            local value = default
            local dragging = false

            local container = create("Frame", {
                Size = UDim2.new(1, 0, 0, 50),
                BackgroundColor3 = Theme.BackgroundSecondary,
                Parent = page,
            })
            create("UICorner", { CornerRadius = Theme.CornerRadius, Parent = container })
            create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = container })

            create("TextLabel", {
                Size = UDim2.new(1, -70, 0, 20),
                Position = UDim2.new(0, 12, 0, 5),
                BackgroundTransparency = 1,
                Text = sliderName,
                TextColor3 = Theme.Text,
                Font = Theme.Font,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = container,
            })

            local valueLabel = create("TextLabel", {
                Size = UDim2.new(0, 55, 0, 20),
                Position = UDim2.new(1, -67, 0, 5),
                BackgroundTransparency = 1,
                Text = tostring(value),
                TextColor3 = Theme.TextDimmed,
                Font = Theme.FontBold,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = container,
            })

            -- Barra com área de toque maior (para mobile)
            local barHit = create("Frame", {
                Size = UDim2.new(1, -24, 0, 20),
                Position = UDim2.new(0, 12, 0, 26),
                BackgroundTransparency = 1,
                Parent = container,
            })

            local bar = create("Frame", {
                Size = UDim2.new(1, 0, 0, 6),
                Position = UDim2.new(0, 0, 0.5, -3),
                BackgroundColor3 = Theme.BackgroundTertiary,
                Parent = barHit,
            })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = bar })

            local fill = create("Frame", {
                Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
                BackgroundColor3 = Theme.Accent,
                Parent = bar,
            })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })

            local knob = create("Frame", {
                Size = UDim2.fromOffset(14, 14),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
                BackgroundColor3 = Theme.Text,
                ZIndex = 2,
                Parent = bar,
            })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })
            create("UIStroke", { Color = Theme.Background, Thickness = 2, Parent = knob })

            local function roundTo(n, d)
                local mult = 10 ^ d
                return math.floor(n * mult + 0.5) / mult
            end

            local function updateFromInput(input)
                local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                local newVal = roundTo(min + (max - min) * rel, decimals)
                if newVal ~= value then
                    value = newVal
                    valueLabel.Text = tostring(value)
                    fill.Size = UDim2.new(rel, 0, 1, 0)
                    tween(knob, 0.08, { Position = UDim2.new(rel, 0, 0.5, 0) })
                    if flag then window.Flags[flag] = value end
                    pcall(callback, value)
                end
            end

            barHit.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    tween(knob, 0.15, { Size = UDim2.fromOffset(18, 18) })
                    updateFromInput(input)
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch) then
                    updateFromInput(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    if dragging then
                        dragging = false
                        tween(knob, 0.15, { Size = UDim2.fromOffset(14, 14) })
                    end
                end
            end)

            if flag then window.Flags[flag] = value end

            return {
                Set = function(_, val)
                    value = math.clamp(roundTo(val, decimals), min, max)
                    local rel = (value - min) / (max - min)
                    valueLabel.Text = tostring(value)
                    tween(fill, 0.2, { Size = UDim2.new(rel, 0, 1, 0) })
                    tween(knob, 0.2, { Position = UDim2.new(rel, 0, 0.5, 0) })
                    if flag then window.Flags[flag] = value end
                    pcall(callback, value)
                end,
                Get = function()
                    return value
                end,
            }
        end

        function tab:Input(inputConfig)
            inputConfig = inputConfig or {}
            local inputName = inputConfig.Name or "Input"
            local placeholder = inputConfig.Placeholder or "Digite..."
            local callback = inputConfig.Callback or function() end
            local flag = inputConfig.Flag

            local container = create("Frame", {
                Size = UDim2.new(1, 0, 0, 50),
                BackgroundColor3 = Theme.BackgroundSecondary,
                Parent = page,
            })
            create("UICorner", { CornerRadius = Theme.CornerRadius, Parent = container })
            create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = container })

            create("TextLabel", {
                Size = UDim2.new(1, -24, 0, 18),
                Position = UDim2.new(0, 12, 0, 5),
                BackgroundTransparency = 1,
                Text = inputName,
                TextColor3 = Theme.Text,
                Font = Theme.Font,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = container,
            })

            local box = create("TextBox", {
                Size = UDim2.new(1, -24, 0, 20),
                Position = UDim2.new(0, 12, 0, 24),
                BackgroundTransparency = 1,
                Text = "",
                PlaceholderText = placeholder,
                PlaceholderColor3 = Theme.TextDimmed,
                TextColor3 = Theme.Text,
                Font = Theme.Font,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
                Parent = container,
            })

            local line = create("Frame", {
                Size = UDim2.new(1, -24, 0, 1),
                Position = UDim2.new(0, 12, 1, -3),
                BackgroundColor3 = Theme.Border,
                BorderSizePixel = 0,
                Parent = container,
            })

            box.Focused:Connect(function()
                tween(line, 0.15, { BackgroundColor3 = Theme.Accent })
            end)
            box.FocusLost:Connect(function(enterPressed)
                tween(line, 0.15, { BackgroundColor3 = Theme.Border })
                if flag then window.Flags[flag] = box.Text end
                pcall(callback, box.Text, enterPressed)
            end)

            if flag then window.Flags[flag] = box.Text end

            return {
                Set = function(_, text)
                    box.Text = text
                    if flag then window.Flags[flag] = text end
                end,
                Get = function()
                    return box.Text
                end,
            }
        end

        function tab:Dropdown(ddConfig)
            ddConfig = ddConfig or {}
            local ddName = ddConfig.Name or "Dropdown"
            local options = ddConfig.Options or {}
            local callback = ddConfig.Callback or function() end
            local flag = ddConfig.Flag

            local selected = nil
            local opened = false

            local container = create("Frame", {
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundColor3 = Theme.BackgroundSecondary,
                ClipsDescendants = false,
                ZIndex = 2,
                Parent = page,
            })
            create("UICorner", { CornerRadius = Theme.CornerRadius, Parent = container })
            create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = container })

            local header = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 3,
                Parent = container,
            })

            local nameLabel = create("TextLabel", {
                Size = UDim2.new(1, -60, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = ddName,
                TextColor3 = Theme.Text,
                Font = Theme.Font,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 3,
                Parent = container,
            })

            local arrowLabel = create("TextLabel", {
                Size = UDim2.new(0, 30, 1, 0),
                Position = UDim2.new(1, -35, 0, 0),
                BackgroundTransparency = 1,
                Text = "▾",
                TextColor3 = Theme.TextDimmed,
                Font = Theme.FontBold,
                TextSize = 14,
                ZIndex = 3,
                Parent = container,
            })

            local list = create("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 1, 4),
                BackgroundColor3 = Theme.BackgroundTertiary,
                Visible = false,
                ClipsDescendants = true,
                ZIndex = 10,
                Parent = container,
            })
            create("UICorner", { CornerRadius = Theme.CornerRadius, Parent = list })
            create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = list })
            create("UIListLayout", {
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = list,
            })
            create("UIPadding", {
                PaddingTop = UDim.new(0, 4),
                PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, 4),
                PaddingRight = UDim.new(0, 4),
                Parent = list,
            })

            local function closeList()
                opened = false
                tween(arrowLabel, 0.2, { Rotation = 0 })
                local t = tween(list, 0.2, { Size = UDim2.new(1, 0, 0, 0) })
                t.Completed:Connect(function()
                    if not opened then list.Visible = false end
                end)
            end

            local function openList()
                opened = true
                list.Visible = true
                local height = math.min(#options * 28 + 8, 160)
                tween(list, 0.2, { Size = UDim2.new(1, 0, 0, height) }, Enum.EasingStyle.Back)
                tween(arrowLabel, 0.2, { Rotation = 180 })
            end

            local function buildOptions()
                for _, child in ipairs(list:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                for _, opt in ipairs(options) do
                    local optBtn = create("TextButton", {
                        Size = UDim2.new(1, 0, 0, 24),
                        BackgroundColor3 = Theme.BackgroundTertiary,
                        Text = "  " .. tostring(opt),
                        TextColor3 = Theme.Text,
                        Font = Theme.Font,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        AutoButtonColor = false,
                        ZIndex = 11,
                        Parent = list,
                    })
                    create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = optBtn })

                    optBtn.MouseEnter:Connect(function()
                        tween(optBtn, 0.12, { BackgroundColor3 = Theme.Border })
                    end)
                    optBtn.MouseLeave:Connect(function()
                        tween(optBtn, 0.12, { BackgroundColor3 = Theme.BackgroundTertiary })
                    end)
                    optBtn.MouseButton1Click:Connect(function()
                        selected = opt
                        nameLabel.Text = ddName .. ": " .. tostring(opt)
                        if flag then window.Flags[flag] = opt end
                        pcall(callback, opt)
                        closeList()
                    end)
                end
            end

            buildOptions()

            header.MouseButton1Click:Connect(function()
                if opened then closeList() else openList() end
            end)
            header.MouseEnter:Connect(function()
                tween(arrowLabel, 0.15, { TextColor3 = Theme.Text })
            end)
            header.MouseLeave:Connect(function()
                tween(arrowLabel, 0.15, { TextColor3 = Theme.TextDimmed })
            end)

            return {
                Set = function(_, value)
                    selected = value
                    nameLabel.Text = ddName .. ": " .. tostring(value)
                    if flag then window.Flags[flag] = value end
                    pcall(callback, value)
                end,
                Get = function()
                    return selected
                end,
                Refresh = function(_, newOptions)
                    options = newOptions
                    buildOptions()
                end,
            }
        end

        function tab:Label(text)
            local label = create("TextLabel", {
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text = text or "",
                TextColor3 = Theme.TextDimmed,
                Font = Theme.Font,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = page,
            })
            return label
        end

        function tab:Divider()
            local div = create("Frame", {
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = Theme.Border,
                BorderSizePixel = 0,
                Parent = page,
            })
            return div
        end

        return tab
    end

    --==========================================================
    -- API PÚBLICA
    --==========================================================
    function window:Toggle()
        if opened then closeWindow() else openWindow() end
    end

    function window:Destroy()
        gui:Destroy()
    end

    function window:GetFlags()
        return window.Flags
    end

    return window
end

--==============================================================
-- NOTIFY
--==============================================================
function Hermez:Notify(config)
    config = config or {}
    local title = config.Title or "Hermez"
    local content = config.Content or ""
    local duration = config.Duration or 4

    local parent = getParent()
    local container = parent:FindFirstChild("Hermez_Notifications")
    if not container then
        container = create("ScreenGui", {
            Name = "Hermez_Notifications",
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            Parent = parent,
        })
        local holder = create("Frame", {
            Name = "Holder",
            Size = UDim2.new(0, IsMobile and 240 or 280, 0, 0),
            Position = UDim2.new(1, IsMobile and -250 or -300, 1, -20),
            BackgroundTransparency = 1,
            Parent = container,
        })
        create("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            Parent = holder,
        })
    end

    local holder = container:FindFirstChild("Holder")

    local notif = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(1, IsMobile and 260 or 300, 0, 0),
        BackgroundColor3 = Theme.BackgroundSecondary,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = holder,
    })
    create("UICorner", { CornerRadius = Theme.CornerRadius, Parent = notif })
    create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = notif })

    -- Animação de entrada (slide)
    tween(notif, 0.35, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Back)

    local progress = create("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = notif,
    })

    create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 18),
        Position = UDim2.new(0, 10, 0, 8),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Theme.Text,
        Font = Theme.FontBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notif,
    })

    create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 10, 0, 26),
        BackgroundTransparency = 1,
        Text = content,
        TextColor3 = Theme.TextDimmed,
        Font = Theme.Font,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = notif,
    })

    tween(notif, 0.3, { Size = UDim2.new(1, 0, 0, 70) }, Enum.EasingStyle.Back)
    tween(progress, duration, { Size = UDim2.new(0, 0, 0, 2) })

    task.delay(duration, function()
        tween(notif, 0.3, {
            Position = UDim2.new(1, IsMobile and 260 or 300, 0, 0),
        }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        tween(notif, 0.3, { Size = UDim2.new(1, 0, 0, 0) })
        task.delay(0.35, function()
            notif:Destroy()
        end)
    end)

    return notif
end

return Hermez
