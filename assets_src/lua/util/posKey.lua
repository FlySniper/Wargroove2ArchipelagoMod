local PosKey = {}

function PosKey.generatePosKey(pos)
	return pos.x*1000+pos.y --Should work as long as people don't make maps taller than 1000 tiles.
end
function PosKey.revertPosKey(posKey)
	return {x = math.floor(posKey/1000), y = math.floor(posKey%1000)} --Should work as long as people don't make maps taller than 1000 tiles.
end
return PosKey
