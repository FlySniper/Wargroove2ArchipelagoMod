local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local OldDeposit = require "verbs/deposit"

local Deposit = Verb:new()

local stateKey = "gold"

function Deposit.init()
    OldDeposit.canExecuteWithTarget = Deposit.canExecuteWithTarget
end

function Deposit:canExecuteWithTarget(unit, endPos, targetPos, strParam)    
    local targetUnit = Wargroove.getUnitAt(targetPos)
    return targetUnit and (targetUnit.unitClassId == "hideout" or targetUnit.unitClassId == "hideout_ap") and Wargroove.areAllies(unit.playerId, targetUnit.playerId)
end

return Deposit
