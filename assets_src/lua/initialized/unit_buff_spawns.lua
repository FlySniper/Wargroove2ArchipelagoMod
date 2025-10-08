local originalUnitBuffSpawns = require "wargroove/unit_buff_spawns"

local UnitBuffSpawns = {}

local BuffSpawns = {}

function UnitBuffSpawns.init()
    originalUnitBuffSpawns.getBuffSpawns = UnitBuffSpawns.getBuffSpawns
end


local BuffSpawns = {}

function BuffSpawns.buff(Wargroove, unit)
    -- this is just a shell for making buffs more generic
    local buffSpawnId = Wargroove.getUnitState(unit, "buffSpawnId")
    local unitId = Wargroove.getUnitState(unit, "unitId")
    local buffUnit = Wargroove.getUnitById(unitId)
    if buffSpawnId and buffSpawnId ~= "" then
        local buffSpawn = BuffSpawns[buffSpawnId]
        if buffSpawn then
            buffSpawn(Wargroove, buffUnit)
            coroutine.yield()
        end
    end
end

function BuffSpawns.high_alert_spawn(Wargroove, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "units/commanders/duchess/high_alert", "spawn", 1, {}, "over_units")
end

function BuffSpawns.vampiric_touch_spawn(Wargroove, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "units/commanders/sigrid/sigrid_groove_2_back", "idle", 1.0, {}, "units", {x = 0, y = -1}, false, false)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "units/commanders/sigrid/sigrid_groove_2_front", "idle", 1.0, {}, "over_units", {x = 0, y = 0}, false, false)
end

function BuffSpawns.ham_string_spawn(Wargroove, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/groove/slow_effect", "spawn", 1.0, {}, "over_units", {x = 0, y = 0}, false, false)
end

function BuffSpawns.rhomb_command_spawn(Wargroove, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
end

function BuffSpawns.guardian_recharge_spawn(Wargroove, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
end

function BuffSpawns.inspire_high_spawn(Wargroove, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/groove/speed_effect", "spawn", 1.0, {}, "over_units", {x = 0, y = -8}, false, false)
end

function BuffSpawns.spin_concussion_spawn(Wargroove, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/groove/stun_effect", "spawn", 1.0, {}, "over_units", {x = 0, y = 0}, false, false)
end

function BuffSpawns.recruit_discount_spawn(Wargroove, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/groove/nuru_sale_effect", "spawn", 1.0, {}, "over_units", {x = 0, y = 4}, false, false)
end

function BuffSpawns.immunity_potion_spawn(Wargroove, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
end

function BuffSpawns.emeric_boost_spawn(Wargroove, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
end

function BuffSpawns.convert_spawn(Wargroove, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/groove/control_unit", "idle", 1.0, {}, "over_units", {x = 0, y = 0}, false, false)
end

function BuffSpawns.crystal(Wargroove, unit)
    local effectPositions = Wargroove.getTargetsInRange(unit.pos, 2, "all")
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "units/commanders/emeric/crystal_aura_small", "spawn", 0.3, effectPositions)
end

function BuffSpawns.crystal_tier_two(Wargroove, unit)
    local effectPositions = Wargroove.getTargetsInRange(unit.pos, 3, "all")
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "units/commanders/emeric/crystal_aura_aggressive", "spawn", 0.3, effectPositions)
end

function BuffSpawns.drink_rum_spawn(Wargroove, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
end

function BuffSpawns.smoke_producer(Wargroove, unit)
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

    local effectPositions = Wargroove.getTargetsInRange(center, radius, "all")
    Wargroove.displayBuffVisualEffectAtPosition(unit.id, center, unit.playerId, "units/commanders/vesper/"..smokeAnim[tier], "spawn", 0.4, effectPositions, "ground")

    local firePositions = Wargroove.getTargetsInRange(center, radius, "all")
    for i, pos in ipairs(firePositions) do
        Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/vesper/smoke_back", "spawn", 0.4, effectPositions, "units", {x = 0, y = 0})
        Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/vesper/smoke_front", "spawn", 0.5, effectPositions, "units", {x = 0, y = 2})
    end
end

function BuffSpawns.low_resonance_music(Wargroove, unit)
    local currentRadius = 2

    local posString = Wargroove.getUnitState(unit, "pos")
    local vals = {}
    for val in posString.gmatch(posString, "([^"..",".."]+)") do
        vals[#vals+1] = val
    end
    local center = { x = tonumber(vals[1]), y = tonumber(vals[2])}

    local targets = {}

    for i, pos in ipairs(Wargroove.getTargetsInRange(center, currentRadius, "unit")) do
        local targetUnit = Wargroove.getUnitAt(pos)

        if Wargroove.areAllies(targetUnit.playerId, unit.playerId) and not targetUnit.unitClass.isStructure then
            table.insert(targets, targetUnit.id)
            Wargroove.updateUnit(targetUnit)
            Wargroove.displayBuffVisualEffect(targetUnit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, effectPositions, "units", {x = 0, y = 0}, false, false)
        end
    end

    if #targets >= 1 then
        local targetsString = Wargroove.unitIdsToString(targets)

        Wargroove.setUnitState(unit, "targets", targetsString)
        Wargroove.updateUnit(unit)
    end
end

function BuffSpawns.area_heal(Wargroove, unit)
    local posString = Wargroove.getUnitState(unit, "pos")
    
    local vals = {}
    for val in posString.gmatch(posString, "([^"..",".."]+)") do
        vals[#vals+1] = val
    end
    local center = { x = tonumber(vals[1]), y = tonumber(vals[2])}
  
    local radius = tonumber(Wargroove.getUnitState(unit, "radius"))

    local effectPositions = Wargroove.getTargetsInRange(center, radius, "all")
    Wargroove.displayBuffVisualEffectAtPosition(unit.id, center, unit.playerId, "units/commanders/twins/area_heal_" .. tostring(radius), "spawn", 0.3, effectPositions)
    
    local firePositions = Wargroove.getTargetsInRange(center, radius, "all")
    for i, pos in ipairs(firePositions) do
        Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/twins/heal_back2", "spawn", 0.5, effectPositions, "units", {x = 0, y = 0})
        Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/twins/heal_back", "spawn", 0.8, effectPositions, "units", {x = 0, y = 0})
        Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/twins/heal_front", "spawn", 0.1, effectPositions, "units", {x = 0, y = 0})
    end
end

function BuffSpawns.area_damage(Wargroove, unit)
    local posString = Wargroove.getUnitState(unit, "pos")
    
    local vals = {}
    for val in posString.gmatch(posString, "([^"..",".."]+)") do
        vals[#vals+1] = val
    end
    local center = { x = tonumber(vals[1]), y = tonumber(vals[2])}
  
    local radius = tonumber(Wargroove.getUnitState(unit, "radius"))

    local effectPositions = Wargroove.getTargetsInRange(center, radius, "all")
    Wargroove.displayBuffVisualEffectAtPosition(unit.id, center, unit.playerId, "units/commanders/twins/area_damage_" .. tostring(radius), "spawn", 0.4, effectPositions)
    
    local firePositions = Wargroove.getTargetsInRange(center, radius, "all")
    for i, pos in ipairs(firePositions) do
        Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/twins/smoke_back", "spawn", 0.5, effectPositions, "units", {x = 0, y = 0})
        Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/twins/fire_back", "spawn", 0.5, effectPositions, "units", {x = 0, y = 0})
        Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/twins/fire_front", "spawn", 0.5, effectPositions, "units", {x = 0, y = 2})
    end
end


function BuffSpawns.area_combined(Wargroove, unit)
    local posString = Wargroove.getUnitState(unit, "pos")
    
    local vals = {}
    for val in posString.gmatch(posString, "([^"..",".."]+)") do
        vals[#vals+1] = val
    end
    local center = { x = tonumber(vals[1]), y = tonumber(vals[2])}
  
    local radius = tonumber(Wargroove.getUnitState(unit, "radius"))

    local effectPositions = Wargroove.getTargetsInRange(center, radius, "all")
    Wargroove.displayBuffVisualEffectAtPosition(unit.id, center, unit.playerId, "units/commanders/twins/area_damage_" .. tostring(radius), "spawn", 0.4, effectPositions)
    
    local firePositions = Wargroove.getTargetsInRange(center, radius, "all")
    for i, pos in ipairs(firePositions) do
        Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/twins/combined_front", "spawn", 0.5, effectPositions, "over_units", {x = 0, y = 2})
        Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/twins/combined_back", "spawn", 0.5, effectPositions, "units", {x = 0, y = -1})
    end
end


function BuffSpawns.splinter_fire(Wargroove, unit)
    local currentRadius = tonumber(Wargroove.getUnitState(unit, "radius"))

    local posString = Wargroove.getUnitState(unit, "pos")
    local vals = {}
    for val in posString.gmatch(posString, "([^"..",".."]+)") do
        vals[#vals+1] = val
    end
    local center = { x = tonumber(vals[1]), y = tonumber(vals[2])}

    local targets = {}

    for i, pos in ipairs(Wargroove.getTargetsInRange(center, currentRadius, "unit")) do
        local targetUnit = Wargroove.getUnitAt(pos)
        local isPoisoned = Wargroove.getUnitState(targetUnit, "poisoned")

        if isPoisoned ~= "true" and Wargroove.areEnemies(targetUnit.playerId, unit.playerId) then
            table.insert(targets, targetUnit.id)
            Wargroove.setUnitState(targetUnit, "poisoned", "true")
            Wargroove.updateUnit(targetUnit)
            Wargroove.displayBuffVisualEffect(targetUnit.id, unit.playerId, "fx/poison_back", "spawn", 0.6, effectPositions, "units", {x = 0, y = 0}, false, false)
        end
    end

    if #targets >= 1 then
        local targetsString = Wargroove.unitIdsToString(targets)

        Wargroove.setUnitState(unit, "targets", targetsString)
        Wargroove.updateUnit(unit)
    end
end

function BuffSpawns.band_aid(Wargroove, unit)
    local targetUnitId = Wargroove.getUnitState(unit, "unitId")
    local targetUnit = Wargroove.getUnitById(tonumber(targetUnitId))

    if targetUnit then
        Wargroove.displayBuffVisualEffect(targetUnit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, targetUnit.pos, "units", { x = 0, y = 12 }, false, false)
    end
end

function BuffSpawns.stock_trade(Wargroove, unit)
    local targetUnitId = Wargroove.getUnitState(unit, "unitId")
    local targetUnit = Wargroove.getUnitById(tonumber(targetUnitId))

    if targetUnit then
        Wargroove.displayBuffVisualEffect(targetUnit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, targetUnit.pos, "units", { x = 0, y = 12 }, false, false)
    end
end

function BuffSpawns.elder_strength(Wargroove, unit)
    local effectPositions = Wargroove.getTargetsInRange(unit.pos, 3, "all")
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "units/commanders/emeric/crystal_aura", "spawn", 0.3, effectPositions)
end

function UnitBuffSpawns:getBuffSpawns()
    return BuffSpawns
end

return UnitBuffSpawns