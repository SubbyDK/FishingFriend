local addonName, ns = ...
local L = ns.L

local realmName = nil

-----------------------------------------------------------------------
-- SECTION 1: Item List Configuration
-- All IDs and names must match the server database exactly (case-sensitive)
-----------------------------------------------------------------------

local OPEN_ITEMS = {
    -- Clams
    [5523]   = "Small Barnacled Clam",
    [7973]   = "Big-mouth Clam",
    [15874]  = "Soft-Shelled Clam",
    -- Trunks
    [21228]  = "Mithril Bound Trunk",
    [21150]  = "Iron Bound Trunk",
    [21113]  = "Watertight Trunk",
    -- Other
    [6647] = "Bloated Catfish",
    [100625] = "Bloated Flat Fish",
}

-----------------------------------------------------------------------
-- SECTION 2: Diagnostic Tools (/ffcheck and /fffind)
-- Used to verify and find correct Item IDs on the current server
-----------------------------------------------------------------------

-- Command: /ffcheck
-- Scans the OPEN_ITEMS list and verifies if IDs match the expected names
function ns.CheckIDs()
    print("|cff00ff00" .. addonName .. ": Analyzing OPEN_ITEMS...|r")
    
    for id, expectedName in pairs(OPEN_ITEMS) do
        if expectedName then
            local currentName = GetItemInfo(id)
            
            -- Strict case-sensitive comparison
            if currentName and currentName == expectedName then
                print(string.format("|cff00ff00[OK]|r ID %d matches |cffffff00%s|r", id, currentName))
            else
                local foundID = nil
                -- Search cache for the exact name if ID is wrong or missing
                for i = 1, 150000 do
                    local scanName = GetItemInfo(i)
                    if scanName and scanName == expectedName then
                        foundID = i
                        break
                    end
                end
                
                if foundID then
                    print(string.format("|cffff0000[ERROR]|r ID for '|cffffff00%s|r' is |cff00ffff%d|r", expectedName, foundID))
                else
                    if currentName then
                        print(string.format("|cffffa500[WARNING]|r ID %d is '%s', but we expect exact '%s'.", id, currentName, expectedName))
                    else
                        print(string.format("|cffff0000[ERROR]|r '%s' not found in cache. (Check spelling/case or see item in-game)", expectedName))
                    end
                end
            end
        end
    end
end

SLASH_FFCHECK1 = "/ffcheck"
SlashCmdList["FFCHECK"] = ns.CheckIDs

-- Command: /fffind [Name]
-- Searches the game cache for a specific item name to retrieve its ID
SLASH_FFFIND1 = "/fffind"
SlashCmdList["FFFIND"] = function(msg)
    if not msg or msg == "" then print("Usage: /fffind Item Name"); return end
    print("|cff00ff00Searching for exact match: '" .. msg .. "'...|r")
    local found = false
    for i = 1, 150000 do
        local name = GetItemInfo(i)
        if name and name == msg then
            print("|cff00ff00Found!|r ID for |cffffff00" .. name .. "|r is: |cff00ffff" .. i .. "|r")
            found = true
            break
        end
    end
    if not found then print("|cffff0000Not found. Remember exact spelling and case.|r") end
end

-----------------------------------------------------------------------
-- SECTION 3: Internal Helper Functions
-----------------------------------------------------------------------

-- Retrieves the ItemID from a specific bag slot
local function GetItemID(bag, slot)
    local _, _, _, _, _, _, _, _, _, itemID = GetContainerItemInfo(bag, slot)
    if not itemID then
        local link = GetContainerItemLink(bag, slot)
        if link then itemID = tonumber(link:match("item:(%d+)")) end
    end
    return itemID
end

-----------------------------------------------------------------------
-- SECTION 4: UI Component (The Loot Button)
-----------------------------------------------------------------------

local LootBtn = CreateFrame("Button", "FF_LootButton", UIParent, "SecureActionButtonTemplate, ActionButtonTemplate")
LootBtn:SetSize(45, 45)
LootBtn:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
LootBtn:SetAttribute("type", "item")
LootBtn:SetMovable(true)
LootBtn:EnableMouse(true)
LootBtn:RegisterForDrag("LeftButton")
LootBtn:SetClampedToScreen(true)
LootBtn:Hide()

LootBtn.icon = _G[LootBtn:GetName().."Icon"]
LootBtn.text = LootBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
LootBtn.text:SetPoint("BOTTOM", LootBtn, "TOP", 0, 5)
LootBtn.text:SetText("Open!")

-- Interaction: Move button with Shift + Left Click
LootBtn:SetScript("OnDragStart", function(self) if IsShiftKeyDown() then self:StartMoving() end end)
LootBtn:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

-----------------------------------------------------------------------
-- SECTION 5: Core Logic & Event Handling
-----------------------------------------------------------------------

-- Scans bags for items in OPEN_ITEMS and updates button visibility
local function UpdateLootButton()
    if InCombatLockdown() then return end
    if not FF_SETTINGS or not FF_SETTINGS.autoOpen then 
        LootBtn:Hide()
        return 
    end

    for bag = 0, 4 do
        local slots = GetContainerNumSlots(bag)
        for slot = 1, (slots or 0) do
            local id = GetItemID(bag, slot)
            -- If ID is in our list, show the button
            if id and OPEN_ITEMS[id] then 
                local icon = GetContainerItemInfo(bag, slot)
                LootBtn:SetAttribute("item", "item:"..id)
                LootBtn.icon:SetTexture(icon)
                LootBtn:Show()
                return 
            end
        end
    end
    LootBtn:Hide()
end

-- Register events to trigger the update
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("BAG_UPDATE")
eventFrame:RegisterEvent("CHAT_MSG_LOOT")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    UpdateLootButton()
    if (event == "PLAYER_ENTERING_WORLD") then
        realmName = GetRealmName()
    end
end)

-- Export function for use in other parts of the addon
ns.UpdateLootButton = UpdateLootButton