local originalUnitBuffDeaths = require "wargroove/unit_buff_deaths"




local UnitBuffDeaths = {}

local BuffDeaths = {}

function UnitBuffDeaths.init()
    originalUnitBuffDeaths.getBuffDeaths = UnitBuffDeaths.getBuffDeaths
end

function BuffDeaths.high_alert_death(Wargroove, unit)
    if not unit then
        return
    end

    Wargroove.setUnitState(unit, "high_alert", "false")
    Wargroove.spawnPaletteSwappedMapAnimation(unit.pos, 0, "units/commanders/duchess/high_alert", unit.playerId, "despawn", "over_units", { x = 12, y = 12 })
    Wargroove.clearBuffVisualEffect(unit.id)
    Wargroove.updateUnit(unit)
end

function BuffDeaths.vampiric_touch_death(Wargroove, unit)
    if not unit then
        return
    end

    Wargroove.popUnitClassModifier(unit.id, "invincibility")
    Wargroove.clearBuffVisualEffect(unit.id)
end

function BuffDeaths.ham_string_death(Wargroove, unit)
    if not unit then
        return
    end

    Wargroove.popUnitClassModifier(unit.id, "ham_string")
    Wargroove.clearBuffVisualEffect(unit.id)
end

function BuffDeaths.drink_rum_death(Wargroove, unit)
    if not unit then
        return
    end

    Wargroove.popUnitClassModifier(unit.id, "inspire_high")
    Wargroove.clearBuffVisualEffect(unit.id)
end

function BuffDeaths.rhomb_command_death(Wargroove, unit)
    if not unit then
        return
    end

    Wargroove.popUnitClassModifier(unit.id, "rhomb_command")
    Wargroove.clearBuffVisualEffect(unit.id)
end

function BuffDeaths.guardian_recharge_death(Wargroove, unit)
    if not unit then
        return
    end

    Wargroove.playUnitAnimation(unit.id, "idle")
    Wargroove.setUnitState(unit, "recharging", "false")
    Wargroove.popUnitClassModifier(unit.id, "guardian_recharge")
    Wargroove.clearBuffVisualEffect(unit.id)
    unit.hadTurn = false
    Wargroove.updateUnit(unit)
end

function BuffDeaths.inspire_high_death(Wargroove, unit)
    if not unit then
        return
    end

    Wargroove.popUnitClassModifier(unit.id, "caesar_inspire_high")
    Wargroove.clearBuffVisualEffect(unit.id)
end

function BuffDeaths.spin_concussion_death(Wargroove, unit)
    if not unit then
        return
    end

    Wargroove.popUnitClassModifier(unit.id, "spin_concussion")
    Wargroove.clearBuffVisualEffect(unit.id)
end

function BuffDeaths.recruit_discount_death(Wargroove, unit)
    if not unit then
        return
    end

    Wargroove.popUnitClassModifier(unit.id, "recruit_discount")
    Wargroove.clearBuffVisualEffect(unit.id)
end

function BuffDeaths.immunity_potion_death(Wargroove, unit)
    if not unit then
        return
    end

    Wargroove.popUnitClassModifier(unit.id, "invincibility")
    Wargroove.clearBuffVisualEffect(unit.id)
end

function BuffDeaths.emeric_boost_death(Wargroove, unit)
    if not unit then
        return
    end

    Wargroove.popUnitClassModifier(unit.id, "emeric_range_boost")
    Wargroove.clearBuffVisualEffect(unit.id)
end

function BuffDeaths.convert_death(Wargroove, unit)
    if not unit then
        return
    end

    local ogPlayerId = tonumber(Wargroove.getUnitState(unit, "originalPlayerId"))
    unit.playerId = ogPlayerId
    Wargroove.clearBuffVisualEffect(unit.id)
    Wargroove.updateUnit(unit)
end

function BuffDeaths.rhomb_rage_death(Wargroove, unit)
    if not unit then
        return
    end

    Wargroove.trackCameraTo(unit.pos)
    Wargroove.waitTime(0.4)

    print("rhomb rage death")

    Wargroove.playUnitAnimation(unit.id, "groove_end")
    Wargroove.playMapSound("rhomb/rhombGrooveEnd", unit.pos)
    Wargroove.waitTime(1.3)

    unit.unitClassId = "commander_rhomb"
    unit.canChargeGroove = true
    Wargroove.updateUnit(unit)
    Wargroove.waitFrame()
    Wargroove.playUnitAnimation(unit.id, "groove_end")

    Wargroove.waitTime(2.0)

    local modifier = Wargroove.getUnitState(unit, "rage")

    if modifier ~= nil and modifier ~= "" then
        Wargroove.popUnitClassModifier(unit.id, modifier)
        Wargroove.setUnitState(unit, "rage", "")
    end
    Wargroove.updateUnit(unit)
end

function UnitBuffDeaths:getBuffDeaths()
    return BuffDeaths
end

return UnitBuffDeaths