local AnimationLogger = {}

-- UI Elements
local ScreenGui = nil
local MainFrame = nil
local LogContainer = nil
local ButtonsContainer = nil
local AnimationList = {}
local BlacklistedAnimations = {}

-- Configuration
local config = {
    uiSize = UDim2.new(0, 400, 0, 300),
    uiPosition = UDim2.new(0.5, -200, 0.5, -150),
    backgroundColor = Color3.fromRGB(40, 40, 40),
    textColor = Color3.fromRGB(255, 255, 255),
    buttonColor = Color3.fromRGB(60, 60, 60),
    buttonHoverColor = Color3.fromRGB(80, 80, 80),
    maxLogs = 100,
    fontSize = Enum.FontSize.Size14,
    font = Enum.Font.SourceSansBold,
    cornerRadius = UDim.new(0, 8),
    padding = UDim.new(0, 5),
    saveFileName = "AnimationBlacklist.json"
}

-- Initialize the UI
function AnimationLogger:Init()
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
    
    -- Create title
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 30)
    TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    
    local UICornerTitle = Instance.new("UICorner")
    UICornerTitle.CornerRadius = config.cornerRadius
    UICornerTitle.Parent = TitleBar
    
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, -30, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "Animation Logger"
    Title.TextColor3 = config.textColor
    Title.TextSize = 18
    Title.Font = config.font
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TitleBar
    
    -- Close button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Size = UDim2.new(0, 20, 0, 20)
    CloseButton.Position = UDim2.new(1, -25, 0, 5)
    CloseButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    CloseButton.Text = "X"
    CloseButton.TextColor3 = config.textColor
    CloseButton.Font = config.font
    CloseButton.TextSize = 14
    CloseButton.Parent = TitleBar
    
    local UICornerClose = Instance.new("UICorner")
    UICornerClose.CornerRadius = UDim.new(0, 4)
    UICornerClose.Parent = CloseButton
    
    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui.Enabled = false
    end)
    
    -- Create log container
    LogContainer = Instance.new("ScrollingFrame")
    LogContainer.Name = "LogContainer"
    LogContainer.Size = UDim2.new(1, -20, 1, -80)
    LogContainer.Position = UDim2.new(0, 10, 0, 40)
    LogContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    LogContainer.BorderSizePixel = 0
    LogContainer.ScrollBarThickness = 6
    LogContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    LogContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    LogContainer.Parent = MainFrame
    
    local UICornerLog = Instance.new("UICorner")
    UICornerLog.CornerRadius = UDim.new(0, 6)
    UICornerLog.Parent = LogContainer
    
    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Padding = config.padding
    UIListLayout.Parent = LogContainer
    
    local UIPadding = Instance.new("UIPadding")
    UIPadding.PaddingLeft = UDim.new(0, 5)
    UIPadding.PaddingRight = UDim.new(0, 5)
    UIPadding.PaddingTop = UDim.new(0, 5)
    UIPadding.PaddingBottom = UDim.new(0, 5)
    UIPadding.Parent = LogContainer
    
    -- Create buttons container
    ButtonsContainer = Instance.new("Frame")
    ButtonsContainer.Name = "ButtonsContainer"
    ButtonsContainer.Size = UDim2.new(1, -20, 0, 30)
    ButtonsContainer.Position = UDim2.new(0, 10, 1, -40)
    ButtonsContainer.BackgroundTransparency = 1
    ButtonsContainer.Parent = MainFrame
    
    local UIListLayoutButtons = Instance.new("UIListLayout")
    UIListLayoutButtons.FillDirection = Enum.FillDirection.Horizontal
    UIListLayoutButtons.Padding = UDim.new(0, 10)
    UIListLayoutButtons.Parent = ButtonsContainer
    
    -- Create buttons
    self:CreateButton("Clear", function()
        self:ClearLogs()
    end)
    
    self:CreateButton("Export", function()
        self:ExportAnimations()
    end)
    
    self:CreateButton("Save Blacklist", function()
        self:SaveBlacklist()
    end)
    
    self:CreateButton("Load Blacklist", function()
        self:LoadBlacklist()
    end)
    
    -- Add to PlayerGui
    local player = game.Players.LocalPlayer
    if player then
        ScreenGui.Parent = player.PlayerGui
    end
    
    -- Hook into animation events
    self:HookAnimations()
    
    return self
end

-- Create a button
function AnimationLogger:CreateButton(text, callback)
    local Button = Instance.new("TextButton")
    Button.Name = text .. "Button"
    Button.Size = UDim2.new(0, 90, 1, 0)
    Button.BackgroundColor3 = config.buttonColor
    Button.Text = text
    Button.TextColor3 = config.textColor
    Button.Font = config.font
    Button.TextSize = 14
    Button.Parent = ButtonsContainer
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 4)
    UICorner.Parent = Button
    
    -- Button hover effect
    Button.MouseEnter:Connect(function()
        Button.BackgroundColor3 = config.buttonHoverColor
    end)
    
    Button.MouseLeave:Connect(function()
        Button.BackgroundColor3 = config.buttonColor
    end)
    
    Button.MouseButton1Click:Connect(callback)
    
    return Button
end

-- Log an animation
function AnimationLogger:LogAnimation(animation)
    if not animation or not animation.AnimationId then return end
    
    local animId = animation.AnimationId
    
    -- Check if animation is blacklisted
    if self:IsBlacklisted(animId) then return end
    
    -- Add to animation list
    table.insert(AnimationList, animId)
    
    -- Create log entry
    local LogEntry = Instance.new("Frame")
    LogEntry.Name = "LogEntry"
    LogEntry.Size = UDim2.new(1, 0, 0, 30)
    LogEntry.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    LogEntry.BorderSizePixel = 0
    LogEntry.Parent = LogContainer
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 4)
    UICorner.Parent = LogEntry
    
    local AnimIdLabel = Instance.new("TextLabel")
    AnimIdLabel.Name = "AnimIdLabel"
    AnimIdLabel.Size = UDim2.new(1, -110, 1, 0)
    AnimIdLabel.Position = UDim2.new(0, 5, 0, 0)
    AnimIdLabel.BackgroundTransparency = 1
    AnimIdLabel.Text = animId
    AnimIdLabel.TextColor3 = config.textColor
    AnimIdLabel.Font = config.font
    AnimIdLabel.TextSize = 14
    AnimIdLabel.TextXAlignment = Enum.TextXAlignment.Left
    AnimIdLabel.TextTruncate = Enum.TextTruncate.AtEnd
    AnimIdLabel.Parent = LogEntry
    
    -- Copy button
    local CopyButton = Instance.new("TextButton")
    CopyButton.Name = "CopyButton"
    CopyButton.Size = UDim2.new(0, 50, 0, 20)
    CopyButton.Position = UDim2.new(1, -105, 0.5, -10)
    CopyButton.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
    CopyButton.Text = "Copy"
    CopyButton.TextColor3 = config.textColor
    CopyButton.Font = config.font
    CopyButton.TextSize = 12
    CopyButton.Parent = LogEntry
    
    local UICornerCopy = Instance.new("UICorner")
    UICornerCopy.CornerRadius = UDim.new(0, 4)
    UICornerCopy.Parent = CopyButton
    
    CopyButton.MouseButton1Click:Connect(function()
        setclipboard(animId)
    end)
    
    -- Blacklist button
    local BlacklistButton = Instance.new("TextButton")
    BlacklistButton.Name = "BlacklistButton"
    BlacklistButton.Size = UDim2.new(0, 50, 0, 20)
    BlacklistButton.Position = UDim2.new(1, -50, 0.5, -10)
    BlacklistButton.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
    BlacklistButton.Text = "Block"
    BlacklistButton.TextColor3 = config.textColor
    BlacklistButton.Font = config.font
    BlacklistButton.TextSize = 12
    BlacklistButton.Parent = LogEntry
    
    local UICornerBlacklist = Instance.new("UICorner")
    UICornerBlacklist.CornerRadius = UDim.new(0, 4)
    UICornerBlacklist.Parent = BlacklistButton
    
    BlacklistButton.MouseButton1Click:Connect(function()
        self:BlacklistAnimation(animId)
        LogEntry:Destroy()
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

-- Hook into animation events
function AnimationLogger:HookAnimations()
    local player = game.Players.LocalPlayer
    if not player then return end
    
    local function hookCharacter(character)
        if not character then return end
        
        local humanoid = character:WaitForChild("Humanoid", 5)
        if not humanoid then return end
        
        local animator = humanoid:WaitForChild("Animator", 5)
        if not animator then return end
        
        -- Hook into GetPlayingAnimationTracks
        local oldGetTracks = animator.GetPlayingAnimationTracks
        animator.GetPlayingAnimationTracks = function(...)
            local tracks = oldGetTracks(...)
            for _, track in pairs(tracks) do
                self:LogAnimation(track.Animation)
            end
            return tracks
        end
        
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
    local exportText = table.concat(AnimationList, "\n")
    setclipboard(exportText)
end

-- Blacklist an animation
function AnimationLogger:BlacklistAnimation(animId)
    if not self:IsBlacklisted(animId) then
        table.insert(BlacklistedAnimations, animId)
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
        writefile(config.saveFileName, game:GetService("HttpService"):JSONEncode(BlacklistedAnimations))
    end)
    
    if not success then
        warn("Failed to save blacklist: " .. tostring(err))
    end
end

-- Load blacklist from file
function AnimationLogger:LoadBlacklist()
    local success, content = pcall(function()
        return readfile(config.saveFileName)
    end)
    
    if success then
        local decoded = game:GetService("HttpService"):JSONDecode(content)
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
