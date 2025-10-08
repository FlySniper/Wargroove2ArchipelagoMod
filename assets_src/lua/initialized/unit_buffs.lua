local originalUnitBuffs = require "wargroove/unit_buffs"

local UnitBuffs = {}

local Buffs = {}
local ClearBuffs = {}

function UnitBuffs.init()
    originalUnitBuffs.getBuffs = UnitBuffs.getBuffs
    originalUnitBuffs.getClearBuffs = UnitBuffs.getClearBuffs
end

function Buffs.buff(Wargroove, unit)
    if Wargroove.isSimulating() then
        return
    end

    -- this is just a shell for making buffs more generic
    local buffId = Wargroove.getUnitState(unit, "buffId")
    local unitId = Wargroove.getUnitState(unit, "unitId")
    local buffUnit = Wargroove.getUnitById(tonumber(unitId))

    if buffUnit and buffId and buffId ~= "" then
        local buff = Buffs[buffId]
        if buff then
            buff(Wargroove, buffUnit)
        end
    else 
        -- this buff shouldn't be active, the buff unit doesn't exist anymore
        unit:setHealth(0, -1)
        Wargroove.updateUnit(unit)
    end
end

function Buffs.high_alert(Wargroove, unit)
    Wargroove.displayBuffVisualEffect(
        unit.id --[[parentId]], 
        unit.playerId --[[playerId]],
        "units/commanders/duchess/high_alert" --[[animation]],
        "idle" --[[startSequence]],
        1.0 --[[alpha]],
        {} --[[effectPositions]],
        "over_units" --[[layer]]
    )
end

function Buffs.vampiric_touch(Wargroove, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "units/commanders/sigrid/sigrid_groove_2_back", "idle", 0.6, {}, "units", {x = 0, y = -1}, false, false)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "units/commanders/sigrid/sigrid_groove_2_front", "idle", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
end

function Buffs.ham_string(Wargroove, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/groove/slow_effect", "idle", 1.0, {}, "over_units", {x = 0, y = 0}, false, false)
end

function Buffs.rhomb_command(Wargroove, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
end

function Buffs.guardian_recharge(Wargroove, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
end

function Buffs.inspire_high(Wargroove, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/groove/speed_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = -8}, false, false)
end

function Buffs.spin_concussion(Wargroove, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/groove/stun_effect", "spawn", 1.0, {}, "over_units", {x = 0, y = 0}, false, false)
end

function Buffs.recruit_discount(Wargroove, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/groove/nuru_sale_effect", "idle", 1.0, {}, "over_units", {x = 0, y = 4}, false, false)
end

function Buffs.immunity_potion(Wargroove, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
end

function Buffs.emeric_boost(Wargroove, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
end

function Buffs.convert(Wargroove, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/groove/control_unit", "idle", 1.0, {}, "over_units", {x = 0, y = 0}, false, false)
end

function Buffs.drink_rum(Wargroove, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
end

function Buffs.rhomb_rage(Wargroove, unit)
    -- Just an empty shell so it doesn't trigger death immediately
end

function applyCrystal(Wargroove, unit, tier, range, player_defense_bonus, enemy_defense_penalty)
    if Wargroove.isSimulating() then
        return
    end

    local effectPositions = Wargroove.getTargetsInRange(unit.pos, range, "all")

    if tier == 1 then
        Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "units/commanders/emeric/crystal_aura_small", "idle", 0.3)
    elseif tier == 2 then
        Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "units/commanders/emeric/crystal_aura_aggressive", "idle", 0.3)
    end

    local positions = Wargroove.getTargetsInRange(unit.pos, range, "all")

    -- Reset all units that aren't inside the range anymore
    if tier == 2 then 
        local allUnits = Wargroove.getAllUnitsForPlayer(unit.playerId)
        for _, u in ipairs(allUnits) do
            if Wargroove.getUnitState(u, "emeric_range_boost") == "true" then
                Wargroove.popUnitClassModifier(u.id, "emeric_range_boost")
                Wargroove.setUnitState(u, "emeric_range_boost", "false")
            end
        end
    end

    for i, pos in pairs(positions) do
        local u = Wargroove.getUnitAt(pos)

        -- If (and only if) it's your turn, or your ally's, also apply to empty tiles, because your unit might be about to move that.
        -- Otherwise, combat results preview will be wrong.
        -- Likewise, if this happens on an enemy's turn, preview will be wrong.
        -- Note that preview also affects AI's ability to judge moves.
        local includeEmpty = Wargroove.areAllies(Wargroove.getCurrentPlayerId(), unit.playerId)

        if (u == nil and includeEmpty) or (u ~= nil and Wargroove.areAllies(u.playerId, unit.playerId)) then
            local baseDefence = Wargroove.getBaseTerrainDefenceAt(pos)
            local currentDefence = Wargroove.getTerrainDefenceAt(pos)
            local newDefence = math.min(math.max(baseDefence + player_defense_bonus, currentDefence), 4)
            Wargroove.setTerrainDefenceAt(pos, newDefence)

            local baseSkyDefence = Wargroove.getBaseSkyDefence()
            local currentSkyDefence = Wargroove.getSkyDefenceAt(pos)
            local newSkyDefence = math.min(math.max(baseSkyDefence + player_defense_bonus, currentSkyDefence), 4)
            Wargroove.setSkyDefenceAt(pos, newSkyDefence)
        end

        if (u ~= nil and enemy_defense_penalty > 0 and Wargroove.areEnemies(u.playerId, unit.playerId)) then
            local baseDefence = Wargroove.getBaseTerrainDefenceAt(pos)
            local currentDefence = Wargroove.getTerrainDefenceAt(pos)
            local newDefence = math.min(baseDefence - enemy_defense_penalty, currentDefence)
            Wargroove.setTerrainDefenceAt(pos, newDefence)

            print("Base: "..baseDefence.." Current: "..currentDefence.." New: "..newDefence)

            local baseSkyDefence = Wargroove.getBaseSkyDefence()
            local currentSkyDefence = Wargroove.getSkyDefenceAt(pos)
            local newSkyDefence = math.min(baseSkyDefence - enemy_defense_penalty, currentSkyDefence)
            Wargroove.setSkyDefenceAt(pos, newSkyDefence)
        end

        -- Also apply range buff at this point to any unit within range
        if tier == 2 then
            if u and Wargroove.areAllies(u.playerId, unit.playerId) and u.id ~= unit.id and #u.unitClass.weapons > 0 and u.unitClass.weapons[1].maxRange > 1 then
                Wargroove.pushUnitClassModifier(u.id, "emeric_range_boost")
                Wargroove.setUnitState(u, "emeric_range_boost", "true")
                Wargroove.updateUnit(u)
            end
        end
    end
end

function Buffs.crystal(Wargroove, unit)
    applyCrystal(Wargroove, unit, 1, 2, 2, 0)
end

function Buffs.crystal_tier_two(Wargroove, unit)
    applyCrystal(Wargroove, unit, 2, 3, 3, 0)
end

function Buffs.elder_strength(Wargroove, unit)
    local effectPositions = Wargroove.getTargetsInRange(unit.pos, 3, "all")
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "units/commanders/emeric/crystal_aura", "spawn", 0.3, effectPositions)

    local isEnemyTurn = Wargroove.areEnemies(Wargroove.getCurrentPlayerId(), unit.playerId)

    for i, pos in pairs(effectPositions) do
        -- This is bascically the opposite of the crystal's version above. Only apply to empty in enemy turn.
        -- We do this because we don't want the ally to be impacted by the buff to the enemy's counter
        if isEnemyTurn then
            Wargroove.setCounterModifierAt(pos, 15)
        else
            Wargroove.setCounterModifierAt(pos, 0)
        end
    end
end

function Buffs.crystal_struct(Wargroove, unit)
    if Wargroove.isSimulating() then
        return
    end
    
    local effectPositions = Wargroove.getTargetsInRange(unit.pos, 3, "all")
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "units/commanders/emeric/crystal_aura", "idle", 0.3, effectPositions)

    local range = 3
    local positions = Wargroove.getTargetsInRange(unit.pos, range, "all")
    for i, pos in pairs(positions) do
        local u = Wargroove.getUnitAt(pos)

        -- If (and only if) it's your turn, or your ally's, also apply to empty tiles, because your unit might be about to move that.
        -- Otherwise, combat results preview will be wrong.
        -- Likewise, if this happens on an enemy's turn, preview will be wrong.
        -- Note that preview also affects AI's ability to judge moves.
        local includeEmpty = Wargroove.areAllies(Wargroove.getCurrentPlayerId(), unit.playerId)

        if (u == nil and includeEmpty) or (u ~= nil and Wargroove.areAllies(u.playerId, unit.playerId)) then
            local baseDefence = Wargroove.getBaseTerrainDefenceAt(pos)
            local currentDefence = Wargroove.getTerrainDefenceAt(pos)
            local newDefence = math.min(math.max(baseDefence + 3, currentDefence), 4)
            Wargroove.setTerrainDefenceAt(pos, newDefence)

            local baseSkyDefence = Wargroove.getBaseSkyDefence()
            local currentSkyDefence = Wargroove.getSkyDefenceAt(pos)
            local newSkyDefence = math.min(math.max(baseSkyDefence + 3, currentSkyDefence), 4)
            Wargroove.setSkyDefenceAt(pos, newSkyDefence)
        end
    end
end

function Buffs.burn(Wargroove, unit)
    if Wargroove.isSimulating() then
        return
    end
    
    local targetId = Wargroove.getUnitState(unit, "unitId")
    local targetUnit = Wargroove.getUnitById(tonumber(targetId))

    if targetUnit then
        local isBurning = Wargroove.getUnitState(targetUnit, "burning")

        if isBurning == "true" then
            Wargroove.displayBuffVisualEffect(targetUnit.id, targetUnit.playerId, "units/commanders/nadia/nadia_fire_front", "spawn", 0.6, nil, "over_units", {x = 0, y = -7}, false, false)          
        end
    end
end

function Buffs.roots(Wargroove, unit)
    if Wargroove.isSimulating() then
        return
    end

    local targetId = Wargroove.getUnitState(unit, "unitId")
    local targetUnit = Wargroove.getUnitById(tonumber(targetId))

    if targetUnit then
        local isRooted = Wargroove.getUnitState(targetUnit, "rooted")

        if isRooted == "true" then
            Wargroove.displayBuffVisualEffect(targetUnit.id, targetUnit.playerId, "fx/general_unit_effect", "spawn", 0.6, effectPositions, "units", {x = 0, y = 0}, false, false)
        end
    end
end

function Buffs.smoke_producer(Wargroove, unit)
    local smokeRadius = {2, 2}
    local smokeAnim = {"smoke_large", "smoke_large"}
    local posString = Wargroove.getUnitState(unit, "pos")
    local tier = tonumber(Wargroove.getUnitState(unit, "tier"))
    
    local vals = {}
    for val in posString.gmatch(posString, "([^"..",".."]+)") do
        vals[#vals+1] = val
    end
    local center = { x = tonumber(vals[1]), y = tonumber(vals[2])}

    local radius = smokeRadius[tier]
    
    if (not Wargroove.isSimulating()) then
        local effectPositions = Wargroove.getTargetsInRange(center, radius, "all")
        Wargroove.displayBuffVisualEffectAtPosition(unit.id, center, unit.playerId, "units/commanders/vesper/"..smokeAnim[tier], "idle", 0.4, effectPositions, "ground")

        local firePositions = Wargroove.getTargetsInRange(center, radius, "all")
        for i, pos in ipairs(firePositions) do
            Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/vesper/smoke_back", "", 0.4, effectPositions, "units", {x = 0, y = 0})
            Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/vesper/smoke_front", "", 0.5, effectPositions, "units", {x = 0, y = 2})
        end
    end

    local positions = Wargroove.getTargetsInRange(center, radius, "unit")
    for i, pos in pairs(positions) do      
        local u = Wargroove.getUnitAt(pos)
        u.canBeAttacked = false
        Wargroove.setUnitState(u, "smokeScreened", "true")
    end
end

function Buffs.low_resonance_music(Wargroove, unit)
    local posString = Wargroove.getUnitState(unit, "pos")
    
    local vals = {}
    for val in posString.gmatch(posString, "([^"..",".."]+)") do
        vals[#vals+1] = val
    end
    local center = { x = tonumber(vals[1]), y = tonumber(vals[2])}

    local radius = 2

    local positions = Wargroove.getTargetsInRange(center, radius, "unit")
    for i, pos in pairs(positions) do      
        local u = Wargroove.getUnitAt(pos)    
        u.canBeAttackedFromDistance = false
    end
end

function ClearBuffs.smoke_producer(Wargroove, unit)
    local mapSize = Wargroove.getMapSize()
    for x0 = 0, mapSize.x do
        for y0 = 0, mapSize.y do
            local unit = Wargroove.getUnitAt({x = x0, y = y0})
            if unit ~= nil and Wargroove.getUnitState(unit, "smokeScreened") == "true" then
                unit.canBeAttacked = true
                Wargroove.setUnitState(unit, "smokeScreened", "false")
            end
        end
    end
end

function ClearBuffs.low_resonance_music(Wargroove, unit)
    local mapSize = Wargroove.getMapSize()
    for x0 = 0, mapSize.x do
        for y0 = 0, mapSize.y do
            local unit = Wargroove.getUnitAt({x = x0, y = y0})
            if unit ~= nil then
                unit.canBeAttackedFromDistance = true
            end
        end
    end
end

function Buffs.area_heal(Wargroove, unit)
    if Wargroove.isSimulating() then
        return
    end

    local posString = Wargroove.getUnitState(unit, "pos")
    
    local vals = {}
    for val in posString.gmatch(posString, "([^"..",".."]+)") do
        vals[#vals+1] = val
    end
    local center = { x = tonumber(vals[1]), y = tonumber(vals[2])}
    local radius = tonumber(Wargroove.getUnitState(unit, "radius"))
  
    local effectPositions = Wargroove.getTargetsInRange(center, radius, "all")
    Wargroove.displayBuffVisualEffectAtPosition(unit.id, center, unit.playerId, "units/commanders/twins/area_heal_" .. tostring(radius), "idle", 0.3, effectPositions)

    local firePositions = Wargroove.getTargetsInRange(center, radius, "all")
    for i, pos in ipairs(firePositions) do
      Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/twins/heal_back2", "", 0.5, effectPositions, "units", {x = 0, y = 0})
      Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/twins/heal_back", "", 0.8, effectPositions, "units", {x = 0, y = 0})
      Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/twins/heal_front", "", 0.1, effectPositions, "units", {x = 0, y = 0})
    end

    local centerRadius = math.max(radius - 1, 0)
    local result = Buffs.createAreaThreatMap(Wargroove, center, radius, centerRadius, -0.2, -0.05)
    Wargroove.setThreatMap(unit.id, result)
end

function Buffs.area_damage(Wargroove, unit)
    if Wargroove.isSimulating() then
        return
    end

    local posString = Wargroove.getUnitState(unit, "pos")
    
    local vals = {}
    for val in posString.gmatch(posString, "([^"..",".."]+)") do
        vals[#vals+1] = val
    end
    local center = { x = tonumber(vals[1]), y = tonumber(vals[2])}
    local radius = tonumber(Wargroove.getUnitState(unit, "radius"))
  
    local effectPositions = Wargroove.getTargetsInRange(center, radius, "all")
    Wargroove.displayBuffVisualEffectAtPosition(unit.id, center, unit.playerId, "units/commanders/twins/area_damage_" .. tostring(radius), "idle", 0.4, effectPositions)

    local firePositions = Wargroove.getTargetsInRange(center, radius, "all")
    for i, pos in ipairs(firePositions) do
      Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/twins/smoke_back", "spawn", 0.5, effectPositions, "units", {x = 0, y = 0})
      Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/twins/fire_back", "spawn", 0.5, effectPositions, "units", {x = 0, y = 0})
      Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/twins/fire_front", "spawn", 0.5, effectPositions, "units", {x = 0, y = 0})
    end

    local maxRadius = 3
    local centerRadius = math.max(radius - 1, 0)
    local result = Buffs.createAreaThreatMap(Wargroove, center, maxRadius, centerRadius, 100, 1)
    Wargroove.setThreatMap(unit.id, result)
end

function Buffs.area_combined_hidden(Wargroove, unit)
    if Wargroove.isSimulating() then
        return
    end

    local posString = Wargroove.getUnitState(unit, "pos")
    
    local vals = {}
    for val in posString.gmatch(posString, "([^"..",".."]+)") do
        vals[#vals+1] = val
    end
    local center = { x = tonumber(vals[1]), y = tonumber(vals[2])}
    local radius = tonumber(Wargroove.getUnitState(unit, "radius"))
  
    local effectPositions = Wargroove.getTargetsInRange(center, radius, "all")
    Wargroove.displayBuffVisualEffectAtPosition(unit.id, center, unit.playerId, "units/commanders/twins/area_damage_" .. tostring(radius), "idle", 0.4, effectPositions)

    local firePositions = Wargroove.getTargetsInRange(center, radius, "all")
    for i, pos in ipairs(firePositions) do
      Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/twins/combined_front", "spawn", 0.5, effectPositions, "over_units", {x = 0, y = 2})
      Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/twins/combined_back", "spawn", 0.5, effectPositions, "units", {x = 0, y = -1})
    end

    local maxRadius = 3
    local centerRadius = math.max(radius - 1, 0)
    local result = Buffs.createAreaThreatMap(Wargroove, center, maxRadius, centerRadius, 100, 1)
    Wargroove.setThreatMap(unit.id, result)
end

function Buffs.createAreaThreatMap(Wargroove, center, maxRadius, radius, centerValue, outerValue)
    local mapSize = Wargroove.getMapSize()

    local result = {}
    local x0 = center.x
    local y0 = center.y
    for yo = -maxRadius, maxRadius do
        for xo = -maxRadius, maxRadius do
            local distance = math.abs(xo) + math.abs(yo)            
            if distance <= maxRadius then
                local x = x0 + xo
                local y = y0 + yo
                if (x >= 0) and (y >= 0) and (x < mapSize.x) and (y < mapSize.y) then
                    local value = 0
                    if distance <= radius then
                        value = centerValue
                    else
                        value = outerValue
                    end
                    table.insert(result, {position = {x = x, y = y},  value = value})
                end
            end
        end
    end
    return result
end

local outOfAmmoAnimation = "ui/icons/bullet_out_of_ammo"

function Buffs.rifleman(Wargroove, unit)
    if Wargroove.isSimulating() then
        return
    end

    if (Wargroove.getUnitState(unit, "ammo") == nil) then
        Wargroove.setUnitState(unit, "ammo", 2)
        Wargroove.updateUnit(unit)
    end

    if (Wargroove.getUnitState(unit, "ammo") == "0") then
        if not Wargroove.hasUnitEffect(unit.id, outOfAmmoAnimation) then
            Wargroove.spawnUnitEffect(unit.id, unit.id, outOfAmmoAnimation, "idle", startAnimation, true, false)
        end
    elseif Wargroove.hasUnitEffect(unit.id, outOfAmmoAnimation) then
        Wargroove.deleteUnitEffectByAnimation(unit.id, outOfAmmoAnimation)
    end
end

function Buffs.thief(Wargroove, unit)
    if Wargroove.isSimulating() then
        return
    end

    if (Wargroove.getUnitState(unit, "gold") == nil) then
        Wargroove.setUnitState(unit, "gold", 0)
        Wargroove.updateUnit(unit)
    end
end

function Buffs.thief_with_gold(Wargroove, unit)
    if Wargroove.isSimulating() then
        return
    end
    
    if (Wargroove.getUnitState(unit, "gold") == nil) then
        Wargroove.setUnitState(unit, "gold", 300)
        Wargroove.updateUnit(unit)
    end
end

function UnitBuffs:getBuffs()
    return Buffs
end

function UnitBuffs:getClearBuffs()
    return ClearBuffs
end

return UnitBuffs