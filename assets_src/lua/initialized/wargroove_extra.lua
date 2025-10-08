local OldWargroove = require "wargroove/wargroove"
local Combat = require "wargroove/combat"
local UnitPostCombat = require "wargroove/unit_post_combat"

local WargrooveExtra = {}
local Original = {}
function WargrooveExtra.init()
	print("wargroove_extra.lua loaded")

	OldWargroove.removeBuff = WargrooveExtra.removeBuff
	
	OldWargroove.doPostCombat = WargrooveExtra.doPostCombat

	Original.startCombat = OldWargroove.startCombat
	OldWargroove.startCombat = WargrooveExtra.startCombat

end

function WargrooveExtra:doPostCombat(unitId, isAttacker, healthAfterCombat)
    local unit = self.getUnitById(unitId)
    if unit == nil then
        return
    end

    local postCombat = UnitPostCombat:getPostCombat(unit.unitClassId)
    if (postCombat ~= nil) then
        postCombat(self, unit, isAttacker, healthAfterCombat)
    end
	local postCombatGeneric = UnitPostCombat:getPostCombatGeneric()
	for i,method in pairs(postCombatGeneric) do
		method(self, unit, isAttacker, healthAfterCombat)
	end

end
local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function WargrooveExtra.startCombat(attacker, defender, path, combatType)
	
    Original.startCombat(attacker, defender, path, combatType)
	OldWargroove.lastAttacker = deepcopy(attacker)
	OldWargroove.lastDefender = deepcopy(defender)
	local result = Combat:solveCombat(attacker.id, defender.id, path, combatType)
	OldWargroove.lastAttacker.health = result.attackerHealth
	OldWargroove.lastDefender.health = result.defenderHealth
end

function WargrooveExtra.removeBuff(unit, playerId, buffSpawnId, buffId, buffDeathId)
	local buffUnits = OldWargroove.getUnitsAtLocation()
	local foundBuff = nil
	local lowestTurnCount = 100000 
	for i, buffUnit in ipairs(buffUnits) do
		if buffUnit.unitClassId == "buff" then
			local foundUnitId = OldWargroove.getUnitState(buffUnit,"unitId")
			if foundUnitId~=nil then
				foundUnitId = tonumber(foundUnitId)
			end
			local foundBuffSpawnId = OldWargroove.getUnitState(buffUnit,"buffSpawnId")
			local foundBuffId = OldWargroove.getUnitState(buffUnit,"buffId")
			local foundBuffDeathId = OldWargroove.getUnitState(buffUnit,"buffDeathId")
			local foundTurnCount = OldWargroove.getUnitState(buffUnit,"turnCount")
			if foundTurnCount~=nil then
				foundTurnCount = tonumber(foundTurnCount)
			end
			if foundUnitId == unit.id and foundBuffSpawnId == buffSpawnId and foundBuffId == buffId and foundBuffDeathId == buffDeathId and foundTurnCount<lowestTurnCount then
				foundBuff = buffUnit
				if foundTurnCount == nil then
					lowestTurnCount = 0
				else
					lowestTurnCount = foundTurnCount
				end
			end
		end
	end
	if foundBuff~=nil then
		foundBuff:setHealth(0, foundBuff.id, true)
		OldWargroove.updateUnit(foundBuff)
	end
end

return WargrooveExtra
