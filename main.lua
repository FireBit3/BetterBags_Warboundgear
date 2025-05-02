local addonName, addon = ...

local BetterBags = LibStub("AceAddon-3.0"):GetAddon("BetterBags")
local Categories = BetterBags:GetModule("Categories")

local CATEGORY_ARMOR = "Usable Warbound Armor"
local CATEGORY_WEAPON = "Usable Warbound Weapons"
local CATEGORY_ACCESSORY = "Usable Warbound Accessories"
local CATEGORY_OTHER = "Other Warbound Gear"

-- Tooltip strings for "Warbound Until Equipped"
local WUE_STRINGS = {
    ITEM_ACCOUNTBOUND_UNTIL_EQUIP,
    ITEM_BIND_TO_ACCOUNT_UNTIL_EQUIP
}

-- Define valid equip locations
local ARMOR_EQUIP_LOCATIONS = {
    INVTYPE_HEAD = true,
    INVTYPE_SHOULDER = true,
    INVTYPE_CHEST = true,
    INVTYPE_WAIST = true,
    INVTYPE_LEGS = true,
    INVTYPE_FEET = true,
    INVTYPE_WRIST = true,
    INVTYPE_HAND = true,
    INVTYPE_ROBE = true,
    INVTYPE_CLOAK = true
}

local ACCESSORY_EQUIP_LOCATIONS = {
    INVTYPE_FINGER = true,
    INVTYPE_NECK = true,
    INVTYPE_TRINKET = true
}

-- Define armor types by class
local _, playerClass = UnitClass("player")

local armorTypesByClass = {
    DRUID       = { "Leather" },
    HUNTER      = { "Mail" },
    MAGE        = { "Cloth" },
    PALADIN     = { "Plate" },
    PRIEST      = { "Cloth" },
    ROGUE       = { "Leather" },
    SHAMAN      = { "Mail" },
    WARLOCK     = { "Cloth" },
    WARRIOR     = { "Plate" },
    DEATHKNIGHT = { "Plate" },
    MONK        = { "Leather" },
    DEMONHUNTER = { "Leather" },
    EVOKER      = { "Mail" },
}

-- Weapon Type IDs (Blizzard Official Values)
local weaponTypeIDs = {
    [0]  = "One-Handed Axes",
    [1]  = "Two-Handed Axes",
    [2]  = "Bows",
    [3]  = "Guns",
    [4]  = "One-Handed Maces",
    [5]  = "Two-Handed Maces",
    [6]  = "Polearms",
    [7]  = "One-Handed Swords",
    [8]  = "Two-Handed Swords",
    [9]  = "Warglaives",
    [10] = "Staves",
    [11] = "Bear Claws",
    [12] = "Cat Claws",
    [13] = "Fist Weapons",
    [14] = "Miscellaneous",
    [15] = "Daggers",
    [16] = "Thrown",
    [17] = "Spears",
    [18] = "Crossbows",
    [19] = "Wands",
    [20] = "Fishing Poles",
    [21] = "Held in Offhand",
    [22] = "Shields"
}

-- Define valid weapon types by class using numeric IDs
local weaponTypesByClass = {
    DEATHKNIGHT = { 0, 1, 7, 8, 4, 5, 6 },               -- Axes, Swords, Maces, Polearms, Relic
    DRUID       = { 4, 5, 6, 10, 15, 13, 14 },           -- Maces, Polearms, Staves, Daggers, Fist, Relic
    HUNTER      = { 0, 1, 7, 8, 6, 10, 15, 13, 2, 18, 3 }, -- Axes, Swords, Polearms, Staves, Daggers, Fist, Bows, Crossbows, Guns
    MAGE        = { 7, 8, 10, 15, 19, 21 },              -- Swords, Staves, Daggers, Wands, Held in Offhand
    MONK        = { 0, 7, 4, 6, 10, 13 },                -- One-Handed Axes, One-Handed Swords, One-Handed Maces, Polearms, Staves, Fist
    PALADIN     = { 0, 1, 7, 8, 4, 5, 6, 14, 22 },       -- Axes, Swords, Maces, Polearms, Relic, Shield
    PRIEST      = { 4, 10, 15, 19, 21 },                 -- One-Handed Maces, Staves, Daggers, Wands, Held in Offhand
    ROGUE       = { 0, 7, 4, 15, 13, 2, 18, 3, 16 },     -- One-Handed Axes, One-Handed Swords, One-Handed Maces, Daggers, Fist, Bows, Crossbows, Guns, Thrown
    SHAMAN      = { 0, 1, 4, 5, 6, 10, 15, 13, 14, 22 }, -- Axes, Maces, Polearms, Staves, Daggers, Fist, Relic, Shield
    WARLOCK     = { 7, 8, 10, 15, 19, 21 },              -- Swords, Staves, Daggers, Wands, Held in Offhand
    WARRIOR     = { 0, 1, 7, 8, 4, 5, 6, 10, 15, 13, 2, 18, 3, 16, 14, 22 }, -- Axes, Swords, Maces, Polearms, Staves, Daggers, Fist, Bows, Crossbows, Guns, Thrown, Shield
    EVOKER      = { 10, 15, 19, 21 }                     -- Staves, Daggers, Wands, Held in Offhand
}

-- Categorization function
local function FilterFunction(data)
    -- Check if it's a "Warbound Until Equipped" item
    local tooltipInfo = C_TooltipInfo.GetBagItem(data.bagid, data.slotid)
    if not tooltipInfo or not tooltipInfo.lines then return nil end

    local matchFound = false
    for i = 2, 6 do
        local line = tooltipInfo.lines[i]
        if line and line.leftText then
            for _, pattern in ipairs(WUE_STRINGS) do
                if string.find(line.leftText, pattern) then
                    matchFound = true
                    break
                end
            end
        end
        if matchFound then break end
    end

    if not matchFound then return nil end

    -- Extract item data
    local itemID = data.itemInfo.itemID
    if not itemID then return nil end

    local _, itemType, itemSubType, equipLoc, _, _, itemWeaponID = C_Item.GetItemInfoInstant(itemID)

    if not itemType or not equipLoc then return nil end

    -- Categorize Accessories
    if ACCESSORY_EQUIP_LOCATIONS[equipLoc] then
        return CATEGORY_ACCESSORY
    end

    -- Categorize Armor
    if itemType == "Armor" and ARMOR_EQUIP_LOCATIONS[equipLoc] then
        for _, allowedType in ipairs(armorTypesByClass[playerClass] or {}) do
            if itemSubType == allowedType then
                return CATEGORY_ARMOR
            end
        end
        return CATEGORY_OTHER
    end

    -- Categorize Weapons using Numeric Matching
    if itemType == "Weapon" then
        local allowedWeapons = weaponTypesByClass[playerClass] or {}

        for _, allowedWeaponID in ipairs(allowedWeapons) do
            if itemWeaponID == allowedWeaponID then
                return CATEGORY_WEAPON
            end
        end
    end

    -- Categorize Held in Offhand
    if equipLoc == "INVTYPE_HOLDABLE" then
        local allowedOffhandClasses = { "MAGE", "PRIEST", "WARLOCK", "EVOKER" }
        for _, class in ipairs(allowedOffhandClasses) do
            if playerClass == class then
                return CATEGORY_WEAPON
            end
        end
    end

    return CATEGORY_OTHER
end

-- Register the filter
Categories:RegisterCategoryFunction("WarboundFilter", FilterFunction)
