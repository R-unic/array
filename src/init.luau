local HttpService = game:GetService("HttpService")
--!native
--!strict
local Array = {}
local ArrayInstance = {}
ArrayInstance.__index = ArrayInstance

type PredicateFunction<T> = (value: T, index: number) -> boolean
type SortFunction<T> = (a: T, b: T) -> boolean
type CheckableType =
	"string"
	| "boolean"
	| "number"
	| "function"
	| "table"
	| "Vector2"
	| "Vector3"
	| "CFrame"
	| "Instance"
	| "Rect"
	| "Font"
	| "BrickColor"
	| "Color"
	| "UDim"
	| "UDim2"
	| "NumberSequence"
	| "ColorSequence"
	| "NumberRange"
	| "any"
	| "unknown"

local function getInstance<T>(elementType: CheckableType, preset: { T }): typeof(ArrayInstance)
	ArrayInstance = { __index = ArrayInstance }
	local cache = preset

	function ArrayInstance:_AssertValidType<T>(value: T): nil
		if elementType == "any" or elementType == "unknown" then return end
		local valueType = typeof(value) :: CheckableType
		assert(elementType == valueType, `Expected array element to be of type "{elementType}", but got "{valueType}"`)
		return
	end

	function ArrayInstance:First<T>(): T?
		return cache[1] :: any
	end

	function ArrayInstance:Last<T>(): T?
		return cache[#cache] :: any
	end

	function ArrayInstance:Push<T>(...: T): nil
		for _, v in { ... } do
			self:_AssertValidType(v)
			table.insert(cache, v :: any)
		end
		return
	end

	function ArrayInstance:Unshift<T>(...: T): nil
		for _, v in { ... } do
			self:_AssertValidType(v)
			self:Insert(v, 1)
		end
		return
	end

	function ArrayInstance:Insert<T>(value: T, index: number): nil
		self:_AssertValidType(value)
		table.insert(cache, index, value :: any)
		return
	end

	function ArrayInstance:Pop<T>(): T?
		return table.remove(cache, #cache) :: any
	end

	function ArrayInstance:Shift<T>(): T?
		return table.remove(cache, 1) :: any
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
		return Array.new(elementType, sorted)
	end

	function ArrayInstance:Map<T, U>(transform: (value: T, index: number) -> U): typeof(ArrayInstance)
		local result = Array.new()
		for v: T, i: number in self:Values() do
			result:Push(transform(v, i) :: U)
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
		return result :: any
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

	function ArrayInstance:Values<T>(): () -> (T?, number?)
		local nextIndex: () -> number? = self:Indexes()
		return function()
			local index = nextIndex()
			if index ~= nil then
				return cache[index] :: any, index
			end
			return
		end
	end

	function ArrayInstance:Indexes(): () -> number?
		local index = 0
		return function()
			index += 1
			if index <= #cache then
				return index
			end
			return
		end
	end

	function ArrayInstance:ToTable<T>(): { T }
		return cache :: any
	end

	function ArrayInstance:ToString(): string
		return HttpService:JSONEncode(cache)
	end

	ArrayInstance._cache = cache
	ArrayInstance.__type = `Array`
	return ArrayInstance
end

function Array.new<T>(elementType: CheckableType?, cache: { T }?)
	assert(cache == nil or typeof(cache) == "table", "Preset cache must be a table!")

	local self = getInstance(elementType or "any", cache or {})
	for v in self:Values() do
		self:_AssertValidType(v)
	end

	return setmetatable({}, {
		__metatable = "Not your business ;)",
		__index = function(_, i)
			return if typeof(i) == "number" then self._cache[i] else self[i]
		end,
		__newindex = function(_, i, v)
			self:_AssertValidType(v)
			self._cache[i] = v
		end,
		__len = function()
			return #self._cache
		end,
		__eq = function(_, other)
			return self._cache == other
		end,
		__tostring = function()
			local function stringify(arr: typeof(self))
				return arr:Map(function(element)
					if typeof(element) == "table" and element.__type == "Array" then
						return stringify(element)
					else
						return tostring(element)
					end
				end):ToString()
			end
			return stringify(self)
		end
	}) :: any
end

return setmetatable(Array, {
	__call = function<T>(_, ...)
		return Array.new(...)
	end
})