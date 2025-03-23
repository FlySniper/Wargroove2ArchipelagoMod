local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local io = require "io"
local Utils = require "utils"
local prng = require "PRNG"

local effectRange = 1
local MWSummon = Verb:new()


function MWSummon:getMaximumRange(unit, endPos)
    return 3
end

function MWSummon:canExecuteAnywhere(unit)
    local settings = Utils.getSettings()
    if settings ~= nil then
        local state = Wargroove.getUnitState(unit, "summons")
        if state == nil then
            state = 0
        else
            state = tonumber(state)
        end

        local limit = 0
        if Wargroove.isHuman(unit.playerId) then
            limit = settings["player_summon_limit"]
        else
            limit = settings["ai_summon_limit"]
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

function MWSummon:getTargetType()
    return "empty"
end


function MWSummon:execute(unit, targetPos, strParam, path)
    local requestFileName = "AP\\unitSummonRequestAI"
    if Wargroove.isHuman(unit.playerId) then
        requestFileName = "AP\\unitSummonRequest"
    end
    local f = io.open(requestFileName, "w+")
    f:write("")
    io.close(f)
    print("Attempting to summon a unit")
    local targetUnitClass = ""
    for i = 1, 8 do
        Wargroove.waitTime(0.2)
        local f = io.open("AP\\unitSummonResponse", "r+")
        if f ~= nil then
            targetUnitClass = f:read()
            if targetUnitClass == nil or targetUnitClass == "" then
                io.close(f)
            else
                f:write("")
                io.close(f)
                break
            end
        end
    end
    if targetUnitClass == nil or targetUnitClass == "" then
        Wargroove.showMessage("A call for aid to the multiworld was made, yet no sacrifice was paid.")
        return
    end
    local unitPos = unit.pos
    local spawnPosList1 = {{x=unitPos.x + 1, y=unitPos.y},
                           {x=unitPos.x, y=unitPos.y + 1},
                           {x=unitPos.x - 1, y=unitPos.y},
                           {x=unitPos.x, y=unitPos.y - 1}}
    Utils.shuffle(spawnPosList1)
    local spawnPosList2 = {{x=unitPos.x + 2, y=unitPos.y},
                           {x=unitPos.x, y=unitPos.y + 2},
                           {x=unitPos.x - 2, y=unitPos.y},
                           {x=unitPos.x, y=unitPos.y - 2},
                           {x=unitPos.x + 1, y=unitPos.y + 1},
                           {x=unitPos.x - 1, y=unitPos.y - 1},
                           {x=unitPos.x - 1, y=unitPos.y + 1},
                           {x=unitPos.x + 1, y=unitPos.y - 1}}
    Utils.shuffle(spawnPosList2)
    local spawnPosList3 = {{x=unitPos.x + 3, y=unitPos.y},
                           {x=unitPos.x, y=unitPos.y + 3},
                           {x=unitPos.x - 3, y=unitPos.y},
                           {x=unitPos.x, y=unitPos.y - 3},
                           {x=unitPos.x + 2, y=unitPos.y + 1},
                           {x=unitPos.x - 2, y=unitPos.y - 1},
                           {x=unitPos.x - 2, y=unitPos.y + 1},
                           {x=unitPos.x + 2, y=unitPos.y - 1},
                           {x=unitPos.x + 1, y=unitPos.y + 2},
                           {x=unitPos.x - 1, y=unitPos.y - 2},
                           {x=unitPos.x - 1, y=unitPos.y + 2},
                           {x=unitPos.x + 1, y=unitPos.y - 2}}
    Utils.shuffle(spawnPosList3)
    local validSpawns = {}
    local allSpawns = {spawnPosList1, spawnPosList2, spawnPosList3}
    local allSpawnsIndex = 1
    while #validSpawns == 0  and allSpawnsIndex <= 3 do
        local spawnPosList = allSpawns[allSpawnsIndex]
        for i, pos in ipairs(spawnPosList) do
            local u = Wargroove.getUnitAt(pos)
            if u == nil and Wargroove.canStandAt(targetUnitClass, pos) then
                table.insert(validSpawns, pos)
            end
        end
        allSpawnsIndex = allSpawnsIndex + 1
    end
    local numValidSpawns = #validSpawns
    if numValidSpawns == 0 then
        Wargroove.showMessage("A call for aid to the multiworld was made, yet no there's no place for it to stand.")
        Wargroove.showMessage("The unit is lost to the abyss.")
        return
    end
    local random = (prng.get_random_32() % numValidSpawns) + 1
    local spawnPos = validSpawns[random]
    Wargroove.spawnUnit(unit.playerId, spawnPos, targetUnitClass, true)
    Wargroove.spawnMapAnimation(spawnPos, effectRange, "fx/heal_spell", "idle", "over_units", {x = 11, y = 11})
    Wargroove.playMapSound("mageSpell", spawnPos)
    Wargroove.waitTime(0.7)
    Wargroove.spawnMapAnimation(spawnPos, 0, "fx/heal_unit")
    Wargroove.playMapSound("unitHealed", spawnPos)
    Wargroove.waitTime(0.35)
    local state = Wargroove.getUnitState(unit, "summons")
    if state == nil then
        state = 0
    else
        state = tonumber(state)
    end
    state = state + 1
    Wargroove.setUnitState(unit, "summons", state)
    Wargroove.updateUnit(unit)
    print("Summoned " .. targetUnitClass)
end

function MWSummon:generateOrders(unitId, canMove)
    local orders = {}
    local unit = Wargroove.getUnitById(unitId)

    if not self:canExecuteAnywhere(unit) then
        return orders
    end

    local targetPositions = {}
    if canMove then
        targetPositions = Wargroove.getTargetsInRange(unit.pos, effectRange, "empty")
    end

    for i, pos in ipairs(targetPositions) do
        local u = Wargroove.getUnitAt(pos)
        if u == nil then
            table.insert(orders, {targetPosition = pos, strParam = "", movePosition = unit.pos, endPosition = unit.pos})
            break
        end
    end

    return orders
end


function MWSummon:getScore(unitId, order)
    local score = (prng.get_random_32() % 10) + 1
    return { score = score, healthDelta = 0, introspection = {}}
end

return MWSummon
