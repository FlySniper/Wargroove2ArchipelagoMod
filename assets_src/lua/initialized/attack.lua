local Wargroove = require "wargroove/wargroove"
local OldAttack = require "verbs/attack"
local Combat = require "wargroove/combat"


local Attack = {}
function Attack.init()
	OldAttack.execute = Attack.execute
end


function Attack:execute(unit, targetPos, strParam, path, telegraph)
    --- Telegraph
    if (not Wargroove.isLocalPlayer(unit.playerId)) and Wargroove.canCurrentlySeeTile(targetPos) and telegraph then
        Wargroove.spawnMapAnimation(targetPos, 0, "ui/grid/selection_cursor", "target", "over_units", {x = -4, y = -4})
        Wargroove.waitTime(0.5)
    end

    local target = Wargroove.getUnitAt(targetPos)
	local defenderIsHighAlert = Wargroove.getUnitState(target, "high_alert")
    
	if defenderIsHighAlert~=nil and defenderIsHighAlert == "true" and self:canExecuteWithTarget(target, targetPos, unit.pos, "") then
        Combat:startReverseCombat(unit, target, path)
    else
        Wargroove.startCombat(unit, target, path, "average")
    end
end

return Attack
