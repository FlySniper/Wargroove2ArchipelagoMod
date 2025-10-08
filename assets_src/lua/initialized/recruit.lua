local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local OldRecruit = require "verbs/recruit"
local Utils = require "utils"
local UnitState = require "unit_state"
local prng = require "PRNG"

local Recruit = Verb:new()


function Recruit.init()
    OldRecruit.canExecuteWithTarget = Recruit.canExecuteWithTarget
    OldRecruit.execute = Recruit.execute
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

function Recruit:execute(unit, targetPos, strParam, path)
    if not Wargroove.isHuman(unit.playerId) then
        -- Check if this can recruit that type of unit. We do this here too so the AI can follow recruitment bans
        local recruit_str = UnitState.getState("player_" .. tostring(unit.playerId + 1) .. "_recruits")
        local recruitableUnits = { }
        if recruit_str ~= nil and recruit_str ~= "" then
            for unit_str in recruit_str:gmatch("([^,]+)") do
                table.insert(recruitableUnits, unit_str)
            end
        end
        if #recruitableUnits == 0 then
            print("No Recruitable Units.")
            return
        end

        local prunedRecruitables = {}
        local unit_recruiter_str = UnitState.getState("unit_recruit_" .. tostring(unit.pos.x) .. "_" .. tostring(unit.pos.y))
        if unit_recruiter_str ~= 0 then
            local split = unit_recruiter_str:gmatch("([^,]+)")
            local split_table = {}
            for unit_str in split do
                table.insert(split_table, unit_str)
            end
            for i, recruit in ipairs(recruitableUnits) do
                for j, unit_recruit in ipairs(unit.recruits) do
                    if unit_recruit == recruit then
                        for k, unit_str in ipairs(split_table) do
                            if recruit == unit_str then
                                local uc = Wargroove.getUnitClass(recruit)
                                local recruiter = Wargroove.getUnitClass(unit.unitClassId, unit.id)

                                local recruitDiscount = 1.0
                                if Wargroove.isInList(recruit, unit.recruitDiscounts) then
                                    recruitDiscount = unit.recruitDiscountMultiplier
                                end

                                if Wargroove.canStandAt(recruit, targetPos) and Wargroove.getMoney(unit.playerId) >= (uc.cost * recruiter.recruitingCostMultiplier * recruitDiscount) then
                                    table.insert(prunedRecruitables, recruit)
                                end
                            end
                        end
                    end

                end
            end
            if #prunedRecruitables == 0 then
                print("No Pruned Recruitables")
                return
            end
        end
        local ok = false
        for i, uid in ipairs(prunedRecruitables) do
            if uid == strParam then
                ok = true
            end
        end
        if not ok and #prunedRecruitables ~= 0 then
            local random = (prng.get_random_32() % (#prunedRecruitables)) + 1
            strParam = prunedRecruitables[random]
        end

    end
    local uc = Wargroove.getUnitClass(strParam)
    local recruiter = Wargroove.getUnitClass(unit.unitClassId, unit.id)

    local recruitDiscount = 1.0
    if Wargroove.isInList(strParam, unit.recruitDiscounts) then
        recruitDiscount = unit.recruitDiscountMultiplier
    end

    Wargroove.changeMoney(unit.playerId, -(uc.cost * recruiter.recruitingCostMultiplier * recruitDiscount))
    Wargroove.spawnUnit(unit.playerId, targetPos, strParam, true)
    if Wargroove.canCurrentlySeeTile(targetPos) then
        Wargroove.spawnMapAnimation(targetPos, 0, "fx/mapeditor_unitdrop")
        Wargroove.playMapSound("spawn", targetPos)
        Wargroove.playPositionlessSound("recruit")
    end
    Wargroove.notifyEvent("unit_recruit", unit.playerId)
    Wargroove.setMetaLocation("last_recruit", targetPos)
    Wargroove.setMetaUnitClass("last_recruit", uc)
    Wargroove.reportUnitRecruited(unit.id, strParam)

    Wargroove.logAnalyticsAction("UnitPurchased", unit.playerId, strParam, "", uc.cost)
end


return Recruit
