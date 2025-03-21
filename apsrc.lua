-- Animation Logger UI Library
local AnimLogger = {}
AnimLogger.__index = AnimLogger

-- Define a local copy function
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

-- Safe I/O operations with fallbacks
local function safeFileExists(path)
    -- Check if io module is available
    if not io then
        return false
    end
    
    -- Try to open the file
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

local function safeWriteFile(path, content)
    -- Check if io module is available
    if not io then
        return false
    end
    
    -- Try to write to the file
    local file = io.open(path, "w")
    if file then
        file:write(content)
        file:close()
        return true
    end
    return false
end

local function safeReadFile(path)
    -- Check if io module is available
    if not io then
        return nil
    end
    
    -- Try to read the file
    local file = io.open(path, "r")
    if file then
        local content = file:read("*all")
        file:close()
        return content
    end
    return nil
end

-- Simplified directory handling that works in restricted environments
local function ensureLogDirectory()
    -- If we're in a restricted environment, just assume the directory exists
    if not io or not os then
        return true
    end
    
    -- Try to create a test file in the directory
    local success = pcall(function()
        local testFile = io.open(config.logFolder .. "/test.tmp", "w")
        if testFile then
            testFile:close()
            os.remove(config.logFolder .. "/test.tmp")
        end
    end)
    
    -- If that failed, try to create the directory
    if not success and os and os.execute then
        -- Different commands for different OS types
        local createDirCmd
        if package and package.config and package.config:sub(1,1) == '\\' then
            -- Windows
            createDirCmd = "mkdir \"" .. config.logFolder .. "\""
        else
            -- Unix-like
            createDirCmd = "mkdir -p \"" .. config.logFolder .. "\""
        end
        
        os.execute(createDirCmd)
        
        -- Verify the directory was created
        success = pcall(function() 
            local testFile = io.open(config.logFolder .. "/test.tmp", "w")
            if testFile then
                testFile:close()
                os.remove(config.logFolder .. "/test.tmp")
            end
        end)
    end
    
    return success
end

-- Save configuration to file (with fallbacks)
function AnimLogger.saveConfig()
    -- Skip file operations in restricted environments
    if not io then
        return false
    end
    
    if not ensureLogDirectory() then
        print("AnimLogger: Failed to create log directory")
        return false
    end
    
    local serialized
    
    -- Try JSON encoding first
    if pcall(function() require("json") end) then
        local json = require("json")
        serialized = json.encode(config)
    else
        -- Fallback to simple serialization
        serialized = "return {\n"
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
    end
    
    return safeWriteFile(config.logFolder .. "/config.json", serialized)
end

-- Load configuration from file (with fallbacks)
function AnimLogger.loadConfig()
    -- Skip file operations in restricted environments
    if not io then
        return false
    end
    
    local content = safeReadFile(config.logFolder .. "/config.json")
    if not content then
        AnimLogger.saveConfig()
        return false
    end
    
    local success = false
    
    -- Try JSON decoding first
    if pcall(function() require("json") end) then
        local json = require("json")
        local result = json.decode(content)
        if result then
            for k, v in pairs(result) do
                config[k] = v
            end
            success = true
        end
    end
    
    -- Fallback to Lua loader if JSON failed
    if not success and loadstring then
        local func = loadstring(content)
        if func then
            local loaded_config = func()
            for k, v in pairs(loaded_config) do
                config[k] = v
            end
            success = true
        end
    end
    
    -- If loading fails, save the default config
    if not success then
        AnimLogger.saveConfig()
    end
    
    return success
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
    ensureLogDirectory()
    
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
        timestamp = os.time and os.time() or 0,
        data = animData or {}
    }
    
    -- Add to history and trim if necessary
    table.insert(animationHistory, 1, entry)
    if #animationHistory > config.maxLogs then
        table.remove(animationHistory)
    end
    
    -- Write to log file if verbose logging is enabled
    if config.logLevel >= 3 and io then
        local logFile = io.open(config.logFolder .. "/animation_log.txt", "a")
        if logFile then
            local timeStr = os.date and os.date("%Y-%m-%d %H:%M:%S", entry.timestamp) or tostring(entry.timestamp)
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
    
    -- This is just a placeholder - actual implementation depends on your UI framework
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
