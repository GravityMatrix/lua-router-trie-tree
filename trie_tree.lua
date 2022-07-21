---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by WangChen.
--- DateTime: 2022/7/18 10:49
---

local ipairs                = ipairs
local pairs                 = pairs
local insert                = table.insert
local concat                = table.concat
local gmatch                = string.gmatch
local Separator             = "/"
local ParameterPlaceholder  = "{variable}"
local FuzzyPlaceholder      = "**"

local _M = {}

local Node = {}

function Node:get_next_nodes_capacity()
    -- 字典取值需要这样,  数组可以用# ...
    local size = 0
    for _,_ in pairs(self.next_nodes) do size = size + 1 end
    return size
end

function Node:has_next_node()
    return self:get_next_nodes_capacity() > 0
end

function Node:has_not_next_node()
    return not self:has_next_node()
end

function Node:new()
    return setmetatable({
        fragment = nil,
        is_wildcard = false,
        is_end = false,
        next_nodes = {}
    }, { __index = Node })
end

local function make_node(fragment)
    local node = Node:new()
    if fragment == nil then
        return node
    end
    node.fragment = fragment
    if fragment == FuzzyPlaceholder then
        node.is_wildcard = true
        node.fragment = FuzzyPlaceholder
    elseif fragment == ParameterPlaceholder then
        node.is_wildcard = true
        node.fragment = ParameterPlaceholder
    end
    return node
end

local function split(input, separator)
    local result = {}
    for item in gmatch(input, "([^" .. separator .. "]+)") do
        insert(result, item)
    end
    return result
end

local function make_match_path(match_path_array)
    if #match_path_array == 0 then
        return nil
    end
    -- 跳过第一个请求方法标记位。
    return Separator .. concat(match_path_array, Separator, 2)
end


local function make_complete_path(path, method)
    return Separator .. method .. path
end

function _M:_insert(path)
    local this_node = self.root
    local fragment_array = split(path, Separator)
    for _, fragment in ipairs(fragment_array) do
        local next_node = this_node.next_nodes[fragment]
        if next_node == nil then
            next_node = make_node(fragment)
            this_node.next_nodes[next_node.fragment] = next_node
        end
        -- 遍历的节点都当作不是最后一个节点, 动态插入可动态修改最后一级。
        this_node = next_node
        next_node.is_end = false
    end
    this_node.is_end = true
end


function _M:insert(path, method)
    self:_insert(make_complete_path(path, method))
end

function _M:remove(path, method)
    return self:_remove(split(make_complete_path(path, method), Separator), 1, self.root)
end

function _M:_remove(path_array, depth, this_node)
    -- lua 索引都是从1开始。
    if #path_array == (depth - 1) then
        return this_node:has_not_next_node()
    end
    local fragment = path_array[depth]
    local next_node = this_node.next_nodes[fragment]
    if next_node and self:_remove(path_array, depth + 1, next_node) then
        this_node.next_nodes[fragment] = nil
    end
    -- 没有下一个节点, 直接递归删除。
    return this_node:has_not_next_node()
end

function _M:_match(path, node_path)
    local match_path_array = {}
    local match_fuzzy_array = {}
    local this_node = self.root
    local fragment_array = split(node_path, Separator)
    for _, fragment in ipairs(fragment_array) do
        local exist_fuzzy_next_node = this_node.next_nodes[FuzzyPlaceholder]
        if exist_fuzzy_next_node then
            -- 每遍历一个节点, 记录当前节点的模糊匹配。
            if #match_path_array > 0 then
                local match_fuzzy_path = make_match_path(match_path_array) .. Separator .. exist_fuzzy_next_node.fragment
                insert(match_fuzzy_array, match_fuzzy_path)
            end
        end
        local exist_next_node = this_node.next_nodes[fragment]
        if exist_next_node then
            this_node = exist_next_node
            insert(match_path_array, exist_next_node.fragment)
        else
            local exist_parameter_next_node = this_node.next_nodes[ParameterPlaceholder]
            if exist_parameter_next_node then
                insert(match_path_array, exist_parameter_next_node.fragment)
                this_node = exist_parameter_next_node
            end
        end
    end
    local method = match_path_array[1]
    -- 存在完整匹配
    if #match_path_array == #fragment_array then
        return path, make_match_path(match_path_array), method, true
        -- 是否有模糊匹配
    elseif #match_fuzzy_array > 0 then
        return path, match_fuzzy_array[#match_fuzzy_array], method, true
    end
    return path, nil, nil, false
end


function _M:match(path, method)
    return self:_match(path, make_complete_path(path, method))
end

function _M:new()
    return setmetatable({ root = make_node(nil) }, { __index = _M })
end

return _M
