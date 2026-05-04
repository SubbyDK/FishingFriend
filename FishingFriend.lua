local addonName, ns = ... -- The private namespace shared between files
ns.L = {} -- Create the localization table in the namespace
local L = ns.L -- Local alias for easy access within this file

-- ====================================================================
-- LOCALIZATION SETUP
-- Handles translation of game terms for different language clients.
-- ====================================================================
local locale = GetLocale()

L["Fishing"] = "Fishing"
L["Fishing Pole"] = "Fishing Pole"
L["Fishing Bobber"] = "Fishing Bobber"
L["Find Fish"] = "Find Fish"

if locale == "deDE" then
    L["Fishing"] = "Angeln"
    L["Fishing Pole"] = "Angel"
    L["Fishing Bobber"] = "Schwimmer"
    L["Find Fish"] = "Fischsuche"
elseif locale == "frFR" then
    L["Fishing"] = "Pêche"
    L["Fishing Pole"] = "Canne à pêche"
    L["Fishing Bobber"] = "Flotteur"
    L["Find Fish"] = "Découverte de poissons"
elseif locale == "esES" or locale == "esMX" then
    L["Fishing"] = "Pesca"
    L["Fishing Pole"] = "Caña de pescar"
    L["Fishing Bobber"] = "Flotador"
    L["Find Fish"] = "Buscar pescado"
elseif locale == "ruRU" then
    L["Fishing"] = "Рыбная ловля"
    L["Fishing Pole"] = "Удочка"
    L["Fishing Bobber"] = "Поплавок"
    L["Find Fish"] = "Поиск рыбы"
elseif locale == "zhCN" or locale == "enCN" then
    L["Fishing"] = "钓鱼"
    L["Fishing Pole"] = "钓鱼竿"
    L["Fishing Bobber"] = "鱼漂"
    L["Find Fish"] = "寻找鱼类"
elseif locale == "zhTW" or locale == "enTW" then
    L["Fishing"] = "釣魚"
    L["Fishing Pole"] = "釣魚竿"
    L["Fishing Bobber"] = "鱼漂"
    L["Find Fish"] = "尋找魚類"
elseif locale == "koKR" then
    L["Fishing"] = "낚시"
    L["Fishing Pole"] = "낚싯대"
    L["Fishing Bobber"] = "찌"
    L["Find Fish"] = "물고기 찾기"
elseif locale == "itIT" then
    L["Fishing"] = "Pesca"
    L["Fishing Pole"] = "Canna da Pesca"
    L["Fishing Bobber"] = "Galleggiante"
    L["Find Fish"] = "Trova Pesci"
elseif locale == "ptBR" or locale == "ptPT" then
    L["Fishing"] = "Pescaria"
    L["Fishing Pole"] = "Vara de Pesca"
    L["Fishing Bobber"] = "Isca"
    L["Find Fish"] = "Encontrar Peixe"
end

-- ====================================================================
-- DATABASE & SETTINGS INITIALIZATION
-- Ensures tables exist for persistent storage of stats and settings.
-- ====================================================================
if (not REQUIRED_FISHING_SKILL) or (type(REQUIRED_FISHING_SKILL) ~= "table") then
    REQUIRED_FISHING_SKILL = {}
end
if (not FF_STATS) or (type(FF_STATS) ~= "table") then
    FF_STATS = {}
end
if (not FF_SETTINGS) or (type(FF_SETTINGS) ~= "table") then
    -- Added autoTrack and lastTrackingIndex to defaults
    FF_SETTINGS = { autoLure = true, playSounds = true, showChat = true, debug = false, showTracker = true, autoOpen = 1, perfectSound = 1, autoTrack = true, lastTrackingIndex = nil }
end

local SUCCESS_SOUND = "Interface\\AddOns\\FishingFriend\\Sounds\\GoodFishing.ogg"
local SKILL_BREAKPOINTS = {0, 25, 75, 150, 225, 300, 375, 400, 425, 450, 475, 490, 500, 525, 575}

-- ====================================================================
-- ITEM LISTS (LURES, JUNK, QUESTS, SPECIALS)
-- Comprehensive lists of items for logic and alerts.
-- ====================================================================

-- Available fishing lures and their required skill/bonuses.
local LURES = {
    { name = "Shiny Bauble", bonus = 25, minSkill = 1, id = 6529 },
    { name = "Nightcrawlers", bonus = 50, minSkill = 50, id = 6530 },
    { name = "Bright Baubles", bonus = 75, minSkill = 100, id = 6532 },
    { name = "Aquadynamic Fish Lens", bonus = 50, minSkill = 100, id = 34861 },
    { name = "Flesh Eating Worm", bonus = 75, minSkill = 100, id = 34861 },
    { name = "Aquadynamic Fish Attractor", bonus = 100, minSkill = 100, id = 6533 },
    { name = "Glow-worm", bonus = 100, minSkill = 100, id = 43334 }
}

-- List of "fake" junk items (Dalaran coins, etc.) that shouldn't trigger skill-up requirements.
local FAKE_GREY_LOOT_LIST = { 
    -- Copper coins from Dalaran
    [43702] = true, -- Alonsus Faol's Copper Coin
    [43703] = true, -- Ansirem's Copper Coin
    [43704] = true, -- Attumen's Copper Coin
    [43705] = true, -- Danath's Copper Coin
    [43706] = true, -- Dornaa's Shiny Copper Coin
    [43707] = true, -- Eitrigg's Copper Coin
    [43708] = true, -- Elling Trias' Copper Coin
    [43709] = true, -- Falstad Wildhammer's Copper Coin
    [43710] = true, -- Genn's Copper Coin
    [43711] = true, -- Inigo's Copper Coin
    [43712] = true, -- Krasus' Copper Coin
    [43713] = true, -- Kryll's Copper Coin
    [43714] = true, -- Landro Longshot's Copper Coin
    [43715] = true, -- Molok's Copper Coin
    [43716] = true, -- Murky's Copper Coin
    [43717] = true, -- Princess Calia Menethil's Copper Coin
    [43718] = true, -- Private Marcus Jonathan's Copper Coin
    [43719] = true, -- Salandria's Shiny Copper Coin
    [43720] = true, -- Squire Rowe's Copper Coin
    [43721] = true, -- Stalvan's Copper Coin
    [43722] = true, -- Vereesa's Copper Coin
    [43723] = true, -- Vargoth's Copper Coin

    -- Silver coins from Dalaran
    [43643] = true, -- Prince Magni Bronzebeard's Silver Coin
    [43644] = true, -- A Peasant's Silver Coin
    [43675] = true, -- Fandral Staghelm's Silver Coin
    [43676] = true, -- Arcanist Doan's Silver Coin
    [43677] = true, -- High Tinker Mekkatorque's Silver Coin
    [43678] = true, -- Antonidas' Silver Coin
    [43679] = true, -- Muradin Bronzebeard's Silver Coin
    [43680] = true, -- King Varian Wrynn's Silver Coin
    [43681] = true, -- King Terenas Menethil's Silver Coin
    [43682] = true, -- King Anasterian Sunstrider's Silver Coin
    [43683] = true, -- Khadgar's Silver Coin
    [43684] = true, -- Medivh's Silver Coin
    [43685] = true, -- Maiev Shadowsong's Silver Coin
    [43686] = true, -- Alleria's Silver Coin
    [43687] = true, -- Aegwynn's Silver Coin

    -- Fake random
    [27441] = true, -- Felblood Snapper (Lives in fel pools and lava)
    [27442] = true, -- Goldenscale Vendorfish
    [43659] = true, -- Bloodied Prison Shank
    [6304]  = true, -- Damp Diary Page (Day 4)
    [6306]  = true, -- Damp Diary Page (Day 512)
}

-- Specific Quest items that can be caught regardless of skill.
local QUEST_FISHING_ITEMS = { 
    -- TBC Daily Fishing Quests
    [34864] = true, -- Baby Crocolisk (Crocolisks in the City)
    [34867] = true, -- Monstrous Felblood Snapper (Felblood Fillet)
    [35313] = true, -- Bloated Barbed Gill Trout (Shrimpin' Ain't Easy)
    [34865] = true, -- Blackfin Darter (Bait Bandits)
    [34868] = true, -- World's Largest Mudfish (The One That Got Away)

    -- WotLK Daily Fishing Quests
    [45905] = true, -- Bloodtooth Frenzy (Blood Is Thicker)
    [45904] = true, -- Terrorfish (Dangerously Delicious)
    [45328] = true, -- Bloated Slippery Eel (Disarmed!)
    [45903] = true, -- Corroded Jewelry (Jewel Of The Sewers)
    [45902] = true, -- Phantom Ghostfish (The Ghostfish)

    -- Nat Pagle, Angler Extreme
    [16967] = true, -- Feralas Ahi
    [16970] = true, -- Misty Reed Mahi Mahi
    [16968] = true, -- Sar'theris Striker
    [16969] = true, -- Savage Coast Blue Sailfin

    -- Classic Quests
    [6718]  = true, -- Electropeller
    [6717]  = true, -- Gaffer Jack
    [34469] = true, -- Strange Engine Part

    -- Weekly fishing contests
    [19807] = true, -- Speckled Tastyfish (Master Angler)
    [50289] = true, -- Blacktip Shark (Kalu'ak Fishing Derby)
    [19805] = true, -- Keefer's Angelfish
    [19806] = true, -- Dezian Queenfish
    [19803] = true, -- Brownell's Blue Striped Racer
    [19804] = true, -- Pale Ghoulfish
}

-- Rare or special items that trigger sound alerts.
local SPECIAL_FISHING_ITEMS = {
    -- Classic
    [34486] = true, -- Old Crafty
    [34484] = true, -- Old Ironjaw
    -- TBC
    [27388] = true, -- Mr. Pinchy
    -- WotLK
    [46109] = true, -- Sea Turtle
    [43698] = true, -- Giant Sewer Rat
    [43650] = true, -- Rusty Prison Key
    -- Miscellaneous
    [27442] = true, -- Goldenscale Vendorfish
    [43659] = true, -- Bloodied Prison Shank
    [6304]  = true, -- Damp Diary Page (Day 4)
    [6306]  = true, -- Damp Diary Page (Day 512)
}

-- ====================================================================
-- UTILS & HELPER FUNCTIONS
-- Internal functions for logging, skill checks, and item identification.
-- ====================================================================

-- Prints a message to the chat frame if Debug mode is enabled.
local function DebugLog(msg, color)
    if FF_SETTINGS.debug then
        print("|cff8080ff[FF]|r |cff"..(color or "ffffff")..msg.."|r")
    end
end

-- Extracts the numerical ID from an item link string.
local function GetItemID(itemLink)
    if not itemLink then return nil end
    return tonumber(itemLink:match("item:(%d+)"))
end

-- Returns the player's total fishing skill including all gear bonuses.
function ns.GetCurrentTotalSkill()
    for i = 1, GetNumSkillLines() do
        local name, _, _, rank, _, modifier = GetSkillLineInfo(i)
        if name == L["Fishing"] then return rank + modifier end
    end
    return 0
end

-- Returns the player's base fishing skill without gear/lures.
function ns.GetBaseFishingSkill()
    for i = 1, GetNumSkillLines() do
        local name, _, _, rank = GetSkillLineInfo(i)
        if name == L["Fishing"] then return rank end
    end
    return 0
end

-- Checks if an item belongs to any quest or special reward list.
function ns.IsItemSpecial(itemID)
    if QUEST_FISHING_ITEMS[itemID] or SPECIAL_FISHING_ITEMS[itemID] or FAKE_GREY_LOOT_LIST[itemID] then
        return true
    end
    local _, _, quality = GetItemInfo(itemID)
    if quality and quality > 0 then
        return true
    end
    return false
end

-- Returns the next skill breakpoint for the current zone.
local function GetNextBreakpoint(currentSkill)
    for _, b in ipairs(SKILL_BREAKPOINTS) do if b > currentSkill then return b end end
    return currentSkill + 25
end

-- Checks if the player currently has a fishing pole equipped in the main hand.
local function IsItFishingPole()
    local itemID = GetInventoryItemID("player", 16)
    if (itemID) then
        local _, _, _, _, _, _, itemSubType = GetItemInfo(itemID)
        if (itemSubType) then
            local s = itemSubType:lower()
            if (s:find("fishing poles")) then return true end
        end
    end
    return false
end

-- ====================================================================
-- STATE VARIABLES
-- Tracking the current state of fishing actions.
-- ====================================================================
local wasFishing, clickedBobber = false, false
local lastClickTime = 0
local wasPoleEquipped = false

-- ====================================================================
-- EVENT ENGINE
-- Core event handler for looting, inventory changes, and combat logs.
-- ====================================================================
local f = CreateFrame("Frame")
f:RegisterEvent("LOOT_OPENED")
f:RegisterEvent("UNIT_INVENTORY_CHANGED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:RegisterEvent("GAMEOBJECT_USED")
f:RegisterEvent("UI_INFO_MESSAGE")
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

f:SetScript("OnEvent", function(self, event, ...)
    -- Handle system messages (e.g., fish got away).
    if event == "UI_INFO_MESSAGE" then
        local msg = ...
        if msg == ERR_FISH_ESCAPED or msg == ERR_FISH_NOT_HOOKED then
            wasFishing, clickedBobber = false, false
            DebugLog("Reset: " .. msg, "ffaa00")
        end

    -- Switch "Find Fish" tracking on/off when equipping a pole.
    elseif event == "UNIT_INVENTORY_CHANGED" then
        local unit = ...
        if unit == "player" then
            local isPoleEquipped = IsItFishingPole()
            if isPoleEquipped ~= wasPoleEquipped then
                DebugLog("Equipment change detected. IsPole: " .. tostring(isPoleEquipped), "00ffff")
                
                local knowsFindFish = GetSpellInfo(L["Find Fish"])
                
                if isPoleEquipped and FF_SETTINGS.autoTrack then
                    if knowsFindFish then
                        DebugLog("Find Fish spell found! Checking tracking types...", "00ff00")
                        for i = 1, GetNumTrackingTypes() do
                            local name, _, active = GetTrackingInfo(i)
                            if active then 
                                -- Save to database instead of local variable
                                FF_SETTINGS.lastTrackingIndex = i 
                                DebugLog("Saved current tracking: " .. name, "808080")
                            end
                            if name == L["Find Fish"] then
                                if not active then
                                    SetTracking(i, true)
                                    DebugLog("Find Fish tracking ACTIVATED", "00ffff")
                                else
                                    DebugLog("Find Fish already active", "00ffff")
                                end
                            end
                        end
                    else
                        DebugLog("Player does NOT know 'Find Fish' spell.", "ff8000")
                    end
                elseif not isPoleEquipped and FF_SETTINGS.autoTrack then
                    -- Restore previous tracking using saved database value
                    if knowsFindFish and FF_SETTINGS.lastTrackingIndex then
                        local name = GetTrackingInfo(FF_SETTINGS.lastTrackingIndex)
                        SetTracking(FF_SETTINGS.lastTrackingIndex, true)
                        DebugLog("Restored previous tracking: " .. (name or "Unknown"), "00ffff")
                        FF_SETTINGS.lastTrackingIndex = nil
                    end
                end
                wasPoleEquipped = isPoleEquipped
            end
        end

    -- Initial state check on login/reload
    elseif event == "PLAYER_ENTERING_WORLD" then
        wasPoleEquipped = IsItFishingPole()
        DebugLog("Initial Pole Status: " .. tostring(wasPoleEquipped), "00ffff")

    -- Detect when the player interacts with the bobber object.
    elseif event == "GAMEOBJECT_USED" then
        local objectID = ...
        if objectID == 35591 then
            clickedBobber = true
            DebugLog('Player clicked on "Fishing Bobber"', "00ffff")
        end

    -- Track the Fishing aura in the combat log to determine cast status.
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subevent, sourceGUID, _, _, destGUID, _, _, _, spellName = ...
        if destGUID == UnitGUID("player") and spellName == L["Fishing"] then
            if subevent == "SPELL_AURA_APPLIED" then
                wasFishing, clickedBobber = true, false
                DebugLog("Started fishing aura", "00ff00")
            elseif subevent == "SPELL_AURA_REMOVED" then
                if not clickedBobber then
                    wasFishing, clickedBobber = false, false
                    DebugLog("Reset: Movement or cast cancelled", "ff0000")
                end
            end
        end

    -- Process loot and update zone skill requirements.
    elseif event == "LOOT_OPENED" then
        if wasFishing and clickedBobber then
            local foundTrueJunk = false
            local playAlertSound = false
            local zone = GetZoneText() .. " - " .. GetMinimapZoneText()

            for i = 1, GetNumLootItems() do
                local _, name, quantity, quality = GetLootSlotInfo(i)
                local link = GetLootSlotLink(i)
                local itemID = GetItemID(link)
                
                if itemID then
                    DebugLog(string.format("Caught: %s x%d", link, quantity or 1), "00ff00")
                    if not FF_STATS[zone] then FF_STATS[zone] = {} end
                    if not FF_STATS[zone][itemID] then 
                        FF_STATS[zone][itemID] = {name = name, count = 0} 
                    end
                    FF_STATS[zone][itemID].count = FF_STATS[zone][itemID].count + (quantity or 1)
                    
                    if SPECIAL_FISHING_ITEMS[itemID] then playAlertSound = true end
                    -- If we catch true grey junk, current skill is too low for the zone.
                    if quality == 0 and not FAKE_GREY_LOOT_LIST[itemID] then 
                        foundTrueJunk = true 
                    end
                end
            end
            
            if playAlertSound and FF_SETTINGS.playSounds then PlaySoundFile(SUCCESS_SOUND, "Master") end
            if foundTrueJunk then
                REQUIRED_FISHING_SKILL[zone] = GetNextBreakpoint(ns.GetCurrentTotalSkill())
                DebugLog("Junk detected! Updating zone skill requirement.", "ff8000")
            end
        end
        wasFishing, clickedBobber = false, false
    end
end)

-- ====================================================================
-- CLICK ENGINE (RIGHT-CLICK TO CAST)
-- Handles the double-right-click to cast fishing or apply lures.
-- ====================================================================
local btn = CreateFrame("Button", "EasyFishingButton", UIParent, "SecureActionButtonTemplate")
WorldFrame:HookScript("OnMouseDown", function(_, button)
    if (button ~= "RightButton") or (InCombatLockdown()) or (not IsItFishingPole()) then
        return
    end
    
    -- Check if cursor is over the bobber to allow normal looting.
    if GameTooltip:IsVisible() and _G["GameTooltipTextLeft1"]:GetText() == L["Fishing Bobber"] then
        clickedBobber = true 
        wasFishing = true
        DebugLog("Manual Bobber Click via Tooltip", "00ffff")
        ClearOverrideBindings(btn)
        return
    end

    local currentTime = GetTime()
    if (currentTime - lastClickTime) < 0.4 then
        local hasMainHandEnchant = GetWeaponEnchantInfo()
        local lureToUse = nil

        -- Auto-lure logic based on zone requirement.
        if FF_SETTINGS.autoLure and not hasMainHandEnchant then
            local zone = GetZoneText() .. " - " .. GetMinimapZoneText()
            local totalSkill = ns.GetCurrentTotalSkill()
            local baseSkill = ns.GetBaseFishingSkill() 
            local required = REQUIRED_FISHING_SKILL[zone] or 0

            if totalSkill < required then
                for _, lure in ipairs(LURES) do
                    if GetItemCount(lure.id) > 0 and baseSkill >= lure.minSkill then
                        lureToUse = lure.id
                        break
                    end
                end
            end
        end

        -- Determine whether to cast Fishing or use an item.
        if lureToUse then
            btn:SetAttribute("type", "item")
            btn:SetAttribute("item", "item:"..lureToUse)
            btn:SetAttribute("target-slot", 16)
            DebugLog("Applying Lure: " .. lureToUse, "00ff00")
        else
            btn:SetAttribute("type", "spell")
            btn:SetAttribute("spell", L["Fishing"])
        end

        SetOverrideBindingClick(btn, true, "BUTTON2", "EasyFishingButton")
        lastClickTime = 0
    else
        ClearOverrideBindings(btn)
        lastClickTime = currentTime
    end
end)
btn:SetScript("PostClick", function() ClearOverrideBindings(btn) end)

-- ====================================================================
-- SLASH COMMANDS
-- Slash command setup for /ff.
-- ====================================================================
SLASH_FISHINGFRIEND1 = "/ff"
SlashCmdList["FISHINGFRIEND"] = function(msg)
    msg = msg:lower()
    if msg == "debug" then
        FF_SETTINGS.debug = not FF_SETTINGS.debug
        print("FishingFriend Debug: "..(FF_SETTINGS.debug and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
    else
        if FF_Config then
            if FF_Config:IsVisible() then FF_Config:Hide() else FF_Config:Show() end
        end
    end
end