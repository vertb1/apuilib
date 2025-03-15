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
    uiSize = UDim2.new(0, 500, 0, 400),
    uiPosition = UDim2.new(0.5, -250, 0.5, -200),
    backgroundColor = Color3.fromRGB(30, 30, 40),
    textColor = Color3.fromRGB(255, 255, 255),
    buttonColor = Color3.fromRGB(60, 60, 80),
    buttonHoverColor = Color3.fromRGB(80, 80, 100),
    accentColor = Color3.fromRGB(65, 175, 105),
    dangerColor = Color3.fromRGB(175, 65, 65),
    neutralColor = Color3.fromRGB(65, 105, 175),
    entryColor = Color3.fromRGB(40, 40, 55),
    maxLogs = 100,
    fontSize = Enum.FontSize.Size14,
    font = Enum.Font.GothamMedium,
    cornerRadius = UDim.new(0, 6),
    padding = UDim.new(0, 8),
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
    
    -- Create title bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    
    local UICornerTitle = Instance.new("UICorner")
    UICornerTitle.CornerRadius = UDim.new(0, 6)
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
    Title.Font = config.font
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TitleBar
    
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
    UIListLayoutTop.Padding = UDim.new(0, 10)
    UIListLayoutTop.Parent = TopButtonsContainer
    
    -- Show All toggle
    local ShowAllContainer = Instance.new("Frame")
    ShowAllContainer.Name = "ShowAllContainer"
    ShowAllContainer.Size = UDim2.new(0, 100, 0, 30)
    ShowAllContainer.BackgroundTransparency = 1
    ShowAllContainer.Parent = TopButtonsContainer
    
    local ShowAllLabel = Instance.new("TextLabel")
    ShowAllLabel.Name = "ShowAllLabel"
    ShowAllLabel.Size = UDim2.new(0, 70, 1, 0)
    ShowAllLabel.BackgroundTransparency = 1
    ShowAllLabel.Text = "Show All"
    ShowAllLabel.TextColor3 = config.textColor
    ShowAllLabel.TextSize = 14
    ShowAllLabel.Font = config.font
    ShowAllLabel.TextXAlignment = Enum.TextXAlignment.Left
    ShowAllLabel.Parent = ShowAllContainer
    
    local ShowAllToggle = Instance.new("Frame")
    ShowAllToggle.Name = "ShowAllToggle"
    ShowAllToggle.Size = UDim2.new(0, 40, 0, 20)
    ShowAllToggle.Position = UDim2.new(1, -40, 0.5, -10)
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
        end
    end)
    
    -- Log Local button
    self:CreateTopButton("Log Local", config.neutralColor, function()
        -- Implement log local functionality
    end, TopButtonsContainer)
    
    -- Export button
    self:CreateTopButton("Export", config.neutralColor, function()
        self:ExportAnimations()
    end, TopButtonsContainer)
    
    -- Clear button
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
    CloseButton.Font = config.font
    CloseButton.Parent = TitleBar
    
    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui.Enabled = false
    end)
    
    -- Create log container
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
    UIListLayout.Padding = UDim.new(0, 8)
    UIListLayout.Parent = LogContainer
    
    local UIPadding = Instance.new("UIPadding")
    UIPadding.PaddingLeft = UDim.new(0, 5)
    UIPadding.PaddingRight = UDim.new(0, 5)
    UIPadding.PaddingTop = UDim.new(0, 5)
    UIPadding.PaddingBottom = UDim.new(0, 5)
    UIPadding.Parent = LogContainer
    
    -- Add to PlayerGui
    local player = game.Players.LocalPlayer
    if player then
        ScreenGui.Parent = player.PlayerGui
    end
    
    -- Hook into animation events
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
    Button.Font = config.font
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
    Button.Font = config.font
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
    
    -- Create log entry
    local LogEntry = Instance.new("Frame")
    LogEntry.Name = "LogEntry"
    LogEntry.Size = UDim2.new(1, 0, 0, 75)
    LogEntry.BackgroundColor3 = config.entryColor
    LogEntry.BorderSizePixel = 0
    LogEntry.Parent = LogContainer
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 6)
    UICorner.Parent = LogEntry
    
    -- Count label
    local CountLabel = Instance.new("TextLabel")
    CountLabel.Name = "CountLabel"
    CountLabel.Size = UDim2.new(0, 100, 0, 20)
    CountLabel.Position = UDim2.new(0, 10, 0, 5)
    CountLabel.BackgroundTransparency = 1
    CountLabel.Text = "Seen: 1×"
    CountLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    CountLabel.Font = config.font
    CountLabel.TextSize = 12
    CountLabel.TextXAlignment = Enum.TextXAlignment.Left
    CountLabel.Parent = LogEntry
    
    -- Animation name
    local AnimNameLabel = Instance.new("TextLabel")
    AnimNameLabel.Name = "AnimNameLabel"
    AnimNameLabel.Size = UDim2.new(1, -20, 0, 20)
    AnimNameLabel.Position = UDim2.new(0, 10, 0, 25)
    AnimNameLabel.BackgroundTransparency = 1
    AnimNameLabel.Text = animName
    AnimNameLabel.TextColor3 = config.textColor
    AnimNameLabel.Font = Enum.Font.GothamBold
    AnimNameLabel.TextSize = 16
    AnimNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    AnimNameLabel.Parent = LogEntry
    
    -- Animation ID
    local AnimIdLabel = Instance.new("TextLabel")
    AnimIdLabel.Name = "AnimIdLabel"
    AnimIdLabel.Size = UDim2.new(1, -20, 0, 20)
    AnimIdLabel.Position = UDim2.new(0, 10, 0, 45)
    AnimIdLabel.BackgroundTransparency = 1
    AnimIdLabel.Text = "ID: " .. animId
    AnimIdLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    AnimIdLabel.Font = config.font
    AnimIdLabel.TextSize = 12
    AnimIdLabel.TextXAlignment = Enum.TextXAlignment.Left
    AnimIdLabel.TextTruncate = Enum.TextTruncate.AtEnd
    AnimIdLabel.Parent = LogEntry
    
    -- Buttons container
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
        -- Implement save config functionality
    end)
    
    -- Blacklist button
    self:CreateEntryButton("Blacklist", config.dangerColor, ButtonsRow, UDim2.new(0, 180, 0, 0), function()
        self:BlacklistAnimation(animId)
        LogEntry:Destroy()
    end)
    
    -- Retry button
    self:CreateEntryButton("Retry", config.neutralColor, LogEntry, UDim2.new(0.5, -40, 1, -30), function()
        -- Implement retry functionality
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
