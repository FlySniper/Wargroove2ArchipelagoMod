local Events = require "wargroove/events"
local Wargroove = require "wargroove/wargroove"

local Triggers = {}

function Triggers.getRandomCOTrigger()
    local trigger = {}
    trigger.id =  "Randomize CO"
    trigger.isIntro = false
    trigger.enabled = true
    trigger.recurring = "start_of_match"
    trigger.players = { 1, 1, 1, 1, 1, 1, 1, 1 }
    trigger.conditions = {}
    trigger.actions = {}

    table.insert(trigger.actions, { id = "unit_random_co", parameters = { "current" }, enabled = true })
    
    return trigger
end

function Triggers.getAPGrooveTrigger()
    local trigger = {}
    trigger.id =  "AP Groove"
    trigger.isIntro = false
    trigger.enabled = true
    trigger.recurring = "oncePerPlayer"
    trigger.players = { 1, 1, 1, 1, 1, 1, 1, 1 }
    trigger.conditions = {}
    trigger.actions = {}

    table.insert(trigger.conditions, { id = "start_of_turn", parameters = { }, enabled = true  })
    table.insert(trigger.actions, { id = "ap_groove_boost", parameters = { }, enabled = true })

    return trigger
end

function Triggers.getAPBoostTrigger()
    local trigger = {}
    trigger.id =  "AP Boost"
    trigger.isIntro = false
    trigger.enabled = true
    trigger.recurring = "repeat"
    trigger.players = { 1, 1, 1, 1, 1, 1, 1, 1 }
    trigger.conditions = {}
    trigger.actions = {}

    table.insert(trigger.conditions, { id = "start_of_turn", parameters = { }, enabled = true  })
    table.insert(trigger.conditions, { id = "player_turn", parameters = { "current" }, enabled = true })
    table.insert(trigger.actions, { id = "ap_income_boost", parameters = { "current" }, enabled = true })
    table.insert(trigger.actions, { id = "ap_commander_defense_boost", parameters = { }, enabled = true })

    return trigger
end

function Triggers.replaceProductionWithAP()
    local trigger = {}
    trigger.id =  "Replace Production with AP Structures and Count Items"
    trigger.isIntro = false
    trigger.enabled = true
    trigger.recurring = "repeat"
    trigger.players = { 1, 1, 1, 1, 1, 1, 1, 1 }
    trigger.conditions = {}
    trigger.actions = {}

    table.insert(trigger.conditions, { id = "player_turn", parameters = { "current" }, enabled = true })
    table.insert(trigger.actions, { id = "ap_item_check", parameters = { }, enabled = true   })
    table.insert(trigger.actions, { id = "ap_replace_production", parameters = { "current" }, enabled = true })

    return trigger
end

function Triggers.getAPDeathLinkReceivedTrigger()
    local trigger = {}
    trigger.id =  "AP Deathlink"
    trigger.isIntro = false
    trigger.enabled = true
    trigger.recurring = "repeat"
    trigger.players = { 1, 1, 1, 1, 1, 1, 1, 1 }
    trigger.conditions = {}
    trigger.actions = {}

    table.insert(trigger.conditions, { id = "ap_has_death_link", parameters = { "current" }, enabled = true })

    return trigger
end

function Triggers.getAPSuspendDetection()
    local trigger = {}
    trigger.id =  "AP Suspend Detection"
    trigger.isIntro = false
    trigger.enabled = true
    trigger.recurring = "repeat"
    trigger.players = { 1, 1, 1, 1, 1, 1, 1, 1 }
    trigger.conditions = {}
    trigger.actions = {}

    table.insert(trigger.conditions, { id = "ap_suspend_check", parameters = { "current" }, enabled = true })

    return trigger
end

return Triggers