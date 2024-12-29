--[[
	ToDo list
        ✓ Get the addon up and running.
        Get the addon uploaded to CurseForge.
        Get the addon uploaded to GitHub.
        ✓ Make it cast fishing when double clicking.
        ✓ Make it luer when needed.
        ✓ Auto collect what fishing skill is needed in each zone to have a 100% chance to catch something usefull.
        ✓ Make it collect info about everything that we catch.
        ✓ Play a sound when something special or a quest item is catch.
        Make a check for the right version.
        Get someone to translate as I spell like the blind people fight.
        Make a graphical interface for settings.
        Make a graphical list of what we have caught.
        ✓ Make sure it's not running if we have no Fishing Pole on.
        Make sure it's not running while in a vehicle.

    Known bugs
        • When adding what we have cought to the database it's doing it wrong.
            Sometimes it's adding it two times, seems to be when there is many people around.
            If we catch 2 items it's only adding 1 item.
        • When double clicking to fast loot is not going in to your bags.
            Need to find a way to see if it's the bobber there was clicked to slow it a bit down.

    Help stuff
        /etrace
]]--

-- ====================================================================================================
-- =                                  Set some locals for this addon                                  =
-- ====================================================================================================

local AddonName = ...
local PRINT_COLOR = "|cFFFFA500"
local DEBUG_PRINT_COLOR = "|cFFFF0000"
local FF_Debug = false
local LocalizedFishingName = GetSpellInfo(7620) or "Fishing"
local lastClickTime = nil
local FakeGrey = false
local FoundGUID = nil
local RESET_DATABASE = false

local FishingButtonUsed = "RightButton" -- LeftButton - RightButton - MiddleButton - Button4 - Button5
local MinClickTime = 0.05
local MaxClickTime = 0.5

local FishingStatisticsLines = 1 -- For how many lines we will show in the stats.
local StopStatisticsLines = false

local MuteRhonin = true

local ChosenSound = 1
local SOUND_FILE_ID = {
    [1] = 6255,     -- B_MortarTeamPissed9
    [2] = 6313,     -- B_ArcherYes4
    [3] = 1440,     -- Level Up
}
-- ====================================================================================================
-- =                          Print function so all prints will be the same.                          =
-- ====================================================================================================

-- For the normal prints
local function PRINT_TEXT(str)
    DEFAULT_CHAT_FRAME:AddMessage(PRINT_COLOR .. AddonName .. ":|r " .. str);
end

-- For debug prints
local function DEBUG_PRINT_TEXT(str)
    DEFAULT_CHAT_FRAME:AddMessage(DEBUG_PRINT_COLOR .. AddonName .. "Debug:|r " .. str);
end

-- ====================================================================================================
-- =                          Check that it's the right version of the addon                          =
-- ====================================================================================================

if (select(4, GetBuildInfo()) < 30000) or (select(4, GetBuildInfo()) > 40000) then
    C_Timer.After(40, function()
        PRINT_TEXT("Your running the The Wrath of the Lich King version of " .. AddonName .. ".");
        PRINT_TEXT("Please download the right version, if there is one.");
    end)
    --return
end

-- ====================================================================================================
-- =          A small localization function, will be mover to seperate file if it get to big          =
-- ====================================================================================================

-- Sadly we have to use localization for some items as we can't get the ID for it, so there is always a chance of human errors.
    -- The localized names below of "Fishing Bobber" is "borrowed" from "FishingBuddy" and I have added the missing, sorry or thanks, up to you. ;)
    -- More about localization here: https://wowpedia.fandom.com/wiki/Localization

-- Make the table we need.
local L = {};

-- English - United States of America
if (GetLocale() == "enUS") then
    L["Fishing Bobber"] = "Fishing Bobber";
    L["Skill"] = "Skill";
    L["Zone"] = "Zone";

-- English - United Kingdom of Great Britain and Northern Ireland
elseif (GetLocale() == "enGB") then
    L["Fishing Bobber"] = "Fishing Bobber";
    L["Skill"] = "Skill";
    L["Zone"] = "Zone";

-- Spanish - Spain
elseif (GetLocale() == "esES") then
    L["Fishing Bobber"] = "Anzuelo";
    L["Skill"] = "Skill";
    L["Zone"] = "Zone";

-- Spanish - Mexico
elseif (GetLocale() == "esMX") then
    L["Fishing Bobber"] = "Anzuelo";
    L["Skill"] = "Skill";
    L["Zone"] = "Zone";

-- German - Germany
elseif (GetLocale() == "deDE") then
    L["Fishing Bobber"] = "Schwimmer";
    L["Skill"] = "Skill";
    L["Zone"] = "Zone";

-- French - France
elseif (GetLocale() == "frFR") then
    L["Fishing Bobber"] = "Flotteur";
    L["Skill"] = "Skill";
    L["Zone"] = "Zone";

-- Portuguese - Brazil
elseif (GetLocale() == "ptBR") then
    L["Fishing Bobber"] = "Isca de Pesca";
    L["Skill"] = "Skill";
    L["Zone"] = "Zone";

-- Russian - Russia
elseif (GetLocale() == "ruRU") then
    L["Fishing Bobber"] = "Поплавок";
    L["Skill"] = "Skill";
    L["Zone"] = "Zone";

-- Chinese - Taiwan
elseif (GetLocale() == "zhTW") then
    L["Fishing Bobber"] = "釣魚浮標";
    L["Skill"] = "Skill";
    L["Zone"] = "Zone";

-- Chinese - (Mainland - China)
elseif (GetLocale() == "zhCN") then
    L["Fishing Bobber"] = "垂钓水花";
    L["Skill"] = "Skill";
    L["Zone"] = "Zone";

-- English - (Mainland - China)
elseif (GetLocale() == "enCN") then
    L["Fishing Bobber"] = "Fishing Bobber unknown";
    L["Skill"] = "Skill";
    L["Zone"] = "Zone";

-- Italian - Italy
elseif (GetLocale() == "itIT") then
    L["Fishing Bobber"] = "Fishing Bobber unknown";
    L["Skill"] = "Skill";
    L["Zone"] = "Zone";

-- Portuguese - Portugal
elseif (GetLocale() == "ptPT") then
    L["Fishing Bobber"] = "Fishing Bobber unknown";
    L["Skill"] = "Skill";
    L["Zone"] = "Zone";

-- Korean - Republic of Korea
elseif (GetLocale() == "koKR") then
    L["Fishing Bobber"] = "Fishing Bobber unknown";
    L["Skill"] = "Skill";
    L["Zone"] = "Zone";

-- English - Taiwan
elseif (GetLocale() == "enTW") then
    L["Fishing Bobber"] = "Fishing Bobber unknown";
    L["Skill"] = "Skill";
    L["Zone"] = "Zone";
end

-- ====================================================================================================
-- =                              Create frames and register some events                              =
-- ====================================================================================================

local f = CreateFrame("Frame", nil, UIParent);
-- ====================================================================================================
-- local f1 = CreateFrame("Frame", nil, UIParent, "TooltipBackdropTemplate");
local f1 = CreateFrame("Frame", nil, UIParent); -- For the list with fish stats
-- 
f1:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 40, -40);
f1:SetSize(200, ((tonumber(FishingStatisticsLines) * 18) + 32));
-- Make the 2 tables we need to make the statistic lines.
f1.FonstringsLeft = {}
f1.FonstringsRight = {}

-- ====================================================================================================

f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
f:RegisterEvent("PLAYER_ENTERING_WORLD");
f:RegisterEvent("ADDON_LOADED");
f:RegisterEvent("UI_INFO_MESSAGE");
f:RegisterEvent("UI_ERROR_MESSAGE");
f:RegisterEvent("LOOT_READY");
f:RegisterEvent("LOOT_OPENED");
f:RegisterEvent("PLAYER_REGEN_DISABLED");
f:RegisterEvent("GLOBAL_MOUSE_DOWN");

f:RegisterEvent("ZONE_CHANGED");
f:RegisterEvent("ZONE_CHANGED_INDOORS");
f:RegisterEvent("ZONE_CHANGED_NEW_AREA");

f:RegisterEvent("BAG_UPDATE");

-- ====================================================================================================
-- =                                       The OnEvent function                                       =
-- ====================================================================================================

f:SetScript("OnEvent", function(self, event, arg1, arg2, arg3)
    -- Addon is loaded, do some stuff here.
    if event == 'ADDON_LOADED' and arg1 == AddonName then
        if (not REQUIRED_FISHING_SKILL) then
            REQUIRED_FISHING_SKILL = {}
        end
        if (not FISHING_LOOT) then
            FISHING_LOOT = {}
        end
        if (not SUCCESSFUL_THROWS) then
            SUCCESSFUL_THROWS = {}
        end
        if (RESET_DATABASE == true) then
            FISHING_LOOT = {}
            SUCCESSFUL_THROWS = {}
        end
        -- Make the statistics interface.
        FishingStatisticsInterface()
        -- Check to see if we want to mute Rhonin.
        MySpamFilter()
        -- Unregister the event, as we do not need it anymore
        f:UnregisterEvent("ADDON_LOADED");
-- ====================================================================================================
    -- A welcome message with fishing skill.
    elseif (event == "BAG_UPDATE") then
        --[[-- Get the amount of shards
        ShardCount = GetItemCount(6265)

        -- Do we run the delete function ?
        if (CursorHasItem() == false) and (ShardCount >= 3) then
            -- Loop though all items until we find a Soal Shard
            for bag = 0, NUM_BAG_SLOTS do
                for slot = 1, C_Container.GetContainerNumSlots(bag) do
                    local itemLink = C_Container.GetContainerItemLink(bag, slot)
                    -- Did we get a link ?
                    if (itemLink) then
                        itemID = tonumber(strmatch(itemLink, "item:(%d+):"))
                        -- Did we get a ID ?
                        if (itemID ~= nil) and (itemID ~= "") then
                            -- Is it a Soul Shard ?
                            if (itemID == 6265) then
                                C_Container.PickupContainerItem(bag, slot)
                                DeleteCursorItem()
                            end
                        end
                    end
                end
            end
        end--]]
-- ====================================================================================================
    -- A welcome message with fishing skill.
    elseif (event == "PLAYER_ENTERING_WORLD") then
        -- Make the statistics interface.
        FishingStatisticsInterface()
        -- 
        C_Timer.After(20, function()
            -- Do we know fishing ?
            if (IsSpellKnown(7620, false)) or (IsSpellKnown(7731, false)) or (IsSpellKnown(7732, false)) or (IsSpellKnown(18248, false)) or (IsSpellKnown(33095, false)) or (IsSpellKnown(51294, false)) then
                PRINT_TEXT("Fishing skill: " .. TotalFishingSkill(true) .. ".");
            -- You don't know fishing
            else
                PRINT_TEXT("You don't know fishing on this character.");
            end
        end)
        -- Unregister the event, as we do not need it anymore
        f:UnregisterEvent("PLAYER_ENTERING_WORLD");
-- ====================================================================================================
    -- Did we enter combat ? If we did, then we have to free the mouse as it seems to lock when we enter combat.
    elseif (event == "PLAYER_REGEN_DISABLED") then
        -- Clear the binding we have made for the button.
        ClearOverrideBindings(btn);
-- ====================================================================================================
    elseif (event == "GLOBAL_MOUSE_DOWN") and (InCombatLockdown() == false) then
        -- Only do something if we have a Fishing Pole equipped.
        if (IsEquippedItemType(GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON,LE_ITEM_WEAPON_FISHINGPOLE)) == true) then
            -- Only do something if it's the button we want to use there was used.
            if (arg1 == FishingButtonUsed) then
                MouseClickTriggert(arg1)
            end
        end
-- ====================================================================================================
    -- Check to see if a spell is casted successfully by our self, but only if we have Fishing Pole equipped, else it will be a lot of checks.
    elseif (event == "UNIT_SPELLCAST_SUCCEEDED") and (arg1 == "player") and (IsEquippedItemType(GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON,LE_ITEM_WEAPON_FISHINGPOLE)) == true)then
        if (arg3 == 7620) or (arg3 == 7731) or (arg3 == 7732) or (arg3 == 18248) or (arg3 == 33095) or (arg3 == 51294) then
            NewZoneSkill()
        end
-- ====================================================================================================
    -- Did we get a info message ?
    -- (This one is for Vanilla and TBC as you get a error message if nothing is caught, in WotLK and later you will always catch something, it's just grey if skill is to low, we check that later.)
    elseif (event == "UI_INFO_MESSAGE") then
        if (arg1 == 378) then -- SPELL_FAILED_FISHING_TOO_LOW = "Requires Fishing %d";
            AdjustFishingSkill()
        end
-- ====================================================================================================
    -- Did we get a error message ?
    elseif (event == "UI_ERROR_MESSAGE") then
        if (arg1 == 259) then -- Must have a Fishing Pole equipped
            -- Clear the binding we have made for the button.
            ClearOverrideBindings(btn);
        end
-- ====================================================================================================
    elseif (event == "ZONE_CHANGED") or (event == "ZONE_CHANGED_INDOORS") or (event == "ZONE_CHANGED_NEW_AREA") then
        FishingStatisticsInterface()
    end
-- ====================================================================================================
    -- Did we loot something ?
    if (event == "LOOT_READY") then -- For some reason this is dobbelt fireing when the area is crowded.
    -- if (event == "LOOT_OPENED") then -- For some reason this is not always fireing, seems to just be some characters it's working on.

        -- Set locals
        local SetNewTime = 0
        local LootDelay = 0.3

        -- Get the raw loot source. We only use number 1 to make it all a bit faster.
        local LootSources = {GetLootSourceInfo(1)}

        -- Is it loot from fishing ?
        if (FixLootSourceInfo(LootSources[1]) == "GameObject-35591") then

            -- Set a small delay as the code is executed faster then the game can handle
            if ((GetTime() - SetNewTime) >= LootDelay) then

                -- Make a loop so we can check it all.
                for i = GetNumLootItems(), 1, -1 do

                    -- Get loot quality.
                    local _, Name, _, _, LootQuality = GetLootSlotInfo(i)

                    -- Get the item link from the loot.
                    local ItemLink = GetLootSlotLink(i)

                    -- Add the loot we found.
                    AddLoot(Name, ItemLink, LootQuality)

                    -- Debug
                    if (FF_Debug == true) then
                        DEBUG_PRINT_TEXT(ItemLink .. " was send to be added to database.")
                    end

                    -- Fast auto loot, but only if auto loot is enabled.
                    if (GetCVarBool("autoLootDefault") ~= IsModifiedClick("AUTOLOOTTOGGLE")) then
                        -- Loot
                        LootSlot(i)
                    end
                    -- Set a new time so we can calculate the delay.
                    SetNewTime = GetTime()
                end
            end
            -- Start counter
            Counter(ItemLink, LootQuality)
        end
    end
end
)

-- ====================================================================================================
-- =                   The OnUpdate function (Maybe we need it, if we do it's here)                   =
-- ====================================================================================================

f:SetScript("OnUpdate",function()

    

end)

-- ====================================================================================================
-- =                                         Add loot to list                                         =
-- ====================================================================================================

function AddLoot(Name, Link, Quality)

    -- Set locals
    local FakeGrey = false
    local QuestItem = false
    local SpecialItem = false
    local  Zone = nil
    local CountBefore = 0

    -- Get name.
    local LootName = Name
    -- Get link.
    local LootLink = Link
    -- Get quality.
    local LootQuality = Quality

    -- Make sure that we have a name.
    if (LootName == "") or (LootName == nil) then
        -- Debug
        if (FF_Debug == true) then
            DEBUG_PRINT_TEXT("The name of the loot was not found.");
        end
        return
    end

    -- Make sure that we have the link.
    if (LootLink == "") or (LootLink == nil) then
        -- Debug
        if (FF_Debug == true) then
            DEBUG_PRINT_TEXT("The link of the loot was not found.");
        end
        return
    end

    -- Make sure that we have the quality.
    if (LootQuality == "") or (LootQuality == nil) then
        -- Debug
        if (FF_Debug == true) then
            DEBUG_PRINT_TEXT("The quality of the loot was not found.");
        end
        return
    end

    -- Get the ID.
    local ItemID = tonumber(strmatch(LootLink, "item:(%d+):"))

    -- Make sure that we got a ID.
    if (ItemID == "") or (ItemID == nil) then
        -- Debug
        if (FF_Debug == true) then
            DEBUG_PRINT_TEXT("The ID of the loot was not found.");
        end
        return
    end

    -- Some items are grey but are not counting as grey, just like some coins in Dalaran.
    -- Check if it's a "fake grey" item.
    if (LootQuality == 0) then
        -- Loop throuh the fake grey list to see if ID is there.
        for k,v in pairs(FAKE_GREY_LOOT_LIST) do
            if (v == ItemID) then
                FakeGrey = true
                -- Debug
                if (FF_Debug == true) then
                    DEBUG_PRINT_TEXT(LootLink .. " is a fake grey.");
                end
            end
        end

    -- Item was not grey.
    else
        -- Is it a quest item ?
        for k,v in pairs(QUEST_FISHING_ITEMS) do
            if (v == ItemID) then
                QuestItem = true
                -- Play a sound so we can Netflix and fish at the same time. ;)
                -- PlaySoundFile("Sound\\Creature\\Mortar Team\\MortarTeamPissed9.ogg", "Master");
                PlaySound(SOUND_FILE_ID[ChosenSound]);
                -- Debug
                if (FF_Debug == true) then
                    DEBUG_PRINT_TEXT(LootLink .. " is a quest item.");
                end
            end
        end
        -- Is it a special item (Turtle mount for examlpe)
        for k,v in pairs(SPECIAL_FISHING_ITEMS) do
            if (v == ItemID) then
                SpecialItem = true
                -- Play a sound so we can Netflix and fish at the same time. ;)
                -- PlaySoundFile("Sound\\Creature\\Mortar Team\\MortarTeamPissed9.ogg", "Master");
                PlaySound(SOUND_FILE_ID[ChosenSound]);
                -- Debug
                if (FF_Debug == true) then
                    DEBUG_PRINT_TEXT(LootLink .. " is a special item.");
                end
            end
        end
    end

    -- Get the zone we are in so we can add the right place.
        Zone = GetZone()

    -- Check that we have made all the tables that we need, if not, then we make them.
    if (not FISHING_LOOT[Zone]) then
        FISHING_LOOT[Zone] = {};
    end
    if (not FISHING_LOOT[Zone][ItemID]) then
        FISHING_LOOT[Zone][ItemID] = {};
        FISHING_LOOT[Zone][ItemID].LootName = 0
        FISHING_LOOT[Zone][ItemID].NumberCaught = 0
        FISHING_LOOT[Zone][ItemID].QuestItem = 0
        FISHING_LOOT[Zone][ItemID].SpecialItem = 0
        FISHING_LOOT[Zone][ItemID].LootQuality = 0
        FISHING_LOOT[Zone][ItemID].FakeGrey = false

        -- Tell that we are adding new loot.
        PRINT_TEXT("Adding " .. LootLink .. " to location " .. Zone .. ".");
    end

    -- What number did we have before we are adding. (For debugging.)
    CountBefore = FISHING_LOOT[Zone][ItemID].NumberCaught

    -- Add what we have found to the table.
    FISHING_LOOT[Zone][ItemID].LootName = LootName
    FISHING_LOOT[Zone][ItemID].NumberCaught = FISHING_LOOT[Zone][ItemID].NumberCaught + 1
    FISHING_LOOT[Zone][ItemID].QuestItem = QuestItem
    FISHING_LOOT[Zone][ItemID].SpecialItem = SpecialItem
    FISHING_LOOT[Zone][ItemID].LootQuality = LootQuality
    -- Was it a fake grey item ?
    if (FakeGrey == true) then
        FISHING_LOOT[Zone][ItemID].FakeGrey = true
    else
        FISHING_LOOT[Zone][ItemID].FakeGrey = false
    end

    -- Clear the binding we have made for the button, else it might freeze when we click to fast.
    ClearOverrideBindings(btn);
    -- Reset click time.
    lastClickTime = nil;

    -- Debug
    if (FF_Debug == true) then
        DEBUG_PRINT_TEXT("Loot count:")
        print("Loot: " .. LootLink)
        print("Before: " .. CountBefore)
        print("After: " .. FISHING_LOOT[Zone][ItemID].NumberCaught)
    end

    -- Adjust fishing skill if it a grey item there is not on the "fake grey" list.
    if (LootQuality == 0) and (FakeGrey == false) then
        -- Adjust fishing skill if it need adjustment.
        AdjustFishingSkill()
        -- Debug
        if (FF_Debug == true) then
            DEBUG_PRINT_TEXT("Order send to adjust fishing skill.");
        end
    end

    -- Refresh fishing statistics interface.
    FishingStatisticsInterface()

end

-- ====================================================================================================
-- =                Counter so we at some point can make some statistics on everything                =
-- ====================================================================================================

function Counter()

    -- Set locals
    local FailedAttempts = 0
    local SuccessfulAttempts = 0
    -- Get the zone
    local Zone = GetZone()

    -- Check that we have the table we want to look in, it should be there as it made in add loot.
    if (FISHING_LOOT[Zone]) then
        -- Loop through it all and look for what we have to count.
        for key,value in pairs(FISHING_LOOT[Zone]) do
            -- Count all grey items.
            if (tonumber(FISHING_LOOT[Zone][key].LootQuality) == 0) and (FISHING_LOOT[Zone][key].FakeGrey == false) then
                FailedAttempts = FailedAttempts + tonumber(FISHING_LOOT[Zone][key].NumberCaught)
            -- Count all there is not grey.
            elseif (tonumber(FISHING_LOOT[Zone][key].LootQuality) > 0) and (FISHING_LOOT[Zone][key].FakeGrey == false) then
                SuccessfulAttempts = SuccessfulAttempts + tonumber(FISHING_LOOT[Zone][key].NumberCaught)
            -- Count all the fake grey and add it the the good loot.
            elseif (tonumber(FISHING_LOOT[Zone][key].LootQuality) == 0) and (FISHING_LOOT[Zone][key].FakeGrey == true) then
                SuccessfulAttempts = SuccessfulAttempts + tonumber(FISHING_LOOT[Zone][key].NumberCaught)
            end
        end
    end

    -- Check that the table is made, if not then make it and set to 0
    if (not SUCCESSFUL_THROWS) then
        SUCCESSFUL_THROWS = {}
    end
    if (not SUCCESSFUL_THROWS["Total"]) then
        SUCCESSFUL_THROWS.Total = 0
    end
    if (not SUCCESSFUL_THROWS[Zone]) then
        SUCCESSFUL_THROWS[Zone] = {}
        SUCCESSFUL_THROWS[Zone] = 0
    end

    -- Add a +1 to the total counter
    SUCCESSFUL_THROWS.Total = tonumber(SUCCESSFUL_THROWS.Total) + 1
    SUCCESSFUL_THROWS[Zone] = tonumber(SUCCESSFUL_THROWS[Zone]) + 1

    -- Debug
    if (FF_Debug == true) then
        DEBUG_PRINT_TEXT("Total counter: " .. SUCCESSFUL_THROWS.Total)
        DEBUG_PRINT_TEXT("Zone counter: " .. SUCCESSFUL_THROWS[Zone])
    end

end

-- ====================================================================================================
-- =           Function where we check where the loot is from (mob, game object, and so on)           =
-- =                 The reason that we are not just checking the ID is that in later                 =
-- =               expanctions there will come mob's with same ID as the Fishing Bobber               =
-- =                        Who knows, maybe we will be playing there also. ;)                        =
-- ====================================================================================================

function FixLootSourceInfo(arg1)
    -- Is there anything send to us ?
    if (arg1 == nil) or (arg1 == "") then
        return "Nothing"
    end
    -- Make table
    local t = {}
    -- Make locals
    local intCount = 0
    local NewStr = nil
    -- Replace - with space
    NewStr = string.gsub(arg1, "-", " ")
    -- Split it all up
    for Str in string.gmatch(NewStr, "[^%s]+") do
        table.insert(t, Str)
        intCount = intCount + 1
    end
    -- Return what we found.
    if (intCount >= 6) then
        return t[1] .. "-" ..  t[6]
    else
        return "Nothing"
    end
end

-- ====================================================================================================
-- =                                Check what zone we are fishing in.                                =
-- ====================================================================================================

function GetZone()
    -- Find the name of the zone we are in.
    local ZoneName = GetZoneText();
    -- Fine the name of the sub-zone we are in.
    local SubZoneName = GetMinimapZoneText();
    -- Make a name we will use in the table
    local FishingZone = ZoneName .. " - " .. SubZoneName

    -- Return zone
    return FishingZone
end

-- ====================================================================================================
-- =                                 Check if zone have a skill level                                 =
-- ====================================================================================================

function NewZoneSkill()
    -- Get the zone where we are.
    local Zone = GetZone()
    -- Is the zone already added ?
    if (REQUIRED_FISHING_SKILL[Zone] == nil) then
        -- Add it an give it the value 25 as we have no idea what the 100% skill is.
        REQUIRED_FISHING_SKILL[Zone] = 25
        -- Inform that a new zone have been added.
        PRINT_TEXT(Zone .. " added to the list with fishing skill 25.")
    end

    -- Update interface.
    FishingStatisticsInterface()
end

-- ====================================================================================================
-- =                  Adjust our fishing skill so we will get the lure when we need.                  =
-- ====================================================================================================

function AdjustFishingSkill()
    -- Get the zone we are in
    local FishingZone = GetZone()
    -- Get our total fishing skill
    local CharacterFishingSkill = tonumber(TotalFishingSkill(false))

    if (tonumber(CharacterFishingSkill) >= tonumber(REQUIRED_FISHING_SKILL[FishingZone])) then
        if CharacterFishingSkill >= 575 then
            REQUIRED_FISHING_SKILL[FishingZone] = 1
        elseif CharacterFishingSkill >= 525 then
            REQUIRED_FISHING_SKILL[FishingZone] = 575
        elseif CharacterFishingSkill >= 500 then
            REQUIRED_FISHING_SKILL[FishingZone] = 525
        elseif CharacterFishingSkill >= 490 then
            REQUIRED_FISHING_SKILL[FishingZone] = 500
        elseif CharacterFishingSkill >= 475 then
            REQUIRED_FISHING_SKILL[FishingZone] = 490
        elseif CharacterFishingSkill >= 450 then
            REQUIRED_FISHING_SKILL[FishingZone] = 475
        elseif CharacterFishingSkill >= 425 then
            REQUIRED_FISHING_SKILL[FishingZone] = 450
        elseif CharacterFishingSkill >= 400 then
            REQUIRED_FISHING_SKILL[FishingZone] = 425
        elseif CharacterFishingSkill >= 375 then
            REQUIRED_FISHING_SKILL[FishingZone] = 400
        elseif CharacterFishingSkill >= 300 then
            REQUIRED_FISHING_SKILL[FishingZone] = 375
        elseif CharacterFishingSkill >= 225 then
            REQUIRED_FISHING_SKILL[FishingZone] = 300
        elseif CharacterFishingSkill >= 150 then
            REQUIRED_FISHING_SKILL[FishingZone] = 225
        elseif CharacterFishingSkill >= 75 then
            REQUIRED_FISHING_SKILL[FishingZone] = 150
        elseif CharacterFishingSkill >= 25 then
            REQUIRED_FISHING_SKILL[FishingZone] = 75
        end
        -- Inform that we have changed the zone skill.
        PRINT_TEXT("\"" .. FishingZone .. "\" is now adjusted to fishing skill: " .. REQUIRED_FISHING_SKILL[FishingZone]);
    end

    -- Update interface.
    FishingStatisticsInterface()

end

-- ====================================================================================================
-- =                                   Find our total fishing skill                                   =
-- ====================================================================================================

function TotalFishingSkill(pure)
    -- Set locals
    local CharacterSkill = 0
    local CharacterSkillPlus = 0
    local CalculatedSkill = 0

    -- What are our fishing skill ?
    for skillIndex = 1, GetNumSkillLines() do
        local skillName, header, _, skillRank, numTempPoints, skillModifier, skillMaxRank,  _ , _, _, minLevel, skillCostType, skillDescription = GetSkillLineInfo(skillIndex)
        if not header then
            if skillName == LocalizedFishingName then
                CharacterSkill = skillRank
                CharacterSkillPlus = skillModifier
            end
        end
    end

    -- Did we find anything ?
    if (CharacterSkill ~= nil) and (CharacterSkillPlus ~= nil) then
        -- Is it the characters skill or the total skill we need ?
        if (pure == true) then
            -- Only the character skill
            CalculatedSkill = tonumber(CharacterSkill)
        else
            -- The character skill + skill from Fishing Pole + Lure + Rum
            CalculatedSkill = tonumber(CharacterSkill) + tonumber(CharacterSkillPlus)
        end
    end

    -- Return our fishing skill.
    return CalculatedSkill
end

-- ====================================================================================================
-- =                              All the things we need for the button.                              =
-- =                    There is a lot of stuff here, but I will try to explain as                    =
-- =                         much as I can so I don't forget it for next time                         =
-- =              Right now when writing this addon I know nothing about making buttons.              =
-- ====================================================================================================

-- Creat the button we need.
if (not btn) then
    btn = CreateFrame("Button", "FishingFriend_Button", UIParent, "SecureActionButtonTemplate");
    --btn:EnableMouse(true);
    --btn:RegisterForClicks("RightButtonUp", "RightButtonDown"); -- up and down required for SecureActionButtonTemplate
    -- btn:SetAttribute("spell", "Fishing")
end

-- ====================================================================================================

-- The event GLOBAL_MOUSE_DOWN was triggert.
function MouseClickTriggert(button)
    -- Was it double click ?
    if (CheckForDoubleClick() == true) then
        -- Unlock the mouse.
        FreeTheMouse()
        -- Do we need to use a lure ?
        if (DoWeLure() ~= nil) then
            SetOverrideBindingItem(btn, true, "BUTTON2", DoWeLure());
        else
            SetOverrideBindingSpell(btn, true, "BUTTON2", LocalizedFishingName);
        end
    else
        -- Was not a double click, so clear the binding.
        ClearOverrideBindings(btn);
    end
    -- Unlock the mouse.
    FreeTheMouse()
end

-- ====================================================================================================

function FreeTheMouse()
    if (IsMouselooking() == true) then
        MouselookStop()
    end
end

-- ====================================================================================================

-- Did we double click ?
function CheckForDoubleClick()
    -- Make sure it's not just the loot frame we are clicking.
    if (not LootFrame:IsShown()) and (GetNumLootItems() == 0) and (MouseOverBobber() == false) then
        -- Do we have a time for when we clicked last time ?
        if (lastClickTime) then
            -- Get the time for this click.
            local pressTime = GetTime();
            -- Calculate the time between the two clicks.
            local doubleTime = pressTime - lastClickTime;
            -- Is the two click between the min. and max. time we have set ?
            if ((doubleTime < MaxClickTime) and (doubleTime > MinClickTime)) then
                -- Reset click time.
                lastClickTime = nil;
                -- Debug
                if (FF_Debug == true) then
                    -- DEBUG_PRINT_TEXT("It was a double click");
                end
                -- It was a double click, so return "true"
                return true;
            end
        end
    end
    -- Get the time for the click we just did.
    lastClickTime = GetTime();
    -- Restore overridden bindings that we have made with this button.
    ClearOverrideBindings(btn);
    -- Debug
    if (FF_Debug == true) then
        -- DEBUG_PRINT_TEXT("It was NOT a double click");
    end
    -- It was NOT a double click, return "false"
    return false;
end

-- ====================================================================================================
-- =                         Check to see if mouse is over a "Fishing Bobber"                         =
-- ====================================================================================================

function MouseOverBobber()

    -- Set some locals
    local LocalizedFishingBobber;

    -- Did we find anything usefull ?
    if (L["Fishing Bobber"]) and (L["Fishing Bobber"] ~= "Fishing Bobber unknown") then
        LocalizedFishingBobber = L["Fishing Bobber"]
    else
        PRINT_TEXT("The addon don't know the localized name of Fishing Bobber.")
        PRINT_TEXT("Please report this error with the localized name of the Fishing Bobber.")
        return false
    end

    -- Get the name from the mouseover tooltip.
    local ToolTipText = GameTooltipTextLeft1

    -- Did we find anything and was it the name of the Fishing Bobber ?
    if (ToolTipText) and (ToolTipText:GetText() == LocalizedFishingBobber) then
        return true
    end
    return false
end

-- ====================================================================================================
-- =                                       Add a lure and drink                                       =
-- ====================================================================================================

function DoWeLure()
    -- Get the skill of the zone we are in.
    local FishingZone = GetZone()
    if (not REQUIRED_FISHING_SKILL[FishingZone]) then
        -- No data colected yet, wait for that.
        return nil
    end

    -- Do we even need a lure ? No need to continue if we don't
    if (tonumber(REQUIRED_FISHING_SKILL[FishingZone]) <= tonumber(TotalFishingSkill(false))) then
        return nil
    end

    -- Set locals
    local TempSkill = nil
    local EnchantedWith = "NoEnchant"
    local MissingFishingSkill = 0
    local LocalizedRum = nil

    -- Do we already have a temporary enchant on our fishing pole ?
    local hasMainHandEnchant, _, _, mainHandEnchantID, _, _, _, _ = GetWeaponEnchantInfo()
    if (hasMainHandEnchant == true) then
        -- Is is a fishing enchant we have on ?
        for key,value in pairs(FISHING_POLE_ENCHANT_ID) do
            -- 
            for k,v in pairs(value) do
                if (k == "SkillAdded") then
                    TempSkill = v
                end
                if (k == "EnchantID") and (v == mainHandEnchantID) then
                    EnchantedWith = TempSkill
                end
            end
        end
        -- If it was a fishing enchant, can we then use rum to get it higher ?
        if (EnchantedWith ~= "NoEnchant") and (HaveRum() == true) then
            -- Get the local name of the rum and return it.
            LocalizedRum = GetItemInfo(34832)
            return LocalizedRum
        -- It was not a fishing enchant, enchant the pole.
        elseif (EnchantedWith == "NoEnchant") and (HaveLure() ~= "NoLure") then
            return HaveLure()
        -- It is as good as it get's, just get skill up. ;)
        else
            return nil
        end
    -- We have no fishing enchant, enchant the pole.
    else
        if (HaveLure() ~= "NoLure") then
            return HaveLure()
        else
            return nil
        end
    end
end

-- ====================================================================================================
-- =                             Check to see if we have rum in our bags.                             =
-- ====================================================================================================

function HaveRum()
    -- Set some locals
    local RumBuffFound = nil
    -- First we check to see if we already have the buff from rum.
    for i=1,5 do
        local name, _, _, _, _, _, _, _, _, SpellId = UnitBuff("player",i);
        if (SpellId == 45694) then
            RumBuffFound = true
        end
    end

    -- We have the rum buff
    if (RumBuffFound == true) then
        return false
    -- We did not have a rum buff.
    else
        -- Do we have any rum in our bags ?
        for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
            local numSlots = C_Container.GetContainerNumSlots(bag);
            if (numSlots > 0) then
                -- check each slot in the bag
                for slot=1, numSlots do
                    local ItemId = C_Container.GetContainerItemID(bag, slot);
                    if (ItemId == 34832) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- ====================================================================================================
-- =                             Check to see if we have lure in our bags                             =
-- ====================================================================================================

function HaveLure()
    -- Do we have the fishing hat equipped ? If so, then we use that one as that is no cost.
    local HeadSlotInfo = GetInventoryItemLink("player",GetInventorySlotInfo("HeadSlot"));
    -- Do we have anything in the head slot ?
    if (HeadSlotInfo) then
        local HeadSlotName, ItemLink = GetItemInfo(HeadSlotInfo);
        local ItemID = tonumber(strmatch(ItemLink, "item:(%d+):"));
        if (ItemID == 33820) then
            return HeadSlotName
        end
    end

    -- Set locals
    local LurePrio1 = nil
    local LurePrio2 = nil
    local LurePrio3 = nil
    local LurePrio4 = nil
    local LurePrio5 = nil
    local LurePrio6 = nil
    local LurePrio7 = nil
    local LurePrio8 = nil

    -- Loop through all bags to see if we have any lures
    for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        local numSlots = C_Container.GetContainerNumSlots(bag);
        if (numSlots > 0) then
            for slot=1, numSlots do
                local ItemId = C_Container.GetContainerItemID(bag, slot);
                -- Let's do it the ugly way, another smarter way will come at some point, maybe.
                if (ItemId == 34861) and (TotalFishingSkill(true) >= 100) then      -- Sharpened Fish Hook
                    LurePrio1 = true
                elseif (ItemId == 46006) and (TotalFishingSkill(true) >= 100) then  -- Glow Worm
                    LurePrio2 = true
                elseif (ItemId == 6533) and (TotalFishingSkill(true) >= 100) then   -- Aquadynamic Fish Attractor
                    LurePrio3 = true
                elseif (ItemId == 7307) and (TotalFishingSkill(true) >= 75) then    -- Flesh Eating Worm
                    LurePrio4 = true
                elseif (ItemId == 6532) and (TotalFishingSkill(true) >= 75) then    -- Bright Baubles
                    LurePrio5 = true
                elseif (ItemId == 6811) and (TotalFishingSkill(true) >= 50) then    -- Aquadynamic Fish Lens
                    LurePrio6 = true
                elseif (ItemId == 6530) and (TotalFishingSkill(true) >= 50) then    -- Nightcrawlers
                    LurePrio7 = true
                elseif (ItemId == 6529) and (TotalFishingSkill(true) >= 1) then     -- Shiny Bauble
                    LurePrio8 = true
                end
            end
        end
    end
    -- Now another ugly way
    if (LurePrio1 == true) then
        return GetItemInfo(34861)
    elseif (LurePrio2 == true) then
        return GetItemInfo(46006)
    elseif (LurePrio3 == true) then
        return GetItemInfo(6533)
    elseif (LurePrio4 == true) then
        return GetItemInfo(7307)
    elseif (LurePrio5 == true) then
        return GetItemInfo(6532)
    elseif (LurePrio6 == true) then
        return GetItemInfo(6811)
    elseif (LurePrio7 == true) then
        return GetItemInfo(6530)
    elseif (LurePrio8 == true) then
        return GetItemInfo(6529)
    else
        return "NoLure"
    end
end

-- ====================================================================================================
-- ====================================================================================================
-- ====================================================================================================
-- ====================================================================================================
-- =                                          The interface.                                          =
-- ====================================================================================================
-- ====================================================================================================
-- ====================================================================================================
-- ====================================================================================================

-- HELP
-- https://www.youtube.com/watch?v=nfaE7NQhMlc&list=PL3wt7cLYn4N-3D3PTTUZBM2t1exFmoA2G&ab_channel=Mayron


-- ====================================================================================================
-- =                                                    =
-- ====================================================================================================

function FishingStatisticsInterface()

    -- Make parent frame movable.
    f1:SetMovable(true);
    f1:SetScript("OnMouseDown",f1.StartMoving);
    f1:SetScript("OnMouseUp",f1.StopMovingOrSizing);

    if (not f1.tex) then
        f1.tex = f1:CreateTexture(nil, "ARTWORK");
        f1.tex:SetAllPoints(f1);
        f1.tex:SetTexture("Interface/Tooltips/UI-Tooltip-Background");
        f1.tex:SetColorTexture(0, 0, 0, 0.3); -- black, 20% opacity
    end

    -- Make the title there is showing fishing skill and zone skill.
    if (not f1.title) then
        f1.title = f1:CreateFontString(nil, "OVERLAY", "GameTooltipText");
        f1.title:SetPoint("TOP", 0, -10);
    end
    f1.title:SetText(GetFishingHeadline());

    -- 
    for i = 1, FishingStatisticsLines do
        -- Only make it if it's not already there.
        if (StopStatisticsLines == false) and (not f1.FonstringsLeft[i]) then
            -- 
            f1.FonstringsLeft[i] = f1:CreateFontString(nil, "OVERLAY", "GameTooltipText");
            f1.FonstringsRight[i] = f1:CreateFontString(nil, "OVERLAY", "GameTooltipText");

            -- Is it the first one ? If so, then anchor it to the parent frame.
            if (i == 1) then
                f1.FonstringsLeft[i]:SetPoint("TOPLEFT", f1, 5, -32);
                f1.FonstringsRight[i]:SetPoint("TOPRIGHT", f1, -5, -32);
            -- Anchor it the the line above.
            else
                f1.FonstringsLeft[i]:SetPoint("TOPLEFT", f1.FonstringsLeft[i-1], 0, -18);
                f1.FonstringsRight[i]:SetPoint("TOPRIGHT", f1.FonstringsRight[i-1], 0, -18);
            end
        end

        -- Set the text.
        f1.FonstringsLeft[i]:SetText("Left " .. i);
        f1.FonstringsRight[i]:SetText("Right " .. i);

        -- We need to stop the frame making, let's try this little tricks.
        if (i == FishingStatisticsLines) then
            StopStatisticsLines = true
        end
    end


--[[

    -- 
    -- for k,v in ipairs(table2) do
    for i = 1, LineStat do
        -- 
        if (not f1.Fonstrings[i]) then
            -- 
            left = f1:CreateFontString(nil, "OVERLAY", "GameTooltipText")
            right = f1:CreateFontString(nil, "OVERLAY", "GameTooltipText")
            print("FontString " .. i .. " made.")
            -- 
            if i == 1 then
                -- 
                left:SetPoint("TOPLEFT", f1, 5, -32)
                right:SetPoint("TOPRIGHT", f1, -5, -32)
            -- 
            else
                -- 
                left:SetPoint("TOPLEFT", f1.Fonstrings[i-1].left, 0, -18)
                right:SetPoint("TOPRIGHT", f1.Fonstrings[i-1].right, 0, -18)
            end
            -- 
            tinsert(f1.Fonstrings, {left=left, right=right})
        end
        -- 
        f1.Fonstrings[i].left:SetText("Left " .. i)
        f1.Fonstrings[i].right:SetText("Right " .. i)
    end
    
--]]



--[[


    -- Check if the font strings for showing fishing stats is made.
    if (not f1.leftline1) then
        -- Make a loop to make all the font strings
        for i = 1, LineStat do
            -- Is it the first loop ?
            if (i == 1) then
                f1.leftline1 = f1:CreateFontString(nil, "OVERLAY", "GameTooltipText");
                f1.leftline1:SetPoint("TOPLEFT", f1, 5, -32)
                f1.rightline1 = f1:CreateFontString(nil, "OVERLAY", "GameTooltipText");
                f1.rightline1:SetPoint("TOPRIGHT", f1, -5, -32)
            else
                f1.leftline2 = f1:CreateFontString(nil, "OVERLAY", "GameTooltipText");
                f1.leftline2:SetPoint("TOPLEFT", f1.leftline1, 0, -18)
                f1.rightline2 = f1:CreateFontString(nil, "OVERLAY", "GameTooltipText");
                f1.rightline2:SetPoint("TOPRIGHT", f1.rightline1, 0, -18)
                
                f1.leftline3 = f1:CreateFontString(nil, "OVERLAY", "GameTooltipText");
                f1.leftline3:SetPoint("TOPLEFT", f1.leftline2, 0, -18)
                f1.rightline3 = f1:CreateFontString(nil, "OVERLAY", "GameTooltipText");
                f1.rightline3:SetPoint("TOPRIGHT", f1.rightline2, 0, -18)
                
                f1.leftline4 = f1:CreateFontString(nil, "OVERLAY", "GameTooltipText");
                f1.leftline4:SetPoint("TOPLEFT", f1.leftline3, 0, -18)
                f1.rightline4 = f1:CreateFontString(nil, "OVERLAY", "GameTooltipText");
                f1.rightline4:SetPoint("TOPRIGHT", f1.rightline3, 0, -18)
                
                f1.leftline5 = f1:CreateFontString(nil, "OVERLAY", "GameTooltipText");
                f1.leftline5:SetPoint("TOPLEFT", f1.leftline4, 0, -18)
                f1.rightline5 = f1:CreateFontString(nil, "OVERLAY", "GameTooltipText");
                f1.rightline5:SetPoint("TOPRIGHT", f1.rightline4, 0, -18)
                
                f1.leftline6 = f1:CreateFontString(nil, "OVERLAY", "GameTooltipText");
                f1.leftline6:SetPoint("TOPLEFT", f1.leftline5, 0, -18)
                f1.rightline6 = f1:CreateFontString(nil, "OVERLAY", "GameTooltipText");
                f1.rightline6:SetPoint("TOPRIGHT", f1.rightline5, 0, -18)
                
                f1.leftline7 = f1:CreateFontString(nil, "OVERLAY", "GameTooltipText");
                f1.leftline7:SetPoint("TOPLEFT", f1.leftline6, 0, -18)
                f1.rightline7 = f1:CreateFontString(nil, "OVERLAY", "GameTooltipText");
                f1.rightline7:SetPoint("TOPRIGHT", f1.rightline6, 0, -18)
                
                f1.leftline8 = f1:CreateFontString(nil, "OVERLAY", "GameTooltipText");
                f1.leftline8:SetPoint("TOPLEFT", f1.leftline7, 0, -18)
                f1.rightline8 = f1:CreateFontString(nil, "OVERLAY", "GameTooltipText");
                f1.rightline8:SetPoint("TOPRIGHT", f1.rightline7, 0, -18)
                
                f1.leftline9 = f1:CreateFontString(nil, "OVERLAY", "GameTooltipText");
                f1.leftline9:SetPoint("TOPLEFT", f1.leftline8, 0, -18)
                f1.rightline9 = f1:CreateFontString(nil, "OVERLAY", "GameTooltipText");
                f1.rightline9:SetPoint("TOPRIGHT", f1.rightline8, 0, -18)
                
                f1.leftline10 = f1:CreateFontString(nil, "OVERLAY", "GameTooltipText");
                f1.leftline10:SetPoint("TOPLEFT", f1.leftline9, 0, -18)
                f1.rightline10 = f1:CreateFontString(nil, "OVERLAY", "GameTooltipText");
                f1.rightline10:SetPoint("TOPRIGHT", f1.rightline9, 0, -18)
            end
        end
    end

    -- Get the zone we are in.
    local Zone = GetZone()

    -- Make a temp table where the numbers of fish is sorted.
    if (FISHING_LOOT[Zone]) then
        table.sort(FISHING_LOOT[Zone])
    end

    -- Set some text in the left and right stat lines
    f1.leftline1:SetText("Left 1");
    f1.rightline1:SetText("Right 1");
    f1.leftline2:SetText("Left 2");
    f1.rightline2:SetText("Right 2");
    f1.leftline3:SetText("Left 3");
    f1.rightline3:SetText("Right 3");
    f1.leftline4:SetText("Left 4");
    f1.rightline4:SetText("Right 4");
    f1.leftline5:SetText("Left 5");
    f1.rightline5:SetText("Right 5");
    f1.leftline6:SetText("Left 6");
    f1.rightline6:SetText("Right 6");
    f1.leftline7:SetText("Left 7");
    f1.rightline7:SetText("Right 7");
    f1.leftline8:SetText("Left 8");
    f1.rightline8:SetText("Right 8");
    f1.leftline9:SetText("Left 9");
    f1.rightline9:SetText("Right 9");
    f1.leftline10:SetText("Left 10");
    f1.rightline10:SetText("Right 10");


--]]





--[[


    local table = {
        ["entry"] = "one",
        ["entry2"] = "two",
        ["entry3"] = "three",
        ["entry4"] = "Four",
        ["entry5"] = "Five",
        ["entry6"] = "Six",
        ["entry7"] = "Seven",
        ["entry8"] = "Eight",
        ["entry9"] = "Nine",
        ["entry10"] = "Ten",
    }
     
    local f = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(250, 400)
    f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 40, -40)
     
    f.Title = f:CreateFontString(nil, "OVERLAY", "GameTooltipText")
    f.Title:SetPoint("TOP", 0, -2)
    f.Title:SetText("Original")
     
    f.grabdata = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
    f.grabdata:SetText("G")
    f.grabdata:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    f.grabdata:SetSize(40, 20)
    local offset = 0
    f.grabdata:SetScript("OnClick", function(self)
        local i = 0
        offset = offset + 1
        for k,v in pairs(table) do 
            local fsname = f:CreateFontString(nil, "OVERLAY", "GameTooltipText")
            fsname:SetPoint("TOPLEFT", f, "TOPLEFT", offset, -17*(i-(-2)))
            fsname:SetText(k)
                
            local fsname2 = f:CreateFontString(nil, "OVERLAY", "GameTooltipText")
            fsname2:SetPoint("TOPRIGHT", f, "TOPRIGHT", -offset, -17*(i-(-2)))
            fsname2:SetText(v)              
            i = i + 1
        end
    end
    )
     
    -- Constant ordered display
    local table2 = {
        { display="entry", value="one" },
        { display="entry2", value="two" },
        { display="entry3", value="three" },
        { display="entry4", value="Four" },
    }
     
    local f2 = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset")
    f2:SetSize(250, 400)
    f2:SetPoint("LEFT", f, "RIGHT")
     
    f2.Title = f2:CreateFontString(nil, "OVERLAY", "GameTooltipText")
    f2.Title:SetPoint("TOP", 0, -2)
    f2.Title:SetText("Constant Ordered")
     
    f2.grabdata = CreateFrame("Button", nil, f2, "GameMenuButtonTemplate")
    f2.grabdata:SetText("G")
    f2.grabdata:SetPoint("TOPLEFT", f2, "TOPLEFT", 0, 0)
    f2.grabdata:SetSize(40, 20)
    local offset = 0
    f2.Fonstrings = {}
    f2.grabdata:SetScript("OnClick", function(self)
        local parent = self:GetParent()
        local left, right
        offset = offset + 0
        for k,v in ipairs(table2) do 
            if not parent.Fonstrings[i] then
                left = self:CreateFontString(nil, "OVERLAY", "GameTooltipText")
                right = self:CreateFontString(nil, "OVERLAY", "GameTooltipText")
                if k == 1 then
                    left:SetPoint("TOPLEFT", self:GetParent(), 9, -22)
                    right:SetPoint("TOPRIGHT", self:GetParent(), -9, -22)
                else
                    left:SetPoint("TOPLEFT", parent.Fonstrings[k-1].left, "BOTTOMLEFT", offset, -2)
                    right:SetPoint("TOPRIGHT", parent.Fonstrings[k-1].right, "BOTTOMRIGHT", -offset, -2)
                end
                tinsert(parent.Fonstrings, {left=left, right=right})
            end
            parent.Fonstrings[k].left:SetText(v.display)
            parent.Fonstrings[k].right:SetText(v.value)
        end
    end)
















    local f = CreateFrame("Frame", nil, UIParent, "TooltipBackdropTemplate")
    f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 40, -40)
    f:SetSize(200, 300)

    f.tex = f:CreateTexture(nil, "ARTWORK")
    f.tex:SetAllPoints(f)
    f.tex:SetTexture("Interface/Tooltips/UI-Tooltip-Background")
    f.tex:SetColorTexture(0, 0, 0, 0.2) -- black, 20% opacity

    -- f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
    f.title = f:CreateFontString(nil, "OVERLAY", "GameTooltipText")
    f.title:SetPoint("TOPLEFT", f.tex, "TOPLEFT", 10, -10);
    f.title:SetText("");
    f.title:SetText(GetFishingHeadline());

    local l = f:CreateLine()
    l:SetColorTexture(0.8,0.2,0,0.9)
    l:SetStartPoint("TOPLEFT", 0, -35)
    l:SetEndPoint("TOPRIGHT", 0, -35)


]]--





















































--[[
f.mask = f:CreateMaskTexture()
f.mask:SetAllPoints(f.tex)
f.mask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
f.tex:AddMaskTexture(f.mask)






local f = CreateFrame("Frame")
f:SetPoint("CENTER", 0, 100)
f:SetSize(100,100)
local l = f:CreateLine()
print(l)
l:SetColorTexture(1,0,0,0.5)
l:SetStartPoint("TOPLEFT",10,10)
l:SetEndPoint("BOTTOMRIGHT",10,10)
f:Show()


local myFrame = CreateFrame("Frame", "FishingFriendFrame", UIParent, "TooltipBackdropTemplate")
myFrame:SetWidth(140) 
myFrame:SetHeight(280)
myFrame:SetPoint("CENTER", 0, 0)
myFrame:SetAlpha(0.60);

local ff_title = myFrame:CreateFontString(nil, "ARTWORK", "GameTooltipText")
ff_title:SetPoint("TOP", 0, 0)
ff_title:SetText("Title for Fishing Friend.")

local t = myFrame:CreateFontString(nil, "OVERLAY", "GameTooltipText")
t:SetPoint("CENTER", 0, 0)
t:SetText("Hello, World!")

---------------------------------
-- Reloaduttons
---------------------------------
-- Save Button:
myFrame.saveBtn = CreateFrame("Button", nil, myFrame, "GameMenuButtonTemplate");
myFrame.saveBtn:SetPoint("CENTER", myFrame, "TOP", 0, -70);
myFrame.saveBtn:SetSize(70, 20);
myFrame.saveBtn:SetText("Save");
myFrame.saveBtn:SetNormalFontObject("GameFontNormalLarge");
myFrame.saveBtn:SetHighlightFontObject("GameFontHighlightLarge");





















-- Start with creating all we need.
-- local FF_Frame = CreateFrame("Frame", "FishingFriendFrame", UIParent, "BasicFrameTemplate");
local FF_Frame = CreateFrame("Frame", "FishingFriendFrame", UIParent, "BasicFrameTemplateWithInset");
FF_Frame:SetSize(260, 360);
FF_Frame:SetPoint("CENTER", UIParent, "CENTER");
FF_Frame.title = FF_Frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
FF_Frame.title:SetPoint("LEFT", FF_Frame.TitleBg, "LEFT", 5, 0);
FF_Frame.title:SetText("Fishing - " .. TotalFishingSkill(true) .. "/" .. TotalFishingSkill(false));


---------------------------------
-- Buttons
---------------------------------
-- Save Button:
FF_Frame.saveBtn = CreateFrame("Button", nil, FF_Frame, "GameMenuButtonTemplate");
FF_Frame.saveBtn:SetPoint("CENTER", FF_Frame, "TOP", 0, -70);
FF_Frame.saveBtn:SetSize(70, 20);
FF_Frame.saveBtn:SetText("Save");
FF_Frame.saveBtn:SetNormalFontObject("GameFontNormalLarge");
FF_Frame.saveBtn:SetHighlightFontObject("GameFontHighlightLarge");

---------------------------------
-- Sliders
---------------------------------
FF_Frame.slider1 = CreateFrame("SLIDER", nil, FF_Frame, "OptionsSliderTemplate");
FF_Frame.slider1:SetPoint("TOP", FF_Frame.saveBtn, "TOP", 0, -120);
FF_Frame.slider1:SetMinMaxValues(1, 100);
FF_Frame.slider1:SetValue(15);
FF_Frame.slider1:SetValueStep(5);
FF_Frame.slider1:SetObeyStepOnDrag(true);






---------------------------------
-- Check Buttons
---------------------------------
-- Check Button 1:
FF_Frame.checkBtn1 = CreateFrame("CheckButton", nil, FF_Frame, "UICheckButtonTemplate");
FF_Frame.checkBtn1:SetPoint("TOPLEFT", FF_Frame.slider1, "BOTTOMLEFT", -10, -40);
FF_Frame.checkBtn1:SetText("My Check Button!");
FF_Frame.checkBtn1:SetChecked(true);



---------------------------------
-- make parent frame movable
---------------------------------
FF_Frame:SetMovable(true)
FF_Frame:SetScript("OnMouseDown",FF_Frame.StartMoving)
FF_Frame:SetScript("OnMouseUp",FF_Frame.StopMovingOrSizing)















































local BUTTON_WIDTH = 300
local BUTTON_HEIGHT = 40
local NUM_BUTTONS = 5

-- frame "factory" returns a frame with elements Portrait, Name and Threat
local function createUnitButton(parent)

  local button = CreateFrame("Button", nil, parent, "TooltipBackdropTemplate")
  button:SetBackdropBorderColor(0.5,0.5,0.5)

  button.Portrait = button:CreateTexture(nil,"ARTWORK")
  button.Portrait:SetSize(BUTTON_HEIGHT-8,BUTTON_HEIGHT-8)
  button.Portrait:SetPoint("LEFT",4,0)

  button.Name = button:CreateFontString(nil,"ARTWORK", "GameFontNormal")
  button.Name:SetPoint("TOPLEFT",button.Portrait,"TOPRIGHT",4,-4)
  button.Name:SetPoint("BOTTOMRIGHT",button,"RIGHT",-4,0)
  button.Name:SetJustifyH("LEFT")

  button.Threat = button:CreateFontString(nil,"ARTWORK","GameFontHighlight")
  button.Threat:SetPoint("TOPLEFT",button.Portrait,"RIGHT",4,0)
  button.Threat:SetPoint("BOTTOMRIGHT",-4,4)
  button.Threat:SetJustifyH("LEFT")

  return button
end

-- updates the portrait, name and threat to the given unit
-- (this is for demo purposes; it'd be better to only update portrait and
-- name when the unit changes, and a separate function to update threat)
local function updateUnitButton(button,unit)
  SetPortraitTexture(button.Portrait,unit)
  button.Name:SetText(UnitName(unit))
  button.Threat:SetText("87% Threat")
end

-- creates parent frame with a standard-looking template
local frame = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplate")
frame:SetSize(BUTTON_WIDTH+10,BUTTON_HEIGHT*NUM_BUTTONS+28)
frame:SetPoint("CENTER")
if (tonumber(TotalFishingSkill(true)) == tonumber(TotalFishingSkill(false))) then
    frame.TitleText:SetText("Fishing - " .. TotalFishingSkill(true))
else
    frame.TitleText:SetText("Fishing - " .. TotalFishingSkill(true) .. "/" .. TotalFishingSkill(false))
end

-- make parent frame movable
frame:SetMovable(true)
frame:SetScript("OnMouseDown",frame.StartMoving)
frame:SetScript("OnMouseUp",frame.StopMovingOrSizing)

-- create and position 3 unitbuttons anchored to the parent
frame.unitButtons = {}
for i=1,NUM_BUTTONS do
  frame.unitButtons[i] = createUnitButton(frame)
  frame.unitButtons[i]:SetSize(BUTTON_WIDTH,BUTTON_HEIGHT)
  frame.unitButtons[i]:SetPoint("TOPLEFT",5,-((i-1)*BUTTON_HEIGHT)-24)
  updateUnitButton(frame.unitButtons[i],"player")
end 










local f1 = CreateFrame("Frame",nil,UIParent)
f1:SetWidth(1) 
f1:SetHeight(1) 
f1:SetAlpha(.90);
f1:SetPoint("CENTER",650,-100)
f1.text = f1:CreateFontString(nil,"ARTWORK") 
f1.text:SetFont("Fonts\\ARIALN.ttf", 13, "OUTLINE")
f1.text:SetPoint("CENTER",0,0)
f1:Hide()
 
local f2 = CreateFrame("Frame",nil,UIParent)
f2:SetWidth(1) 
f2:SetHeight(1) 
f2:SetAlpha(.90);
f2:SetPoint("CENTER",650,-100)
f2.text = f2:CreateFontString(nil,"ARTWORK") 
f2.text:SetFont("Fonts\\ARIALN.ttf", 13, "OUTLINE")
f2.text:SetPoint("CENTER",0,0)
f2:Hide()
 
local function displayupdate(show, message)
    if show == 1 then
        f1.text:SetText(message)
        f1:Show()
        f2:Hide()
    elseif show == 2 then
        f2.text:SetText(message)
        f2:Show()
        f1:Hide()
    else
        f1:Hide()
        f2:Hide()
    end
end
 
displayupdate(1, "|cffffffffmyobjective1")
--or 
displayupdate(2, "|cffffffffmyobjective2")
--or 
displayupdate() -- to just hide both
--or possibly display both objectives in the one fontstring
displayupdate(1, "myobjective1\nmyobjective2")
 
--To use variables:
local objective1 = "myobjective1"
local objective2 = "myobjective2"
displayupdate(1, objective1.."\n"..objective2)








--]]



















end

-- ====================================================================================================
-- =                           The headline showing fishing and zone skill.                           =
-- ====================================================================================================

function GetFishingHeadline()

    -- Set local
    local HeadLine = nil
    local ZoneSkill = nil
    local CharacterSkill = nil
    local CharacterSkillPlus = nil
    local ColoredZoneSkill = nil
    local ColoredCharacterSkill = nil
    local ColoredCharacterSkillPlus = nil
    local SameSkill = nil

    -- Get the zone we are in
    local Zone = GetZone()

    -- Check that we have info about the zone we are in.
    if (not REQUIRED_FISHING_SKILL) or (not REQUIRED_FISHING_SKILL[Zone]) then
        -- No info about the zone, set to "??" until we have it in the database.
        ZoneSkill = "??"
    -- We know the zone, so get the zone skill.
    else
        ZoneSkill = tonumber(REQUIRED_FISHING_SKILL[Zone])
    end

    -- Get the characters skill
    CharacterSkill = tonumber(TotalFishingSkill(true))

    -- Get our total skill with all "+ fishing" we have.
    CharacterSkillPlus = tonumber(TotalFishingSkill(false))

    -- Is character skill and character skill + "+ fishing" the same ?
    if (CharacterSkill == CharacterSkillPlus) then
        SameSkill = true
    end

    -- 
    if (ZoneSkill ~= "??") then
        -- If character skill is equal or higher then zone skill, color green.
        if (CharacterSkill >= ZoneSkill) then
            ColoredCharacterSkill = "|cff00ff00" .. CharacterSkill .. "|r"
            ColoredZoneSkill = "|cff00ff00" .. ZoneSkill .. "|r"
        -- Color orange.
        else
            ColoredCharacterSkill = "|cFFFFA500" .. CharacterSkill .. "|r"
            ColoredZoneSkill = "|cFFFFA500" .. ZoneSkill .. "|r"
        end

        -- If character skill + "+ fishing" is equal or higher then zone skill, color green.
        if (CharacterSkillPlus >= ZoneSkill) then
            ColoredCharacterSkillPlus = "|cff00ff00" .. CharacterSkillPlus .. "|r"
            ColoredZoneSkill = "|cff00ff00" .. ZoneSkill .. "|r"
        -- Color orange.
        else
            ColoredCharacterSkillPlus = "|cFFFFA500" .. CharacterSkillPlus .. "|r"
            ColoredZoneSkill = "|cFFFFA500" .. ZoneSkill .. "|r"
        end
    --
    else
        ColoredZoneSkill = ZoneSkill
        ColoredCharacterSkill = CharacterSkill
        ColoredCharacterSkillPlus = CharacterSkillPlus
    end

    -- Make the headline from the data we colocted above.
    HeadLine = L["Skill"] .. ": "

    -- Was it the same skill for character and the + fishing ?
    if (SameSkill == true) then
        HeadLine = HeadLine .. ColoredCharacterSkill
    else
        HeadLine = HeadLine .. ColoredCharacterSkill .. "/" .. ColoredCharacterSkillPlus
    end

    -- Add the rest
    HeadLine = HeadLine .. " - " .. L["Zone"] .. ": " .. ColoredZoneSkill

    -- Return what we have made
    return HeadLine
end

-- ====================================================================================================
-- ====================================================================================================
-- ====================================================================================================
-- ====================================================================================================
-- =                                     The fake grey items list                                     =
-- ====================================================================================================
-- ====================================================================================================
-- ====================================================================================================
-- ====================================================================================================

if not FAKE_GREY_LOOT_LIST then
    FAKE_GREY_LOOT_LIST = {}
end

FAKE_GREY_LOOT_LIST = {

    -- Copper coins from Dalaran
    43702, -- Alonsus Faol's Copper Coin
    43703, -- Ansirem's Copper Coin
    43704, -- Attumen's Copper Coin
    43705, -- Danath's Copper Coin
    43706, -- Dornaa's Shiny Copper Coin
    43707, -- Eitrigg's Copper Coin
    43708, -- Elling Trias' Copper Coin
    43709, -- Falstad Wildhammer's Copper Coin
    43710, -- Genn's Copper Coin
    43711, -- Inigo's Copper Coin
    43712, -- Krasus' Copper Coin
    43713, -- Kryll's Copper Coin
    43714, -- Landro Longshot's Copper Coin
    43715, -- Molok's Copper Coin
    43716, -- Murky's Copper Coin
    43717, -- Princess Calia Menethil's Copper Coin
    43718, -- Private Marcus Jonathan's Copper Coin
    43719, -- Salandria's Shiny Copper Coin
    43720, -- Squire Rowe's Copper Coin
    43721, -- Stalvan's Copper Coin
    43722, -- Vereesa's Copper Coin
    43723, -- Vargoth's Copper Coin

    -- Silver coins from Dalaran
    43643, -- Prince Magni Bronzebeard's Silver Coin
    43644, -- A Peasant's Silver Coin
    43675, -- Fandral Staghelm's Silver Coin
    43676, -- Arcanist Doan's Silver Coin
    43677, -- High Tinker Mekkatorque's Silver Coin
    43678, -- Antonidas' Silver Coin
    43679, -- Muradin Bronzebeard's Silver Coin
    43680, -- King Varian Wrynn's Silver Coin
    43681, -- King Terenas Menethil's Silver Coin
    43682, -- King Anasterian Sunstrider's Silver Coin
    43683, -- Khadgar's Silver Coin
    43684, -- Medivh's Silver Coin
    43685, -- Maiev Shadowsong's Silver Coin
    43686, -- Alleria's Silver Coin
    43687, -- Aegwynn's Silver Coin

    -- Fake random
    27441, -- Felblood Snapper (Lives in fel pools and lava)

    -- Not sure if you can catch the following items if you have max skill.
    -- For now the items are enabled in this list and enabled in "special items" list so we can check.
    27442, -- Goldenscale Vendorfish
    43659, -- Bloodied Prison Shank
    6304, -- Damp Diary Page (Day 4)
    6306, -- Damp Diary Page (Day 512)
}

-- ====================================================================================================
-- =                                   Quest items that we can fish                                   =
-- ====================================================================================================

if (not QUEST_FISHING_ITEMS) then
    QUEST_FISHING_ITEMS = {}
end

QUEST_FISHING_ITEMS = {

    -- TBC Daily Fishing Quests
    34864, -- Baby Crocolisk                -- For the quest "Crocolisks in the City"
    34867, -- Monstrous Felblood Snapper    -- For the quest "Felblood Fillet"
    35313, -- Bloated Barbed Gill Trout     -- For the quest "Shrimpin' Ain't Easy"
    34865, -- Blackfin Darter               -- For the quest "Bait Bandits"
    34868, -- World's Largest Mudfish       -- For the quest "The One That Got Away"

    -- WotLK Daily Fishing Quests
    45905, -- Bloodtooth Frenzy             -- For the quest "Blood Is Thicker"
    45904, -- Terrorfish                    -- For the quest "Dangerously Delicious"
    45328, -- Bloated Slippery Eel          -- For the quest "Disarmed!"
    45903, -- Corroded Jewelry              -- For the quest "Jewel Of The Sewers"
    45902, -- Phantom Ghostfish             -- For the quest "The Ghostfish"

    -- Nat Pagle, Angler Extreme
    16967, -- Feralas Ahi
    16970, -- Misty Reed Mahi Mahi
    16968, -- Sar'theris Striker
    16969, -- Savage Coast Blue Sailfin

    6718, -- Electropeller                  -- For the quest "Electropellers"
    6717, -- Gaffer Jack                    -- For the quest "Gaffer Jacks"

    34469, -- Strange Engine Part           -- Starts the quest "Strange Engine Part"

    -- Weekly fishing contest
    19807, -- Speckled Tastyfish            -- For the quest "Master Angler" (The one in Booty Bay)
    50289, -- Blacktip Shark                -- For the quest "Kalu'ak Fishing Derby" (The one from Dalaran)
    19805, -- Keefer's Angelfish            -- For the quest "Rare Fish - Keefer's Angelfish" (The one in Booty Bay)
    19806, -- Dezian Queenfish              -- For the quest "Rare Fish - Dezian Queenfish" (The one in Booty Bay)
    19803, -- Brownell's Blue Striped Racer -- For the quest "Rare Fish - Brownell's Blue Striped Racer" (The one in Booty Bay)
    19804, -- Pale Ghoulfish                -- For the quest "Rare Fish - Pale Ghoulfish" (The one in Booty Bay)

}

-- ====================================================================================================
-- =                    Special items that we can fish. (Turtle mount for example)                    =
-- ====================================================================================================

if (not SPECIAL_FISHING_ITEMS) then
    SPECIAL_FISHING_ITEMS = {}
end

SPECIAL_FISHING_ITEMS = {

    -- Classic Stuff
    34486, -- Old Crafty
    34484, -- Old Ironjaw

    -- TBC Stuff
    27388, -- Mr. Pinchy

    -- WotLK Stuff
    46109, -- Sea Turtle
    43698, -- Giant Sewer Rat
    43650, -- Rusty Prison Key

    -- Check the following items if they can be fished with max skill.
    -- For now the items are enabled in this list and enabled in "fake grey" list so we can check.
    27442, -- Goldenscale Vendorfish
    43659, -- Bloodied Prison Shank
    6304, -- Damp Diary Page (Day 4)
    6306, -- Damp Diary Page (Day 512)
}

-- ====================================================================================================
-- =                           All the lures there is in the game right now                           =
-- ====================================================================================================

if (not FISHING_POLE_ENCHANT_ID) then
    FISHING_POLE_ENCHANT_ID = {}
end

FISHING_POLE_ENCHANT_ID = {
    [6529] = {
        ["enUS_Name"] = "Shiny Bauble",
        ["MinUseSkill"] = 1,
        ["SkillAdded"] = 25,
        ["Minutes"] = 10,
        ["EnchantID"] = 263,
    },
    [6530] = {
        ["enUS_Name"] = "Nightcrawlers",
        ["MinUseSkill"] = 50,
        ["SkillAdded"] = 50,
        ["Minutes"] = 10,
        ["EnchantID"] = 264,
    },
    [6532] = {
        ["enUS_Name"] = "Bright Baubles",
        ["MinUseSkill"] = 100,
        ["SkillAdded"] = 75,
        ["Minutes"] = 10,
        ["EnchantID"] = 265,
    },
    [6533] = {
        ["enUS_Name"] = "Aquadynamic Fish Attractor",
        ["MinUseSkill"] = 100,
        ["SkillAdded"] = 100,
        ["Minutes"] = 10,
        ["EnchantID"] = 266,
    },
    [6811] = {
        ["enUS_Name"] = "Aquadynamic Fish Lens",
        ["MinUseSkill"] = 50,
        ["SkillAdded"] = 50,
        ["Minutes"] = 10,
        ["EnchantID"] = 264,
    },
    [7307] = {
        ["enUS_Name"] = "Flesh Eating Worm",
        ["MinUseSkill"] = 100,
        ["SkillAdded"] = 75,
        ["Minutes"] = 10,
        ["EnchantID"] = 265,
    },
    [34861] = {
        ["enUS_Name"] = "Sharpened Fish Hook",
        ["MinUseSkill"] = 100,
        ["SkillAdded"] = 100,
        ["Minutes"] = 10,
        ["EnchantID"] = 266,
    },
    [46006] = {
        ["enUS_Name"] = "Glow Worm",
        ["MinUseSkill"] = 100,
        ["SkillAdded"] = 100,
        ["Minutes"] = 60,
        ["EnchantID"] = 3868,
    },
}

-- ====================================================================================================
-- =                                   Advertisement of my self. :D                                   =
-- ====================================================================================================

GameTooltip:HookScript("OnTooltipSetUnit", function(tooltip)
    local UNIT = select(2, tooltip:GetUnit())

    if (UNIT) then
        local GUID = UnitGUID(UNIT) or ""

        -- Súbby - Hunter - [Golemagg - EU]
        if (GUID == "Player-4465-0304CF7C") then
            FoundGUID = true
        -- Subine - Paladin - [Golemagg - EU]
        elseif (GUID == "Player-4465-0304BD2D") then
            FoundGUID = true
        -- Clumsycow - Druid - [Golemagg - EU]
        elseif (GUID == "Player-4465-0304D3CA") then
            FoundGUID = true
        -- Banduck - Priest - [Golemagg - EU]
        elseif (GUID == "Player-4465-0304C4D3") then
            FoundGUID = true
        -- Sheepdog - Mage - [Golemagg - EU]
        elseif (GUID == "Player-4465-0304BD5F") then
            FoundGUID = true
        -- Weakley - Rogue - [Golemagg - EU]
        elseif (GUID == "Player-4465-0304D404") then
            FoundGUID = true
        -- Submancer - Death Knight - [Golemagg - EU]
        elseif (GUID == "Player-4465-037D0A08") then
            FoundGUID = true
        -- Substick - Shaman - [Golemagg - EU]
        elseif (GUID == "Player-4465-0385B049") then
            FoundGUID = true
        -- Submann - Warrior - [Golemagg - EU]
        elseif (GUID == "Player-4465-0386E86F") then
            FoundGUID = true
        -- Sûbby - Warlock - [Golemagg - EU]
        elseif (GUID == "Player-4465-0304C4F6") then
            FoundGUID = true
        -- Luaman - Hunter - [Golemagg - EU]
        elseif (GUID == "Player-4465-0304C4E5") then
            FoundGUID = true
        -- Submann - Warrior - [Pyrewood Village - EU]
        elseif (GUID == "Player-4453-0139FF64") then
            FoundGUID = true
        -- Súbby - Hunter - [Pyrewood Village - EU]
        elseif (GUID == "Player-4453-044E02B6") then
            FoundGUID = true
        else
            FoundGUID = false
        end

        -- Did we find the GUID of me ?
        if (FoundGUID == true) then
            tooltip:AddLine(" ") --blank line
            tooltip:AddLine("Author of \"Fishing Friend\"")
            tooltip:AddLine(" ") --blank line
        else
            -- print(GUID)
        end
    end
    -- Clear just to be sure.
    FoundGUID = nil
end)

-- ====================================================================================================
-- =               Diffrent colors so we don't have to look for them when we need them.               =
-- ====================================================================================================

function DiffrentColors()
    print("|cff888888" .. "GREY" .. "|r")
    print("|cffffffff" .. "WHITE" .. "|r")
    print("|cffbbbbbb" .. "SUBWHITE" .. "|r")
    print("|cffff00ff" .. "MAGENTA" .. "|r")
    print("|cffffff00" .. "YELLOW" .. "|r")
    print("|cffff6060" .. "LIGHTRED" .. "|r")
    print("|cff00ccff" .. "LIGHTBLUE" .. "|r")
    print("|cff0000ff" .. "BLUE" .. "|r")
    print("|cff00ff00" .. "GREEN" .. "|r")
    print("|cffff0000" .. "RED" .. "|r")
    print("|cffffcc00" .. "GOLD" .. "|r")
    print("|cFFF0F8FF" .. "ALICEBLUE" .. "|r")
    print("|cFFFAEBD7" .. "ANTIQUEWHITE" .. "|r")
    print("|cFF00FFFF" .. "AQUA" .. "|r")
    print("|cFF7FFFD4" .. "AQUAMARINE" .. "|r")
    print("|cFFF0FFFF" .. "AZURE" .. "|r")
    print("|cFFF5F5DC" .. "BEIGE" .. "|r")
    print("|cFFFFE4C4" .. "BISQUE" .. "|r")
    print("|cFF000000" .. "BLACK" .. "|r")
    print("|cFFFFEBCD" .. "BLANCHEDALMOND" .. "|r")
    print("|cFF8A2BE2" .. "BLUEVIOLET" .. "|r")
    print("|cFFA52A2A" .. "BROWN" .. "|r")
    print("|cFFDEB887" .. "BURLYWOOD" .. "|r")
    print("|cFF5F9EA0" .. "CADETBLUE" .. "|r")
    print("|cFF7FFF00" .. "CHARTREUSE" .. "|r")
    print("|cFFD2691E" .. "CHOCOLATE" .. "|r")
    print("|cFFFF7F50" .. "CORAL" .. "|r")
    print("|cFF6495ED" .. "CORNFLOWERBLUE" .. "|r")
    print("|cFFFFF8DC" .. "CORNSILK" .. "|r")
    print("|cFFDC143C" .. "CRIMSON" .. "|r")
    print("|cFF00FFFF" .. "CYAN" .. "|r")
    print("|cFF00008B" .. "DARKBLUE" .. "|r")
    print("|cFF008B8B" .. "DARKCYAN" .. "|r")
    print("|cFFB8860B" .. "DARKGOLDENROD" .. "|r")
    print("|cFFA9A9A9" .. "DARKGRAY" .. "|r")
    print("|cFF006400" .. "DARKGREEN" .. "|r")
    print("|cFFBDB76B" .. "DARKKHAKI" .. "|r")
    print("|cFF8B008B" .. "DARKMAGENTA" .. "|r")
    print("|cFF556B2F" .. "DARKOLIVEGREEN" .. "|r")
    print("|cFFFF8C00" .. "DARKORANGE" .. "|r")
    print("|cFF9932CC" .. "DARKORCHID" .. "|r")
    print("|cFF8B0000" .. "DARKRED" .. "|r")
    print("|cFFE9967A" .. "DARKSALMON" .. "|r")
    print("|cFF8FBC8B" .. "DARKSEAGREEN" .. "|r")
    print("|cFF483D8B" .. "DARKSLATEBLUE" .. "|r")
    print("|cFF2F4F4F" .. "DARKSLATEGRAY" .. "|r")
    print("|cFF00CED1" .. "DARKTURQUOISE" .. "|r")
    print("|cFF9400D3" .. "DARKVIOLET" .. "|r")
    print("|cFFFF1493" .. "DEEPPINK" .. "|r")
    print("|cFF00BFFF" .. "DEEPSKYBLUE" .. "|r")
    print("|cFF696969" .. "DIMGRAY" .. "|r")
    print("|cFF1E90FF" .. "DODGERBLUE" .. "|r")
    print("|cFFB22222" .. "FIREBRICK" .. "|r")
    print("|cFFFFFAF0" .. "FLORALWHITE" .. "|r")
    print("|cFF228B22" .. "FORESTGREEN" .. "|r")
    print("|cFFFF00FF" .. "FUCHSIA" .. "|r")
    print("|cFFDCDCDC" .. "GAINSBORO" .. "|r")
    print("|cFFF8F8FF" .. "GHOSTWHITE" .. "|r")
    print("|cFFFFD700" .. "GOLD" .. "|r")
    print("|cFFDAA520" .. "GOLDENROD" .. "|r")
    print("|cFF808080" .. "GRAY" .. "|r")
    print("|cFF008000" .. "GREEN" .. "|r")
    print("|cFFADFF2F" .. "GREENYELLOW" .. "|r")
    print("|cFFF0FFF0" .. "HONEYDEW" .. "|r")
    print("|cFFFF69B4" .. "HOTPINK" .. "|r")
    print("|cFFCD5C5C" .. "INDIANRED" .. "|r")
    print("|cFF4B0082" .. "INDIGO" .. "|r")
    print("|cFFFFFFF0" .. "IVORY" .. "|r")
    print("|cFFF0E68C" .. "KHAKI" .. "|r")
    print("|cFFE6E6FA" .. "LAVENDER" .. "|r")
    print("|cFFFFF0F5" .. "LAVENDERBLUSH" .. "|r")
    print("|cFF7CFC00" .. "LAWNGREEN" .. "|r")
    print("|cFFFFFACD" .. "LEMONCHIFFON" .. "|r")
    print("|cFFADD8E6" .. "LIGHTBLUE" .. "|r")
    print("|cFFF08080" .. "LIGHTCORAL" .. "|r")
    print("|cFFE0FFFF" .. "LIGHTCYAN" .. "|r")
    print("|cFFD3D3D3" .. "LIGHTGRAY" .. "|r")
    print("|cFF90EE90" .. "LIGHTGREEN" .. "|r")
    print("|cFFFFB6C1" .. "LIGHTPINK" .. "|r")
    print("|cFFFF6060" .. "LIGHTRED" .. "|r")
    print("|cFFFFA07A" .. "LIGHTSALMON" .. "|r")
    print("|cFF20B2AA" .. "LIGHTSEAGREEN" .. "|r")
    print("|cFF87CEFA" .. "LIGHTSKYBLUE" .. "|r")
    print("|cFF778899" .. "LIGHTSLATEGRAY" .. "|r")
    print("|cFFB0C4DE" .. "LIGHTSTEELBLUE" .. "|r")
    print("|cFFFFFFE0" .. "LIGHTYELLOW" .. "|r")
    print("|cFF00FF00" .. "LIME" .. "|r")
    print("|cFF32CD32" .. "LIMEGREEN" .. "|r")
    print("|cFFFAF0E6" .. "LINEN" .. "|r")
    print("|cFFFF00FF" .. "MAGENTA" .. "|r")
    print("|cFF800000" .. "MAROON" .. "|r")
    print("|cFF66CDAA" .. "MEDIUMAQUAMARINE" .. "|r")
    print("|cFF0000CD" .. "MEDIUMBLUE" .. "|r")
    print("|cFFBA55D3" .. "MEDIUMORCHID" .. "|r")
    print("|cFF9370DB" .. "MEDIUMPURPLE" .. "|r")
    print("|cFF3CB371" .. "MEDIUMSEAGREEN" .. "|r")
    print("|cFF7B68EE" .. "MEDIUMSLATEBLUE" .. "|r")
    print("|cFF00FA9A" .. "MEDIUMSPRINGGREEN" .. "|r")
    print("|cFF48D1CC" .. "MEDIUMTURQUOISE" .. "|r")
    print("|cFFC71585" .. "MEDIUMVIOLETRED" .. "|r")
    print("|cFF191970" .. "MIDNIGHTBLUE" .. "|r")
    print("|cFFF5FFFA" .. "MINTCREAM" .. "|r")
    print("|cFFFFE4E1" .. "MISTYROSE" .. "|r")
    print("|cFFFFE4B5" .. "MOCCASIN" .. "|r")
    print("|cFFFFDEAD" .. "NAVAJOWHITE" .. "|r")
    print("|cFF000080" .. "NAVY" .. "|r")
    print("|cFFFDF5E6" .. "OLDLACE" .. "|r")
    print("|cFF808000" .. "OLIVE" .. "|r")
    print("|cFF6B8E23" .. "OLIVEDRAB" .. "|r")
    print("|cFFFFA500" .. "ORANGE" .. "|r")
    print("|cFFFF4500" .. "ORANGERED" .. "|r")
    print("|cFFDA70D6" .. "ORCHID" .. "|r")
    print("|cFFEEE8AA" .. "PALEGOLDENROD" .. "|r")
    print("|cFF98FB98" .. "PALEGREEN" .. "|r")
    print("|cFFAFEEEE" .. "PALETURQUOISE" .. "|r")
    print("|cFFDB7093" .. "PALEVIOLETRED" .. "|r")
    print("|cFFFFEFD5" .. "PAPAYAWHIP" .. "|r")
    print("|cFFFFDAB9" .. "PEACHPUFF" .. "|r")
    print("|cFFCD853F" .. "PERU" .. "|r")
    print("|cFFFFC0CB" .. "PINK" .. "|r")
    print("|cFFDDA0DD" .. "PLUM" .. "|r")
    print("|cFFB0E0E6" .. "POWDERBLUE" .. "|r")
    print("|cFF800080" .. "PURPLE" .. "|r")
    print("|cFFFF0000" .. "RED" .. "|r")
    print("|cFFBC8F8F" .. "ROSYBROWN" .. "|r")
    print("|cFF4169E1" .. "ROYALBLUE" .. "|r")
    print("|cFF8B4513" .. "SADDLEBROWN" .. "|r")
    print("|cFFFA8072" .. "SALMON" .. "|r")
    print("|cFFF4A460" .. "SANDYBROWN" .. "|r")
    print("|cFF2E8B57" .. "SEAGREEN" .. "|r")
    print("|cFFFFF5EE" .. "SEASHELL" .. "|r")
    print("|cFFA0522D" .. "SIENNA" .. "|r")
    print("|cFFC0C0C0" .. "SILVER" .. "|r")
    print("|cFF87CEEB" .. "SKYBLUE" .. "|r")
    print("|cFF6A5ACD" .. "SLATEBLUE" .. "|r")
    print("|cFF708090" .. "SLATEGRAY" .. "|r")
    print("|cFFFFFAFA" .. "SNOW" .. "|r")
    print("|cFF00FF7F" .. "SPRINGGREEN" .. "|r")
    print("|cFF4682B4" .. "STEELBLUE" .. "|r")
    print("|cFFD2B48C" .. "TAN" .. "|r")
    print("|cFF008080" .. "TEAL" .. "|r")
    print("|cFFD8BFD8" .. "THISTLE" .. "|r")
    print("|cFFFF6347" .. "TOMATO" .. "|r")
    print("|c00FFFFFF" .. "TRANSPARENT" .. "|r")
    print("|cFF40E0D0" .. "TURQUOISE" .. "|r")
    print("|cFFEE82EE" .. "VIOLET" .. "|r")
    print("|cFFF5DEB3" .. "WHEAT" .. "|r")
    print("|cFFFFFFFF" .. "WHITE" .. "|r")
    print("|cFFF5F5F5" .. "WHITESMOKE" .. "|r")
    print("|cFFFFFF00" .. "YELLOW" .. "|r")
    print("|cFF9ACD32" .. "YELLOWGREEN" .. "|r")
end

-- ====================================================================================================
-- =                                          Shut up Rhonin                                          =
-- ====================================================================================================

local RhoninSpammMessages = {
    -- English
    "We received Brann's message, and we have begun preparations.",
    "Citizens of Dalaran! Raise your eyes to the skies and observe!",
    "Today our world's destruction has been averted in defiance of our very makers!",
    "Algalon the Observer, herald of the titans, has been defeated by our brave comrades in the depths of the titan city of Ulduar.",
    "Algalon was sent here to judge the fate of our world.",
    "He found a planet whose races had deviated from the titans' blueprints. A planet where not everything had gone according to plan.",
    "Cold logic deemed our world not worth saving. Cold logic, however, does not account for the power of free will. It's up to each of us to prove this is a world worth saving.",
    "That our lives... our lives are worth living.",

    -- German
    "Wir haben Branns Nachricht erhalten und mit Vorbereitungen begonnen.",
    "Bürger von Dalaran! Richtet Eure Blicke gen Himmel und beobachtet aufmerksam!",
    "Heute wurde die Zerstörung dieser Welt abgewendet, im Widerstand gegen unsere eigenen Schöpfer!",
    "Algalon der Beobachter, Herold der Titanen, wurde von unseren tapferen Kameraden in den Tiefen der Titanenstadt Ulduar bezwungen.",
    "Algalon wurde zu uns gesandt, um über diese Welt zu richten.",
    "Er fand eine Welt vor, deren Völker nicht mehr den Blaupausen der Titanen entsprachen. Eine Welt, in der nicht alles nach Plan gelaufen war.",
    "Kalte Logik befand unseren Planeten nicht der Rettung würdig. Jedoch trägt Logik nicht der Macht des freien Willens Rechnung. Es ist an uns, zu beweisen, dass diese Welt es wert ist, gerettet zu werden.",
    "Dass unsere Leben es wert sind... gelebt zu werden.",

    -- Spanish
    "Recibimos el mensaje de Brann y hemos comenzado con los preparativos.",
    "¡Ciudadanos de Dalaran! ¡Alzad la vista al cielo y observad!",
    "Hoy hemos evitado la destrucción de nuestro mundo desafiando a nuestros propios creadores.",
    "Nuestros valientes camaradas han derrotado al heraldo de los titanes, Algalon el Observador, en las profundidades de Ulduar, la ciudad de los titanes.",
    "Algalon, fue enviado aquí para juzgar el futuro de nuestro mundo.",
    "Encontró un planeta cuyas razas se habían desviado de los planes de los titanes. Un planeta en el que no todo había ido según lo planeado.",
    "La fría lógica consideró que nuestro planeta no merece ser salvado. La fría lógica, sin embargo, no contó con el poder del libre albedrío. Depende de cada uno de nosotros demostrar que este es un mundo que vale la pena salvar.",
    "Que nuestras vidas… son vidas que vale la pena vivir.",

    -- French
    "Nous avons reçu le message de Brann, et nous avons entamé les préparatifs.",
    "Citoyens de Dalaran ! Levez les yeux vers le ciel et regardez bien !",
    "En ce jour, la destruction de notre monde a été évitée, au grand dam de nos propres créateurs !",
    "Algalon l'Observateur, héraut des titans, a été vaincu par nos braves camarades dans les profondeurs de la cité d'Ulduar.",
    "Algalon avait été envoyé parmi nous pour juger du sort du monde.",
    "Il a trouvé un monde où les peuples s'étaient écartés du modèle des titans. Un monde sur lequel tout ne s'était pas déroulé conformément au plan.",
    "L'implacable logique voulait que notre monde ne mérite pas d'être sauvé. Mais cette logique ne prend pas en compte la puissance du libre arbitre. C'est à chacun de nous qu'il revient de prouver que ce monde mérite son salut.",
    "Que nos vies... Méritent d'être vécues.",

    -- Russian
    "Мы получили сообщение Бранна и начали подготовку.",
    "Жители Даларана! Поднимите глаза и взгляните на это небо!",
    "Сегодня, чтобы предотвратить гибель мира, пришлось противостоять самим его создателям!",
    "Наши бравые герои в глубинах Ульдуара, обители титанов, одолели их вестника, Наблюдателя Алгалона.",
    "Он был послан, чтобы решить судьбу нашего мира.",
    "Мира, обитатели которого не стали следовать шаблону титанов. Планеты, чье развитие отклонилось от изначального плана.",
    "С точки зрения логики наша планета не имеет права на существование. Но холодная логика не берет в расчет силу свободной воли. И теперь дело каждого – доказать, что наш мир заслуживает спасения.",
    "Что мы живем... не напрасно.",
};

local RhoninSoundFiles = {
    545431, -- sound/creature/brann/ur_brann_dalaran01.ogg
    559130, -- sound/creature/rhonin/ur_rhonin_event01.ogg
    559131, -- sound/creature/rhonin/ur_rhonin_event02.ogg
    559126, -- sound/creature/rhonin/ur_rhonin_event03.ogg
    559128, -- sound/creature/rhonin/ur_rhonin_event04.ogg
    559133, -- sound/creature/rhonin/ur_rhonin_event05.ogg
    559129, -- sound/creature/rhonin/ur_rhonin_event06.ogg
    559132, -- sound/creature/rhonin/ur_rhonin_event07.ogg
    559127, -- sound/creature/rhonin/ur_rhonin_event08.ogg
};

function MySpamFilter(self, event, message, author, ...)
    -- Is there a message we have check ?
    if (message ~= nil) then
        -- Do we want to hide all spam text from Rhonin ?
        if (MuteRhonin == true) then
            -- Check the message we got to see if it's one we have to remove.
            for k, v in ipairs(RhoninSpammMessages) do
                -- Did we find the message ?
                if message:find(v) then
                    return true -- Hide this message.
                end
            end
        end
    end

    -- Loop through all the sound files.
    for _, SoundFile in pairs(RhoninSoundFiles) do
        -- Do we want to mute the sound from Rhonin ?
        if (MuteRhonin == true) then
            -- Mute the sound files.
            MuteSoundFile(SoundFile);
        else
            -- Unmute the sound files.
            UnmuteSoundFile(SoundFile);
        end
    end
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_YELL", MySpamFilter)

-- ====================================================================================================
-- =                             ---   TEST ZONE   ----   TEST ZONE   ---                             =
-- ====================================================================================================


--[[



name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId








Check if we already have drink buff.
If not, check if we have any drinks in the bags.
If so, use drink.

Check to see if we have lure buff.
If not, check if we have any lure in the bags.
If so, use lure.




local function FindFishingPoles()
	local poles = {};
	if ( FL:IsFishingPole() ) then
		local link = GetInventoryItemLink("player", mainhandslot);
		tinsert(poles, MakeOutfitInfo(link));
	end
	for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
		local numSlots = GetContainerNumSlots(bag);
		if (numSlots > 0) then
			-- check each slot in the bag
			for slot=1, numSlots do
				local link = GetContainerItemLink(bag, slot);
				if ( link ) then
					if ( FL:IsFishingPole(link) ) then
						tinsert(poles, MakeOutfitInfo(link));
					end
				end
			end
		end
	end
	return poles;
end


]]--


















