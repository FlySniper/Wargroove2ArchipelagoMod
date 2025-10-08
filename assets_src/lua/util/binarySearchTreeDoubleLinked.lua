local Node = {}

Node.__index = Node

function Node:new(key, data)
    self = {}

    self._key = key
    self._data = data
    self.left = nil
    self.right = nil
    self.prev = nil
    self.next = nil

    setmetatable(self, Node)
    return self
end

function Node:getKey()
    return self._key
end

function Node:getData()
    return self._data
end

function Node:getPrev()
    return self.prev
end

function Node:getNext()
    return self.next
end

function Node:setPrev(node)
    self.prev = node
end

function Node:setNext(node)
    self.next = node
end

local Tree = {}
package.loaded["Tree"] = Tree

Tree.__index = Tree

function Tree:new()
    self = {}
    self._root = nil
	self.size = 0

    setmetatable(self, Tree)
    return self
end

local function contains(node, key)
    if node:getKey() == key then
        return true
    elseif key < node:getKey() then

        if node.left ~= nil then
            return contains(node.left, key)
        end
    else
        if node.right ~= nil then
            return contains(node.right, key)
        end
    end

    return false
end

function Tree:contains(key)
    if self._root == nil then
        return false
    end

    return contains(self._root, key)
end

local function getAdjNode(node,key)
    if node:getKey() == key then
        return node
    elseif key < node:getKey() then

        if node.left ~= nil then
            return getAdjNode(node.left, key)
        end
    else
        if node.right ~= nil then
            return getAdjNode(node.right, key)
        end
    end
	return node
end

function Tree:getAdjNode(key)
    if self._root == nil then
        return nil
    end

    return getAdjNode(self._root, key)
end

function Tree:getNodeBefore(key)
    if self._root == nil then
        return nil
    end
	local node = getAdjNode(self._root, key)
	if node:getKey() > key then
		return node.prev
	end
    return node
end

function Tree:getSize()
    return self.size
end

local function insert(node, key, data)
    if key >= node:getKey() then
        if node.right == nil then
            local nodeNew = Node:new(key, data)
            node.right = nodeNew
			node.next.prev = nodeNew
			nodeNew.next = node.next
			node.next = nodeNew
			nodeNew.prev = node
        else
            node.right = insert(node.right, key, data)
        end
    else
        if node.left == nil then
            local nodeNew = Node:new(key, data)
            node.left = nodeNew
			node.prev.next = nodeNew
			nodeNew.prev = node.prev
			node.prev = nodeNew
			nodeNew.next = node
        else
            node.left = insert(node.left, key, data)
        end
    end

    return node
end

function Tree:insert(key, data)
	self.size = self.size+1
    if self._root == nil then
        local node = Node:new(key, data)
		node.prev = node
		node.next = node
        self._root = node
        return
    end

    self._root = insert(self._root, key, data)
end

local function remove(node, key)
    if key > node:getKey() then
        if node.right == nil then
            return node, nil
        else
            node.right = remove(node.right, key)
        end
    elseif key < node:getKey() then
        if node.left == nil then
            return node, nil
        else
            node.left = remove(node.left, key)
        end
    else
        if node.left == nil and node.right == nil then
			node.prev.next = node.next
			node.next.prev = node.prev
            return nil, key
        elseif node.left == nil then
			node.prev.next = node.next
			node.next.prev = node.prev
            node = node.right
        elseif node.right == nil then
			node.prev.next = node.next
			node.next.prev = node.prev
            node = node.left
        else
            node._key = node.right:getKey()
            node._data = node.right:getData()
            node.right, _ = remove(node.right, node:getKey())
        end
    end

    return node, key
end

function Tree:remove(key)
    if self._root == nil then
        return nil
    end

    self._root, popped = remove(self._root, key)
	if popped ~= nil then
		self.size = self.size-1
	end
    return popped
end

return Tree
