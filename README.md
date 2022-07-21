# 基于trie tree路由匹配树


## 匹配模式


匹配优先级:  完整 > 参数 > 模糊

提供模糊匹配:

/api/v1/user/**

提供参数匹配:

/api/v1/user/{variable}/order/{variable}

完整匹配:

/api/v1/user/..





