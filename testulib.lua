--[[
    UI Library
    A simple, modular UI library for creating game interfaces
    Inspired by the Matrix Cheats UI
]]

local UILib = {}
UILib.__index = UILib

-- Constants
local COLORS = {
    BACKGROUND = {20, 20, 20, 230},
    HEADER = {25, 25, 25, 255},
    ACCENT = {41, 128, 185, 255},
    TEXT = {255, 255, 255, 255},
    DISABLED = {100, 100, 100, 255},
    BUTTON = {35, 35, 35, 255},
    BUTTON_HOVER = {45, 45, 45, 255},
    CHECKBOX_BG = {35, 35, 35, 255},
    SLIDER_BG = {35, 35, 35, 255},
    SLIDER_FILL = {41, 128, 185, 255}
}

-- Utility functions
local function drawRect(x, y, width, height, color)
    -- Implementation depends on your rendering system
    -- This is a placeholder
end

local function drawText(text, x, y, size, color)
    -- Implementation depends on your rendering system
    -- This is a placeholder
end

-- Create a new UI window
function UILib.new(title, x, y, width, height)
    local self = setmetatable({}, UILib)
    
    self.title = title or "UI Window"
    self.x = x or 100
    self.y = y or 100
    self.width = width or 600
    self.height = height or 400
    self.visible = true
    self.dragging = false
    self.dragOffsetX = 0
    self.dragOffsetY = 0
    
    self.tabs = {}
    self.activeTab = nil
    self.elements = {}
    
    return self
end

-- Add a tab to the UI
function UILib:addTab(name)
    local tab = {
        name = name,
        elements = {}
    }
    
    table.insert(self.tabs, tab)
    
    if #self.tabs == 1 then
        self.activeTab = 1
    end
    
    return #self.tabs
end

-- Add a section to a tab
function UILib:addSection(tabIndex, name, x, y, width, height)
    if not self.tabs[tabIndex] then return nil end
    
    local section = {
        type = "section",
        name = name,
        x = x,
        y = y,
        width = width,
        height = height,
        elements = {}
    }
    
    table.insert(self.tabs[tabIndex].elements, section)
    return #self.tabs[tabIndex].elements
end

-- Add a checkbox element
function UILib:addCheckbox(tabIndex, sectionIndex, name, default)
    if not self.tabs[tabIndex] or not self.tabs[tabIndex].elements[sectionIndex] then return nil end
    
    local section = self.tabs[tabIndex].elements[sectionIndex]
    
    local checkbox = {
        type = "checkbox",
        name = name,
        value = default or false,
        callback = nil
    }
    
    table.insert(section.elements, checkbox)
    return checkbox
end

-- Add a slider element
function UILib:addSlider(tabIndex, sectionIndex, name, min, max, default, suffix)
    if not self.tabs[tabIndex] or not self.tabs[tabIndex].elements[sectionIndex] then return nil end
    
    local section = self.tabs[tabIndex].elements[sectionIndex]
    
    local slider = {
        type = "slider",
        name = name,
        min = min or 0,
        max = max or 100,
        value = default or min or 0,
        suffix = suffix or "%",
        callback = nil
    }
    
    table.insert(section.elements, slider)
    return slider
end

-- Add a button element
function UILib:addButton(tabIndex, sectionIndex, name, callback)
    if not self.tabs[tabIndex] or not self.tabs[tabIndex].elements[sectionIndex] then return nil end
    
    local section = self.tabs[tabIndex].elements[sectionIndex]
    
    local button = {
        type = "button",
        name = name,
        callback = callback
    }
    
    table.insert(section.elements, button)
    return button
end

-- Add a dropdown element
function UILib:addDropdown(tabIndex, sectionIndex, name, options, default)
    if not self.tabs[tabIndex] or not self.tabs[tabIndex].elements[sectionIndex] then return nil end
    
    local section = self.tabs[tabIndex].elements[sectionIndex]
    
    local dropdown = {
        type = "dropdown",
        name = name,
        options = options or {},
        value = default or (options and options[1] or ""),
        open = false,
        callback = nil
    }
    
    table.insert(section.elements, dropdown)
    return dropdown
end

-- Add a keybind element
function UILib:addKeybind(tabIndex, sectionIndex, name, default, callback)
    if not self.tabs[tabIndex] or not self.tabs[tabIndex].elements[sectionIndex] then return nil end
    
    local section = self.tabs[tabIndex].elements[sectionIndex]
    
    local keybind = {
        type = "keybind",
        name = name,
        key = default or "",
        listening = false,
        callback = callback
    }
    
    table.insert(section.elements, keybind)
    return keybind
end

-- Set callback for an element
function UILib:setCallback(element, callback)
    if element then
        element.callback = callback
    end
end

-- Handle mouse input
function UILib:handleMouse(mouseX, mouseY, mouseButton, isDown)
    if not self.visible then return end
    
    -- Handle window dragging
    if isDown and mouseButton == 1 then
        if mouseX >= self.x and mouseX <= self.x + self.width and
           mouseY >= self.y and mouseY <= self.y + 30 then
            self.dragging = true
            self.dragOffsetX = mouseX - self.x
            self.dragOffsetY = mouseY - self.y
        end
    else
        self.dragging = false
    end
    
    if self.dragging then
        self.x = mouseX - self.dragOffsetX
        self.y = mouseY - self.dragOffsetY
    end
    
    -- Handle tab selection
    local tabWidth = 100
    local tabHeight = 30
    local tabX = self.x
    
    for i, tab in ipairs(self.tabs) do
        if mouseX >= tabX and mouseX <= tabX + tabWidth and
           mouseY >= self.y + 30 and mouseY <= self.y + 30 + tabHeight and
           isDown and mouseButton == 1 then
            self.activeTab = i
        end
        
        tabX = tabX + tabWidth
    end
    
    -- Handle elements
    if self.activeTab and self.tabs[self.activeTab] then
        for _, section in ipairs(self.tabs[self.activeTab].elements) do
            if section.type == "section" then
                local sectionX = self.x + section.x
                local sectionY = self.y + section.y
                
                for i, element in ipairs(section.elements) do
                    local elementY = sectionY + 30 + (i - 1) * 30
                    
                    if element.type == "checkbox" then
                        local checkboxX = sectionX + section.width - 30
                        
                        if mouseX >= checkboxX and mouseX <= checkboxX + 20 and
                           mouseY >= elementY and mouseY <= elementY + 20 and
                           isDown and mouseButton == 1 then
                            element.value = not element.value
                            if element.callback then
                                element.callback(element.value)
                            end
                        end
                    elseif element.type == "slider" then
                        local sliderX = sectionX + 100
                        local sliderWidth = section.width - 120
                        
                        if mouseX >= sliderX and mouseX <= sliderX + sliderWidth and
                           mouseY >= elementY and mouseY <= elementY + 20 and
                           isDown and mouseButton == 1 then
                            local percentage = (mouseX - sliderX) / sliderWidth
                            element.value = element.min + (element.max - element.min) * percentage
                            if element.callback then
                                element.callback(element.value)
                            end
                        end
                    elseif element.type == "button" then
                        if mouseX >= sectionX + 10 and mouseX <= sectionX + section.width - 10 and
                           mouseY >= elementY and mouseY <= elementY + 25 and
                           isDown and mouseButton == 1 then
                            if element.callback then
                                element.callback()
                            end
                        end
                    elseif element.type == "keybind" then
                        local keybindX = sectionX + section.width - 50
                        
                        if mouseX >= keybindX and mouseX <= keybindX + 40 and
                           mouseY >= elementY and mouseY <= elementY + 20 and
                           isDown and mouseButton == 1 then
                            element.listening = true
                        end
                    end
                end
            end
        end
    end
end

-- Handle keyboard input
function UILib:handleKeyboard(key, isDown)
    if not self.visible then return end
    
    if self.activeTab and self.tabs[self.activeTab] then
        for _, section in ipairs(self.tabs[self.activeTab].elements) do
            if section.type == "section" then
                for _, element in ipairs(section.elements) do
                    if element.type == "keybind" and element.listening and isDown then
                        element.key = key
                        element.listening = false
                        if element.callback then
                            element.callback(key)
                        end
                    end
                end
            end
        end
    end
end

-- Draw the UI
function UILib:draw()
    if not self.visible then return end
    
    -- Draw window background
    drawRect(self.x, self.y, self.width, self.height, COLORS.BACKGROUND)
    
    -- Draw header
    drawRect(self.x, self.y, self.width, 30, COLORS.HEADER)
    drawText(self.title, self.x + 10, self.y + 8, 14, COLORS.TEXT)
    
    -- Draw tabs
    local tabWidth = 100
    local tabHeight = 30
    local tabX = self.x
    
    for i, tab in ipairs(self.tabs) do
        local tabColor = (self.activeTab == i) and COLORS.ACCENT or COLORS.BUTTON
        drawRect(tabX, self.y + 30, tabWidth, tabHeight, tabColor)
        drawText(tab.name, tabX + 10, self.y + 30 + 8, 12, COLORS.TEXT)
        tabX = tabX + tabWidth
    end
    
    -- Draw active tab content
    if self.activeTab and self.tabs[self.activeTab] then
        for _, section in ipairs(self.tabs[self.activeTab].elements) do
            if section.type == "section" then
                local sectionX = self.x + section.x
                local sectionY = self.y + section.y
                
                -- Draw section background
                drawRect(sectionX, sectionY, section.width, section.height, COLORS.BACKGROUND)
                
                -- Draw section header
                drawRect(sectionX, sectionY, section.width, 30, COLORS.HEADER)
                drawText(section.name, sectionX + 10, sectionY + 8, 12, COLORS.TEXT)
                
                -- Draw section elements
                for i, element in ipairs(section.elements) do
                    local elementY = sectionY + 30 + (i - 1) * 30
                    
                    if element.type == "checkbox" then
                        drawText(element.name, sectionX + 10, elementY + 5, 12, COLORS.TEXT)
                        
                        local checkboxX = sectionX + section.width - 30
                        drawRect(checkboxX, elementY, 20, 20, COLORS.CHECKBOX_BG)
                        
                        if element.value then
                            drawRect(checkboxX + 4, elementY + 4, 12, 12, COLORS.ACCENT)
                        end
                    elseif element.type == "slider" then
                        drawText(element.name, sectionX + 10, elementY - 15, 12, COLORS.TEXT)
                        
                        local sliderX = sectionX + 10
                        local sliderWidth = section.width - 20
                        
                        -- Draw slider background
                        drawRect(sliderX, elementY, sliderWidth, 10, COLORS.SLIDER_BG)
                        
                        -- Draw slider fill
                        local fillWidth = (element.value - element.min) / (element.max - element.min) * sliderWidth
                        drawRect(sliderX, elementY, fillWidth, 10, COLORS.SLIDER_FILL)
                        
                        -- Draw value text
                        local valueText = tostring(math.floor(element.value)) .. element.suffix
                        drawText(valueText, sliderX + sliderWidth - 40, elementY + 15, 12, COLORS.TEXT)
                    elseif element.type == "button" then
                        drawRect(sectionX + 10, elementY, section.width - 20, 25, COLORS.BUTTON)
                        drawText(element.name, sectionX + 20, elementY + 5, 12, COLORS.TEXT)
                    elseif element.type == "dropdown" then
                        drawText(element.name, sectionX + 10, elementY + 5, 12, COLORS.TEXT)
                        
                        local dropdownX = sectionX + section.width - 150
                        drawRect(dropdownX, elementY, 140, 20, COLORS.BUTTON)
                        drawText(element.value, dropdownX + 5, elementY + 3, 12, COLORS.TEXT)
                        
                        if element.open then
                            for j, option in ipairs(element.options) do
                                drawRect(dropdownX, elementY + 20 + (j-1) * 20, 140, 20, COLORS.BUTTON)
                                drawText(option, dropdownX + 5, elementY + 23 + (j-1) * 20, 12, COLORS.TEXT)
                            end
                        end
                    elseif element.type == "keybind" then
                        drawText(element.name, sectionX + 10, elementY + 5, 12, COLORS.TEXT)
                        
                        local keybindX = sectionX + section.width - 50
                        local keybindColor = element.listening and COLORS.ACCENT or COLORS.BUTTON
                        drawRect(keybindX, elementY, 40, 20, keybindColor)
                        drawText(element.key, keybindX + 15, elementY + 3, 12, COLORS.TEXT)
                    end
                end
            end
        end
    end
end

-- Toggle UI visibility
function UILib:toggle()
    self.visible = not self.visible
end

-- Set UI visibility
function UILib:setVisible(visible)
    self.visible = visible
end

return UILib 
