local addonName, ns = ... 
local L = ns.L

-- ====================================================================
-- HELPER FUNCTIONS
-- ====================================================================
-- Generates a unique key for the current location using Zone and Sub-zone names.
local function GetZoneKey()
    return GetZoneText() .. " - " .. GetMinimapZoneText()
end

-- ====================================================================
-- SOUND MANAGEMENT (IMMERSIVE FISHING)
-- ====================================================================
-- Toggles game sounds to highlight the fishing bobber splash.
-- Mutes music/ambience and boosts SFX/Master volume when a pole is equipped.
local function AdjustSounds(enable)
    if not FF_SETTINGS or not FF_SETTINGS.perfectSound then return end
    if not FF_SETTINGS.originalSounds then FF_SETTINGS.originalSounds = {} end
    
    if enable then
        -- Store current user settings before modifying them
        if not FF_SETTINGS.isSoundAdjusted then
            FF_SETTINGS.originalSounds.music = GetCVar("Sound_EnableMusic")
            FF_SETTINGS.originalSounds.musicVol = GetCVar("Sound_MusicVolume")
            FF_SETTINGS.originalSounds.ambience = GetCVar("Sound_EnableAmbience")
            FF_SETTINGS.originalSounds.ambienceVol = GetCVar("Sound_AmbienceVolume")
            FF_SETTINGS.originalSounds.sfx = GetCVar("Sound_SFXVolume")
            FF_SETTINGS.originalSounds.master = GetCVar("Sound_MasterVolume")
            
            -- Set immersive fishing levels
            SetCVar("Sound_EnableMusic", 0)
            SetCVar("Sound_EnableAmbience", 0)
            SetCVar("Sound_SFXVolume", 1.0)
            SetCVar("Sound_MasterVolume", 1.0)
            FF_SETTINGS.isSoundAdjusted = true
        end
    else
        -- Restore original user settings
        if FF_SETTINGS.isSoundAdjusted then
            local o = FF_SETTINGS.originalSounds
            if o and o.music ~= nil then
                SetCVar("Sound_EnableMusic", o.music)
                SetCVar("Sound_MusicVolume", o.musicVol)
                SetCVar("Sound_EnableAmbience", o.ambience)
                SetCVar("Sound_AmbienceVolume", o.ambienceVol)
                SetCVar("Sound_SFXVolume", o.sfx)
                SetCVar("Sound_MasterVolume", o.master)
            end
            FF_SETTINGS.isSoundAdjusted = false
            FF_SETTINGS.originalSounds = {}
        end
    end
end

-- ====================================================================
-- TRACKER UI SETUP (ON-SCREEN DISPLAY)
-- ====================================================================
-- Create the main tracker frame
local Tracker = CreateFrame("Frame", "FF_Tracker", UIParent)
Tracker:SetSize(150, 50)
Tracker:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 250, -250)
Tracker:SetMovable(true); Tracker:EnableMouse(true); Tracker:RegisterForDrag("LeftButton")
Tracker:SetClampedToScreen(true)

-- Background texture
Tracker.bg = Tracker:CreateTexture(nil, "BACKGROUND"); 
Tracker.bg:SetTexture(0, 0, 0, 0.15); 
Tracker.bg:SetPoint("TOPLEFT", Tracker, "TOPLEFT", 0, 0)

-- Main Title (Addon Name)
Tracker.title = Tracker:CreateFontString(nil, "OVERLAY", "GameFontNormal")
local fPath, fSize, fFlags = Tracker.title:GetFont(); 
Tracker.title:SetFont(fPath, fSize + 2, fFlags)
Tracker.title:SetPoint("TOPLEFT", Tracker, "TOPLEFT", 10, -8); 
Tracker.title:SetText(addonName)

-- Current Zone Display
Tracker.zoneText = Tracker:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
Tracker.zoneText:SetPoint("TOPLEFT", Tracker.title, "BOTTOMLEFT", 0, -2); 
Tracker.zoneText:SetTextColor(1, 1, 1)

-- Skill Level (Current / Required)
Tracker.skill = Tracker:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
Tracker.skill:SetPoint("TOPLEFT", Tracker.zoneText, "BOTTOMLEFT", 0, -2)

-- Loot List (Items caught in this zone)
Tracker.items = Tracker:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
Tracker.items:SetPoint("TOPLEFT", Tracker.skill, "BOTTOMLEFT", 0, -8); 
Tracker.items:SetJustifyH("LEFT")

-- Dragging functionality (Shift + Left Click to move)
Tracker:SetScript("OnMouseDown", function(self, button) if button == "LeftButton" and IsShiftKeyDown() then self:StartMoving() end end)
Tracker:SetScript("OnMouseUp", function(self, button) if button == "LeftButton" then self:StopMovingOrSizing() end end)

-- ====================================================================
-- TRACKER UPDATE LOGIC
-- ====================================================================
-- Refreshes all text and item statistics shown on the tracker.
local function RefreshTracker()
    if not Tracker:IsVisible() then return end
    
    local zone = GetZoneKey()
    -- Set zone name (prefer Minimap sub-zone if available)
    Tracker.zoneText:SetText(GetMinimapZoneText() ~= "" and GetMinimapZoneText() or GetZoneText())
    
    -- Skill info
    local current = ns.GetCurrentTotalSkill()
    local required = REQUIRED_FISHING_SKILL[zone] or 0
    Tracker.skill:SetText(string.format("Skill: |cff00ff00%d|r / %s", current, (required == 0 and "???" or required)))
    
    -- Loot statistics info
    local zoneStats = FF_STATS[zone]
    if zoneStats and next(zoneStats) then
        local total, sorted = 0, {}
        for id, data in pairs(zoneStats) do
            total = total + data.count
            -- Only show "Special" items (Fish, Rares, Coins) in the tracker list
            if ns.IsItemSpecial(id) then
                local _, _, quality = GetItemInfo(id)
                local colorCode = "ffffff"
                
                -- Color items based on their game quality (rarity)
                if quality then
                    local r, g, b = GetItemQualityColor(quality)
                    colorCode = string.format("%02x%02x%02x", r*255, g*255, b*255)
                end

                table.insert(sorted, { 
                    name = data.name or "Unknown", 
                    count = data.count, 
                    color = colorCode 
                }) 
            end
        end
        
        -- Sort items by count (highest first)
        table.sort(sorted, function(a,b) return a.count > b.count end)
        
        -- Build the loot string with percentages
        local txt = ""
        for _, itemData in ipairs(sorted) do 
            txt = txt .. string.format("|cff%s%s|r - %d (|cff00ff00%d%%|r)\n", itemData.color, itemData.name, itemData.count, math.floor((itemData.count/total)*100+0.5)) 
        end
        
        Tracker.items:SetText(txt); 
        Tracker.items:Show()
        -- Adjust background size to fit items
        Tracker.bg:SetPoint("BOTTOMRIGHT", Tracker.items, "BOTTOMRIGHT", 10, -8)
    else
        -- Hide items section if no data exists for this zone
        Tracker.items:Hide(); 
        Tracker.bg:SetPoint("BOTTOMRIGHT", Tracker.skill, "BOTTOMRIGHT", 10, -8)
    end
    
    -- Dynamically resize frame width to fit the longest text line
    Tracker:SetWidth(math.max(Tracker.title:GetStringWidth(), Tracker.skill:GetStringWidth(), (Tracker.items:IsVisible() and Tracker.items:GetStringWidth() or 0)) + 25)
end

-- ====================================================================
-- MAIN UPDATE CONTROLLER
-- ====================================================================
-- Checks player state (pole equipped, combat, settings) and updates UI/Sounds.
local function UpdateEverything()
    if not FF_SETTINGS then return end
    
    -- Check if player has a fishing pole in the main hand
    local isPole = false
    local itemID = GetInventoryItemID("player", 16)
    if itemID then
        local _, _, _, _, _, _, itemSubType = GetItemInfo(itemID)
        if itemSubType then
            local s = itemSubType:lower()
            if (s:find("fishing poles")) then
                isPole = true
            end
        end
    end

    -- Toggle Tracker visibility
    if (isPole) and (FF_SETTINGS.showTracker) and (not InCombatLockdown()) then
        Tracker:Show();
        RefreshTracker()
    else
        Tracker:Hide()
    end

    -- Toggle enhanced sounds
    if (isPole) and (FF_SETTINGS.perfectSound) then
        AdjustSounds(true)
    else
        AdjustSounds(false)
    end

    -- External UI hook (e.g. Loot Buttons)
    if (ns.UpdateLootButton) then
        ns.UpdateLootButton()
    end
end

-- ====================================================================
-- SETTINGS UI & POPUPS
-- ====================================================================
-- Popup: Clear data for the current location only
StaticPopupDialogs["FF_CONFIRM_CLEAR_ZONE"] = { 
    text = "Clear data for this zone?", 
    button1 = "Yes", button2 = "No", 
    OnAccept = function() FF_STATS[GetZoneKey()] = nil; RefreshTracker() end, 
    timeout = 0, whileDead = true, hideOnEscape = true 
}

-- Popup: Factory reset of all statistics and sound profiles
StaticPopupDialogs["FF_CONFIRM_CLEAR_ALL"] = { 
    text = "Clear ALL data? (Resets stats and sound profile)", 
    button1 = "Yes", button2 = "No", 
    OnAccept = function() 
        FF_STATS = {}; FF_SETTINGS.originalSounds = {}; FF_SETTINGS.isSoundAdjusted = false
        RefreshTracker(); if ns.UpdateLootButton then ns.UpdateLootButton() end
    end, timeout = 0, whileDead = true, hideOnEscape = true 
}

-- CONFIG FRAME SETUP
local Config = CreateFrame("Frame", "FF_Config", UIParent)
Config:SetSize(280, 360) 
Config:SetPoint("CENTER")
Config:SetBackdrop({ bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", tile=true, tileSize=32, edgeSize=32, insets={left=8,right=8,top=8,bottom=8} })
Config:Hide(); Config:EnableMouse(true); Config:SetMovable(true); Config:RegisterForDrag("LeftButton"); 
Config:SetScript("OnDragStart", Config.StartMoving); 
Config:SetScript("OnDragStop", Config.StopMovingOrSizing)

-- Config Header
Config.title = Config:CreateFontString(nil, "OVERLAY", "GameFontNormal")
local cPath, cSize, cFlags = Config.title:GetFont(); Config.title:SetFont(cPath, cSize + 4, cFlags)
Config.title:SetPoint("TOP", 0, -20)
Config.title:SetText(addonName)

Config.version = Config:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
Config.version:SetPoint("TOP", Config.title, "BOTTOM", 0, -2)
Config.version:SetTextColor(1, 1, 1)
Config.version:SetText("Version " .. (GetAddOnMetadata(addonName, "Version") or "0.0.1"))

-- Helper function to generate standardized checkboxes in the settings menu
local function CreateCheckButton(key, label, y)
    local c = CreateFrame("CheckButton", "FF_C_"..key, Config, "UICheckButtonTemplate")
    c:SetPoint("TOPLEFT", 25, y); _G[c:GetName().."Text"]:SetText(label)
    c:SetScript("OnShow", function(s) s:SetChecked(FF_SETTINGS[key]) end)
    c:SetScript("OnClick", function(s) FF_SETTINGS[key] = s:GetChecked(); UpdateEverything() end)
    return c
end

-- Settings Menu Buttons
CreateCheckButton("showTracker", "Show Fishing Tracker", -65)
CreateCheckButton("autoLure", "Auto Use Lures", -90)
CreateCheckButton("playSounds", "Play Rare Catch Sounds", -115)
CreateCheckButton("showChat", "Show Chat Messages", -140)
CreateCheckButton("autoOpen", "Show Loot Button for Clams", -165)
CreateCheckButton("perfectSound", "Enhance Fishing Sounds", -190)
CreateCheckButton("debug", "Debug Mode", -215)

-- Data Management Buttons
local b1 = CreateFrame("Button", nil, Config, "UIPanelButtonTemplate"); 
b1:SetSize(180, 22); b1:SetPoint("TOP", 0, -250); b1:SetText("Clear Current Zone")
b1:SetScript("OnClick", function() StaticPopup_Show("FF_CONFIRM_CLEAR_ZONE") end)

local b2 = CreateFrame("Button", nil, Config, "UIPanelButtonTemplate"); 
b2:SetSize(180, 22); b2:SetPoint("TOP", b1, "BOTTOM", 0, -5); b2:SetText("Clear All Data")
b2:SetScript("OnClick", function() StaticPopup_Show("FF_CONFIRM_CLEAR_ALL") end)

local cl = CreateFrame("Button", nil, Config, "UIPanelButtonTemplate"); 
cl:SetSize(80, 22); cl:SetPoint("BOTTOM", 0, 18); cl:SetText("Close")
cl:SetScript("OnClick", function() Config:Hide() end)

-- ====================================================================
-- GLOBAL EVENT HANDLER
-- ====================================================================
-- Monitors game events to trigger UI and state updates.
local e = CreateFrame("Frame")
e:RegisterEvent("UNIT_INVENTORY_CHANGED")
e:RegisterEvent("PLAYER_ENTERING_WORLD")
e:RegisterEvent("ZONE_CHANGED_NEW_AREA")
e:RegisterEvent("ZONE_CHANGED")
e:RegisterEvent("ZONE_CHANGED_INDOORS")
e:RegisterEvent("CHAT_MSG_LOOT")
e:RegisterEvent("SKILL_LINES_CHANGED")

e:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_LOOT" then 
        -- Update stats live if something is looted while tracker is open
        if Tracker:IsVisible() then RefreshTracker() end
    elseif event == "UNIT_INVENTORY_CHANGED" then
        -- Only trigger update if the inventory change happened to the player
        if ... == "player" then UpdateEverything() end
    else 
        -- Handle area changes and entering world
        UpdateEverything() 
    end
end)