local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local io = require "io"
local Utils = require "utils"
local prng = require "PRNG"

local effectRange = 1
local recruitableUnits = {
    "spearman",
    "wagon",
    "mage",
    "archer",
    "knight",
    "ballista",
    "trebuchet",
    "giant",
    "golem_unit",
    "griffin_walking",
    "harpy",
    "witch",
    "dragon",
    "balloon",
    "travelboat",
    "caravel",
    "merman",
    "turtle",
    "harpoonship",
    "warship",
    "frog",
    "kraken",
    "thief",
    "rifleman",
}
local MWSacrifice = Verb:new()


function MWSacrifice:getMaximumRange(unit, endPos)

    local mapSize = Wargroove.getMapSize()
    return mapSize.x + mapSize.y
end


function MWSacrifice:getTargetType()
    return "unit"
end

function MWSacrifice:canExecuteAnywhere(unit)
    local settings = Utils.getSettings()
    if settings ~= nil then
        local state = Wargroove.getUnitState(unit, "sacrifices")
        if state == nil then
            state = 0
        else
            state = tonumber(state)
        end

        local limit = 0
        if Wargroove.isHuman(unit.playerId) then
            limit = settings["player_sacrifice_limit"]
        else
            limit = settings["ai_sacrifice_limit"]
        end
        if limit == nil then
            limit = 0
        else
            limit = tonumber(limit)
        end

        return state < limit
    end
    return true
end

function MWSacrifice:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    local targetUnit = Wargroove.getUnitAt(targetPos)
    if (not targetUnit) or (targetUnit == unit) or (targetUnit.playerId ~= unit.playerId) then
        return false
    end
    return targetUnit.playerId == unit.playerId
            and (not targetUnit.unitClass.isCommander)
            and (not targetUnit.unitClass.isStructure)
            and Utils.listContains(recruitableUnits, targetUnit.unitClass.id)
end


function MWSacrifice:execute(unit, targetPos, strParam, path)
    local targetUnitId = Wargroove.getUnitIdAt(targetPos)
    if targetUnitId == -1 then
        return
    end
    local targetUnit = Wargroove.getUnitById(targetUnitId)
    Wargroove.spawnMapAnimation(targetPos, effectRange, "fx/hex_spell", "idle", "behind_units", {x = 13, y = 16})
    Wargroove.playMapSound("witchSpell", targetPos)
    Wargroove.waitTime(1.35)
    targetUnit:setHealth(0, unit.id)
    Wargroove.updateUnit(targetUnit)
    Wargroove.spawnMapAnimation(targetPos, 0, "fx/hex_spell_hit")
    Wargroove.playMapSound("darkmercia/darkmerciaGrooveUnitDrained", targetPos)
    Wargroove.playUnitAnimation(targetUnit.id, "hit")
    Wargroove.waitTime(0.3)
    local sacrificeFileName = "AP\\unitSacrificeAI"
    if Wargroove.isHuman(unit.playerId) then
        sacrificeFileName = "AP\\unitSacrifice"
    end
    local f = io.open(sacrificeFileName, "w+")
    f:write(targetUnit.unitClass.id)
    io.close(f)
    print("Sacrificed " .. targetUnit.unitClass.id)
    local state = Wargroove.getUnitState(unit, "sacrifices")
    if state == nil then
        state = 0
    else
        state = tonumber(state)
    end
    state = state + 1
    Wargroove.setUnitState(unit, "sacrifices", state)
    Wargroove.updateUnit(unit)
end

function MWSacrifice:generateOrders(unitId, canMove)
    local orders = {}
    local unit = Wargroove.getUnitById(unitId)

    if not self:canExecuteAnywhere(unit) then
        return orders
    end

    local targetPositions = {}
    if canMove then
        local mapSize = Wargroove.getMapSize()
        targetPositions = Wargroove.getTargetsInRange(unit.pos, mapSize.x + mapSize.y, "unit")
    end

    for i, pos in ipairs(targetPositions) do
        local u = Wargroove.getUnitAt(pos)
        if u ~= nil and self:canExecuteWithTarget(unit, unit.pos, pos, "") then
            table.insert(orders, {targetPosition = pos, strParam = "", movePosition = unit.pos, endPosition = unit.pos})
        end
    end

    return orders
end


function MWSacrifice:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)

    local cost = 0
    local costScore = 0

    local u = Wargroove.getUnitAt(order.targetPosition)
    if u ~= nil then
        local uc = Wargroove.getUnitClass(u.unitClassId)
        local unitValue = math.sqrt((uc.cost * unit.health) / 100)
        if uc.isCommander then
            unitValue = 10
        end
        cost = (uc.cost * unit.health) / 10000
        costScore = unitValue * 0.5
    end

    local score = (prng.get_random_32() % 4) + 3
    return { score = score, healthDelta = 0, introspection = {
        { key = "cost", value = cost },
        { key = "costScore", value = costScore }
    }}
end


return MWSacrifice
