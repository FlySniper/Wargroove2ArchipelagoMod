local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"
local Pathfinding = require "util/pathfinding"
local PosKey = require "util/posKey"
local MoraleBoost = GrooveVerb:new()


function MoraleBoost:getMaximumRange(unit, endPos)
    return 0
end


function MoraleBoost:getTargetType()
    return "unit"
end

local highAlertAnimation = "ui/icons/high_alert"
local highAlertBuffSound = "highAlertBuff"
function MoraleBoost:getTier(unit)
    return 2;
end
function MoraleBoost:canExecuteAnywhere(unit)
    local tier = self:getCurrentGrooveTier(unit)
    return tier>=MoraleBoost:getTier(unit)
end
function MoraleBoost:execute(unit, targetPos, strParam, path)
    print("MoraleBoost")
    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id)

    local targets = Wargroove.getTargetsInRange(targetPos, 2, "unit")

    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.playMapSound("duchess/duchessGroove", targetPos)
    Wargroove.waitTime(1.1)
    Wargroove.spawnMapAnimation(targetPos, 3, "fx/groove/en_garde_groove_fx", "idle", "behind_units", {x = 12, y = 12})

    Wargroove.playGrooveEffect()

    local function distFromTarget(a)
        return math.abs(a.x - targetPos.x) + math.abs(a.y - targetPos.y)
    end
    table.sort(targets, function(a, b) return distFromTarget(a) < distFromTarget(b) end)

    for i, pos in ipairs(targets) do
        local u = Wargroove.getUnitAt(pos)
        local uc = u.unitClass
        if u ~= nil and Wargroove.areAllies(u.playerId, unit.playerId) and (not uc.isStructure) then
            if (uc.weapons ~= nil) and (uc.weapons[1] ~= nil) and (uc.weapons[1].canMoveAndAttack == true) then
                Wargroove.setUnitState(u, "high_alert", "true")
                Wargroove.pushBuff(1, u, unit.playerId, "high_alert_spawn", "high_alert", "high_alert_death")
                --Wargroove.highAlertBuff(u)
                Wargroove.playMapSound(highAlertBuffSound,pos)
                Wargroove.updateUnit(u)
                Wargroove.waitTime(0.02)
            end
        end
    end
    Wargroove.waitTime(1.0)
end

function MoraleBoost:generateOrders(unitId, canMove)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    if Wargroove.hasAIRestriction(unitId, "cant_attack") then
        return {}
    end
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in pairs(movePositions) do
        local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, 1, "unit")
        orders[#orders+1] = {targetPosition = pos, strParam = "", movePosition = pos, endPosition = pos}
    end

    return orders
end
function MoraleBoost:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    if unit == nil then
        return{ score = -1000, introspection = {}}
    end
    
    local endPos = order.endPosition
    local units = Wargroove.getUnitsAtLocation()
    local enemyLocations = {}
    for i,u in pairs(units) do
        local uc = u.unitClass
        if Pathfinding.withinBounds(u.pos) then
            if Wargroove.areEnemies(u.playerId,unit.playerId) and (not uc.isStructure) and (uc.weapons ~= nil) and (uc.weapons[1] ~= nil) then
                table.insert(enemyLocations,u.pos)
            end
        end
    end
    local enemyDistMap = Pathfinding.getDistanceToLocationMap(endPos, 20, enemyLocations)
    local targets = Wargroove.getTargetsInRange(endPos, 2, "unit")
    local score = -300
    for i, pos in ipairs(targets) do
        local u = Wargroove.getUnitAt(pos)
        local uc = u.unitClass
        local uValue = u.unitClass.cost*u.health/100
        if u ~= nil and Wargroove.areAllies(u.playerId, unit.playerId) and (not uc.isStructure) and (u.id ~= unitId) then
            if (uc.weapons ~= nil) and (uc.weapons[1] ~= nil) and (uc.weapons[1].canMoveAndAttack == true) then
                local posKey = PosKey.generatePosKey(pos)
                local distToEnemy = enemyDistMap[posKey];
                if u.hadTurn then
                    distToEnemy = distToEnemy*2 -- this is to compensate for the unit not being able to close the distance after the buff is applied
                end
                if enemyDistMap[posKey]<6 then
                    score = score + (10-enemyDistMap[posKey])*uValue/10
                end
            end
        end
    end
    return { score = score, introspection = {}}
end

return MoraleBoost
