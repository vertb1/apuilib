local AnimationLogger = {}

-- Services
local players = game:GetService("Players")
local http_service = game:GetService("HttpService")
local run_service = game:GetService("RunService")

-- UI Elements
local ScreenGui = nil
local MainFrame = nil
local LogContainer = nil
local ButtonsContainer = nil
local AnimationList = {}
local BlacklistedAnimations = {}

-- Configuration
local config = {
    uiSize = UDim2.new(0, 600, 0, 400),
    uiPosition = UDim2.new(0.5, -300, 0.5, -200),
    backgroundColor = Color3.fromRGB(30, 30, 40),
    textColor = Color3.fromRGB(255, 255, 255),
    buttonColor = Color3.fromRGB(60, 60, 80),
    buttonHoverColor = Color3.fromRGB(80, 80, 100),
    accentColor = Color3.fromRGB(65, 175, 105),
    dangerColor = Color3.fromRGB(175, 65, 65),
    neutralColor = Color3.fromRGB(65, 105, 175),
    entryColor = Color3.fromRGB(40, 40, 55),
    maxLogs = 100,
    fontSize = 14,
    cornerRadius = UDim.new(0, 8),
    padding = UDim.new(0, 10),
    saveFileName = "AnimationBlacklist.json",
    configFolder = "animation_logger"
}

-- Initialize the UI Library
local function InitUILibrary()
    -- Create directory structure
    if not isfolder(config.configFolder) then
        makefolder(config.configFolder)
    end
    
    if not isfolder(config.configFolder .. "/fonts") then
        makefolder(config.configFolder .. "/fonts")
    end
    
    if not isfolder(config.configFolder .. "/configs") then
        makefolder(config.configFolder .. "/configs")
    end
    
    -- Download and save the font if it doesn't exist
    if not isfile(config.configFolder .. "/fonts/main.ttf") then
        writefile(config.configFolder .. "/fonts/main.ttf", game:HttpGet("https://github.com/f1nobe7650/other/raw/main/uis/font.ttf"))
    end
    
    -- Create font encoding
    local tahoma = {
        name = "SmallestPixel7",
        faces = {
            {
                name = "Regular",
                weight = 400,
                style = "normal",
                assetId = getcustomasset(config.configFolder .. "/fonts/main.ttf")
            }
        }
    }
    
    if not isfile(config.configFolder .. "/fonts/main_encoded.ttf") then
        writefile(config.configFolder .. "/fonts/main_encoded.ttf", http_service:JSONEncode(tahoma))
    end
    
    -- Load the font
    AnimationLogger.font = Font.new(getcustomasset(config.configFolder .. "/fonts/main_encoded.ttf"), Enum.FontWeight.Regular)
    
    return AnimationLogger.font
end

-- Initialize the UI
function AnimationLogger:Init()
    -- Initialize UI Library and font
    local font = InitUILibrary()
    
    -- Create ScreenGui
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AnimationLoggerGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Create main frame
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = config.uiSize
    MainFrame.Position = config.uiPosition
    MainFrame.BackgroundColor3 = config.backgroundColor
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui
    
    -- Add corner radius
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = config.cornerRadius
    UICorner.Parent = MainFrame
    
    -- Add drop shadow for modern look
    local DropShadow = Instance.new("ImageLabel")
    DropShadow.Name = "DropShadow"
    DropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
    DropShadow.BackgroundTransparency = 1
    DropShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    DropShadow.Size = UDim2.new(1, 40, 1, 40)
    DropShadow.ZIndex = 0
    DropShadow.Image = "rbxassetid://6014261993"
    DropShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    DropShadow.ImageTransparency = 0.5
    DropShadow.ScaleType = Enum.ScaleType.Slice
    DropShadow.SliceCenter = Rect.new(49, 49, 450, 450)
    DropShadow.Parent = MainFrame
    
    -- Add resize handle
    local ResizeHandle = Instance.new("TextButton")
    ResizeHandle.Name = "ResizeHandle"
    ResizeHandle.Size = UDim2.new(0, 18, 0, 18)
    ResizeHandle.Position = UDim2.new(1, -18, 1, -18)
    ResizeHandle.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
    ResizeHandle.Text = ""
    ResizeHandle.AutoButtonColor = false
    ResizeHandle.ZIndex = 10
    ResizeHandle.Parent = MainFrame
    
    local UICornerResize = Instance.new("UICorner")
    UICornerResize.CornerRadius = UDim.new(0, 3)
    UICornerResize.Parent = ResizeHandle
    
    -- Resize functionality with auto-width adjustment
    local resizing = false
    local startPos, startSize
    
    ResizeHandle.MouseButton1Down:Connect(function()
        resizing = true
        startPos = game:GetService("UserInputService"):GetMouseLocation()
        startSize = MainFrame.Size
    end)
    
    game:GetService("UserInputService").InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = false
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = game:GetService("UserInputService"):GetMouseLocation() - startPos
            local newSize = UDim2.new(
                startSize.X.Scale,
                math.max(400, startSize.X.Offset + delta.X),
                startSize.Y.Scale,
                math.max(250, startSize.Y.Offset + delta.Y)
            )
            MainFrame.Size = newSize
            
            -- Auto-adjust log container width
            if LogContainer then
                LogContainer.Size = UDim2.new(1, -20, 1, -50)
            end
        end
    end)
    
    -- Create title bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    
    local UICornerTitle = Instance.new("UICorner")
    UICornerTitle.CornerRadius = UDim.new(0, 8)
    UICornerTitle.Parent = TitleBar
    
    -- Create title
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(0, 150, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "Animation Logger"
    Title.TextColor3 = config.textColor
    Title.TextSize = 18
    Title.FontFace = font
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TitleBar
    
    -- Create credits
    local Credits = Instance.new("TextLabel")
    Credits.Name = "Credits"
    Credits.Size = UDim2.new(0, 100, 0, 20)
    Credits.Position = UDim2.new(0, 15, 1, -20)
    Credits.BackgroundTransparency = 1
    Credits.Text = "by vertb1"
    Credits.TextColor3 = Color3.fromRGB(150, 150, 150)
    Credits.TextSize = 12
    Credits.FontFace = font
    Credits.TextXAlignment = Enum.TextXAlignment.Left
    Credits.Parent = TitleBar
    
    -- Create top buttons
    local TopButtonsContainer = Instance.new("Frame")
    TopButtonsContainer.Name = "TopButtonsContainer"
    TopButtonsContainer.Size = UDim2.new(1, -180, 1, 0)
    TopButtonsContainer.Position = UDim2.new(0, 165, 0, 0)
    TopButtonsContainer.BackgroundTransparency = 1
    TopButtonsContainer.Parent = TitleBar
    
    local UIListLayoutTop = Instance.new("UIListLayout")
    UIListLayoutTop.FillDirection = Enum.FillDirection.Horizontal
    UIListLayoutTop.HorizontalAlignment = Enum.HorizontalAlignment.Left
    UIListLayoutTop.VerticalAlignment = Enum.VerticalAlignment.Center
    UIListLayoutTop.Padding = UDim.new(0, 15)
    UIListLayoutTop.Parent = TopButtonsContainer
    
    -- Log Local toggle (converted from button to toggle)
    local LogLocalContainer = Instance.new("Frame")
    LogLocalContainer.Name = "LogLocalContainer"
    LogLocalContainer.Size = UDim2.new(0, 110, 0, 30)
    LogLocalContainer.BackgroundTransparency = 1
    LogLocalContainer.Parent = TopButtonsContainer
    
    local LogLocalLabel = Instance.new("TextLabel")
    LogLocalLabel.Name = "LogLocalLabel"
    LogLocalLabel.Size = UDim2.new(0, 70, 1, 0)
    LogLocalLabel.BackgroundTransparency = 1
    LogLocalLabel.Text = "Log Local"
    LogLocalLabel.TextColor3 = config.textColor
    LogLocalLabel.TextSize = 14
    LogLocalLabel.FontFace = font
    LogLocalLabel.TextXAlignment = Enum.TextXAlignment.Left
    LogLocalLabel.Parent = LogLocalContainer
    
    local LogLocalToggle = Instance.new("Frame")
    LogLocalToggle.Name = "LogLocalToggle"
    LogLocalToggle.Size = UDim2.new(0, 40, 0, 20)
    LogLocalToggle.Position = UDim2.new(0, 70, 0.5, -10)
    LogLocalToggle.BackgroundColor3 = config.neutralColor
    LogLocalToggle.Parent = LogLocalContainer
    
    local UICornerLogToggle = Instance.new("UICorner")
    UICornerLogToggle.CornerRadius = UDim.new(1, 0)
    UICornerLogToggle.Parent = LogLocalToggle
    
    local LogToggleCircle = Instance.new("Frame")
    LogToggleCircle.Name = "ToggleCircle"
    LogToggleCircle.Size = UDim2.new(0, 16, 0, 16)
    LogToggleCircle.Position = UDim2.new(0, 2, 0.5, -8)
    LogToggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    LogToggleCircle.Parent = LogLocalToggle
    
    local UICornerLogCircle = Instance.new("UICorner")
    UICornerLogCircle.CornerRadius = UDim.new(1, 0)
    UICornerLogCircle.Parent = LogToggleCircle
    
    local logLocalEnabled = false
    local logLocalConnection = nil
    
    LogLocalToggle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            logLocalEnabled = not logLocalEnabled
            if logLocalEnabled then
                LogLocalToggle.BackgroundColor3 = config.accentColor
                LogToggleCircle.Position = UDim2.new(1, -18, 0.5, -8)
                
                -- Start logging local animations
                logLocalConnection = run_service.Heartbeat:Connect(function()
                    self:LogLocalAnimations()
                end)
            else
                LogLocalToggle.BackgroundColor3 = config.neutralColor
                LogToggleCircle.Position = UDim2.new(0, 2, 0.5, -8)
                
                -- Stop logging local animations
                if logLocalConnection then
                    logLocalConnection:Disconnect()
                    logLocalConnection = nil
                end
            end
        end
    end)
    
    -- Show All toggle (fixed positioning)
    local ShowAllContainer = Instance.new("Frame")
    ShowAllContainer.Name = "ShowAllContainer"
    ShowAllContainer.Size = UDim2.new(0, 110, 0, 30)
    ShowAllContainer.BackgroundTransparency = 1
    ShowAllContainer.Parent = TopButtonsContainer
    
    local ShowAllLabel = Instance.new("TextLabel")
    ShowAllLabel.Name = "ShowAllLabel"
    ShowAllLabel.Size = UDim2.new(0, 70, 1, 0)
    ShowAllLabel.BackgroundTransparency = 1
    ShowAllLabel.Text = "Show All"
    ShowAllLabel.TextColor3 = config.textColor
    ShowAllLabel.TextSize = 14
    ShowAllLabel.FontFace = font
    ShowAllLabel.TextXAlignment = Enum.TextXAlignment.Left
    ShowAllLabel.Parent = ShowAllContainer
    
    local ShowAllToggle = Instance.new("Frame")
    ShowAllToggle.Name = "ShowAllToggle"
    ShowAllToggle.Size = UDim2.new(0, 40, 0, 20)
    ShowAllToggle.Position = UDim2.new(0, 70, 0.5, -10) -- Fixed position
    ShowAllToggle.BackgroundColor3 = config.accentColor
    ShowAllToggle.Parent = ShowAllContainer
    
    local UICornerToggle = Instance.new("UICorner")
    UICornerToggle.CornerRadius = UDim.new(1, 0)
    UICornerToggle.Parent = ShowAllToggle
    
    local ToggleCircle = Instance.new("Frame")
    ToggleCircle.Name = "ToggleCircle"
    ToggleCircle.Size = UDim2.new(0, 16, 0, 16)
    ToggleCircle.Position = UDim2.new(1, -18, 0.5, -8)
    ToggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ToggleCircle.Parent = ShowAllToggle
    
    local UICornerCircle = Instance.new("UICorner")
    UICornerCircle.CornerRadius = UDim.new(1, 0)
    UICornerCircle.Parent = ToggleCircle
    
    local showAllEnabled = true
    
    ShowAllToggle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            showAllEnabled = not showAllEnabled
            if showAllEnabled then
                ShowAllToggle.BackgroundColor3 = config.accentColor
                ToggleCircle.Position = UDim2.new(1, -18, 0.5, -8)
            else
                ShowAllToggle.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
                ToggleCircle.Position = UDim2.new(0, 2, 0.5, -8)
            end
            -- Implement filtering logic here
            self:FilterLogs(showAllEnabled)
        end
    end)
    
    -- Create top buttons
    self:CreateTopButton("Export", config.neutralColor, function()
        self:ExportAnimations()
    end, TopButtonsContainer)
    
    self:CreateTopButton("Clear", config.neutralColor, function()
        self:ClearLogs()
    end, TopButtonsContainer)
    
    -- Close button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Size = UDim2.new(0, 30, 0, 30)
    CloseButton.Position = UDim2.new(1, -35, 0.5, -15)
    CloseButton.BackgroundTransparency = 1
    CloseButton.Text = "×"
    CloseButton.TextColor3 = config.textColor
    CloseButton.TextSize = 24
    CloseButton.FontFace = font
    CloseButton.Parent = TitleBar
    
    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui.Enabled = false
    end)
    
    -- Create log container with auto-width
    LogContainer = Instance.new("ScrollingFrame")
    LogContainer.Name = "LogContainer"
    LogContainer.Size = UDim2.new(1, -20, 1, -50)
    LogContainer.Position = UDim2.new(0, 10, 0, 45)
    LogContainer.BackgroundTransparency = 1
    LogContainer.BorderSizePixel = 0
    LogContainer.ScrollBarThickness = 4
    LogContainer.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
    LogContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    LogContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    LogContainer.Parent = MainFrame
    
    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Padding = UDim.new(0, 10)
    UIListLayout.Parent = LogContainer
    
    local UIPadding = Instance.new("UIPadding")
    UIPadding.PaddingLeft = UDim.new(0, 8)
    UIPadding.PaddingRight = UDim.new(0, 8)
    UIPadding.PaddingTop = UDim.new(0, 8)
    UIPadding.PaddingBottom = UDim.new(0, 8)
    UIPadding.Parent = LogContainer
    
    -- Add accent line
    local AccentLine = Instance.new("Frame")
    AccentLine.Name = "AccentLine"
    AccentLine.Size = UDim2.new(1, 0, 0, 2)
    AccentLine.Position = UDim2.new(0, 0, 0, 0)
    AccentLine.BackgroundColor3 = config.accentColor
    AccentLine.BorderSizePixel = 0
    AccentLine.Parent = MainFrame
    
    -- Add glow effect
    local Glow = Instance.new("ImageLabel")
    Glow.Name = "Glow"
    Glow.Size = UDim2.new(1, 40, 0, 42)
    Glow.Position = UDim2.new(0, -20, 0, -20)
    Glow.BackgroundTransparency = 1
    Glow.Image = "http://www.roblox.com/asset/?id=18245826428"
    Glow.ImageColor3 = config.accentColor
    Glow.ImageTransparency = 0.9
    Glow.ScaleType = Enum.ScaleType.Slice
    Glow.SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79))
    Glow.ZIndex = 2
    Glow.Parent = AccentLine
    
    -- Add to PlayerGui
    local player = players.LocalPlayer
    if player then
        ScreenGui.Parent = player.PlayerGui
    end
    
    -- Hook into animation events with the fixed method
    self:HookAnimations()
    
    return self
end

-- Create a top button
function AnimationLogger:CreateTopButton(text, color, callback, parent)
    local Button = Instance.new("TextButton")
    Button.Name = text .. "Button"
    Button.Size = UDim2.new(0, 80, 0, 26)
    Button.BackgroundColor3 = color
    Button.Text = text
    Button.TextColor3 = config.textColor
    Button.FontFace = self.font
    Button.TextSize = 14
    Button.Parent = parent
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 4)
    UICorner.Parent = Button
    
    -- Button hover effect
    Button.MouseEnter:Connect(function()
        Button.BackgroundColor3 = Color3.new(
            math.min(color.R * 1.1, 1),
            math.min(color.G * 1.1, 1),
            math.min(color.B * 1.1, 1)
        )
    end)
    
    Button.MouseLeave:Connect(function()
        Button.BackgroundColor3 = color
    end)
    
    Button.MouseButton1Click:Connect(callback)
    
    return Button
end

-- Create a button for animation entries
function AnimationLogger:CreateEntryButton(text, color, parent, position, callback)
    local Button = Instance.new("TextButton")
    Button.Name = text .. "Button"
    Button.Size = UDim2.new(0, 80, 0, 24)
    Button.Position = position
    Button.BackgroundColor3 = color
    Button.Text = text
    Button.TextColor3 = config.textColor
    Button.FontFace = self.font
    Button.TextSize = 12
    Button.Parent = parent
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 4)
    UICorner.Parent = Button
    
    -- Button hover effect
    Button.MouseEnter:Connect(function()
        Button.BackgroundColor3 = Color3.new(
            math.min(color.R * 1.1, 1),
            math.min(color.G * 1.1, 1),
            math.min(color.B * 1.1, 1)
        )
    end)
    
    Button.MouseLeave:Connect(function()
        Button.BackgroundColor3 = color
    end)
    
    Button.MouseButton1Click:Connect(callback)
    
    return Button
end

-- Filter logs based on Show All toggle
function AnimationLogger:FilterLogs(showAll)
    for _, child in pairs(LogContainer:GetChildren()) do
        if child:IsA("Frame") then
            -- Implement your filtering logic here
            -- For example, you might want to hide certain animations when showAll is false
            child.Visible = showAll
        end
    end
end

-- Log local animations with error handling
function AnimationLogger:LogLocalAnimations()
    local player = players.LocalPlayer
    if not player or not player.Character then return end
    
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end
    
    -- Use pcall to safely get animation tracks
    local success, tracks = pcall(function()
        return animator:GetPlayingAnimationTracks()
    end)
    
    if success and tracks then
        for _, track in pairs(tracks) do
            self:LogAnimation(track.Animation)
        end
    else
        -- Alternative method if GetPlayingAnimationTracks fails
        for _, instance in pairs(animator:GetChildren()) do
            if instance:IsA("AnimationTrack") then
                self:LogAnimation(instance.Animation)
            end
        end
    end
end

-- Log an animation
function AnimationLogger:LogAnimation(animation)
    if not animation or not animation.AnimationId then return end
    
    local animId = animation.AnimationId
    
    -- Check if animation is blacklisted
    if self:IsBlacklisted(animId) then return end
    
    -- Extract animation name from ID if possible
    local animName = "Unknown Animation"
    local success, result = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(tonumber(animId:match("%d+")))
    end)
    
    if success and result and result.Name then
        animName = result.Name
    else
        -- Try to extract a name from the URL
        local nameMatch = animId:match("/([^/]+)$")
        if nameMatch then
            animName = nameMatch:gsub("%d", ""):gsub("^%l", string.upper)
            if #animName < 3 then
                animName = "Animation " .. nameMatch
            end
        end
    end
    
    -- Add to animation list if not already present
    local alreadyLogged = false
    for _, entry in pairs(AnimationList) do
        if entry.id == animId then
            entry.count = entry.count + 1
            alreadyLogged = true
            
            -- Update count in UI if entry exists
            for _, child in pairs(LogContainer:GetChildren()) do
                if child:IsA("Frame") and child:FindFirstChild("AnimIdLabel") and child.AnimIdLabel.Text:find(animId, 1, true) then
                    local countLabel = child:FindFirstChild("CountLabel")
                    if countLabel then
                        countLabel.Text = "Seen: " .. entry.count .. "×"
                    end
                    return
                end
            end
            break
        end
    end
    
    if not alreadyLogged then
        table.insert(AnimationList, {id = animId, name = animName, count = 1})
    else
        return -- Don't create a new entry if already logged
    end
    
    -- Create log entry with modern styling
    local LogEntry = Instance.new("Frame")
    LogEntry.Name = "LogEntry"
    LogEntry.Size = UDim2.new(1, 0, 0, 80)
    LogEntry.BackgroundColor3 = config.entryColor
    LogEntry.BorderSizePixel = 0
    LogEntry.Parent = LogContainer
    
    -- Add subtle gradient for modern look
    local UIGradient = Instance.new("UIGradient")
    UIGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 45, 60)),
        ColorSequenceKeypoint.new(1, config.entryColor)
    })
    UIGradient.Rotation = 90
    UIGradient.Parent = LogEntry
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = LogEntry
    
    -- Add subtle stroke
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(60, 60, 80)
    UIStroke.Thickness = 1
    UIStroke.Transparency = 0.7
    UIStroke.Parent = LogEntry
    
    -- Count label
    local CountLabel = Instance.new("TextLabel")
    CountLabel.Name = "CountLabel"
    CountLabel.Size = UDim2.new(0, 100, 0, 20)
    CountLabel.Position = UDim2.new(0, 12, 0, 8)
    CountLabel.BackgroundTransparency = 1
    CountLabel.Text = "Seen: 1×"
    CountLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    CountLabel.FontFace = self.font
    CountLabel.TextSize = 12
    CountLabel.TextXAlignment = Enum.TextXAlignment.Left
    CountLabel.Parent = LogEntry
    
    -- Animation name
    local AnimNameLabel = Instance.new("TextLabel")
    AnimNameLabel.Name = "AnimNameLabel"
    AnimNameLabel.Size = UDim2.new(1, -24, 0, 20)
    AnimNameLabel.Position = UDim2.new(0, 12, 0, 28)
    AnimNameLabel.BackgroundTransparency = 1
    AnimNameLabel.Text = animName
    AnimNameLabel.TextColor3 = config.textColor
    AnimNameLabel.FontFace = self.font
    AnimNameLabel.TextSize = 16
    AnimNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    AnimNameLabel.Parent = LogEntry
    
    -- Animation ID
    local AnimIdLabel = Instance.new("TextLabel")
    AnimIdLabel.Name = "AnimIdLabel"
    AnimIdLabel.Size = UDim2.new(1, -24, 0, 20)
    AnimIdLabel.Position = UDim2.new(0, 12, 0, 48)
    AnimIdLabel.BackgroundTransparency = 1
    AnimIdLabel.Text = "ID: " .. animId
    AnimIdLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    AnimIdLabel.FontFace = self.font
    AnimIdLabel.TextSize = 12
    AnimIdLabel.TextXAlignment = Enum.TextXAlignment.Left
    AnimIdLabel.TextTruncate = Enum.TextTruncate.AtEnd
    AnimIdLabel.Parent = LogEntry
    
    -- Buttons container with auto-width adjustment
    local ButtonsRow = Instance.new("Frame")
    ButtonsRow.Name = "ButtonsRow"
    ButtonsRow.Size = UDim2.new(0, 270, 0, 30)
    ButtonsRow.Position = UDim2.new(1, -280, 0.5, -15)
    ButtonsRow.BackgroundTransparency = 1
    ButtonsRow.Parent = LogEntry
    
    -- Copy ID button
    self:CreateEntryButton("Copy ID", Color3.fromRGB(60, 60, 80), ButtonsRow, UDim2.new(0, 0, 0, 0), function()
        setclipboard(animId)
    end)
    
    -- Save Config button
    self:CreateEntryButton("Save Config", config.accentColor, ButtonsRow, UDim2.new(0, 90, 0, 0), function()
        self:SaveConfig(animId, animName)
    end)
    
    -- Blacklist button
    self:CreateEntryButton("Blacklist", config.dangerColor, ButtonsRow, UDim2.new(0, 180, 0, 0), function()
        self:BlacklistAnimation(animId)
        LogEntry:Destroy()
    end)
    
    -- Retry button with modern styling
    local RetryButton = self:CreateEntryButton("Retry", config.neutralColor, LogEntry, UDim2.new(0.5, -40, 1, -35), function()
        self:RetryAnimation(animId)
    end)
    
    -- Add hover effect to the entire entry
    LogEntry.MouseEnter:Connect(function()
        game:GetService("TweenService"):Create(LogEntry, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(50, 50, 65)
        }):Play()
    end)
    
    LogEntry.MouseLeave:Connect(function()
        game:GetService("TweenService"):Create(LogEntry, TweenInfo.new(0.2), {
            BackgroundColor3 = config.entryColor
        }):Play()
    end)
    
    -- Limit the number of logs
    if #LogContainer:GetChildren() > config.maxLogs + 2 then -- +2 for UIListLayout and UIPadding
        for _, child in pairs(LogContainer:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
                break
            end
        end
    end
end

-- Save animation config
function AnimationLogger:SaveConfig(animId, animName)
    local configData = {
        id = animId,
        name = animName,
        timestamp = os.time()
    }
    
    local fileName = config.configFolder .. "/configs/" .. animName:gsub("[^%w]", "_") .. ".json"
    
    local success, err = pcall(function()
        writefile(fileName, http_service:JSONEncode(configData))
    end)
    
    if not success then
        warn("Failed to save config: " .. tostring(err))
    end
end

-- Retry playing an animation
function AnimationLogger:RetryAnimation(animId)
    local player = players.LocalPlayer
    if not player or not player.Character then return end
    
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local animation = Instance.new("Animation")
    animation.AnimationId = animId
    
    local animTrack = humanoid:LoadAnimation(animation)
    animTrack:Play()
end

-- Hook into animation events with the fixed method
function AnimationLogger:HookAnimations()
    local player = players.LocalPlayer
    if not player then return end
    
    local function hookCharacter(character)
        if not character then return end
        
        local humanoid = character:WaitForChild("Humanoid", 5)
        if not humanoid then return end
        
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then return end
        
        -- Use a safer approach to monitor animations
        run_service.Heartbeat:Connect(function()
            if not animator or not animator.Parent then return end
            
            -- Try to get animation tracks safely
            local success, tracks = pcall(function()
                return animator:GetPlayingAnimationTracks()
            end)
            
            if success and tracks then
                for _, track in pairs(tracks) do
                    self:LogAnimation(track.Animation)
                end
            end
        end)
        
        -- Monitor animation playing
        humanoid.AnimationPlayed:Connect(function(animTrack)
            self:LogAnimation(animTrack.Animation)
        end)
    end
    
    -- Hook current character
    if player.Character then
        hookCharacter(player.Character)
    end
    
    -- Hook future characters
    player.CharacterAdded:Connect(hookCharacter)
end

-- Clear all logs
function AnimationLogger:ClearLogs()
    for _, child in pairs(LogContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    AnimationList = {}
end

-- Export animations
function AnimationLogger:ExportAnimations()
    local exportText = ""
    for _, anim in pairs(AnimationList) do
        exportText = exportText .. anim.name .. " - " .. anim.id .. "\n"
    end
    setclipboard(exportText)
end

-- Blacklist an animation
function AnimationLogger:BlacklistAnimation(animId)
    if not self:IsBlacklisted(animId) then
        table.insert(BlacklistedAnimations, animId)
        self:SaveBlacklist()
    end
end

-- Check if animation is blacklisted
function AnimationLogger:IsBlacklisted(animId)
    for _, id in pairs(BlacklistedAnimations) do
        if id == animId then
            return true
        end
    end
    return false
end

-- Save blacklist to file
function AnimationLogger:SaveBlacklist()
    local success, err = pcall(function()
        writefile(config.configFolder .. "/" .. config.saveFileName, http_service:JSONEncode(BlacklistedAnimations))
    end)
    
    if not success then
        warn("Failed to save blacklist: " .. tostring(err))
    end
end

-- Load blacklist from file
function AnimationLogger:LoadBlacklist()
    local success, content = pcall(function()
        return readfile(config.configFolder .. "/" .. config.saveFileName)
    end)
    
    if success then
        local decoded = http_service:JSONDecode(content)
        BlacklistedAnimations = decoded
    else
        warn("Failed to load blacklist")
    end
end

-- Toggle UI visibility
function AnimationLogger:ToggleVisibility()
    if ScreenGui then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
end

-- Set UI position
function AnimationLogger:SetPosition(position)
    if MainFrame then
        MainFrame.Position = position
    end
end

return AnimationLogger 
