local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local OldConvertSoldier = require "verbs/convert_soldier"
local Utils = require "utils"
local UnitState = require "unit_state"

local ConvertSoldier = Verb:new()

function ConvertSoldier.init()

end

local defaultUnits = {"soldier", "dog"}

local conversionUnits = {
    [1] = { "soldier", "spearman", "dog", "wagon", "mage", "archer", "knight", "ballista", "trebuchet", "giant" },
    [2] = { "caravel", "merman", "frog", "travelboat", "harpoonship", "turtle", "kraken", "warship" }
}

function containsKey(table, key)
    for k, _ in pairs(table) do
        if k == key then
            return true
        end
    end
    return false
end

function apPruneConversionUnits(index)
    local groundOrNavelUnits = conversionUnits[index]
    local prunedGroundOrNavelUnits = {}
    if index == 1 then
        prunedGroundOrNavelUnits = {"soldier", "dog"}
    end
    for k, v in pairs(Utils.items) do
        local count = UnitState.getState(k)

        if tonumber(count) > 0 and containsKey(groundOrNavelUnits, k) then
            prunedGroundOrNavelUnits[k] = nil
        end
    end
    return prunedGroundOrNavelUnits
end

function ConvertSoldier:canExecuteAnywhere(unit)
    for i, u in ipairs(apPruneConversionUnits(1)) do
        if u == unit.unitClassId then
            return true
        end
    end
    for i, u in ipairs(apPruneConversionUnits(2)) do
        if u == unit.unitClassId then
            return true
        end
    end
    return false
end

function ConvertSoldier:getRecruitableTargets(unit)
    local targetTags = unit.unitClass.tags
    for i, tag in ipairs(targetTags) do
        if tag == "type.ground.light" or tag == "type.ground.medium" or tag == "type.ground.heavy" then
            return 2, apPruneConversionUnits(2)
        elseif tag == "type.sea.light" or tag == "type.sea.medium" or tag == "type.sea.heavy" or tag == "type.amphibious.heavy" or tag == "type.amphibious.light" then
            return 1, apPruneConversionUnits(1)
        end
    end
    return 0, nil
end
return ConvertSoldier
