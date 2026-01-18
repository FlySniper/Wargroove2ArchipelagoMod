local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Utils = require "utils"
local UnitState = require "unit_state"
local OldTeleportBeam = require "verbs/groove_teleport_beam"

local RecruitAP = Verb:new()

local costMultiplier = 1

local defaultUnits = {"soldier", "dog"}

local function getCost(cost)
    return math.floor(cost * costMultiplier + 0.5)
end

function RecruitAP:getMaximumRange(unit, endPos)
    return 1
end

function RecruitAP:getTargetType()
    return "empty"
end

RecruitAP.classToRecruit = nil

function RecruitAP:getRecruitableTargets(unit)
    local allUnits = Wargroove.getAllUnitsForPlayer(unit.playerId, true)
    local recruitableUnits = {}
    for i, recruit in pairs(unit.recruits) do

        if not OldTeleportBeam.recruitsContain(self, recruitableUnits, recruit) then
            if Wargroove.isHuman(unit.playerId) and recruit ~= "dog" and recruit ~= "soldier" then

                for k, v in pairs(Utils.items) do
                    if v <= Utils.items["rifleman"] then
                        local count = UnitState.getState(k)
                        if recruit == k and tonumber(count) > 0 then
                            recruitableUnits[#recruitableUnits + 1] = recruit
                        end
                    end
                end
            else
                recruitableUnits[#recruitableUnits + 1] = recruit
            end
        end
    end

    if #recruitableUnits == 0 and unit.unitClassId == "barracks_ap" then
        recruitableUnits = defaultUnits
    end

    return recruitableUnits
end

function RecruitAP:getCost(unitClassId, playerId)
    local costs = Utils.getCosts(tonumber(UnitState.getState("Map_ID")))
    if Wargroove.isHuman(playerId) then
        if unitClassId == "barracks" or unitClassId == "barracks_ap" then
            return costs["player_barracks_cost"] / 100.0
        end
        if unitClassId == "tower" or unitClassId == "tower_ap" then
            return costs["player_tower_cost"] / 100.0
        end
        if unitClassId == "hideout" or unitClassId == "hideout_ap" then
            return costs["player_hideout_cost"] / 100.0
        end
        if unitClassId == "port" or unitClassId == "port_ap" then
            return costs["player_port_cost"] / 100.0
        end
    else
        if unitClassId == "barracks" or unitClassId == "barracks_ap" then
            return costs["ai_barracks_cost"] / 100.0
        end
        if unitClassId == "tower" or unitClassId == "tower_ap" then
            return costs["ai_tower_cost "] / 100.0
        end
        if unitClassId == "hideout" or unitClassId == "hideout_ap" then
            return costs["ai_hideout_cost"] / 100.0
        end
        if unitClassId == "port" or unitClassId == "port_ap" then
            return costs["ai_port_cost"] / 100.0
        end
    end
    return 1.0
end

function RecruitAP:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if strParam == nil or strParam == "" then
        return true
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

    local uc = Wargroove.getUnitClass(strParam)
    local recruiter = Wargroove.getUnitClass(unit.unitClassId, unit.id)

    local recruitDiscount = RecruitAP:getCost(unit.unitClassId, unit.playerId)
    if Wargroove.isInList(strParam, unit.recruitDiscounts) then
        recruitDiscount = unit.recruitDiscountMultiplier
    end

    return Wargroove.canStandAt(strParam, targetPos) and Wargroove.getMoney(unit.playerId) >= (uc.cost * recruiter.recruitingCostMultiplier * recruitDiscount)
end


function RecruitAP:preExecute(unit, targetPos, strParam, endPos)
    local recruitableUnits = RecruitAP:getRecruitableTargets(unit);
    local recruitCostMultiplier = RecruitAP:getCost(unit.unitClass.id, unit.playerId)
    Wargroove.openRecruitMenu(unit.playerId, unit.id, unit.pos, unit.unitClassId, recruitableUnits, recruitCostMultiplier);

    while Wargroove.recruitMenuIsOpen() do
        coroutine.yield()
    end

    RecruitAP.classToRecruit = Wargroove.popRecruitedUnitClass();

    if RecruitAP.classToRecruit == nil then
        return false, ""
    end

    Wargroove.selectTarget()

    while Wargroove.waitingForSelectedTarget() do
        coroutine.yield()
    end

    local target = Wargroove.getSelectedTarget()

    if (target == nil) then
        return false, ""
    end

    if not Wargroove.canStandAt(RecruitAP.classToRecruit, target) then
        return false, ""
    end
    return true, RecruitAP.classToRecruit
end

function RecruitAP:execute(unit, targetPos, strParam, path)
    RecruitAP.classToRecruit = nil
    local recruiter = Wargroove.getUnitClass(unit.unitClassId, unit.id)

    if strParam == "" then
        print("RecruitAP was not given a class to recruit.")
        return
    end
    local recruitDiscount = RecruitAP:getCost(unit.unitClass.id, unit.playerId)
    if Wargroove.isInList(strParam, unit.recruitDiscounts) then
        recruitDiscount = unit.recruitDiscountMultiplier
    end

    --local split = strParam:gmatch("([^,]+)")
    local unitClassStr = strParam
    -- local targetPos = {x = split(), y = split()}

    local uc = Wargroove.getUnitClass(unitClassStr)
    Wargroove.changeMoney(unit.playerId, -(uc.cost * recruiter.recruitingCostMultiplier * recruitDiscount))
    Wargroove.spawnUnit(unit.playerId, targetPos, unitClassStr, true)
    if Wargroove.canCurrentlySeeTile(targetPos) then
        Wargroove.spawnMapAnimation(targetPos, 0, "fx/mapeditor_unitdrop")
        Wargroove.playMapSound("spawn", targetPos)
        Wargroove.playPositionlessSound("recruit")
    end
    Wargroove.notifyEvent("unit_recruit", unit.playerId)
    Wargroove.setMetaLocation("last_recruit", targetPos)
    Wargroove.setMetaUnitClass("last_recruit", uc)
    Wargroove.reportUnitRecruited(unit.id, strParam)

    strParam = ""
end

return RecruitAP