--!native
--!strict
local Array = {}
local ArrayInstance = {}
ArrayInstance.__index = ArrayInstance

type PredicateFunction<T> = (value: T, index: number) -> boolean
type SortFunction<T> = (a: T, b: T) -> boolean

local function getInstance<T>(preset: { T }): typeof(ArrayInstance)
	ArrayInstance = { __index = ArrayInstance }
	local cache = preset

	function ArrayInstance:First<T>(): T
		return cache[1] :: any
	end

	function ArrayInstance:Last<T>(): T
		return cache[#cache] :: any
	end

	function ArrayInstance:Push<T>(...: T): nil
		for _, v in { ... } do
			table.insert(cache, v :: any)
		end
		return
	end

	function ArrayInstance:Remove(index: number): nil
		table.remove(cache, index)
		return
	end

	function ArrayInstance:RemoveValue<T>(value: T): nil
		self:Remove(self:IndexOf(value))
		return
	end

	function ArrayInstance:Has<T>(value: T): boolean
		for v in self:Values() do
			if v == value then return true end
		end
		return false
	end

	function ArrayInstance:SortMutable<T>(sorter: SortFunction<T>?): nil
		table.sort(cache, sorter :: any)
		return
	end

	function ArrayInstance:Sort<T>(sorter: SortFunction<T>?): typeof(ArrayInstance)
		local sorted = cache
		table.sort(sorted, sorter :: any)
		return Array.new(sorted)
	end

	function ArrayInstance:Map<T, U>(transform: (value: T, index: number) -> U): typeof(ArrayInstance)
		local result = Array.new()
		for v, i in self:Values() do
			result:Push(transform(v, i) :: any)
		end
		return result
	end

	function ArrayInstance:FindAndRemove<T>(predicate: PredicateFunction<T>): nil
		local value = self:Find(predicate)
		if not value then return end
		self:RemoveValue(value)
		return
	end

	function ArrayInstance:Find<T>(predicate: PredicateFunction<T>): T?
		for v, i in self:Values() do
			if predicate(v, i) then return v end
		end
		return
	end

	function ArrayInstance:Filter<T>(predicate: PredicateFunction<T>): typeof(ArrayInstance)
		local filtered = Array.new()
		for v, i in self:Values() do
			if predicate(v, i) then
				filtered:Push(v)
			end
		end
		return filtered
	end

	function ArrayInstance:Reduce<T, U>(accumulator: (acc: T, v: T) -> T, init: T?): T
		local result = init
		for v, i in self:Values() do
			if i == 1 and not init then
				result = v
			else
				assert(result)
				result = accumulator(result, v)
			end
		end
		assert(result)
		return result
	end

	function ArrayInstance:Every<T>(predicate: PredicateFunction<T>): boolean
		local matches = true
		for v, i in self:Values() do
			matches = matches and predicate(v, i)
		end
		return if #self == 0 then false else matches
	end
	
	function ArrayInstance:Some<T>(predicate: PredicateFunction<T>): boolean
		local matches = false
		for v, i in self:Values() do
			matches = matches or predicate(v, i)
		end
		return if #self == 0 then false else matches
	end

	function ArrayInstance:IndexOf<T>(value: T): number?
		for v, i in self:Values() do
			if v == value then return i end
		end
		return
	end

	function ArrayInstance:ForEach<T>(callback: (value: T, index: number) -> nil): nil
		for v, i in self:Values() do
			callback(v, i)
		end
		return
	end

	function ArrayInstance:Values<T>(): () -> ...T?
		local index = 0
		local count = #cache

		return function()
			index += 1
			if index <= count then
				return cache[index] :: any
			end
			return
		end
	end

	function ArrayInstance:ToTable<T>(): { T }
		return cache :: any
	end

	ArrayInstance._cache = cache
	return ArrayInstance
end

function Array.new<T>(cache: { T }?)
	assert(cache == nil or typeof(cache) == "table", "Preset cache must be a table!")

	local self = getInstance(cache or {})

	return setmetatable({}, {
		__len = function()
			return #self._cache
		end,
		__index = function(t, i)
			return if typeof(i) == "number" then self._cache[i] else self[i]
		end,
		__newindex = function(t, i, v)
			self._cache[i] = v
		end,
		__tostring = function()
			return tostring(self._cache)
		end
	}) :: any
end

return setmetatable(Array, {
	__call = function<T>(_, cache: { T }?)
		return Array.new(cache)
	end
})