local LazyStaticState = {
    Uninitialized = 0,
    Initialized = 1
}

---@class LazyStatic<T>
---@generic T: any
---@field public value fun(): T
---@field private init_fn fun(): T
---@field private state number
---@field private inner_value T
local LazyStatic = {}
LazyStatic.__index = LazyStatic

---@generic T
---@param init_fn fun(): T
---@return LazyStatic<T>
function LazyStatic.new(init_fn)
    local obj = setmetatable({}, LazyStatic)
    obj.init_fn = init_fn
    obj.state = LazyStaticState.Uninitialized
    obj.inner_value = nil
    return obj
end

--- Returns the value of the lazy-initialized static variable.
---@generic T: any
---@return T
function LazyStatic:value()
    if self.state == LazyStaticState.Uninitialized then
        local init_fn = self.init_fn
        self.inner_value = init_fn()
        self.state = LazyStaticState.Initialized
    end

    return self.inner_value
end

return {
    LazyStatic = LazyStatic
}
