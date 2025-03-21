-- Animation Logger UI Library
local AnimLogger = {}
AnimLogger.__index = AnimLogger

-- Define a local copy function instead of modifying global table
local function copyTable(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[copyTable(orig_key)] = copyTable(orig_value)
        end
        setmetatable(copy, copyTable(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Default configuration
local default_config = {
    enabled = true,
    logLevel = 1, -- 1=minimal, 2=normal, 3=verbose
    blacklist = {},
    logFolder = "anim_logs",
    captureRate = 1, -- Log every N frames
    maxLogs = 100,
    displayUI = true,
    uiPosition = {x = 10, y = 10},
    uiSize = {width = 300, height = 200}
}

-- Local variables
local config = copyTable(default_config)
local frameCounter = 0
local animationHistory = {}
local initialized = false

-- Ensure the log directory exists
local function ensureLogDirectory()
    local success, err = pcall(function()
        local testFile = io.open(config.logFolder .. "/test.tmp", "w")
        if testFile then
            testFile:close()
            os.remove(config.logFolder .. "/test.tmp")
            return true
        end
        return false
    end)
    
    if not success then
        -- Attempt to create directory
        os.execute("mkdir " .. config.logFolder)
        -- Check if creation was successful
        local testFile = io.open(config.logFolder .. "/test.tmp", "w")
        if testFile then
            testFile:close()
            os.remove(config.logFolder .. "/test.tmp")
            return true
        end
        return false
    end
    
    return true
end

-- Save configuration to file
function AnimLogger.saveConfig()
    if not ensureLogDirectory() then
        print("AnimLogger: Failed to create log directory")
        return false
    end
    
    local configFile = io.open(config.logFolder .. "/config.json", "w")
    if configFile then
        local success, result = pcall(function()
            local json = require("json") -- Assuming JSON module is available
            return json.encode(config)
        end)
        
        if success then
            configFile:write(result)
            configFile:close()
            return true
        else
            -- Fallback to simple serialization if JSON module is not available
            local serialized = "return {\n"
            for k, v in pairs(config) do
                if type(v) == "string" then
                    serialized = serialized .. "  " .. k .. " = \"" .. v .. "\",\n"
                elseif type(v) == "table" then
                    if k == "blacklist" then
                        serialized = serialized .. "  " .. k .. " = {\n"
                        for _, item in ipairs(v) do
                            serialized = serialized .. "    \"" .. item .. "\",\n"
                        end
                        serialized = serialized .. "  },\n"
                    else
                        serialized = serialized .. "  " .. k .. " = { "
                        for tk, tv in pairs(v) do
                            serialized = serialized .. tk .. " = " .. tv .. ", "
                        end
                        serialized = serialized .. "},\n"
                    end
                else
                    serialized = serialized .. "  " .. k .. " = " .. tostring(v) .. ",\n"
                end
            end
            serialized = serialized .. "}"
            
            configFile:write(serialized)
            configFile:close()
            return true
        end
    end
    
    return false
end

-- Load configuration from file
function AnimLogger.loadConfig()
    local configFile = io.open(config.logFolder .. "/config.json", "r")
    if configFile then
        local content = configFile:read("*all")
        configFile:close()
        
        local success, result = pcall(function()
            local json = require("json") -- Assuming JSON module is available
            return json.decode(content)
        end)
        
        if success then
            for k, v in pairs(result) do
                config[k] = v
            end
            return true
        else
            -- Fallback to lua loader if JSON not available
            local func, err = loadstring(content)
            if func then
                local loaded_config = func()
                for k, v in pairs(loaded_config) do
                    config[k] = v
                end
                return true
            end
        end
    end
    
    -- If loading fails, save the default config
    AnimLogger.saveConfig()
    return false
end

-- Initialize the library
function AnimLogger.init(customConfig)
    if initialized then return end
    
    -- Apply custom configuration if provided
    if customConfig then
        for k, v in pairs(customConfig) do
            config[k] = v
        end
    end
    
    -- Create log directory if it doesn't exist
    if not ensureLogDirectory() then
        print("AnimLogger: Warning - Failed to create log directory")
    end
    
    -- Try to load existing configuration
    AnimLogger.loadConfig()
    
    initialized = true
    return config
end

-- Add an animation name to blacklist
function AnimLogger.addToBlacklist(animName)
    if not initialized then AnimLogger.init() end
    
    for _, name in ipairs(config.blacklist) do
        if name == animName then
            return false -- Already in blacklist
        end
    end
    
    table.insert(config.blacklist, animName)
    AnimLogger.saveConfig()
    return true
end

-- Remove an animation from blacklist
function AnimLogger.removeFromBlacklist(animName)
    if not initialized then AnimLogger.init() end
    
    for i, name in ipairs(config.blacklist) do
        if name == animName then
            table.remove(config.blacklist, i)
            AnimLogger.saveConfig()
            return true
        end
    end
    
    return false -- Not found in blacklist
end

-- Check if animation is blacklisted
function AnimLogger.isBlacklisted(animName)
    if not initialized then AnimLogger.init() end
    
    for _, name in ipairs(config.blacklist) do
        if name == animName then
            return true
        end
    end
    
    return false
end

-- Log an animation event
function AnimLogger.logAnimation(animName, animData)
    if not initialized then AnimLogger.init() end
    if not config.enabled then return end
    if AnimLogger.isBlacklisted(animName) then return end
    
    -- Only log at specified capture rate
    frameCounter = frameCounter + 1
    if frameCounter % config.captureRate ~= 0 then return end
    
    -- Create log entry
    local entry = {
        name = animName,
        timestamp = os.time(),
        data = animData or {}
    }
    
    -- Add to history and trim if necessary
    table.insert(animationHistory, 1, entry)
    if #animationHistory > config.maxLogs then
        table.remove(animationHistory)
    end
    
    -- Write to log file if verbose logging is enabled
    if config.logLevel >= 3 then
        local logFile = io.open(config.logFolder .. "/animation_log.txt", "a")
        if logFile then
            local timeStr = os.date("%Y-%m-%d %H:%M:%S", entry.timestamp)
            logFile:write(timeStr .. " - " .. animName .. "\n")
            logFile:close()
        end
    end
end

-- Get animation history
function AnimLogger.getHistory()
    if not initialized then AnimLogger.init() end
    return animationHistory
end

-- Clear history
function AnimLogger.clearHistory()
    animationHistory = {}
end

-- Render the UI
function AnimLogger.renderUI()
    if not initialized then AnimLogger.init() end
    if not config.displayUI then return end
    
    -- This is a placeholder for the actual UI rendering
    -- Implementation depends on the UI framework being used
    -- (e.g., Love2D, custom engine, etc.)
    
    -- Example implementation (pseudocode):
    --[[
    drawRect(config.uiPosition.x, config.uiPosition.y, config.uiSize.width, config.uiSize.height)
    drawText("Animation Logger", config.uiPosition.x + 5, config.uiPosition.y + 5)
    
    local y = config.uiPosition.y + 25
    for i = 1, math.min(10, #animationHistory) do
        local entry = animationHistory[i]
        drawText(entry.name, config.uiPosition.x + 5, y)
        y = y + 20
    end
    --]]
end

-- Update function (call this every frame)
function AnimLogger.update()
    if not initialized then AnimLogger.init() end
    if not config.enabled then return end
    
    -- Process queued logs or other background tasks here
end

-- Get configuration
function AnimLogger.getConfig()
    if not initialized then AnimLogger.init() end
    return config
end

-- Set configuration
function AnimLogger.setConfig(newConfig)
    if not initialized then AnimLogger.init() end
    
    for k, v in pairs(newConfig) do
        config[k] = v
    end
    
    AnimLogger.saveConfig()
    return config
end

-- Reset to default configuration
function AnimLogger.resetConfig()
    config = copyTable(default_config)
    AnimLogger.saveConfig()
    return config
end

return AnimLogger
