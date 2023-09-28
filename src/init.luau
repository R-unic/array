--!native
--!strict
local HttpService = game:GetService("HttpService")
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

local function getInstance<T>(elementType: CheckableType, preset: { T }): Array
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
		for _, v in pairs { ... } do
			self:_AssertValidType(v)
			table.insert(cache, v :: any)
		end
		return
	end

	function ArrayInstance:Unshift<T>(...: T): nil
		for _, v in pairs { ... } do
			self:_AssertValidType(v)
			self:Insert(v, 1)
		end
		return
	end

	function ArrayInstance:Combine<T>(...: Array): Array
		local result = Array.new(elementType, cache)
		for _, arr in pairs { ... } do
			result:Push(arr:Unpack())
		end
		return result
	end

	function ArrayInstance:Unpack(): ...any
		return table.unpack(cache) :: any
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
		self:Remove(self:IndexOf(value) :: number)
		return
	end

	function ArrayInstance:Has<T>(value: T): boolean
		for v in self:Values() do
			if v == value then return true end
		end
		return false
	end

	local function sort<T>(arr: { T }, comparator)
    local function partition<T>(arr: { T }, low: number, high: number)
			local pivot = arr[high]
			local i = low - 1

			for j = low, high - 1 do
				if comparator(arr[j], pivot) then
					i += 1
					arr[i], arr[j] = arr[j], arr[i]
				end
			end

			comparator = comparator or function(a, b)
				return (a :: any) < (b :: any)
			end
			
			arr[i + 1], arr[high] = arr[high], arr[i + 1]
			return i + 1
    end

    local function quicksort<T>(arr: { T }, low: number, high: number)
        if low < high then
					local pivotIndex = partition(arr, low, high)
					quicksort(arr, low, pivotIndex - 1)
					quicksort(arr, pivotIndex + 1, high)
        end
    end

    quicksort(arr, 1, #arr)
end

	function ArrayInstance:SortMutable<T>(sorter: SortFunction<T>?): nil
		sort(cache, sorter :: any)
		return
	end

	function ArrayInstance:Sort<T>(sorter: SortFunction<T>?): Array
		local sorted = cache
		sort(sorted, sorter :: any)
		return Array.new(elementType, sorted)
	end

	function ArrayInstance:Map<T, U>(transform: (value: T, index: number) -> U): Array
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

	function ArrayInstance:Filter<T>(predicate: PredicateFunction<T>): Array
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
		local hasInitialValue = init ~= nil
		for v, i in self:Values() do
			if i == 1 and not hasInitialValue then
				result = v
			else
				result = accumulator(result :: T, v)
			end
		end
		return result :: any
	end

	function ArrayInstance:Every<T>(predicate: PredicateFunction<T>): boolean
		if #cache == 0 then return false end

		local matches = true
		for v, i in self:Values() do
			matches = matches and predicate(v, i)
		end
		return matches
	end
	
	function ArrayInstance:Some<T>(predicate: PredicateFunction<T>): boolean
		if #cache == 0 then return false end

		local matches = false
		for v, i in self:Values() do
			matches = matches or predicate(v, i)
		end
		return matches
	end

	function ArrayInstance:Truncate(count: number): Array
		local truncated = Array.new(elementType)
		for v, i in self:Values() do
			if i >= count then break end
			truncated:Push(v)
		end
		return truncated
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
			if not index then return end
			return cache[index :: number] :: any, index
		end
	end

	function ArrayInstance:Indexes(): () -> number?
		local index = 0
		local length = #cache
		return function()
			index += 1
			if index > length then return end
			return index
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
	return ArrayInstance :: any
end

function Array.new<T>(elementType: CheckableType?, cache: { T }?): typeof(ArrayInstance)
	assert(cache == nil or typeof(cache) == "table", "Preset cache must be a table!")

	local self = getInstance(elementType or "any", cache or {})
	for v in self:Values() do
		self:_AssertValidType(v)
	end

	local function stringify(arr: typeof(self))
		return arr:Map(function(element)
			if typeof(element) == "table" and element.__type == "Array" then
				return stringify(element)
			else
				return tostring(element)
			end
		end):ToString()
	end

	return setmetatable({}, {
		__metatable = "Not your business ;)",
		__index = function(_, i)
			return if typeof(i) == "number" then self._cache[i] else self[i]
		end,
		__newindex = function(_, i, v): nil
			task.spawn(function()
				self:_AssertValidType(v)
				self._cache[i] = v
			end)
			return
		end,
		__len = function()
			return #self._cache
		end,
		__tostring = function()
			return stringify(self)
		end
	}) :: any
end

type Array = typeof(Array.new())
return setmetatable(Array, {
	__call = function<T>(_, ...)
		return Array.new(...)
	end
})