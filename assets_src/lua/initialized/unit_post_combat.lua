local OldUnitPostCombat = require "wargroove/unit_post_combat"
local Attack = require "verbs/attack"

local UnitPostCombat = {}
local PostCombat = {}
local PostCombatGeneric = {}
local originalGetPostCombat


function UnitPostCombat.init()
    originalGetPostCombat = OldUnitPostCombat.getPostCombat
    OldUnitPostCombat.getPostCombat = UnitPostCombat.getPostCombat
    OldUnitPostCombat.getPostCombatGeneric = UnitPostCombat.getPostCombatGeneric
end



function UnitPostCombat:getPostCombat(unitClassId)
    print("UnitPostCombat:getPostCombat(unitClassId)")
    if PostCombat[unitClassId]~=nil then
        return PostCombat[unitClassId]
    else
        return originalGetPostCombat(OldUnitPostCombat,unitClassId)
    end
	
end

function UnitPostCombat:getPostCombatGeneric()
    return PostCombatGeneric
	
end

local outOfAmmoAnimation = "ui/icons/bullet_out_of_ammo"
function PostCombat.rifleman(Wargroove, unit, isAttacker, healthAfterCombat)
    if not isAttacker then
        return
    end

    local ammo = tonumber(Wargroove.getUnitState(unit, "ammo"))
    local newAmmo = math.max(ammo - 1, 0)
    Wargroove.setUnitState(unit, "ammo", newAmmo)
    Wargroove.updateUnit(unit)

    if (newAmmo == 0) and not Wargroove.hasUnitEffect(unit.id, outOfAmmoAnimation) then
        Wargroove.spawnUnitEffect(unit.id, unit.id, outOfAmmoAnimation, "idle", startAnimation, true, false)
    end
end

function PostCombat.kraken(Wargroove, unit, isAttacker, healthAfterCombat)
    if isAttacker then
        return
    end

    local targetId = Wargroove.getUnitState(unit, "targetId")

    -- If we're tentacling, update all the tentacles to the kraken's health
    if targetId ~= nil then
        local tentaclePositionsString = Wargroove.getUnitState(unit, "tentacles")
        local tentaclePositions = Wargroove.stringToPositions(tentaclePositionsString)

        for i, pos in ipairs(tentaclePositions) do
            local tentacle = Wargroove.getUnitAt(pos)
            tentacle:setHealth(healthAfterCombat, tentacle.id)
            Wargroove.updateUnit(tentacle)
        end
    end
end

function PostCombat.tentacle(Wargroove, unit, isAttacker, healthAfterCombat)
    if isAttacker then
        return
    end

    local parentId = Wargroove.getUnitState(unit, "parentId")

    -- Set tentacles and kraken to the same health
    if parentId ~= nil then
        local parentUnit = Wargroove.getUnitById(tonumber(parentId))
        parentUnit:setHealth(healthAfterCombat, unit.id)

        Wargroove.updateUnit(parentUnit)

        local tentaclePositionsString = Wargroove.getUnitState(parentUnit, "tentacles")
        local tentaclePositions = Wargroove.stringToPositions(tentaclePositionsString)

        for i, pos in ipairs(tentaclePositions) do
            local tentacle = Wargroove.getUnitAt(pos)
            tentacle:setHealth(healthAfterCombat, tentacle.id)
            Wargroove.updateUnit(tentacle)
        end
    end
end


function PostCombatGeneric.attack(Wargroove, unit, isAttacker, healthAfterCombat)
    -- if not isAttacker then
    --     return
    -- end    

    local attacker = Wargroove.lastAttacker
    local defender = Wargroove.lastDefender
    if not isAttacker then
        attacker = Wargroove.lastDefender
        defender = Wargroove.lastAttacker
    end
    local high_alert = Wargroove.getUnitState(attacker, "high_alert")
	if high_alert~=nil and high_alert == "true" and isAttacker == false and Attack:canExecuteWithTarget(attacker, attacker.pos, defender.pos, "")  then
		Wargroove.setUnitState(attacker,"high_alert","false")
        Wargroove.removeBuff(attacker, attacker.playerId, "high_alert_spawn", "high_alert", "high_alert_death")
		Wargroove.updateUnit(attacker)
	end
end

return UnitPostCombat