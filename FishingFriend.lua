local addonName, ns = ... -- The private namespace shared between files
ns.L = {} -- Create the localization table in the namespace
local L = ns.L -- Local alias for easy access within this file

-- ====================================================================
-- LOCALIZATION SETUP
-- ====================================================================
-- Detects the game client language and maps essential strings for 
-- fishing, equipment detection, and interaction with the bobber.
local L = ns.L
local locale = GetLocale()

-- Default (English)
L["Fishing"] = "Fishing"
L["Fishing Pole"] = "Fishing Pole"
L["Fishing Bobber"] = "Fishing Bobber"

if locale == "deDE" then
    L["Fishing"] = "Angeln"
    L["Fishing Pole"] = "Angel"
    L["Fishing Bobber"] = "Schwimmer"
elseif locale == "frFR" then
    L["Fishing"] = "Pêche"
    L["Fishing Pole"] = "Canne à pêche"
    L["Fishing Bobber"] = "Flotteur"
elseif locale == "esES" or locale == "esMX" then
    L["Fishing"] = "Pesca"
    L["Fishing Pole"] = "Caña de pescar"
    L["Fishing Bobber"] = "Flotador"
elseif locale == "ruRU" then
    L["Fishing"] = "Рыбная ловля"
    L["Fishing Pole"] = "Удочка"
    L["Fishing Bobber"] = "Поплавок"
elseif locale == "zhCN" or locale == "enCN" then
    L["Fishing"] = "钓鱼"
    L["Fishing Pole"] = "钓鱼竿"
    L["Fishing Bobber"] = "鱼漂"
elseif locale == "zhTW" or locale == "enTW" then
    L["Fishing"] = "釣魚"
    L["Fishing Pole"] = "釣魚竿"
    L["Fishing Bobber"] = "鱼漂"
elseif locale == "koKR" then
    L["Fishing"] = "낚시"
    L["Fishing Pole"] = "낚싯대"
    L["Fishing Bobber"] = "찌"
elseif locale == "itIT" then
    L["Fishing"] = "Pesca"
    L["Fishing Pole"] = "Canna da Pesca"
    L["Fishing Bobber"] = "Galleggiante"
elseif locale == "ptBR" or locale == "ptPT" then
    L["Fishing"] = "Pescaria"
    L["Fishing Pole"] = "Vara de Pesca"
    L["Fishing Bobber"] = "Isca"
end

-- ====================================================================
-- DATABASE & SETTINGS INITIALIZATION
-- ====================================================================
-- Checks if SavedVariables exist in the .toc file, otherwise creates them.
if (not REQUIRED_FISHING_SKILL) or (type(REQUIRED_FISHING_SKILL) ~= "table") then
    REQUIRED_FISHING_SKILL = {}
end
if (not FF_STATS) or (type(FF_STATS) ~= "table") then
    FF_STATS = {}
end
if (not FF_SETTINGS) or (type(FF_SETTINGS) ~= "table") then
    -- autoLure: brug lures, playSounds: lyd ved fangst, showTracker: vis/skjul trackeren
    FF_SETTINGS = { autoLure = true, playSounds = true, showChat = true, debug = false, showTracker = true, autoOpen = 1, perfectSound = 1, }
end

-- File path to the custom alert sound played when quest/special items are looted.
local SUCCESS_SOUND = "Interface\\AddOns\\FishingFriend\\Sounds\\GoodFishing.ogg"

-- Target skill values. If junk is caught, the addon aims for the next value in this list.
local SKILL_BREAKPOINTS = {0, 25, 75, 150, 225, 300, 375, 400, 425, 450, 475, 490, 500, 525, 575}

-- ====================================================================
-- ITEM LISTS (LURES, JUNK, QUESTS, SPECIALS)
-- ====================================================================
-- List of lures available in the game, sorted by their skill bonus.
local LURES = {
    { name = "Shiny Bauble", bonus = 25, id = 6529 },
    { name = "Nightcrawlers", bonus = 50, id = 6530 },
    { name = "Bright Baubles", bonus = 75, id = 6532 },
    { name = "Aquadynamic Fish Lens", bonus = 50, id = 34861 },
    { name = "Flesh Eating Worm", bonus = 75, id = 34861 },
    { name = "Aquadynamic Fish Attractor", bonus = 100, id = 6533 },
    { name = "Glow-worm", bonus = 100, id = 43334 }
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
-- ====================================================================
-- Prints messages to the chat frame only if Debug mode is enabled in settings.
local function DebugLog(msg, color)
    if FF_SETTINGS.debug then
        print("|cff8080ff[FF]|r |cff"..(color or "ffffff")..msg.."|r")
    end
end

-- Extracts the numeric Item ID from a standard WoW Item Link.
local function GetItemID(itemLink)
    if not itemLink then return nil end
    return tonumber(itemLink:match("item:(%d+)"))
end

-- Shared function: Gets the player's total fishing skill.
-- Defined in ns to be accessible from FishingFriendUI.lua
function ns.GetCurrentTotalSkill()
    for i = 1, GetNumSkillLines() do
        local name, _, _, rank, _, modifier = GetSkillLineInfo(i)
        if name == L["Fishing"] then return rank + modifier end
    end
    return 0
end

-- Shared function: Helper to determine if an item should be shown separately in the UI
function ns.IsItemSpecial(itemID)
    -- If it's a Quest item, Special item, or one of the "Fake Greys" (Coins), keep it separate.
    if QUEST_FISHING_ITEMS[itemID] or SPECIAL_FISHING_ITEMS[itemID] or FAKE_GREY_LOOT_LIST[itemID] then
        return true
    end
    
    -- In WoW 3.3.5, most actual "fish" are quality 1 (white) or higher.
    -- We use GetItemInfo to check quality.
    local _, _, quality = GetItemInfo(itemID)
    if quality and quality > 0 then
        return true -- It's a fish or a good item
    end

    return false -- It's junk
end

-- Determines the next target skill level for a zone when junk is caught.
local function GetNextBreakpoint(currentSkill)
    for _, b in ipairs(SKILL_BREAKPOINTS) do if b > currentSkill then return b end end
    return currentSkill + 25 -- Fallback if skill exceeds the table.
end

-- ====================================================================
-- LURE LOGIC
-- ====================================================================
-- Automatically applies a lure if the current skill is lower than the recorded zone requirement.
local function ApplyLure()
    if InCombatLockdown() or not FF_SETTINGS.autoLure then return end
    
    -- Checks if the fishing pole already has an active temporary enchantment (lure).
    local hasMainHandEnchant = GetWeaponEnchantInfo()
    if hasMainHandEnchant then return end

    local zone = GetZoneText() .. " - " .. GetMinimapZoneText()
    local currentSkill = ns.GetCurrentTotalSkill()
    local required = REQUIRED_FISHING_SKILL[zone] or 0

    -- If total skill is below zone requirements, search inventory for the best lure.
    if currentSkill < required then
        DebugLog(string.format("Skill too low for %s (%d/%d). Searching for lure...", zone, currentSkill, required), "ff8000")
        for _, lure in ipairs(LURES) do
            if GetItemCount(lure.id) > 0 then
                DebugLog("Applying Lure ID: " .. lure.id, "00ff00")
                -- UseItemByName works with Item IDs in 3.3.5 when passed as a string.
                UseItemByName(tostring(lure.id)) 
                return 
            end
        end
    end
end

-- ====================================================================
-- STATE VARIABLES
-- ====================================================================
-- Tracks player equipment and fishing status to prevent errors during loot.
local wasFishing, clickedBobber = false, false
local lastClickTime = 0

-- ====================================================================
-- EVENT ENGINE
-- ====================================================================
-- Main event handler frame that monitors combat, looting, and fishing actions.
local f = CreateFrame("Frame")
f:RegisterEvent("LOOT_OPENED")
f:RegisterEvent("UNIT_INVENTORY_CHANGED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:RegisterEvent("GAMEOBJECT_USED")
f:RegisterEvent("UI_INFO_MESSAGE")
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

f:SetScript("OnEvent", function(self, event, ...)
    -- Monitors system messages like "Fish Escaped" to reset the fishing state.
    if event == "UI_INFO_MESSAGE" then
        local msg = ...
        if msg == ERR_FISH_ESCAPED or msg == ERR_FISH_NOT_HOOKED then
            wasFishing, clickedBobber = false, false
            DebugLog("Reset: " .. msg, "ffaa00")
        end

    -- Detects when the player interacts with the world (e.g. clicking the bobber).
    elseif event == "GAMEOBJECT_USED" then
        local objectID = ...
        if objectID == 35591 then -- 35591 is the internal ID for the Fishing Bobber.
            clickedBobber = true
            DebugLog('Player clicked on "Fishing Bobber"', "00ffff")
        end

    -- Monitors spells and buffs to track when the player starts and stops fishing.
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subevent, sourceGUID, _, _, destGUID, _, _, _, spellName = ...
        if destGUID == UnitGUID("player") and spellName == L["Fishing"] then
            if subevent == "SPELL_AURA_APPLIED" then
                wasFishing, clickedBobber = true, false
                DebugLog("Started fishing", "00ff00")
                ApplyLure()
            elseif subevent == "SPELL_AURA_REMOVED" then
                if not clickedBobber then
                    wasFishing, clickedBobber = false, false
                    DebugLog("Reset: Movement or cast cancelled", "ff0000")
                else
                    DebugLog("Fishing aura removed (Waiting for loot)", "ffff00")
                end
            end
        end

        -- If a different spell is cast while fishing, reset state.
        if sourceGUID == UnitGUID("player") and subevent == "SPELL_CAST_START" then
            if spellName ~= L["Fishing"] and wasFishing then
                wasFishing, clickedBobber = false, false
                DebugLog("Reset: Other spell cast started", "ff0000")
            end
        end

    -- Resets fishing state if entering combat.
    elseif event == "PLAYER_REGEN_DISABLED" then
        wasFishing, clickedBobber = false, false

    -- Analyzes loot when the fishing bobber is successfully clicked.
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
                    DebugLog(string.format("Caught: %s x%d (Quality: %d) in %s", link, quantity or 1, quality, zone), "00ff00")
                    
                    -- Record to local statistics database (grouped by zone for UI statistics).
                    if not FF_STATS[zone] then FF_STATS[zone] = {} end
                    if not FF_STATS[zone][itemID] then 
                        FF_STATS[zone][itemID] = {name = name, count = 0} 
                    end
                    FF_STATS[zone][itemID].count = FF_STATS[zone][itemID].count + (quantity or 1)
                    
                    -- Check if caught item is a quest or special rare item.
                    if QUEST_FISHING_ITEMS[itemID] or SPECIAL_FISHING_ITEMS[itemID] then
                        playAlertSound = true
                    end

                    -- If a low-quality item (Grey) is caught and it's not a coin or quest item, 
                    -- it is "True Junk", meaning the zone skill requirement needs updating.
                    if quality == 0 and not FAKE_GREY_LOOT_LIST[itemID] and not QUEST_FISHING_ITEMS[itemID] and not SPECIAL_FISHING_ITEMS[itemID] then 
                        foundTrueJunk = true 
                    end
                end
            end
            
            -- Play sound alert for rare catches.
            if playAlertSound and FF_SETTINGS.playSounds then
                PlaySoundFile(SUCCESS_SOUND, "Master")
            end

            -- If junk was caught, recalculate and save the required skill for this specific zone.
            if foundTrueJunk then
                REQUIRED_FISHING_SKILL[zone] = GetNextBreakpoint(ns.GetCurrentTotalSkill())
                DebugLog("True junk detected. Skill requirement updated for: " .. zone, "ff8000")
            end
        end
        wasFishing, clickedBobber = false, false

    end
end)

-- ====================================================================
-- CHECK IF IT'S A FISHING POLE WE HAVE ON
-- ====================================================================
local function IsItFishingPole()
    local itemID = GetInventoryItemID("player", 16)
    if (itemID) then
        local _, _, _, _, _, _, itemSubType = GetItemInfo(itemID)
        if (itemSubType) then
            local s = itemSubType:lower()
            if (s:find("fishing poles")) then
                return true
            end
        end
    end
    return false
end

-- ====================================================================
-- CLICK ENGINE (RIGHT-CLICK TO CAST)
-- ====================================================================
-- Frame used to cast the Fishing spell via a secure override binding.
local btn = CreateFrame("Button", "EasyFishingButton", UIParent, "SecureActionButtonTemplate")
WorldFrame:HookScript("OnMouseDown", function(_, button)
    -- Only proceed if Right-Clicking, holding a pole, and not in combat.
    if (button ~= "RightButton") or (InCombatLockdown()) or (not IsItFishingPole()) then
        return
    end
    
    -- If the mouse is already over the bobber, don't cast; let the player loot.
    if GameTooltip:IsVisible() and _G["GameTooltipTextLeft1"]:GetText() == L["Fishing Bobber"] then
        ClearOverrideBindings(btn)
        return
    end

    -- Double-click detection: Casts fishing if two right-clicks occur within 0.4 seconds.
    local currentTime = GetTime()
    if (currentTime - lastClickTime) < 0.4 then
        btn:SetAttribute("type", "spell")
        btn:SetAttribute("spell", L["Fishing"])
        SetOverrideBindingClick(btn, true, "BUTTON2", "EasyFishingButton")
        lastClickTime = 0
    else
        ClearOverrideBindings(btn)
        lastClickTime = currentTime
    end
end)
-- Ensures the binding is cleared immediately after the spell is cast.
btn:SetScript("PostClick", function() ClearOverrideBindings(btn) end)

-- ====================================================================
-- SLASH COMMANDS
-- ====================================================================
SLASH_FISHINGFRIEND1 = "/ff"
SlashCmdList["FISHINGFRIEND"] = function(msg)
    msg = msg:lower()
    if msg == "debug" then
        FF_SETTINGS.debug = not FF_SETTINGS.debug
        print("FishingFriend Debug: "..(FF_SETTINGS.debug and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
    else
        -- If UI file is loaded, this will toggle the config window
        if FF_Config then
            if FF_Config:IsVisible() then 
                FF_Config:Hide() 
            else 
                FF_Config:Show() 
            end
        end
    end
end