local Wargroove = require "wargroove/wargroove"
local OldCombat = require "wargroove/combat"

Combat = {}

local defencePerShield = 0.10
local damageAt0Health = 0.0
local damageAt100Health = 1.0
local randomDamageMin = 0.0
local randomDamageMax = 0.1

function Combat.init()
	
    OldCombat.getBestWeapon = Combat.getBestWeapon
    OldCombat.getDamage = Combat.getDamage
	OldCombat.getGrooveAttackerDamage = Combat.getGrooveAttackerDamage
    OldCombat.solveCombat = Combat.solveCombat
	OldCombat.solveRound = Combat.solveRound
	OldCombat.solveBothRounds = Combat.solveBothRounds
	OldCombat.getPassiveMultiplier = Combat.getPassiveMultiplier
	OldCombat.startReverseCombat = Combat.startReverseCombat
end
function Combat:getBestWeapon(unit, target, delta, moved, facing)
	if facing == nil then facing = 0 end --Wargroove doesn't care about facing..
	assert(facing ~= nil)

	local weapons = unit.unitClass.weapons
		for i, weapon in ipairs(weapons) do
		if self:canUseWeapon(weapon, moved, delta, facing) then
			local dmg = Wargroove.getWeaponDamage(weapon, unit, target)
            if dmg > 0.0001 then
                return weapon, dmg
            end
        end
    end

	return nil, 0.0
end
function Combat:getPassiveMultiplier(unit, target, unitPos, targetPos, path, isCounter, unitState)
	local condition = nil

	-- Itemified unit class
	if unit.unitClass.aliasId ~= "" then
		condition = self.passiveConditions[unit.unitClass.aliasId]
	else
		if unit.unitClass.critConditionId == "" then
			condition = self.passiveConditions[unit.unitClassId]
		else
			condition = self.passiveConditions[unit.unitClass.critConditionId]
		end
	end

	local payload = {
		attacker = unit,
		defender = target,
		attackerPos = unitPos,
		defenderPos = targetPos,
		path = path,
		isCounter = isCounter,
		unitState = unitState
	}
	if condition ~= nil and condition(payload) then
		return unit.unitClass.passiveMultiplier
	else
		return 1.0
	end
end


function Combat:getGrooveAttackerDamage(attacker, defender, solveType, attackerPos, defenderPos, attackerPath, weaponIdOverride)
	local damage, hadPassive = self:getDamage(attacker, defender, solveType, false, attackerPos, defenderPos, attackerPath, {defenderPos}, true, weaponIdOverride)
	if (damage == nil) then
		return nil, false
	end

	return damage
end

function Combat:getDamage(unit, target, solveType, isCounter, unitPos, targetPos, unitPath, targetPath, isGroove, grooveWeaponIdOverride)
	if type(solveType) ~= "string" then
		error("solveType should be a string. Value is " .. tostring(solveType))
	end
	local missedAttack = 1.0
	if solveType == "crazy" then
		local values = { unit.id, unit.unitClassId, unit.startPos.x, unit.startPos.y, unitPos.x, unitPos.y,
		                 target.id, target.unitClassId, isCounter, Wargroove.getTurnNumber(), Wargroove.getCurrentPlayerId() }
		local roll = Wargroove.randomIntegerFromTable(values, 1, 100)
		if roll <= 50 then
			missedAttack = 0.0
		end

		solveType = "average"
	end

	local delta = {x = targetPos.x - unitPos.x, y = targetPos.y - unitPos.y }
	local moved = unitPath and #unitPath > 1

	-- This check is specifically relevant in two situations: Koji's groove and Lytra's ultra
	if not unit.unitClass.canAttack and not isGroove then
		return nil, false
	end

	local randomValue = 0.5
	if solveType == "random" and Wargroove.isRNGEnabled() then
		local values = { unit.id, unit.unitClassId, unit.startPos.x, unit.startPos.y, unitPos.x, unitPos.y,
		                 target.id, target.unitClassId, target.startPos.x, target.startPos.y, targetPos.x, targetPos.y,
						 isCounter, Wargroove.getTurnNumber(), Wargroove.getCurrentPlayerId() }
		local str = ""
		for i, v in ipairs(values) do
			str = str .. tostring(v) .. ":"
		end
		randomValue = Wargroove.pseudoRandomFromString(str)

		if isCounter then
			randomValue = 0.5
		end
	end
	if solveType == "simulationOptimistic" then
		if isCounter then
			randomValue = 0.5
		else
			randomValue = 1
		end
	end
	if solveType == "simulationPessimistic" then
		if isCounter then
			randomValue = 0.5
		else
			randomValue = 0
		end
	end
	if solveType == "average" then
		randomValue = 0.5
	end

	local unitHealth = isGroove and 100 or unit.health
	local unitEffectiveness = (unitHealth * 0.01) * (damageAt100Health - damageAt0Health) + damageAt0Health
	local targetEffectiveness = (target.health * 0.01) * (damageAt100Health - damageAt0Health) + damageAt0Health

	-- For structures, check if there's a garrison; if so, attack as if it was that instead
	local effectiveUnit
	if unit.garrisonClassId ~= '' then
		effectiveUnit = {
			id = unit.id,
			pos = unit.pos,
			startPos = unit.startPos,
			playerId = unit.playerId,
			unitClassId = unit.garrisonClassId,
			unitClass = Wargroove.getUnitClass(unit.garrisonClassId),
			health = unitHealth,
			state = unit.state,
			damageTakenPercent = unit.damageTakenPercent,
			stunned = unit.stunned,
			tentacled = unit.tentacled
		}
		unitEffectiveness = 1.0
	else
		effectiveUnit = unit
	end

	local passiveMultiplier = self:getPassiveMultiplier(effectiveUnit, target, unitPos, targetPos, unitPath, isCounter, unit.state)
	if not isGroove then
	--	passiveMultiplier = sawItComingMultiplier(unit, target, unitPos, targetPos, unitPath, targetPath, passiveMultiplier)
	end
	local targetUnitClass = Wargroove.getUnitClass(target.unitClassId)
	local targetIsInAir = targetUnitClass.inAir
	local targetIsStructure = targetUnitClass.isStructure
	local targetIsPoisoned = Wargroove.getUnitState(target, "poisoned")
	-- TODO
	local targetCanBeAttackedFromDistance = target.canBeAttackedFromDistance;

	local terrainDefence
	if targetIsInAir then
		terrainDefence = Wargroove.getSkyDefenceAt(targetPos)
	elseif targetIsStructure then
		terrainDefence = 0
	else
		terrainDefence = Wargroove.getTerrainDefenceAt(targetPos)
	end

	local terrainDefenceBonus = terrainDefence * defencePerShield
	if targetIsPoisoned == "true" then
		terrainDefenceBonus = terrainDefenceBonus - 0.15
	end
	if not targetCanBeAttackedFromDistance then
		terrainDefenceBonus = terrainDefenceBonus + 0.20
	end

	local baseDamage
	if (isGroove) then
		local weaponId
		if (grooveWeaponIdOverride ~= nil) then
			weaponId = grooveWeaponIdOverride
		else
			weaponId = unit.unitClass.weapons[1].id
		end
		baseDamage = Wargroove.getWeaponDamageForceGround(weaponId, unit, target)
	else	
		local weapon
		if grooveWeaponIdOverride ~= nil then
			weapon = Wargroove.getWeapon(grooveWeaponIdOverride, unit.unitClassId, unit.id)
			baseDamage = Wargroove.getWeaponDamage(weapon, unit, target)
		else
			weapon, baseDamage = self:getBestWeapon(effectiveUnit, target, delta, moved, unitPos.facing)
		end

		if weapon == nil or (isCounter and not weapon.canMoveAndAttack) 
						 or baseDamage < 0.01 
						 or (isCounter and not weapon.canCounterAttack) 
						 or (isCounter and effectiveUnit.stunned)
						 or (effectiveUnit.tentacled)
						 then
			return nil, false
		end

		if #(weapon.terrainExclusion) > 0 then
			local targetTerrain = Wargroove.getTerrainNameAt(targetPos)
			for i, terrain in ipairs(weapon.terrainExclusion) do
				if targetTerrain == terrain then
					return nil, false
				end
			end
		end
	end

	local multiplier = 1.0
	if Wargroove.isHuman(target.playerId) then
		multiplier = Wargroove.getDamageMultiplier()
		
		-- If the player is on "easy" for damage, make the AI overlook that.
		if multiplier < 1.0 and solveType == "aiSimulation" then
			multiplier = 1.0
		end

		local isScript = Wargroove.isExecutingScript()
		if isScript then
			multiplier = 1.0
		end
	end

	-- Damage reduction
	multiplier = multiplier * target.damageTakenPercent / 100

	local damage = self:solveDamage(baseDamage, unitEffectiveness, targetEffectiveness, terrainDefenceBonus, randomValue, passiveMultiplier, multiplier)

	-- In case the map a counter modifier we increase the base damage of the unit here
	if isCounter then
		local counterModifier = Wargroove.getCounterModifierAt(unitPos)
		damage = damage + counterModifier
	end

	-- Crazy solve type -> We can miss attacks
	damage = damage * missedAttack

	local hasPassive = passiveMultiplier > 1.01
	if passiveMultiplier == 0 then
		damage = nil
		hasPassive = nil
	end

	return damage, hasPassive
end

function Combat:solveRound(unit, target, solveType, isCounter, unitPos, targetPos, unitPath, targetPath)
	if (target.canBeAttacked == false) or (not target.unitClass.isAttackable) then
		return nil, false
	end

	local damage, hadPassive = self:getDamage(unit, target, solveType, isCounter, unitPos, targetPos, unitPath, targetPath, false, nil)	
	if (damage == nil) then
		return nil, false
	end
	
	local targetHealth = math.floor(target.health - damage)
	return targetHealth, hadPassive
end

function Combat:solveBothRounds(attacker, defender, solveType, attackerPath, defenderPath, counterFirst)
	local results = {
		attackerHealth = attacker.health,
		defenderHealth = defender.health,
		attackerAttacked = false,
		defenderAttacked = false,
		hasCounter = false,
		hasAttackerCrit = false
	}
	local targetHealth = nil
	targetHealth, results.hasAttackerCrit = self:solveRound(attacker, defender, solveType, counterFirst, attacker.pos, defender.pos, attackerPath, defenderPath)
	if targetHealth ~= nil then
		results.defenderHealth = targetHealth
		results.attackerAttacked = true
		if results.defenderHealth < 1 and solveType == "random" then
			results.defenderHealth = 0
		end
	end

	if results.defenderHealth > 0 then
		local damagedDefender = {
			id = defender.id,
			pos = defender.pos,
			startPos = defender.startPos,
			playerId = defender.playerId,
			health = results.defenderHealth,
			unitClass = defender.unitClass,
			unitClassId = defender.unitClassId,
			garrisonClassId = defender.garrisonClassId,
			state = defender.state,
			stunned = defender.stunned
		}
		targetHealth, results.hasDefenderCrit = self:solveRound(damagedDefender, attacker, solveType, not counterFirst, defender.pos, attacker.pos, defenderPath, attackerPath)
		if targetHealth ~= nil then
			results.attackerHealth = targetHealth
			results.defenderAttacked = true
			results.hasCounter = true
			if results.attackerHealth < 1 and solveType == "random" then
				results.attackerHealth = 0
			end
		end
	end
	return results
end
local reverseOrder = false
function Combat:solveCombat(attackerId, defenderId, attackerPath, solveType)
	local attacker = Wargroove.getUnitById(attackerId)
	assert(attacker ~= nil)
	local defender = Wargroove.getUnitById(defenderId)
	assert(defender ~= nil)

	local results = {
		attackerHealth = attacker.health,
		defenderHealth = defender.health,
		attackerAttacked = false,
		defenderAttacked = false,
		hasCounter = false,
		hasAttackerCrit = false,
		hasDefenderCrit = false
	}

	if  (reverseOrder == true) then
		local e1 = self:getEndPosition(attackerPath, defender.pos)
		Wargroove.pushUnitPos(defender, e1)
	else
		local e1 = self:getEndPosition(attackerPath, attacker.pos)
		Wargroove.pushUnitPos(attacker, e1)
	end

	if solveType ~= "random" then
		Wargroove.setSimulating(true)
	end
	Wargroove.applyBuffs()

	local defenderPath = {}
	local defenderIsHighAlert = Wargroove.getUnitState(defender, "high_alert")
	local testResult, testCrit = self:solveRound(defender, attacker, solveType, true, defender.pos, attacker.pos, defenderPath, attackerPath)
	local defenderAttacksFirst = defenderIsHighAlert~=nil and defenderIsHighAlert == "true" and testResult ~= nil
	local isPreview =  (solveType == "random" or solveType == "average")
	if defenderAttacksFirst and isPreview then
		for i,tile in pairs(attackerPath) do
			defenderPath[i] = tile
		end
		attackerPath = {defender.pos}
	else
		defenderPath = {defender.pos}
	end
	if defenderAttacksFirst and not isPreview then
		local tempResults = self:solveBothRounds(defender, attacker, solveType, defenderPath, attackerPath, true)
		results = {
			attackerHealth = tempResults.defenderHealth,
			defenderHealth = tempResults.attackerHealth,
			attackerAttacked = true,
			defenderAttacked = tempResults.attackerAttacked,
			hasCounter = tempResults.attackerAttacked,
			hasAttackerCrit = tempResults.hasDefenderCrit,
			hasDefenderCrit = tempResults.hasAttackerCrit
		}
	else
		local tempResults = self:solveBothRounds(attacker, defender, solveType, attackerPath, defenderPath, false)
		results = tempResults
	end
	Wargroove.popUnitPos()
	Wargroove.applyBuffs()
	
	Wargroove.setSimulating(false)
	reverseOrder = false
	return results
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
function Combat:startReverseCombat(attacker, defender, path)
	reverseOrder = true
	attacker.pos = self:getEndPosition(path, attacker.pos)

    Wargroove.doPreCombat(attacker.id, defender.id)
    Wargroove.startCombat(defender, attacker, {}, "average")
	Wargroove.lastAttacker = deepcopy(attacker)
	Wargroove.lastDefender = deepcopy(defender)
	local result = self:solveCombat(attacker.id, defender.id, path, "")
	Wargroove.lastAttacker.health = result.attackerHealth
	Wargroove.lastDefender.health = result.defenderHealth
    Wargroove.setMetaLocation("last_attacker", attacker.pos)
    Wargroove.setMetaLocation("last_defender", defender.pos)
    Wargroove.clearUnitPositionCache()
end

function Combat:solveDamage(weaponDamage, attackerEffectiveness, defenderEffectiveness, terrainDefenceBonus, randomValue, crit, multiplier)
	-- weaponDamage: the base damage, e.g. soldiers do 0.55 base vs soldiers
	-- attackerEffectiveness: the health of the attacker divided by 100. e.g. a soldier at half health is 0.5
	-- defenderEffectiveness: the health of the defender divided by 100
	-- terrainDefenceBonus: 0.1 * number of shields, or -0.1 * number of skulls. e.g. 0.3 for forests and -0.2 for rivers
	-- randomValue: a random number from 0.0 to 1.0
	-- crit: a damage multiplier from critical damage. 1.0 if not critical, > 1.0 for crits (depending on the attacker)
	-- multiplier: a general multiplier, from campaign difficulty and map editor unit damage multiplier

	-- Adjust RNG as follows: rng' = rng * rngMult + rngAdd
	-- This ensures that the average damage remains the same, but clamps the rng range to 10%
	local rngMult = 1.0 / math.max(1.0, crit)
	local rngAdd = (1.0 - rngMult) * 0.5
	local randomBonus = randomDamageMin + (randomDamageMax - randomDamageMin) * (randomValue * rngMult + rngAdd)

	-- Compute the offence and defence based on the different stats
	local offence = weaponDamage + randomBonus
	local defence = 1.0 - (defenderEffectiveness * math.max(0, terrainDefenceBonus) - math.max(0, -terrainDefenceBonus))

	-- Multiply everything together for final damage (in percent space, not unit health space - still needs to be multiplied by 100)
	local damage = attackerEffectiveness * offence * defence * multiplier * crit

	-- Minimum of 1 damage, if any damage is dealt
	local wholeDamage = math.floor(100 * damage + 0.5)
	if damage > 0.001 and wholeDamage < 1 then
		wholeDamage = 1
	end
	return wholeDamage
end


return Combat