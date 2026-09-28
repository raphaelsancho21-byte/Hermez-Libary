--[[
    Hermez Library v0.2.1
    Minimalist Black Theme UI Library for Roblox
    + Animações + Mobile + Resize + Keybind + Hotkey + Notify Types
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
-- TEMA + CORES DE NOTIFY
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
    Warning = Color3.fromRGB(240, 180, 60),
    Danger = Color3.fromRGB(220, 80, 80),
    Info = Color3.fromRGB(100, 160, 240),
    Font = Enum.Font.Gotham,
    FontBold = Enum.Font.GothamBold,
    CornerRadius = UDim.new(0, 6),
}

local NotifyTypes = {
    info    = { Color = Theme.Info,    Icon = "i" },
    success = { Color = Theme.Success, Icon = "✓" },
    warning = { Color = Theme.Warning, Icon = "!" },
    error   = { Color = Theme.Danger,  Icon = "×" },
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
        TweenInfo.new(time, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
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

local function keyToString(key)
    if typeof(key) == "EnumItem" then
        local name = key.Name:gsub("KeyCode", "")
        if name == "Unknown" then return "?" end
        return name
    end
    return tostring(key)
end

local function isTextBoxFocused()
    local focused = UserInputService:GetFocusedTextBox()
    return focused ~= nil
end

--==============================================================
-- DRAGGABLE
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
-- RESIZE
--==============================================================
local function makeResizable(main, getMinSize, getMaxSize, onResize)
    local handleSize = IsMobile and 32 or 22
    local handle = create("TextButton", {
        Name = "ResizeHandle",
        Size = UDim2.fromOffset(handleSize, handleSize),
        Position = UDim2.new(1, -handleSize, 1, -handleSize),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 5,
        Parent = main,
    })
    local grip = create("TextLabel", {
        Size = UDim2.fromOffset(handleSize, handleSize),
        BackgroundTransparency = 1,
        Text = "◢",
        TextColor3 = Theme.TextDimmed,
        Font = Enum.Font.GothamBold,
        TextSize = IsMobile and 16 or 12,
        ZIndex = 6,
        Parent = handle,
    })

    local resizing = false
    local startSize, startInputPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            startSize = Vector2.new(main.AbsoluteSize.X, main.AbsoluteSize.Y)
            startInputPos = Vector2.new(input.Position.X, input.Position.Y)
            tween(grip, 0.15, { TextColor3 = Theme.Accent })
        end
    end)

    handle.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local deltaX = input.Position.X - startInputPos.X
            local deltaY = input.Position.Y - startInputPos.Y
            local minS, maxS = getMinSize(), getMaxSize()
            local newX = math.clamp(startSize.X + deltaX, minS.X, maxS.X)
            local newY = math.clamp(startSize.Y + deltaY, minS.Y, maxS.Y)
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
        if not resizing then
            tween(grip, 0.15, { TextColor3 = Theme.TextDimmed })
        end
    end)
end

--==============================================================
-- NOTIFY SYSTEM
--==============================================================
local NotifyHolder = nil

local function getNotifyHolder(parent)
    if NotifyHolder and NotifyHolder.Parent then return NotifyHolder end
    local container = parent:FindFirstChild("Hermez_Notifications")
    if not container then
        container = create("ScreenGui", {
            Name = "Hermez_Notifications",
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            Parent = parent,
        })
    end
    local holder = container:FindFirstChild("Holder")
    if not holder then
        holder = create("Frame", {
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
    NotifyHolder = holder
    return holder
end

local function createNotify(title, content, duration, nType)
    duration = duration or 4
    nType = nType or "info"
    local typeData = NotifyTypes[nType] or NotifyTypes.info
    local holder = getNotifyHolder(getParent())

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

    tween(notif, 0.35, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Back)

    -- Barra lateral colorida (indicador do tipo)
    local accent = create("Frame", {
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = typeData.Color,
        BorderSizePixel = 0,
        Parent = notif,
    })

    -- Ícone
    local iconBg = create("Frame", {
        Size = UDim2.fromOffset(24, 24),
        Position = UDim2.new(0, 14, 0, 12),
        BackgroundColor3 = typeData.Color,
        Parent = notif,
    })
    create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = iconBg })
    create("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = typeData.Icon,
        TextColor3 = Theme.Background,
        Font = Theme.FontBold,
        TextSize = 13,
        Parent = iconBg,
    })

    -- Título
    create("TextLabel", {
        Size = UDim2.new(1, -50, 0, 18),
        Position = UDim2.new(0, 46, 0, 10),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Theme.Text,
        Font = Theme.FontBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = notif,
    })

    -- Conteúdo
    create("TextLabel", {
        Size = UDim2.new(1, -56, 0, 30),
        Position = UDim2.new(0, 46, 0, 28),
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

    -- Barra de progresso
    local progress = create("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = typeData.Color,
        BorderSizePixel = 0,
        Parent = notif,
    })

    tween(notif, 0.3, { Size = UDim2.new(1, 0, 0, 70) }, Enum.EasingStyle.Back)
    tween(progress, duration, { Size = UDim2.new(0, 0, 0, 2) })

    task.delay(duration, function()
        tween(notif, 0.3, {
            Position = UDim2.new(1, IsMobile and 260 or 300, 0, 0),
        }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        tween(notif, 0.3, { Size = UDim2.new(1, 0, 0, 0) })
        task.delay(0.35, function() notif:Destroy() end)
    end)

    return notif
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
    local hotkey = config.Hotkey or Enum.KeyCode.H
    local showMobileBtn = config.MobileButton ~= false

    local gui = create("ScreenGui", {
        Name = "Hermez_" .. HttpService:GenerateGUID(false),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = getParent(),
    })

    --==========================================================
    -- BOTÃO MOBILE (flutuante grande) → aparece só em mobile
    --==========================================================
    local mobileBtn
    if IsMobile and showMobileBtn then
        mobileBtn = create("TextButton", {
            Name = "MobileToggle",
            Size = UDim2.fromOffset(50, 50),
            Position = UDim2.new(0, 15, 1, -80),
            BackgroundColor3 = Theme.BackgroundSecondary,
            Text = "☰",
            TextColor3 = Theme.Accent,
            Font = Theme.FontBold,
            TextSize = 22,
            AutoButtonColor = false,
            Parent = gui,
        })
        create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = mobileBtn })
        create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = mobileBtn })
        makeDraggable(mobileBtn, mobileBtn)

        mobileBtn.MouseButton1Click:Connect(function()
            -- placeholder, sobrescrito abaixo
        end)
    end

    --==========================================================
    -- JANELA PRINCIPAL
    --==========================================================
    local main = create("Frame", {
        Name = "Main",
        Size = UDim2.fromOffset(0, 0),
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

    -- Pages container (FIX: sem position animation)
    local pages = create("Frame", {
        Name = "Pages",
        Size = UDim2.new(1, -160, 1, -50),
        Position = UDim2.new(0, 150, 0, 45),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = main,
    })

    local window = {
        Gui = gui,
        Main = main,
        Tabs = {},
        CurrentTab = nil,
        Flags = {},
        _connections = {},
        Hotkey = hotkey,
        Opened = true,
    }

    makeDraggable(main, topbar)

    local currentSize = Vector2.new(size.X.Offset, size.Y.Offset)
    makeResizable(
        main,
        function() return minSize end,
        function() return maxSize end,
        function(w, h) currentSize = Vector2.new(w, h) end
    )

    --============ ABRIR / FECHAR ============
    local function openWindow()
        if window.Opened then return end
        window.Opened = true
        main.Visible = true
        tween(main, 0.35, {
            Size = UDim2.fromOffset(currentSize.X, currentSize.Y),
        }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end

    local function closeWindow()
        if not window.Opened then return end
        window.Opened = false
        local t = tween(main, 0.2, {
            Size = UDim2.fromOffset(currentSize.X, 0),
        }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        t.Completed:Connect(function()
            main.Visible = false
        end)
    end

    local function toggleWindow()
        if window.Opened then closeWindow() else openWindow() end
    end

    window.Open = openWindow
    window.Close = closeWindow
    window.Toggle = toggleWindow

    -- Abre com animação
    main.Size = UDim2.fromOffset(currentSize.X, 0)
    tween(main, 0.4, { Size = UDim2.fromOffset(currentSize.X, currentSize.Y) },
        Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    --============ HOTKEY GLOBAL ============
    local hotkeyConn = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if isTextBoxFocused() then return end
        if input.UserInputType == Enum.UserInputType.Keyboard
            and input.KeyCode == window.Hotkey then
            toggleWindow()
        end
    end)
    table.insert(window._connections, hotkeyConn)

    function window:SetHotkey(keyCode)
        window.Hotkey = keyCode
    end

    --============ MOBILE BUTTON CLICK ============
    if mobileBtn then
        mobileBtn.MouseButton1Click:Connect(toggleWindow)
        mobileBtn.MouseEnter:Connect(function()
            tween(mobileBtn, 0.15, { BackgroundColor3 = Theme.BackgroundTertiary })
        end)
        mobileBtn.MouseLeave:Connect(function()
            tween(mobileBtn, 0.15, { BackgroundColor3 = Theme.BackgroundSecondary })
        end)
    end

    --============ MINIMIZE / CLOSE ============
    local minimized = false
    minimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            tween(main, 0.3, { Size = UDim2.fromOffset(main.AbsoluteSize.X, 40) })
        else
            tween(main, 0.3, {
                Size = UDim2.fromOffset(main.AbsoluteSize.X, currentSize.Y),
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

    --==========================================================
    -- TAB (FIX: conteúdo não some mais ao clicar)
    --==========================================================
    function window:Tab(tabConfig)
        tabConfig = tabConfig or {}
        local tabName = tabConfig.Name or "Tab"

        local btn = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = Theme.BackgroundSecondary,
            Text = "",
            AutoButtonColor = false,
            Parent = tabList,
        })
        create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = btn })

        local btnLabel = create("TextLabel", {
            Size = UDim2.new(1, -14, 1, 0),
            Position = UDim2.new(0, 12, 0, 0),
            BackgroundTransparency = 1,
            Text = tabName,
            TextColor3 = Theme.TextDimmed,
            Font = Theme.Font,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 2,
            Parent = btn,
        })

        -- Página: SEMPRE visível em layout, mas escondida via Visible.
        -- A animação é SÓ de transparência — não mexe em Position/Size.
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
            Label = btnLabel,
            Page = page,
            Window = window,
        }

        local function activate()
            for _, t in pairs(window.Tabs) do
                if t.Page.Visible then
                    t.Page.Visible = false
                end
                tween(t.Button, 0.15, { BackgroundColor3 = Theme.BackgroundSecondary })
                tween(t.Label, 0.15, { TextColor3 = Theme.TextDimmed })
            end
            page.Visible = true
            tween(btn, 0.15, { BackgroundColor3 = Theme.BackgroundTertiary })
            tween(btnLabel, 0.15, { TextColor3 = Theme.Text })
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
        -- COMPONENTES
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
                TextTruncate = Enum.TextTruncate.AtEnd,
                AutoButtonColor = false,
                Parent = page,
            })
            create("UICorner", { CornerRadius = Theme.CornerRadius, Parent = button })
            create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = button })

            button.MouseEnter:Connect(function()
                tween(button, 0.15, { BackgroundColor3 = Theme.BackgroundTertiary })
            end)
            button.MouseLeave:Connect(function()
                tween(button, 0.15, { BackgroundColor3 = Theme.BackgroundSecondary })
            end)
            button.MouseButton1Click:Connect(function()
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
                Get = function() return state end,
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
                Get = function() return value end,
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
                Get = function() return box.Text end,
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
                Get = function() return selected end,
                Refresh = function(_, newOptions)
                    options = newOptions
                    buildOptions()
                end,
            }
        end

        --======================================================
        -- KEYBIND (agora com Enable/Disable)
        --======================================================
        function tab:Keybind(kbConfig)
            kbConfig = kbConfig or {}
            local kbName = kbConfig.Name or "Keybind"
            local default = kbConfig.Default or Enum.KeyCode.Unknown
            local callback = kbConfig.Callback or function() end
            local flag = kbConfig.Flag
            local enabled = kbConfig.Enabled ~= false -- ATIVADO por padrão

            local currentKey = default
            local listening = false

            local container = create("Frame", {
                Size = UDim2.new(1, 0, IsMobile and 0, 0, 0, 32),
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundColor3 = Theme.BackgroundSecondary,
                Parent = page,
            })
            create("UICorner", { CornerRadius = Theme.CornerRadius, Parent = container })
            create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = container })

            local nameLabel = create("TextLabel", {
                Size = UDim2.new(1, -130, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = kbName,
                TextColor3 = Theme.Text,
                Font = Theme.Font,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = container,
            })

            -- Toggle Enable/Disable (ON/OFF)
            local enableBtn = create("TextButton", {
                Size = UDim2.fromOffset(34, 18),
                Position = UDim2.new(1, -108, 0.5, -9),
                BackgroundColor3 = enabled and Theme.Success or Theme.BackgroundTertiary,
                Text = "",
                AutoButtonColor = false,
                Parent = container,
            })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = enableBtn })
            local enableDot = create("Frame", {
                Size = UDim2.fromOffset(14, 14),
                Position = enabled and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
                BackgroundColor3 = enabled and Theme.Background or Theme.TextDimmed,
                Parent = enableBtn,
            })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = enableDot })

            -- Botão de tecla
            local keyBtn = create("TextButton", {
                Size = UDim2.fromOffset(50, 20),
                Position = UDim2.new(1, -62, 0.5, -10),
                BackgroundColor3 = Theme.BackgroundTertiary,
                Text = keyToString(currentKey),
                TextColor3 = Theme.Text,
                Font = Theme.FontBold,
                TextSize = 11,
                AutoButtonColor = false,
                Parent = container,
            })
            create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = keyBtn })
            local keyStroke = create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = keyBtn })

            local function updateEnableVisual()
                if enabled then
                    tween(enableBtn, 0.2, { BackgroundColor3 = Theme.Success })
                    tween(enableDot, 0.2, {
                        Position = UDim2.new(1, -16, 0.5, -7),
                        BackgroundColor3 = Theme.Background,
                    }, Enum.EasingStyle.Back)
                else
                    tween(enableBtn, 0.2, { BackgroundColor3 = Theme.BackgroundTertiary })
                    tween(enableDot, 0.2, {
                        Position = UDim2.new(0, 2, 0.5, -7),
                        BackgroundColor3 = Theme.TextDimmed,
                    }, Enum.EasingStyle.Back)
                end
                if flag then window.Flags[flag .. "_enabled"] = enabled end
            end

            local function setEnabled(value)
                enabled = value
                updateEnableVisual()
            end

            updateEnableVisual()

            enableBtn.MouseButton1Click:Connect(function()
                setEnabled(not enabled)
            end)

            local function stopListening()
                listening = false
                keyBtn.Text = keyToString(currentKey)
                tween(keyBtn, 0.15, { BackgroundColor3 = Theme.BackgroundTertiary })
                keyStroke.Color = Theme.Border
                keyBtn.TextColor3 = Theme.Text
            end

            local function startListening()
                if not enabled then return end
                listening = true
                keyBtn.Text = "..."
                tween(keyBtn, 0.15, { BackgroundColor3 = Theme.Accent })
                keyStroke.Color = Theme.Accent
                keyBtn.TextColor3 = Theme.Background
            end

            keyBtn.MouseButton1Click:Connect(function()
                if listening then stopListening() else startListening() end
            end)
            keyBtn.MouseEnter:Connect(function()
                if not listening then
                    tween(keyBtn, 0.15, { BackgroundColor3 = Theme.Border })
                end
            end)
            keyBtn.MouseLeave:Connect(function()
                if not listening then
                    tween(keyBtn, 0.15, { BackgroundColor3 = Theme.BackgroundTertiary })
                end
            end)

            -- Captura tecla
            local captureConn = UserInputService.InputBegan:Connect(function(input, processed)
                if not listening then return end
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    if input.KeyCode == Enum.KeyCode.Escape then
                        stopListening()
                        return
                    end
                    currentKey = input.KeyCode
                    keyBtn.Text = keyToString(currentKey)
                    if flag then window.Flags[flag] = currentKey end
                    pcall(callback, currentKey)
                    stopListening()
                end
            end)
            table.insert(window._connections, captureConn)

            -- Dispara tecla (só se enabled = true)
            local pressConn = UserInputService.InputBegan:Connect(function(input, processed)
                if processed then return end
                if isTextBoxFocused() then return end
                if not enabled then return end
                if currentKey ~= Enum.KeyCode.Unknown
                    and input.KeyCode == currentKey then
                    pcall(callback, currentKey)
                end
            end)
            table.insert(window._connections, pressConn)

            if flag then
                window.Flags[flag] = currentKey
                window.Flags[flag .. "_enabled"] = enabled
            end

            -- Botões de atalho rápido mobile
            if IsMobile then
                container.Size = UDim2.new(1, 0, 0, 58)
                local mobileRow = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 22),
                    Position = UDim2.new(0, 0, 1, 4),
                    BackgroundTransparency = 1,
                    Parent = container,
                })
                create("UIListLayout", {
                    Padding = UDim.new(0, 4),
                    FillDirection = Enum.FillDirection.Horizontal,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = mobileRow,
                })
                for _, key in ipairs({ Enum.KeyCode.E, Enum.KeyCode.Q, Enum.KeyCode.F, Enum.KeyCode.R }) do
                    local quickBtn = create("TextButton", {
                        Size = UDim2.fromOffset(28, 20),
                        BackgroundColor3 = Theme.BackgroundTertiary,
                        Text = keyToString(key),
                        TextColor3 = Theme.TextDimmed,
                        Font = Theme.FontBold,
                        TextSize = 10,
                        AutoButtonColor = false,
                        Parent = mobileRow,
                    })
                    create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = quickBtn })
                    quickBtn.MouseButton1Click:Connect(function()
                        currentKey = key
                        keyBtn.Text = keyToString(currentKey)
                        if flag then window.Flags[flag] = currentKey end
                        stopListening()
                    end)
                end
            end

            return {
                Set = function(_, key)
                    currentKey = key
                    keyBtn.Text = keyToString(currentKey)
                    if flag then window.Flags[flag] = currentKey end
                end,
                Get = function() return currentKey end,
                SetEnabled = function(_, value) setEnabled(value) end,
                IsEnabled = function() return enabled end,
                Toggle = function() setEnabled(not enabled) end,
            }
        end

        function tab:Label(text)
            return create("TextLabel", {
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text = text or "",
                TextColor3 = Theme.TextDimmed,
                Font = Theme.Font,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = page,
            })
        end

        function tab:Divider()
            return create("Frame", {
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = Theme.Border,
                BorderSizePixel = 0,
                Parent = page,
            })
        end

        return tab
    end

    --==========================================================
    -- API PÚBLICA DA WINDOW
    --==========================================================
    function window:Destroy()
        for _, conn in ipairs(window._connections) do
            pcall(function() conn:Disconnect() end)
        end
        gui:Destroy()
    end

    function window:GetFlags()
        return window.Flags
    end

    function window:SetMobileButtonVisible(visible)
        if mobileBtn then
            mobileBtn.Visible = visible
        end
    end

    return window
end

--==============================================================
-- NOTIFY API PÚBLICA
--==============================================================
function Hermez:Notify(config)
    config = config or {}
    return createNotify(
        config.Title or "Hermez",
        config.Content or "",
        config.Duration or 4,
        config.Type or "info"
    )
end

function Hermez:Info(title, content, duration)
    return createNotify(title, content, duration or 3, "info")
end

function Hermez:Success(title, content, duration)
    return createNotify(title, content, duration or 3, "success")
end

function Hermez:Warning(title, content, duration)
    return createNotify(title, content, duration or 4, "warning")
end

function Hermez:Error(title, content, duration)
    return createNotify(title, content, duration or 5, "error")
end

return Hermez
