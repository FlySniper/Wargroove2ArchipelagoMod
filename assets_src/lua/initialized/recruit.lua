local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local OldRecruit = require "verbs/recruit"
local Utils = require "utils"
local UnitState = require "unit_state"

local Recruit = Verb:new()


function Recruit.init()
    OldRecruit.canExecuteWithTarget = Recruit.canExecuteWithTarget
end


function Recruit:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if strParam == nil or strParam == "" then
        return true
    end
    local uc = Wargroove.getUnitClass(strParam)
    local recruiter = Wargroove.getUnitClass(unit.unitClassId, unit.id)

    local recruitDiscount = 1.0
    if Wargroove.isInList(strParam, unit.recruitDiscounts) then
        recruitDiscount = unit.recruitDiscountMultiplier
    end
    if Wargroove.isHuman(unit.playerId) then
        if unit.unitClass.id == "barracks" then
            for k, v in pairs(Utils.items) do
                if v <= Utils.items["giant"] then
                    local count = UnitState.getState(k)
                    if strParam == k and tonumber(count) > 0 then
                        local uc = Wargroove.getUnitClass(strParam)
                        return Wargroove.canStandAt(strParam, targetPos) and Wargroove.getMoney(unit.playerId) >= (uc.cost * recruiter.recruitingCostMultiplier * recruitDiscount)
                    end
                end
            end
            local uc = Wargroove.getUnitClass(strParam)
            return (Wargroove.canStandAt(strParam, targetPos) and Wargroove.getMoney(unit.playerId) >= uc.cost) and (strParam == "dog" or strParam == "soldier")
        end
        if unit.unitClass.id == "tower" then
            for k, v in pairs(Utils.items) do
                if v >= Utils.items["griffin_walking"] and v <= Utils.items["balloon"] then
                    local count = UnitState.getState(k)
                    if strParam == k and tonumber(count) > 0 then
                        local uc = Wargroove.getUnitClass(strParam)
                        return Wargroove.canStandAt(strParam, targetPos) and Wargroove.getMoney(unit.playerId) >= (uc.cost * recruiter.recruitingCostMultiplier * recruitDiscount)
                    end
                end
            end
            return false
        end
        if unit.unitClass.id == "port" then
            for k, v in pairs(Utils.items) do
                if v >= Utils.items["caravel"] and v <= Utils.items["warship"] then
                    local count = UnitState.getState(k)
                    if strParam == k and tonumber(count) > 0 then
                        local uc = Wargroove.getUnitClass(strParam)
                        return Wargroove.canStandAt(strParam, targetPos) and Wargroove.getMoney(unit.playerId) >= (uc.cost * recruiter.recruitingCostMultiplier * recruitDiscount)
                    end
                end
            end
            return false
        end
        if unit.unitClass.id == "hideout" then
            for k, v in pairs(Utils.items) do
                if v >= Utils.items["thief"] and v <= Utils.items["rifleman"] then
                    local count = UnitState.getState(k)
                    if strParam == k and tonumber(count) > 0 then
                        local uc = Wargroove.getUnitClass(strParam)
                        return Wargroove.canStandAt(strParam, targetPos) and Wargroove.getMoney(unit.playerId) >= (uc.cost * recruiter.recruitingCostMultiplier * recruitDiscount)
                    end
                end
            end
            return false
        end
        return false
    end
    -- Check if this can recruit that type of unit
    local ok = false
    for i, uid in ipairs(unit.recruits) do
        if uid == strParam then
            ok = true
        end
    end
    if not ok then
        return false
    end

    -- Check if this player can recruit this type of unit
    if not Wargroove.canPlayerRecruit(unit.playerId, strParam) then
        return false
    end

    return Wargroove.canStandAt(strParam, targetPos) and Wargroove.getMoney(unit.playerId) >= (uc.cost * recruiter.recruitingCostMultiplier * recruitDiscount)
end


return Recruit
