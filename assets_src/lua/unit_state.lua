local Wargroove = require "wargroove/wargroove"
local UnitState = {}
local globalStateUnitPos = { x = -42, y = -60 }

function UnitState.getState(key)
    local unit = Wargroove.getUnitAt(globalStateUnitPos)
    if unit == nil then
        return 0
    end
    local state = Wargroove.getUnitState(unit, key)
    if state == nil then
        state = 0
    end
    return state
end


function UnitState.setState(key, value)
    local unit = Wargroove.getUnitAt(globalStateUnitPos)
    if unit == nil then
        Wargroove.spawnUnit( -1, globalStateUnitPos, "soldier", true)
        unit = Wargroove.getUnitAt(globalStateUnitPos)
        Wargroove.updateUnit(unit)
    end
    Wargroove.setUnitState(unit, key, value)
    Wargroove.updateUnit(unit)
end

return UnitState