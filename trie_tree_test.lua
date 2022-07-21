local trie_tree = require "trie_tree"

local tree = trie_tree:new()
tree:insert("/api/v1/test", "GET")
tree:insert("/api/v2/**", "ANY")
tree:insert("/api/v2/users/{variable}", "GET")
tree:insert("/api/v2/users/{variable}/order/{variable}", "GET")

print(tree:match("/api/v2/users/123/order/5555", "GET"))

tree:remove("/api/v2/users/{variable}/order/{variable}", "GET")

print(tree:match("/api/v2/users/123/order/5555", "POST"))
