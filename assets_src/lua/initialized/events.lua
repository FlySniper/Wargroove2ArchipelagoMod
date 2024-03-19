local OriginalEvents = require "wargroove/events"
local Wargroove = require("wargroove/wargroove")
local TriggerContext = require("triggers/trigger_context")
local Resumable = require("wargroove/resumable")
local Triggers = require("triggers")

local Events = {}

local triggerContext = TriggerContext:new({
    state = "",
    fired = {},
    campaignFlags = {},
    mapFlags = {},
    mapCounters = {},
    party = {},
    campaignCutscenes = {},
    gotoFlag = nil,
    creditsToPlay = "",
    interactTargetPos = nil
})

local triggerList = nil
local triggerConditions = {}
local triggerActions = {}
local pendingDeadUnits = {}
local pendingVerbsUsed = {}
local pendingInteractionsUsed = {}

-- This is called by the game when the map is loaded.
function Events.init()
  OriginalEvents.populateTriggerList = Events.populateTriggerList
  OriginalEvents.doCheckEvents = Events.doCheckEvents
  OriginalEvents.startSession = Events.startSession
  OriginalEvents.getMatchState = Events.getMatchState
  OriginalEvents.addToActionsList = Events.addToActionsList
  OriginalEvents.addToConditionsList = Events.addToConditionsList
  OriginalEvents.setMapFlag = Events.setMapFlag
  OriginalEvents.canExecuteTrigger = Events.canExecuteTrigger
  OriginalEvents.executeTrigger = Events.executeTrigger
  OriginalEvents.isConditionTrue = Events.isConditionTrue
  OriginalEvents.runAction = Events.runAction
  OriginalEvents.reportUnitDeath = Events.reportUnitDeath
  OriginalEvents.addTriggerToList = Events.addTriggerToList
  OriginalEvents.removeTriggerFromList = Events.removeTriggerFromList
  OriginalEvents.getTriggerKey = Events.getTriggerKey
  OriginalEvents.runActions =  Events.runActions
end

function Events.startSession(matchState)
    pendingDeadUnits = {}
    pendingVerbsUsed = {}
    pendingInteractionsUsed = {}

    Events.populateTriggerList()

    function readVariables(name)
        src = matchState[name]
        dst = triggerContext[name]

        for i, var in ipairs(src) do
            dst[var.id] = var.value
        end
    end

    readVariables("mapFlags")
    readVariables("mapCounters")
    readVariables("campaignFlags")

    for i, var in ipairs(matchState.triggersFired) do
        triggerContext.fired[var] = true
    end

    for i, var in ipairs(matchState.party) do
        table.insert(triggerContext.party, var)
    end

    for i, var in ipairs(matchState.campaignCutscenes) do
        table.insert(triggerContext.campaignCutscenes, var)
    end

    triggerContext.creditsToPlay = matchState.creditsToPlay
end


function Events.getMatchState()
    local result = {}

    function writeVariables(name)
        local src = triggerContext[name]
        local dst = {}
        result[name] = dst

        for k, v in pairs(src) do
            table.insert(dst, { id = k, value = v })
        end
    end

    writeVariables("mapFlags")
    writeVariables("mapCounters")
    writeVariables("campaignFlags")

    result.triggersFired = {}
    for k, v in pairs(triggerContext.fired) do
        table.insert(result.triggersFired, k)
    end

    result.party = {}
    for i, var in ipairs(triggerContext.party) do
        table.insert(result.party, var)
    end

    result.campaignCutscenes = {}
    for i, var in ipairs(triggerContext.campaignCutscenes) do
        table.insert(result.campaignCutscenes, var)
    end

    result.creditsToPlay = triggerContext.creditsToPlay

    return result
end

local additionalActions = {}
local additionalConditions = {}

function Events.setInteractTarget(targetPos)
    triggerContext.interactTargetPos = targetPos
end

function Events.addToActionsList(actions)
  table.insert(additionalActions, actions)
end

function Events.addToConditionsList(conditions)
  table.insert(additionalConditions, conditions)
end

function Events.addTriggerToList(triggerToAdd)    
    local notFinished = true
    while notFinished do
        for i, trigger in ipairs(triggerList) do
            if trigger.id ~= nil and trigger.id == triggerToAdd.id then
                table.remove(triggerList, i)
                break;
            end
            if i == #triggerList then
                notFinished = false
            end
        end
    end
    table.insert(triggerList,triggerToAdd)
end

function Events.removeTriggerFromList(triggerId)
    local notFinished = true
    while notFinished do
        for i, trigger in ipairs(triggerList) do
            if trigger.id ~= nil and trigger.id == triggerId then
                table.remove(triggerList, i)
                break;
            end
            if i == #triggerList then
                notFinished = false
            end
        end
    end
end

function Events.getTrigger(triggerId)
    for i, trigger in ipairs(triggerList) do
        if trigger.id ~= nil and trigger.id == triggerId then
            return trigger
        end
    end
    return nil
end

function Events.populateTriggerList()
    triggerList = Wargroove.getMapTriggers()

    local Actions = require("triggers/actions")
    local Conditions = require("triggers/conditions")

    Events.addTriggerToList(Triggers.getRandomCOTrigger())
    Events.addTriggerToList(Triggers.replaceProductionWithAP())
    Events.addTriggerToList(Triggers.getAPGrooveTrigger())
    Events.addTriggerToList(Triggers.getAPDeathLinkReceivedTrigger())
    Events.addTriggerToList(Triggers.getAPBoostTrigger())


    Conditions.populate(triggerConditions)
    Actions.populate(triggerActions)

    for i, action in ipairs(additionalActions) do
      action.populate(triggerActions)
    end

    for i, condition in ipairs(additionalConditions) do
      condition.populate(triggerConditions)
    end
end

function Events.doCheckEvents(state)
    triggerContext.state = state
    triggerContext.deadUnits = pendingDeadUnits
    triggerContext.verbsUsed = pendingVerbsUsed
    triggerContext.interactionsUsed = pendingInteractionsUsed

    local newPendingUnits = {}
    for i, unit in ipairs(pendingDeadUnits) do
        if unit.triggeredBy ~= nil then
            table.insert(newPendingUnits, unit)
        end
    end

    local newPendingVerbs = {}
    for i, unit in ipairs(pendingVerbsUsed) do
        if unit.verbTriggeredBy ~= nil then
            table.insert(newPendingVerbs, unit)
        end
    end

    local newPendingInteractions = {}
    for i, unit in ipairs(pendingInteractionsUsed) do
        if unit.verbTriggeredBy ~= nil then
            table.insert(newPendingInteractions, unit)
        end
    end

    pendingDeadUnits = newPendingUnits
    pendingVerbsUsed = newPendingVerbs
    pendingInteractionsUsed = newPendingInteractions

    for triggerNum, trigger in ipairs(triggerList) do
        triggerContext.triggerInstanceTriggerId = triggerNum

        local newPendingUnits = {}
        for j, unit in ipairs(pendingDeadUnits) do
            if unit.triggeredBy == nil or unit.triggeredBy ~= triggerNum then
                table.insert(newPendingUnits, unit)
            end
        end

        local newPendingVerbs = {}
        for j, unit in ipairs(pendingVerbsUsed) do
            if unit.verbTriggeredBy == nil or unit.verbTriggeredBy ~= triggerNum then
                table.insert(newPendingVerbs, unit)
            end
        end

        local newPendingInteractions = {}
        for j, unit in ipairs(pendingInteractionsUsed) do
            if unit.interactionTriggeredBy == nil or unit.interactionTriggeredBy ~= triggerNum then
                table.insert(newPendingInteractions, unit)
            end
        end

        pendingDeadUnits = newPendingUnits
        pendingVerbsUsed = newPendingVerbs
        pendingInteractionsUsed = newPendingInteractions

        for n = 0, 7 do
            triggerContext.triggerInstancePlayerId = n
            if trigger.enabled and Events.canExecuteTrigger(trigger) then
                Events.executeTrigger(trigger)
                for j, unit in ipairs(pendingDeadUnits) do
                    if unit.triggeredBy == nil then
                        unit.triggeredBy = triggerNum
                        table.insert(triggerContext.deadUnits, unit)
                    end
                end
                for j, unit in ipairs(pendingVerbsUsed) do
                    if unit.verbTriggeredBy == nil then
                        unit.verbTriggeredBy = triggerNum
                        table.insert(triggerContext.verbsUsed, unit)
                    end
                end
                for j, unit in ipairs(pendingInteractionsUsed) do
                    if unit.interactionTriggeredBy == nil then
                        unit.interactionTriggeredBy = triggerNum
                        table.insert(triggerContext.interactionsUsed, unit)
                    end
                end
            end
        end
    end
end

function Events.runActions(actions, isIntro)
    local i=1
    while i<=#actions do
        triggerContext.triggerInstanceActionId = i
        local action = actions[i]

        if action.enabled then
            --print("Running action #"..i)
            Events.runAction(action)
            coroutine.yield()
        end

        -- Check for goto flag being set, which jumps the current action position
        if triggerContext.gotoFlag ~= nil then
            local newIndex = i + triggerContext.gotoFlag + 1
            newIndex = math.max(0, newIndex)
            newIndex = math.min(#actions, newIndex)

            i = newIndex
            triggerContext.gotoFlag = nil
        else
            i = i + 1
        end
    end
end


function Events.setMapFlag(flagId, value)
    triggerContext:setMapFlagById(flagId, value)
end



function Events.canExecuteTrigger(trigger)
    -- Check if this trigger supports this player
    if trigger.players[triggerContext.triggerInstancePlayerId + 1] ~= 1 then
        return false
    end

    if trigger.recurring ~= 'start_of_match' then
        if triggerContext:checkState('startOfMatch') then
            return false
        end
    elseif not triggerContext:checkState('startOfMatch') then
        return false
    end

    if trigger.recurring ~= 'end_of_match' then
        if triggerContext:checkState('endOfMatch') then
            return false
        end
    elseif not triggerContext:checkState('endOfMatch') then
        return false
    end

    -- Check if it already ran
    if trigger.recurring ~= "repeat" and trigger.recurring ~= "start_of_interact" and trigger.recurring ~= "unit_selected" then
        if triggerContext.fired[Events.getTriggerKey(trigger)] ~= nil then
            return false
        end
    end

    if trigger.recurring ~= 'start_of_interact' then
        if triggerContext:checkState('startOfInteract') then
            return false
        end
    elseif not triggerContext:checkState('startOfInteract') then
        return false
    end

    if trigger.recurring ~= 'unit_selected' then
        if triggerContext:checkState('unitSelected') then
            return false
        end
    elseif not triggerContext:checkState('unitSelected') then
        return false
    end

    -- Check all conditions
    return OriginalEvents.checkConditions(trigger.conditions)
end

function Events.executeTrigger(trigger)
    triggerContext.fired[Events.getTriggerKey(trigger)] = true

    local applySkippable = Wargroove.areIntroEventsSkippable() and trigger.isIntro

    if not applySkippable then
        OriginalEvents.runActions(trigger.actions, trigger.isIntro)
    else
        print("Skipping intro trigger actions "..trigger.id)
    end
end

function Events.getTriggerKey(trigger)
    local key = trigger.id
    if trigger.recurring == "oncePerPlayer" then
        key = key .. ":" .. tostring(triggerContext.triggerInstancePlayerId)
    end
    return key
end


function Events.isConditionTrue(condition)
    local f = triggerConditions[condition.id]
    if f == nil then
        print("Condition not implemented: " .. condition.id)
    else
        triggerContext.params = condition.parameters
        return f(triggerContext)
    end
end


function Events.runAction(action)
    local f = triggerActions[action.id]
    if f == nil then
        print("Action not implemented: " .. action.id)
    else
        --print("Executing action " .. action.id)
        triggerContext.params = action.parameters
        f(triggerContext)
    end
end


function Events.reportUnitDeath(id, attackerUnitId, attackerPlayerId, attackerUnitClass)
    local unit = Wargroove.getUnitById(id)
    unit.attackerId = attackerUnitId
    unit.attackerPlayerId = attackerPlayerId
    unit.attackerUnitClass = attackerUnitClass
    table.insert(pendingDeadUnits, unit)
    Wargroove.setMetaUnitClass("last_death", unit.unitClass)
end

function Events.reportVerbUsed(id, verb, isGrooveVerb, targetPos, strParam, path)
    local unit = Wargroove.getUnitById(id)
    unit.verbUsed = {
        verb = verb,
        isGroove = isGrooveVerb,
        strParam = strParam,
        path = path
    }
    table.insert(pendingVerbsUsed, unit)
end

function Events.reportInteractionUsed(id, verb, targetPos, path)
    local unit = Wargroove.getUnitById(id)
    unit.interactionUsed = {
        verb = verb,
        targetPos = targetPos,
        path = path
    }
    table.insert(pendingInteractionsUsed, unit)
end

return Events