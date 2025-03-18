--[[
    Animation Logger UI Library
    Created by vertb1
    
    A simple UI library for logging animation data with toggle for local logging
]]

local AnimationLogger = {}
AnimationLogger.__index = AnimationLogger

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

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

function AnimationLogger.new()
    local self = setmetatable({}, AnimationLogger)
    
    self.Enabled = true
    self.LogLocal = true
    self.Logs = {}
    self.MaxLogs = 50
    self.UI = nil
    
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
        self.UI.Parent = game:GetService("CoreGui")
    end
    
    -- Create Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 400, 0, 300)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
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
    
    -- Credits
    local credits = Instance.new("TextLabel")
    credits.Name = "Credits"
    credits.Size = UDim2.new(0, 100, 0, 20)
    credits.Position = UDim2.new(1, -110, 0.5, -10)
    credits.BackgroundTransparency = 1
    credits.Font = FONT
    credits.Text = "by vertb1"
    credits.TextSize = 14
    credits.TextColor3 = Color3.fromRGB(200, 200, 200)
    credits.TextXAlignment = Enum.TextXAlignment.Right
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
            if self.LogLocal then
                toggleButton.Position = UDim2.new(1, -23, 0.5, -10)
                toggleFrame.BackgroundColor3 = SUCCESS_COLOR
            else
                toggleButton.Position = UDim2.new(0, 3, 0.5, -10)
                toggleFrame.BackgroundColor3 = Color3.fromRGB(120, 120, 130)
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
    
    -- Copy ID Button
    local copyButton = Instance.new("TextButton")
    copyButton.Name = "CopyID"
    copyButton.Size = UDim2.new(0, 60, 0, 20)
    copyButton.Position = UDim2.new(1, -130, 0, 10)
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
    
    -- Save Config Button
    local saveButton = Instance.new("TextButton")
    saveButton.Name = "SaveConfig"
    saveButton.Size = UDim2.new(0, 80, 0, 20)
    saveButton.Position = UDim2.new(1, -65, 0, 10)
    saveButton.BackgroundColor3 = BUTTON_COLOR
    saveButton.Text = "Save Config"
    saveButton.TextSize = 12
    saveButton.Font = FONT
    saveButton.TextColor3 = TEXT_COLOR
    saveButton.Parent = newLog
    
    local saveCorner = Instance.new("UICorner")
    saveCorner.CornerRadius = UDim.new(0, 4)
    saveCorner.Parent = saveButton
    
    -- Button hover effect
    saveButton.MouseEnter:Connect(function()
        TweenService:Create(saveButton, HOVER_TWEEN_INFO, {BackgroundColor3 = BUTTON_HOVER_COLOR}):Play()
    end)
    
    saveButton.MouseLeave:Connect(function()
        TweenService:Create(saveButton, HOVER_TWEEN_INFO, {BackgroundColor3 = BUTTON_COLOR}):Play()
    end)
    
    -- Retry Button
    local retryButton = Instance.new("TextButton")
    retryButton.Name = "Retry"
    retryButton.Size = UDim2.new(0, 60, 0, 20)
    retryButton.Position = UDim2.new(0.5, -30, 1, -25)
    retryButton.BackgroundColor3 = Color3.fromRGB(50, 100, 170)
    retryButton.Text = "Retry"
    retryButton.TextSize = 14
    retryButton.Font = FONT
    retryButton.TextColor3 = TEXT_COLOR
    retryButton.Parent = newLog
    
    local retryCorner = Instance.new("UICorner")
    retryCorner.CornerRadius = UDim.new(0, 4)
    retryCorner.Parent = retryButton
    
    -- Blacklist Button
    local blacklistButton = Instance.new("TextButton")
    blacklistButton.Name = "Blacklist"
    blacklistButton.Size = UDim2.new(0, 70, 0, 20)
    blacklistButton.Position = UDim2.new(1, -75, 1, -25)
    blacklistButton.BackgroundColor3 = Color3.fromRGB(150, 60, 60)
    blacklistButton.Text = "Blacklist"
    blacklistButton.TextSize = 14
    blacklistButton.Font = FONT
    blacklistButton.TextColor3 = TEXT_COLOR
    blacklistButton.Parent = newLog
    
    local blacklistCorner = Instance.new("UICorner")
    blacklistCorner.CornerRadius = UDim.new(0, 4)
    blacklistCorner.Parent = blacklistButton
    
    -- Button hover effects
    retryButton.MouseEnter:Connect(function()
        TweenService:Create(retryButton, HOVER_TWEEN_INFO, {BackgroundColor3 = Color3.fromRGB(60, 120, 200)}):Play()
    end)
    
    retryButton.MouseLeave:Connect(function()
        TweenService:Create(retryButton, HOVER_TWEEN_INFO, {BackgroundColor3 = Color3.fromRGB(50, 100, 170)}):Play()
    end)
    
    blacklistButton.MouseEnter:Connect(function()
        TweenService:Create(blacklistButton, HOVER_TWEEN_INFO, {BackgroundColor3 = Color3.fromRGB(180, 70, 70)}):Play()
    end)
    
    blacklistButton.MouseLeave:Connect(function()
        TweenService:Create(blacklistButton, HOVER_TWEEN_INFO, {BackgroundColor3 = Color3.fromRGB(150, 60, 60)}):Play()
    end)
    
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
    
    return logData
end

function AnimationLogger:LogAnimation(character, animationTrack)
    if not self.Enabled or (not self.LogLocal and character == LOCAL_PLAYER.Character) then
        return
    end
    
    local animName = animationTrack.Name
    local animId = animationTrack.Animation.AnimationId
    
    -- Check if this animation already exists
    for _, log in ipairs(self.Logs) do
        if log.ID == animId then
            log.SeenCount = log.SeenCount + 1
            if log.Element then
                local seenLabel = log.Element:FindFirstChild("SeenCount")
                if seenLabel then
                    seenLabel.Text = "Seen: " .. log.SeenCount .. "×"
                end
            end
            return log
        end
    end
    
    -- Add new log
    return self:AddLog(animName, animId)
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

-- Listen for animations
function AnimationLogger:StartTracking()
    local function trackCharacter(character)
        local humanoid = character:WaitForChild("Humanoid")
        
        humanoid.AnimationPlayed:Connect(function(animTrack)
            self:LogAnimation(character, animTrack)
        end)
    end
    
    -- Track current player character
    if LOCAL_PLAYER.Character then
        trackCharacter(LOCAL_PLAYER.Character)
    end
    
    -- Track future player characters
    LOCAL_PLAYER.CharacterAdded:Connect(trackCharacter)
    
    -- Track other characters
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LOCAL_PLAYER and player.Character then
            trackCharacter(player.Character)
        end
    end
    
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(trackCharacter)
    end)
end

return AnimationLogger 
