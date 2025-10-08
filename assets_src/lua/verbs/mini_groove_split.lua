local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"

local Split = GrooveVerb:new()
function Split:getTier(unit)
    return 1
end

function Split:consumeGroove(unit)
    local groove = Wargroove.getGroove(self:getGrooveId(unit))
    unit.grooveChargeOnUse = unit.grooveCharge
    unit.grooveCharge = unit.grooveCharge-groove.grooveCost[1]
    if unit.grooveCharge<0 then unit.grooveCharge = 0 end
    Wargroove.updateUnit(unit)
end

function Split:getMaximumRange(unit, endPos)
    if Split.target == nil then
        return 4        
    else
        return 5
    end
end


function Split:getTargetType()
    return "all"
end

Split.target = nil

function Split:preExecute(unit, targetPos, strParam, endPos)

    --[[Split.target = nil
    Wargroove.selectTarget()

    while Wargroove.waitingForSelectedTarget() do
        coroutine.yield()
    end

    local pretargetPos = Wargroove.getSelectedTarget()
    if (pretargetPos == nil) then
        Wargroove.clearDisplayTargets()
        coroutine.yield()
        return false, ""
    end
    Split.target = Wargroove.getUnitAt(pretargetPos)]]
    Split.target = Wargroove.getUnitAt(targetPos)
    if Split.target == nil then
        return false, ""
    end
    Wargroove.displayTarget(targetPos)
    Wargroove.selectTarget()
    while Wargroove.waitingForSelectedTarget() do
        coroutine.yield()
    end

    local preSplitPos = Wargroove.getSelectedTarget()
    if (preSplitPos == nil) then
        Wargroove.clearDisplayTargets()
        coroutine.yield()
        Split.target = nil
        return false, ""
    end
    Wargroove.clearDisplayTargets()
    coroutine.yield()
    local result = ""
    result = targetPos.x .. "," .. targetPos.y .. ";".. preSplitPos.x .. "," .. preSplitPos.y

    Wargroove.waitFrame()
    Wargroove.setSelectedTarget(targetPos)
    Split.target = nil
    Wargroove.clearDisplayTargets()
    return true, result
end

function Split:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end
    if Split.target == nil then
        return Split:isValidTargetUnit(unit, endPos, targetPos)
    else
        return Split:isValidSplitPos(unit, endPos, targetPos)
    end

    return true
end

function Split:isValidTargetUnit(unit, endPos, targetPos)
    local targetUnit = Wargroove.getUnitAt(targetPos)
    if targetUnit == nil then
        return false
    end
    if targetUnit.playerId~=unit.playerId then
        return false
    end
    if targetUnit.id==unit.id then
        return false
    end
    if targetUnit.unitClass.isStructure then
        return false
    end
    if targetUnit.unitClass.isCommander then
        return false
    end
    if not Wargroove.doesUnitHaveTag(targetUnit, {"type.ground.light", "knight", "rifleman", "harpy", "witch", "airtrooper", "type.sea.light", "type.amphibious.light", "type.amphibious.heavy", "turtle"}) then
        return false
    end
    return true
end
function Split:isValidSplitPos(unit, endPos, targetPos)
    local dist = math.abs(Split.target.pos.x-targetPos.x)+math.abs(Split.target.pos.y-targetPos.y)
    if dist>1 then
        return false
    end
    if not Wargroove.canStandAt(Split.target.unitClassId,targetPos) then
        return false
    end
    if Wargroove.getUnitIdAt(targetPos) ~= -1 then
        return false
    end
    return true
end

function Split:execute(unit, targetPos, strParam, path)
    local parsedPos = self:parseTargets(strParam)
    targetPos = {x = parsedPos[1].x, y = parsedPos[1].y}
    local targetUnit = Wargroove.getUnitAt(targetPos)
    local targetEndPos = {x = parsedPos[2].x, y = parsedPos[2].y}


    Wargroove.setIsUsingGroove(unit.id, true)
    local endFacing = (targetPos.x > unit.pos.x and 1 or 3)
    unit.pos.facing = endFacing

    Wargroove.updateUnit(unit)

    Wargroove.playPositionlessSound("battleStart")
    --Wargroove.playGrooveCutscene(unit.id, 1)

    Wargroove.playUnitAnimation(unit.id, "mini_groove_alt")
    Wargroove.playMapSound("duchess/duchessMiniGrooveAlt", unit.pos)
    Wargroove.waitTime(0.25)
    if targetPos.x>unit.pos.x then
        Wargroove.setFacingOverride(targetUnit.id,"left")
    elseif targetPos.x<unit.pos.x then
        Wargroove.setFacingOverride(targetUnit.id,"right")
    end
    Wargroove.waitTime(1)


    local newUnitId = Wargroove.spawnUnit(targetUnit.playerId,targetPos,targetUnit.unitClassId,targetUnit.hadTurn)
    Wargroove.clearCaches()
    local newUnit = Wargroove.getUnitById(newUnitId)
    if newUnit ~= nil then
        targetUnit:setHealth(math.ceil((targetUnit.health-0.1)/2), unit.id)
        newUnit:setHealth(targetUnit.health, unit.id)
        local targetEndFacing = (targetPos.x > unit.pos.x and 3 or 1)
        targetUnit.pos.facing = targetEndFacing
        newUnit.pos.facing = targetEndFacing
        Wargroove.updateUnits({targetUnit, newUnit})
        local delta = {x = targetEndPos.x-targetPos.x, y = targetEndPos.y-targetPos.y}
        if delta.y == 1 then
            Wargroove.playUnitAnimation(newUnitId,"run_down","run_down")
        elseif delta.y == -1 then
            Wargroove.playUnitAnimation(newUnitId,"run_up","run_up")
        else
            Wargroove.playUnitAnimation(newUnitId,"run","run")
        end
        if delta.x == 1 then
            Wargroove.setFacingOverride(newUnitId,"right")
        elseif delta.x == -1 then
            Wargroove.setFacingOverride(newUnitId,"left")
        end
        Wargroove.moveUnitToOverride(newUnitId, targetPos, delta.x, delta.y, 3)
        while (Wargroove.isLuaMoving(newUnitId)) do
            coroutine.yield()
        end
        Wargroove.playUnitAnimation(newUnitId,"idle")
        newUnit.pos = { x = targetEndPos.x, y = targetEndPos.y }
        Wargroove.unsetFacingOverride(newUnitId)
        Wargroove.unsetFacingOverride(targetUnit.id)
        Wargroove.updateUnit(newUnit)
    end

    Wargroove.waitTime(0.1)
    Wargroove.playGrooveEffect()
    

    Wargroove.logAnalyticsAction("UnitAbility", unit.playerId, "groove", unit.unitClassId)
end

return Split
