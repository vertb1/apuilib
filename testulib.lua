local AnimationLogger = {}
AnimationLogger.__index = AnimationLogger

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Constants
local LOCAL_PLAYER = Players.LocalPlayer
local FONT = Enum.Font.SourceSansBold
local TEXT_COLOR = Color3.fromRGB(255, 255, 255)
local BACKGROUND_COLOR = Color3.fromRGB(30, 30, 40)
local HEADER_COLOR = Color3.fromRGB(40, 40, 50)
local BUTTON_COLOR = Color3.fromRGB(60, 60, 70)
local BUTTON_HOVER_COLOR = Color3.fromRGB(70, 70, 80)
local SUCCESS_COLOR = Color3.fromRGB(45, 180, 45)
local HOVER_TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Animation name mapping
local ANIMATION_NAMES = {
    -- Common animation IDs mapped to better names
    ["rbxassetid://507767714"] = "Walk",
    ["rbxassetid://507767968"] = "Run",
    ["rbxassetid://507765000"] = "Idle",
    ["rbxassetid://507765644"] = "Fall",
    ["rbxassetid://507765476"] = "Jump",
    ["rbxassetid://2510198475"] = "Slash",
    ["rbxassetid://2467545061"] = "Swing",
    ["rbxassetid://2510197257"] = "Stab",
    ["rbxassetid://2510196951"] = "Block",
    ["rbxassetid://4087847850"] = "Parry",
    ["rbxassetid://3716468774"] = "Dodge",
    -- Add more mappings as needed
}

-- Parry tracking
local PARRY_ANIMATIONS = {
    ["rbxassetid://4087847850"] = true,  -- Common parry animation
    ["rbxassetid://2510196951"] = true,  -- Block animation (often used for parry)
    ["rbxassetid://3716468774"] = true   -- Another defensive animation
}
local attackTime = 0
local lastParryTime = 0
local bestParryTime = math.huge

function AnimationLogger.new()
    local self = setmetatable({}, AnimationLogger)
    
    self.Enabled = true
    self.LogLocal = true
    self.Logs = {}
    self.MaxLogs = 50
    self.UI = nil
    self.ParryFilterEnabled = false
    
    self:CreateUI()
    
    return self
end

function AnimationLogger:CreateUI()
    -- Create ScreenGui
    self.UI = Instance.new("ScreenGui")
    self.UI.Name = "AnimationLogger"
    self.UI.ResetOnSpawn = false
    self.UI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    if RunService:IsStudio() then
        self.UI.Parent = LOCAL_PLAYER:WaitForChild("PlayerGui")
    else
        pcall(function()
            self.UI.Parent = game:GetService("CoreGui")
        end)
        
        if not self.UI.Parent then
            self.UI.Parent = LOCAL_PLAYER:WaitForChild("PlayerGui")
        end
    end
    
    -- Create Main Frame (increased width from 400 to 550)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 550, 0, 300)
    mainFrame.Position = UDim2.new(0.5, -275, 0.5, -150)
    mainFrame.BackgroundColor3 = BACKGROUND_COLOR
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = self.UI
    
    -- Rounded corners
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 8)
    uiCorner.Parent = mainFrame
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = HEADER_COLOR
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 8)
    headerCorner.Parent = header
    
    -- Fix header corners
    local headerFix = Instance.new("Frame")
    headerFix.Name = "HeaderFix"
    headerFix.Size = UDim2.new(1, 0, 0.5, 0)
    headerFix.Position = UDim2.new(0, 0, 0.5, 0)
    headerFix.BackgroundColor3 = HEADER_COLOR
    headerFix.BorderSizePixel = 0
    headerFix.ZIndex = 0
    headerFix.Parent = header
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -100, 1, 0)
    title.BackgroundTransparency = 1
    title.Font = FONT
    title.Text = "Animation Logger"
    title.TextSize = 22
    title.TextColor3 = TEXT_COLOR
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Position = UDim2.new(0, 15, 0, 0)
    title.Parent = header
    
    -- Credits (moved to the left)
    local credits = Instance.new("TextLabel")
    credits.Name = "Credits"
    credits.Size = UDim2.new(0, 150, 0, 20)
    credits.Position = UDim2.new(0, 180, 0.5, -10) -- Changed position
    credits.BackgroundTransparency = 1
    credits.Font = FONT
    credits.Text = "by vertb1"
    credits.TextSize = 14
    credits.TextColor3 = Color3.fromRGB(200, 200, 200)
    credits.TextXAlignment = Enum.TextXAlignment.Left -- Changed alignment
    credits.Parent = header
    
    -- Close Button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
    closeButton.Text = "X"
    closeButton.TextSize = 18
    closeButton.Font = FONT
    closeButton.TextColor3 = TEXT_COLOR
    closeButton.Parent = header
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    -- Button hover effect
    closeButton.MouseEnter:Connect(function()
        TweenService:Create(closeButton, HOVER_TWEEN_INFO, {BackgroundColor3 = Color3.fromRGB(220, 70, 70)}):Play()
    end)
    
    closeButton.MouseLeave:Connect(function()
        TweenService:Create(closeButton, HOVER_TWEEN_INFO, {BackgroundColor3 = Color3.fromRGB(180, 60, 60)}):Play()
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        self.UI.Enabled = false
    end)
    
    -- Controls Frame
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Name = "Controls"
    controlsFrame.Size = UDim2.new(1, -20, 0, 40)
    controlsFrame.Position = UDim2.new(0, 10, 0, 50)
    controlsFrame.BackgroundTransparency = 1
    controlsFrame.Parent = mainFrame
    
    -- Toggle Log Local
    local logLocalLabel = Instance.new("TextLabel")
    logLocalLabel.Name = "LogLocalLabel"
    logLocalLabel.Size = UDim2.new(0, 80, 1, 0)
    logLocalLabel.BackgroundTransparency = 1
    logLocalLabel.Font = FONT
    logLocalLabel.Text = "Log Local"
    logLocalLabel.TextSize = 16
    logLocalLabel.TextColor3 = TEXT_COLOR
    logLocalLabel.TextXAlignment = Enum.TextXAlignment.Left
    logLocalLabel.Parent = controlsFrame
    
    -- Toggle Button
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Name = "ToggleFrame"
    toggleFrame.Size = UDim2.new(0, 50, 0, 26)
    toggleFrame.Position = UDim2.new(0, 90, 0.5, -13)
    toggleFrame.BackgroundColor3 = SUCCESS_COLOR
    toggleFrame.Parent = controlsFrame
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggleFrame
    
    local toggleButton = Instance.new("Frame")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 20, 0, 20)
    toggleButton.Position = UDim2.new(1, -23, 0.5, -10)
    toggleButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Parent = toggleFrame
    
    local toggleButtonCorner = Instance.new("UICorner")
    toggleButtonCorner.CornerRadius = UDim.new(1, 0)
    toggleButtonCorner.Parent = toggleButton
    
    -- Toggle Functionality
    toggleFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.LogLocal = not self.LogLocal
            
            -- Create smooth animation
            if self.LogLocal then
                TweenService:Create(toggleButton, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
                    {Position = UDim2.new(1, -23, 0.5, -10)}):Play()
                TweenService:Create(toggleFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
                    {BackgroundColor3 = SUCCESS_COLOR}):Play()
            else
                TweenService:Create(toggleButton, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
                    {Position = UDim2.new(0, 3, 0.5, -10)}):Play()
                TweenService:Create(toggleFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
                    {BackgroundColor3 = Color3.fromRGB(120, 120, 130)}):Play()
            end
        end
    end)
    
    -- Clear Button
    local clearButton = Instance.new("TextButton")
    clearButton.Name = "ClearButton"
    clearButton.Size = UDim2.new(0, 80, 0, 30)
    clearButton.Position = UDim2.new(1, -85, 0.5, -15)
    clearButton.BackgroundColor3 = BUTTON_COLOR
    clearButton.Text = "Clear"
    clearButton.TextSize = 16
    clearButton.Font = FONT
    clearButton.TextColor3 = TEXT_COLOR
    clearButton.Parent = controlsFrame
    
    local clearCorner = Instance.new("UICorner")
    clearCorner.CornerRadius = UDim.new(0, 6)
    clearCorner.Parent = clearButton
    
    -- Button hover effect
    clearButton.MouseEnter:Connect(function()
        TweenService:Create(clearButton, HOVER_TWEEN_INFO, {BackgroundColor3 = BUTTON_HOVER_COLOR}):Play()
    end)
    
    clearButton.MouseLeave:Connect(function()
        TweenService:Create(clearButton, HOVER_TWEEN_INFO, {BackgroundColor3 = BUTTON_COLOR}):Play()
    end)
    
    clearButton.MouseButton1Click:Connect(function()
        self:ClearLogs()
    end)
    
    -- Export Button
    local exportButton = Instance.new("TextButton")
    exportButton.Name = "ExportButton"
    exportButton.Size = UDim2.new(0, 80, 0, 30)
    exportButton.Position = UDim2.new(1, -170, 0.5, -15)
    exportButton.BackgroundColor3 = BUTTON_COLOR
    exportButton.Text = "Export"
    exportButton.TextSize = 16
    exportButton.Font = FONT
    exportButton.TextColor3 = TEXT_COLOR
    exportButton.Parent = controlsFrame
    
    local exportCorner = Instance.new("UICorner")
    exportCorner.CornerRadius = UDim.new(0, 6)
    exportCorner.Parent = exportButton
    
    -- Button hover effect
    exportButton.MouseEnter:Connect(function()
        TweenService:Create(exportButton, HOVER_TWEEN_INFO, {BackgroundColor3 = BUTTON_HOVER_COLOR}):Play()
    end)
    
    exportButton.MouseLeave:Connect(function()
        TweenService:Create(exportButton, HOVER_TWEEN_INFO, {BackgroundColor3 = BUTTON_COLOR}):Play()
    end)
    
    exportButton.MouseButton1Click:Connect(function()
        self:ExportLogs()
    end)
    
    -- Filter Toggle Label
    local filterLabel = Instance.new("TextLabel")
    filterLabel.Name = "FilterLabel"
    filterLabel.Size = UDim2.new(0, 80, 1, 0)
    filterLabel.Position = UDim2.new(0, 170, 0, 0)
    filterLabel.BackgroundTransparency = 1
    filterLabel.Font = FONT
    filterLabel.Text = "Show Parries Only"
    filterLabel.TextSize = 16
    filterLabel.TextColor3 = TEXT_COLOR
    filterLabel.TextXAlignment = Enum.TextXAlignment.Left
    filterLabel.Parent = controlsFrame
    
    -- Filter Toggle Button
    local filterFrame = Instance.new("Frame")
    filterFrame.Name = "FilterFrame"
    filterFrame.Size = UDim2.new(0, 50, 0, 26)
    filterFrame.Position = UDim2.new(0, 290, 0.5, -13)
    filterFrame.BackgroundColor3 = Color3.fromRGB(120, 120, 130) -- Start with off
    filterFrame.Parent = controlsFrame
    
    local filterCorner = Instance.new("UICorner")
    filterCorner.CornerRadius = UDim.new(1, 0)
    filterCorner.Parent = filterFrame
    
    local filterButton = Instance.new("Frame")
    filterButton.Name = "FilterButton"
    filterButton.Size = UDim2.new(0, 20, 0, 20)
    filterButton.Position = UDim2.new(0, 3, 0.5, -10) -- Start with off position
    filterButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    filterButton.Parent = filterFrame
    
    local filterButtonCorner = Instance.new("UICorner")
    filterButtonCorner.CornerRadius = UDim.new(1, 0)
    filterButtonCorner.Parent = filterButton
    
    -- Filter Toggle Functionality
    filterFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.ParryFilterEnabled = not self.ParryFilterEnabled
            
            -- Create smooth animation
            if self.ParryFilterEnabled then
                TweenService:Create(filterButton, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
                    {Position = UDim2.new(1, -23, 0.5, -10)}):Play()
                TweenService:Create(filterFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
                    {BackgroundColor3 = Color3.fromRGB(100, 150, 255)}):Play() -- Blue for parry filter
            else
                TweenService:Create(filterButton, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
                    {Position = UDim2.new(0, 3, 0.5, -10)}):Play()
                TweenService:Create(filterFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
                    {BackgroundColor3 = Color3.fromRGB(120, 120, 130)}):Play()
            end
            
            -- Apply filter
            self:ApplyFilter()
        end
    end)
    
    -- Logs Container
    local logsContainer = Instance.new("ScrollingFrame")
    logsContainer.Name = "LogsContainer"
    logsContainer.Size = UDim2.new(1, -20, 1, -100)
    logsContainer.Position = UDim2.new(0, 10, 0, 90)
    logsContainer.BackgroundTransparency = 0.9
    logsContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    logsContainer.BorderSizePixel = 0
    logsContainer.ScrollBarThickness = 6
    logsContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    logsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    logsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    logsContainer.Parent = mainFrame
    
    local logsContainerCorner = Instance.new("UICorner")
    logsContainerCorner.CornerRadius = UDim.new(0, 6)
    logsContainerCorner.Parent = logsContainer
    
    -- Log Entry Template
    local logEntryTemplate = Instance.new("Frame")
    logEntryTemplate.Name = "LogEntryTemplate"
    logEntryTemplate.Size = UDim2.new(1, -10, 0, 60)
    logEntryTemplate.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    logEntryTemplate.BorderSizePixel = 0
    logEntryTemplate.Visible = false
    logEntryTemplate.Parent = self.UI
    
    local logEntryCorner = Instance.new("UICorner")
    logEntryCorner.CornerRadius = UDim.new(0, 6)
    logEntryCorner.Parent = logEntryTemplate
    
    -- Entry Layout
    local entryLayout = Instance.new("UIListLayout")
    entryLayout.Name = "EntryLayout"
    entryLayout.Padding = UDim.new(0, 5)
    entryLayout.FillDirection = Enum.FillDirection.Vertical
    entryLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    entryLayout.SortOrder = Enum.SortOrder.LayoutOrder
    entryLayout.Parent = logsContainer
    
    -- Store references
    self.LogsContainer = logsContainer
    self.LogEntryTemplate = logEntryTemplate
    
    -- Logs Layout
    self.LogsListLayout = entryLayout
    
    -- Add resizable corner
    local resizeHandle = Instance.new("TextButton")
    resizeHandle.Name = "ResizeHandle"
    resizeHandle.Size = UDim2.new(0, 16, 0, 16)
    resizeHandle.Position = UDim2.new(1, -16, 1, -16)
    resizeHandle.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
    resizeHandle.Text = ""
    resizeHandle.AutoButtonColor = false
    resizeHandle.ZIndex = 10
    resizeHandle.Parent = mainFrame

    local resizeIcon = Instance.new("ImageLabel")
    resizeIcon.Name = "ResizeIcon"
    resizeIcon.Size = UDim2.new(1, 0, 1, 0)
    resizeIcon.BackgroundTransparency = 1
    resizeIcon.Image = "rbxassetid://6764432408"  -- A diagonal arrow icon
    resizeIcon.ImageColor3 = Color3.fromRGB(200, 200, 200)
    resizeIcon.Parent = resizeHandle

    local resizeHandleCorner = Instance.new("UICorner")
    resizeHandleCorner.CornerRadius = UDim.new(0, 3)
    resizeHandleCorner.Parent = resizeHandle

    -- Fix resizable corner functionality
    local isDragging = false
    local startSize = nil
    local startMousePos = nil

    resizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            startSize = mainFrame.Size
            startMousePos = UserInputService:GetMouseLocation()
            
            -- Change color to indicate active resize
            TweenService:Create(resizeHandle, TweenInfo.new(0.1), {
                BackgroundColor3 = Color3.fromRGB(120, 120, 150)
            }):Play()
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = UserInputService:GetMouseLocation() - startMousePos
            local newWidth = startSize.X.Offset + delta.X
            local newHeight = startSize.Y.Offset + delta.Y
            
            -- Use the UI layout update function
            self:UpdateUILayout(newWidth, newHeight)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if isDragging then
                isDragging = false
                
                -- Change color back
                TweenService:Create(resizeHandle, TweenInfo.new(0.1), {
                    BackgroundColor3 = Color3.fromRGB(80, 80, 90)
                }):Play()
            end
        end
    end)

    -- Add outer glow effect (appears outside the UI)
    local outerGlow = Instance.new("Frame")
    outerGlow.Name = "OuterGlow"
    outerGlow.Size = UDim2.new(1, 20, 1, 20)
    outerGlow.Position = UDim2.new(0, -10, 0, -10)
    outerGlow.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
    outerGlow.BorderSizePixel = 0
    outerGlow.ZIndex = -5 -- Make sure it's behind the main frame
    outerGlow.Parent = self.UI -- Parent to the ScreenGui directly, not the mainFrame

    -- Make sure it's positioned exactly like mainFrame but bigger
    local function updateGlowPosition()
        outerGlow.Position = UDim2.new(
            mainFrame.Position.X.Scale,
            mainFrame.Position.X.Offset - 10,
            mainFrame.Position.Y.Scale,
            mainFrame.Position.Y.Offset - 10
        )
        outerGlow.Size = UDim2.new(0, mainFrame.Size.X.Offset + 20, 0, mainFrame.Size.Y.Offset + 20)
    end
    updateGlowPosition()

    -- Update glow when mainFrame moves
    mainFrame:GetPropertyChangedSignal("Position"):Connect(updateGlowPosition)
    mainFrame:GetPropertyChangedSignal("Size"):Connect(updateGlowPosition)

    local outerGlowCorner = Instance.new("UICorner")
    outerGlowCorner.CornerRadius = UDim.new(0, 12)
    outerGlowCorner.Parent = outerGlow

    -- Add gradient effect to the glow
    local glowGradient = Instance.new("UIGradient")
    glowGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 90, 160)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 60))
    })
    glowGradient.Rotation = 45
    glowGradient.Parent = outerGlow

    return self.UI
end

function AnimationLogger:AddLog(animName, animId, parryTiming)
    if not self.Enabled then return end
    
    -- Create new log entry
    local newLog = self.LogEntryTemplate:Clone()
    newLog.Name = "LogEntry_" .. animName
    newLog.Visible = true
    newLog.LayoutOrder = #self.Logs + 1
    newLog.Parent = self.LogsContainer
    
    -- Animation Name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "AnimName"
    nameLabel.Size = UDim2.new(1, -20, 0, 20)
    nameLabel.Position = UDim2.new(0, 10, 0, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = FONT
    nameLabel.Text = animName
    nameLabel.TextSize = 18
    nameLabel.TextColor3 = TEXT_COLOR
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = newLog
    
    -- Animation ID
    local idLabel = Instance.new("TextLabel")
    idLabel.Name = "AnimID"
    idLabel.Size = UDim2.new(1, -20, 0, 16)
    idLabel.Position = UDim2.new(0, 10, 0, 25)
    idLabel.BackgroundTransparency = 1
    idLabel.Font = FONT
    idLabel.Text = "ID: " .. animId
    idLabel.TextSize = 14
    idLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    idLabel.TextXAlignment = Enum.TextXAlignment.Left
    idLabel.Parent = newLog
    
    -- Parry Timing
    local parryLabel = Instance.new("TextLabel")
    parryLabel.Name = "ParryTiming"
    parryLabel.Size = UDim2.new(0, 100, 0, 16)
    parryLabel.Position = UDim2.new(0, 10, 0, 41)
    parryLabel.BackgroundTransparency = 1
    parryLabel.Font = FONT
    parryLabel.Text = parryTiming and parryTiming or "No parry timing"
    parryLabel.TextSize = 14
    parryLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    parryLabel.TextXAlignment = Enum.TextXAlignment.Left
    parryLabel.Parent = newLog
    
    -- Seen Count
    local seenLabel = Instance.new("TextLabel")
    seenLabel.Name = "SeenCount"
    seenLabel.Size = UDim2.new(0, 60, 0, 16)
    seenLabel.Position = UDim2.new(1, -65, 0, 41)
    seenLabel.BackgroundTransparency = 1
    seenLabel.Font = FONT
    seenLabel.Text = "Seen: 1×"
    seenLabel.TextSize = 14
    seenLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    seenLabel.TextXAlignment = Enum.TextXAlignment.Right
    seenLabel.Parent = newLog
    
    -- Copy ID Button (moved left)
    local copyButton = Instance.new("TextButton")
    copyButton.Name = "CopyID"
    copyButton.Size = UDim2.new(0, 60, 0, 20)
    copyButton.Position = UDim2.new(1, -150, 0, 10) -- Changed from -130 to -150
    copyButton.BackgroundColor3 = BUTTON_COLOR
    copyButton.Text = "Copy ID"
    copyButton.TextSize = 12
    copyButton.Font = FONT
    copyButton.TextColor3 = TEXT_COLOR
    copyButton.Parent = newLog
    
    local copyCorner = Instance.new("UICorner")
    copyCorner.CornerRadius = UDim.new(0, 4)
    copyCorner.Parent = copyButton
    
    -- Button hover effect
    copyButton.MouseEnter:Connect(function()
        TweenService:Create(copyButton, HOVER_TWEEN_INFO, {BackgroundColor3 = BUTTON_HOVER_COLOR}):Play()
    end)
    
    copyButton.MouseLeave:Connect(function()
        TweenService:Create(copyButton, HOVER_TWEEN_INFO, {BackgroundColor3 = BUTTON_COLOR}):Play()
    end)
    
    copyButton.MouseButton1Click:Connect(function()
        setclipboard(animId)
        copyButton.Text = "Copied!"
        task.delay(1, function()
            copyButton.Text = "Copy ID"
        end)
    end)
    
    -- Save Config Button (green color)
    local saveButton = Instance.new("TextButton")
    saveButton.Name = "SaveConfig"
    saveButton.Size = UDim2.new(0, 80, 0, 20)
    saveButton.Position = UDim2.new(1, -85, 0, 10)
    saveButton.BackgroundColor3 = Color3.fromRGB(45, 180, 45) -- Green color
    saveButton.Text = "Save Config"
    saveButton.TextSize = 12
    saveButton.Font = FONT
    saveButton.TextColor3 = TEXT_COLOR
    saveButton.Parent = newLog

    local saveCorner = Instance.new("UICorner")
    saveCorner.CornerRadius = UDim.new(0, 4)
    saveCorner.Parent = saveButton

    -- Button hover effect (adjusted for green)
    saveButton.MouseEnter:Connect(function()
        TweenService:Create(saveButton, HOVER_TWEEN_INFO, {BackgroundColor3 = Color3.fromRGB(60, 210, 60)}):Play()
    end)

    saveButton.MouseLeave:Connect(function()
        TweenService:Create(saveButton, HOVER_TWEEN_INFO, {BackgroundColor3 = Color3.fromRGB(45, 180, 45)}):Play()
    end)
    
    -- Blacklist Button (moved under Copy ID)
    local blacklistButton = Instance.new("TextButton")
    blacklistButton.Name = "Blacklist"
    blacklistButton.Size = UDim2.new(0, 60, 0, 20)
    blacklistButton.Position = UDim2.new(1, -150, 0, 35) -- Repositioned under Copy ID
    blacklistButton.BackgroundColor3 = Color3.fromRGB(150, 60, 60)
    blacklistButton.Text = "Blacklist"
    blacklistButton.TextSize = 12 -- Smaller text size to match other buttons
    blacklistButton.Font = FONT
    blacklistButton.TextColor3 = TEXT_COLOR
    blacklistButton.Parent = newLog

    local blacklistCorner = Instance.new("UICorner")
    blacklistCorner.CornerRadius = UDim.new(0, 4)
    blacklistCorner.Parent = blacklistButton
    
    -- Store log data
    local logData = {
        Name = animName,
        ID = animId,
        ParryTiming = parryTiming,
        Element = newLog,
        SeenCount = 1
    }
    
    table.insert(self.Logs, logData)
    
    -- Limit logs count
    if #self.Logs > self.MaxLogs then
        local oldestLog = table.remove(self.Logs, 1)
        if oldestLog.Element and oldestLog.Element.Parent then
            oldestLog.Element:Destroy()
        end
    end
    
    if parryTiming then
        parryLabel.TextColor3 = Color3.fromRGB(50, 255, 50) -- Green for parry timing text
        newLog.BackgroundColor3 = Color3.fromRGB(60, 90, 60) -- Green tint for parry animations
    end
    
    -- And for animations that are likely parry animations themselves:
    if self:IsParryAnimation(animId) then
        newLog.BackgroundColor3 = Color3.fromRGB(60, 60, 90) -- Blue tint for parry-type animations
        
        local typeLabel = Instance.new("TextLabel")
        typeLabel.Name = "AnimType"
        typeLabel.Size = UDim2.new(0, 60, 0, 16)
        typeLabel.Position = UDim2.new(0, 110, 0, 41)
        typeLabel.BackgroundTransparency = 1
        typeLabel.Font = FONT
        typeLabel.Text = "Parry"
        typeLabel.TextSize = 14
        typeLabel.TextColor3 = Color3.fromRGB(100, 150, 255)
        typeLabel.TextXAlignment = Enum.TextXAlignment.Left
        typeLabel.Parent = newLog
    end
    
    -- Apply filter to the new log entry if necessary
    if self.ParryFilterEnabled then
        local isParryAnimation = self:IsParryAnimation(animId)
        local wasParried = parryTiming ~= nil
        newLog.Visible = isParryAnimation or wasParried
    end
    
    return logData
end

function AnimationLogger:GetBetterAnimationName(animationTrack)
    local animId = animationTrack.Animation.AnimationId
    local defaultName = animationTrack.Name
    
    -- First check known animation names
    if ANIMATION_NAMES[animId] then
        return ANIMATION_NAMES[animId]
    end
    
    -- Get animation name from properties if possible
    local success, result = pcall(function()
        if animationTrack.Animation and 
           typeof(animationTrack.Animation) == "Instance" and
           animationTrack.Animation:FindFirstChild("AnimationName") and 
           animationTrack.Animation.AnimationName.Value ~= "" then
            return animationTrack.Animation.AnimationName.Value
        end
        return nil
    end)
    
    if success and result then
        return result
    end
    
    -- Try to get info from the instance name
    if defaultName and defaultName ~= "Animation" and defaultName ~= "" then
        return defaultName
    end
    
    -- Try to get character and humanoid name
    local character = nil
    local playerName = ""
    
    -- Check parent chain for character model
    local parent = animationTrack.Parent
    while parent do
        if parent:IsA("Model") and parent:FindFirstChildOfClass("Humanoid") then
            character = parent
            break
        end
        parent = parent.Parent
    end
    
    -- Get animation type from ID patterns
    local animationType = "Unknown"
    local idNumber = animId:match("rbxassetid://(%d+)")
    
    -- Pattern matching for common animation types
    if idNumber then
        local numID = tonumber(idNumber)
        -- Check for patterns in the ID ranges that might indicate animation types
        if numID >= 507765000 and numID <= 507767999 then
            animationType = "Default"
        elseif numID >= 2510196000 and numID <= 2510199999 then
            animationType = "Combat"
        elseif numID >= 3716460000 and numID <= 3716469999 then
            animationType = "Special"
        elseif numID >= 4087840000 and numID <= 4087849999 then
            animationType = "Defensive"
        end
        
        -- Look for keywords in the ID description
        local success, animInfo = pcall(function()
            return game:GetService("MarketplaceService"):GetProductInfo(numID)
        end)
        
        if success and animInfo and animInfo.Description then
            local desc = animInfo.Description:lower()
            if desc:find("attack") or desc:find("slash") or desc:find("swing") then
                animationType = "Attack"
            elseif desc:find("parry") or desc:find("block") or desc:find("defend") then
                animationType = "Defense"
            elseif desc:find("dodge") or desc:find("roll") then
                animationType = "Evasion"
            end
            
            -- If we found a name in the description, use it
            local nameFromDesc = animInfo.Name
            if nameFromDesc and nameFromDesc ~= "" and nameFromDesc ~= "Animation" then
                return nameFromDesc
            end
        end
    end
    
    -- If all else fails, use the ID's last 6 digits
    if idNumber then
        return animationType .. " Animation (" .. idNumber:sub(-6) .. ")"
    end
    
    return "Animation " .. animId:sub(-6)
end

function AnimationLogger:IsParryAnimation(animId)
    -- Direct match for known parry animations
    if PARRY_ANIMATIONS[animId] then 
        return true 
    end
    
    -- Check ID or name for parry-related terms
    local success, animName = pcall(function()
        return self:GetBetterAnimationName({
            Animation = {
                AnimationId = animId,
                -- Add an empty function to avoid the FindFirstChild error
                FindFirstChild = function() return nil end
            }, 
            Name = "Animation"
        })
    end)
    
    if not success then
        return false
    end
    
    local parryTerms = {"parry", "block", "deflect", "counter"}
    
    for _, term in ipairs(parryTerms) do
        if animName:lower():find(term) then
            return true
        end
    end
    
    return false
end

function AnimationLogger:IsAttackAnimation(animId)
    local attackTerms = {"attack", "swing", "slash", "stab", "thrust", "strike"}
    
    local success, animName = pcall(function()
        return self:GetBetterAnimationName({
            Animation = {
                AnimationId = animId,
                -- Add an empty function to avoid the FindFirstChild error
                FindFirstChild = function() return nil end
            }, 
            Name = "Animation"
        })
    end)
    
    if not success then
        return false
    end
    
    for _, term in ipairs(attackTerms) do
        if animName:lower():find(term) then
            return true
        end
    end
    
    return false
end

function AnimationLogger:TrackParryTiming(animationTrack, character)
    local animId = animationTrack.Animation.AnimationId
    
    -- Track attack times
    if self:IsAttackAnimation(animId) and character ~= LOCAL_PLAYER.Character then
        attackTime = tick()
    end
    
    -- Track parry times 
    if self:IsParryAnimation(animId) and character == LOCAL_PLAYER.Character then
        lastParryTime = tick()
        local timeDiff = lastParryTime - attackTime
        
        -- Only count parries that happen shortly after an attack (0.1-1.5 seconds)
        if timeDiff > 0.1 and timeDiff < 1.5 then
            -- Update best parry time
            if timeDiff < bestParryTime then
                bestParryTime = timeDiff
            end
            
            -- Calculate milliseconds for display
            local currentMs = math.floor(timeDiff * 1000)
            local bestMs = math.floor(bestParryTime * 1000)
            
            -- Return formatted string with seconds and milliseconds
            return string.format("%.2fs (%dms) | Best: %.2fs (%dms)", 
                timeDiff, currentMs, bestParryTime, bestMs)
        end
    end
    
    return nil
end

function AnimationLogger:LogAnimation(character, animationTrack)
    if not self.Enabled or (not self.LogLocal and character == LOCAL_PLAYER.Character) then
        return
    end
    
    -- Don't log if character doesn't exist or isn't in workspace
    if not character or not character:IsDescendantOf(workspace) then
        return
    end
    
    -- Check proximity radius (only log animations within 50 studs)
    if character ~= LOCAL_PLAYER.Character and LOCAL_PLAYER.Character then
        local distance = (character:GetPivot().Position - LOCAL_PLAYER.Character:GetPivot().Position).Magnitude
        if distance > 50 then
            return -- Too far away, don't log
        end
    end
    
    -- Get animation info
    local animName = self:GetBetterAnimationName(animationTrack)
    local animId = animationTrack.Animation.AnimationId
    
    -- Track parry timing
    local parryTiming = self:TrackParryTiming(animationTrack, character)
    
    -- Check if this animation already exists
    for _, log in ipairs(self.Logs) do
        if log.ID == animId then
            log.SeenCount = log.SeenCount + 1
            
            -- Update parry timing if we have new information
            if parryTiming and (not log.ParryTiming or parryTiming:find("Best") ~= nil) then
                log.ParryTiming = parryTiming
                
                -- Update the UI
                if log.Element then
                    local parryLabel = log.Element:FindFirstChild("ParryTiming")
                    if parryLabel then
                        parryLabel.Text = parryTiming
                        parryLabel.TextColor3 = Color3.fromRGB(50, 255, 50) -- Green for successful parry
                    end
                    
                    -- Highlight the entry with a special color
                    log.Element.BackgroundColor3 = Color3.fromRGB(60, 90, 60) -- Green tint for parry animations
                end
            end
            
            -- Update seen count
            if log.Element then
                local seenLabel = log.Element:FindFirstChild("SeenCount")
                if seenLabel then
                    seenLabel.Text = "Seen: " .. log.SeenCount .. "×"
                end
            end
            
            return log
        end
    end
    
    -- Add new log with parry timing
    return self:AddLog(animName, animId, parryTiming)
end

function AnimationLogger:ClearLogs()
    for _, log in ipairs(self.Logs) do
        if log.Element and log.Element.Parent then
            log.Element:Destroy()
        end
    end
    
    self.Logs = {}
end

function AnimationLogger:ExportLogs()
    local exportString = "Animation Logs Export:\n\n"
    
    for i, log in ipairs(self.Logs) do
        exportString = exportString .. i .. ". " .. log.Name .. "\n"
        exportString = exportString .. "   ID: " .. log.ID .. "\n"
        if log.ParryTiming then
            exportString = exportString .. "   Parry Timing: " .. log.ParryTiming .. "\n"
        else
            exportString = exportString .. "   Parry Timing: None\n"
        end
        exportString = exportString .. "   Seen Count: " .. log.SeenCount .. "\n\n"
    end
    
    setclipboard(exportString)
    
    -- Create notification
    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.Size = UDim2.new(0, 200, 0, 50)
    notification.Position = UDim2.new(0.5, -100, 0, -60)
    notification.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    notification.BorderSizePixel = 0
    notification.Parent = self.UI
    
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 8)
    notifCorner.Parent = notification
    
    local notifText = Instance.new("TextLabel")
    notifText.Name = "NotifText"
    notifText.Size = UDim2.new(1, 0, 1, 0)
    notifText.BackgroundTransparency = 1
    notifText.Font = FONT
    notifText.Text = "Logs exported to clipboard!"
    notifText.TextSize = 16
    notifText.TextColor3 = TEXT_COLOR
    notifText.Parent = notification
    
    -- Animate notification
    notification:TweenPosition(UDim2.new(0.5, -100, 0, 20), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.5, true)
    
    task.delay(3, function()
        notification:TweenPosition(UDim2.new(0.5, -100, 0, -60), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.5, true, function()
            notification:Destroy()
        end)
    end)
end

function AnimationLogger:SetVisible(visible)
    if self.UI then
        self.UI.Enabled = visible
    end
end

function AnimationLogger:ToggleVisibility()
    if self.UI then
        self.UI.Enabled = not self.UI.Enabled
    end
end

-- Enhanced tracking function (replace your existing StartTracking function)
function AnimationLogger:StartTracking()
    local function trackCharacter(character)
        if not character then return end
        
        -- Wait for humanoid
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then
            humanoid = character:WaitForChild("Humanoid", 2)
            if not humanoid then return end
        end
        
        -- Track new animations being played
        humanoid.AnimationPlayed:Connect(function(animTrack)
            self:LogAnimation(character, animTrack)
        end)
        
        -- Only check existing animations on our own character
        if character == LOCAL_PLAYER.Character then
            task.delay(1, function() -- Delay to ensure animations are loaded
                for _, animator in pairs(character:GetDescendants()) do
                    if animator:IsA("Animator") then
                        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                            self:LogAnimation(character, track)
                        end
                    end
                end
            end)
        end
    end
    
    -- Track current player character
    if LOCAL_PLAYER.Character then
        trackCharacter(LOCAL_PLAYER.Character)
    end
    
    -- Track future player characters
    LOCAL_PLAYER.CharacterAdded:Connect(trackCharacter)
    
    -- Track nearby player characters only
    local function refreshNearbyPlayers()
        if not LOCAL_PLAYER.Character then return end
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LOCAL_PLAYER and player.Character then
                local distance = (player.Character:GetPivot().Position - LOCAL_PLAYER.Character:GetPivot().Position).Magnitude
                if distance <= 50 then -- 50 studs proximity
                    trackCharacter(player.Character)
                end
            end
        end
    end
    
    -- Initial tracking and periodic refresh
    refreshNearbyPlayers()
    task.spawn(function()
        while true do
            task.wait(5) -- Check every 5 seconds
            refreshNearbyPlayers()
        end
    end)
    
    -- Track new players when they join
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(char)
            if LOCAL_PLAYER.Character then
                task.wait(1) -- Wait for character to load
                local distance = (char:GetPivot().Position - LOCAL_PLAYER.Character:GetPivot().Position).Magnitude
                if distance <= 50 then
                    trackCharacter(char)
                end
            end
        end)
    end)
end

-- Create and initialize the logger
local logger = AnimationLogger.new()
logger:SetVisible(true)
logger:StartTracking()

-- Hotkey to toggle visibility
game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.P then
        logger:ToggleVisibility()
    end
end)

print("Animation Logger loaded successfully! Press P to toggle visibility")

function AnimationLogger:ApplyFilter()
    -- Skip if no logs
    if #self.Logs == 0 then return end
    
    for _, log in ipairs(self.Logs) do
        if log.Element then
            if self.ParryFilterEnabled then
                -- When filter is on, only show parry animations and animations that were parried
                local isParryAnimation = self:IsParryAnimation(log.ID)
                local wasParried = log.ParryTiming ~= nil
                
                log.Element.Visible = isParryAnimation or wasParried
            else
                -- Show all when filter is off
                log.Element.Visible = true
            end
        end
    end
end

-- Add this function to update UI elements when resizing
function AnimationLogger:UpdateUILayout(newWidth, newHeight)
    -- Minimum sizes to prevent elements from overlapping
    newWidth = math.max(550, newWidth)  -- Increased minimum width
    newHeight = math.max(300, newHeight)
    
    -- Update main frame size
    mainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
    
    -- Adjust logs container size based on new frame size
    self.LogsContainer.Size = UDim2.new(1, -20, 1, -100)
    
    -- Make sure the resizeHandle stays in the bottom right corner
    resizeHandle.Position = UDim2.new(1, -16, 1, -16)
    
    -- Update outer glow
    if outerGlow then
        outerGlow.Size = UDim2.new(0, newWidth + 20, 0, newHeight + 20)
        outerGlow.Position = UDim2.new(
            mainFrame.Position.X.Scale,
            mainFrame.Position.X.Offset - 10,
            mainFrame.Position.Y.Scale,
            mainFrame.Position.Y.Offset - 10
        )
    end
end
