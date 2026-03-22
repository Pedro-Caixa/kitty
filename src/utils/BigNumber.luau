--!nonstrict
--[=[
	@class BigNumber
	Arbitrary-scale number helper that stores values as mantissa/exponent pairs.
]=]
--// BigNumber Module
--// Author: fariy's (adapted)
--// Purpose: Allows calculations far beyond Roblox’s numeric limits using mantissa + exponent notation.

local BigNumber = {}
BigNumber.__index = BigNumber

local TRIM_DECIMAL_LEVEL = 1
local LARGE_ENOUGH_TO_SHORTEN = 3
local DECIMAL_FOR_SMALL_NUMBERS = true

local parent = script.Parent
assert(parent, "BigNumber must be parented under utils")
local Abbreviations = require(parent:WaitForChild("Abbreviations"))

--[=[
	Rounds and formats a number to the configured decimal precision.

	@param num number
	@param IWantNumber boolean?
	@return number | string
]=]
function BigNumber.TrimDecimal(num: number, IWantNumber: boolean?): number | string
	local multiplier = 10 ^ TRIM_DECIMAL_LEVEL
	local rounded = math.floor(num * multiplier + 0.5) / multiplier

	if IWantNumber then
		return rounded
	end

	local formatted = string.format("%.1f", rounded)
	if formatted:match("%.0$") then
		formatted = formatted:gsub("%.0$", "")
	end

	return formatted
end

--[=[
	Constructs a BigNumber from mantissa and exponent components.

	@param mantissa number
	@param exponent number
	@return BigNumber
]=]
function BigNumber.new(mantissa: number, exponent: number)
	local self = setmetatable({}, BigNumber)
	self.m = mantissa or 0
	self.e = exponent or 0
	self:normalize()
	return self
end

--[=[
	Normalizes mantissa and exponent to canonical scientific notation.
]=]
function BigNumber:normalize()
	if self.m == 0 then
		self.e = 0
		return
	end

	while math.abs(self.m) >= 10 do
		self.m /= 10
		self.e += 1
	end

	while math.abs(self.m) < 1 and self.m ~= 0 do
		self.m *= 10
		self.e -= 1
	end

	self.e = math.floor(self.e)
end

--[=[
	Returns a copy of this BigNumber.

	@return BigNumber
]=]
function BigNumber:clone()
	return BigNumber.new(self.m, self.e)
end

--[=[
	Returns a floored version of this BigNumber.

	@return BigNumber
]=]
function BigNumber:floor()
	if self.e < 0 then
		return BigNumber.new(0, 0)
	end

	if self.e >= 15 then
		local flooredMantissa = math.floor(self.m)
		return BigNumber.new(flooredMantissa, self.e)
	end

	local fullValue = self.m * (10 ^ self.e)
	local floored = math.floor(fullValue)

	return BigNumber.from(floored)
end

--[=[
	Returns a rounded version of this BigNumber.

	@return BigNumber
]=]
function BigNumber:round()
	if self.e < 0 then
		return BigNumber.new(0, 0)
	end

	if self.e >= 15 then
		local roundedMantissa = math.floor(self.m + 0.5)
		return BigNumber.new(roundedMantissa, self.e)
	end

	local fullValue = self.m * (10 ^ self.e)
	local rounded = math.floor(fullValue + 0.5)

	return BigNumber.from(rounded)
end

--[=[
	Converts the BigNumber into a serializable table.

	@return { m: number, e: number }
]=]
function BigNumber:toTable()
	return { m = self.m, e = self.e }
end

--[=[
	Compares this value to another BigNumber-compatible value.

	@param other any
	@return number
]=]
function BigNumber:compare(other: any)
	if typeof(other) == "number" then
		other = BigNumber.from(other)
	end

	if self.e == other.e then
		if math.abs(self.m - other.m) < 1e-10 then
			return 0
		elseif self.m > other.m then
			return 1
		else
			return -1
		end
	elseif self.e > other.e then
		if self.m > 0 then
			return 1
		else
			return -1
		end
	else
		if other.m > 0 then
			return -1
		else
			return 1
		end
	end
end

--[=[
	Returns whether this value is less than another.

	@param other any
	@return boolean
]=]
function BigNumber:lt(other: any)
	return self:compare(other) < 0
end

--[=[
	Returns whether this value is less than or equal to another.

	@param other any
	@return boolean
]=]
function BigNumber:le(other: any)
	return self:compare(other) <= 0
end

--[=[
	Returns whether this value is greater than another.

	@param other any
	@return boolean
]=]
function BigNumber:gt(other: any)
	return self:compare(other) > 0
end

--[=[
	Returns whether this value is greater than or equal to another.

	@param other any
	@return boolean
]=]
function BigNumber:ge(other: any)
	return self:compare(other) >= 0
end

--[=[
	Adds another BigNumber-compatible value to this one.

	@param other any
	@return BigNumber
]=]
function BigNumber:add(other: any)
	if typeof(other) == "number" then
		other = BigNumber.from(other)
	end

	local a = self:clone()
	local b = other:clone()

	if math.abs(a.e - b.e) > 20 then
		return (a.e > b.e) and a or b
	end

	if a.e > b.e then
		b.m = b.m * 10 ^ (b.e - a.e)
		b.e = a.e
	elseif b.e > a.e then
		a.m = a.m * 10 ^ (a.e - b.e)
		a.e = b.e
	end

	local result = BigNumber.new(a.m + b.m, a.e)
	result:normalize()
	return result
end

--[=[
	Subtracts another BigNumber-compatible value from this one.

	@param other any
	@return BigNumber
]=]
function BigNumber:sub(other: any)
	if typeof(other) == "number" then
		other = BigNumber.from(other)
	end

	local negOther = BigNumber.new(-other.m, other.e)
	return self:add(negOther)
end

--[=[
	Multiplies this value by another BigNumber-compatible value.

	@param other any
	@return BigNumber
]=]
function BigNumber:mul(other: any)
	if typeof(other) == "number" then
		other = BigNumber.from(other)
	end

	local result = BigNumber.new(self.m * other.m, self.e + other.e)
	result:normalize()
	return result
end

--[=[
	Divides this value by another BigNumber-compatible value.

	@param other any
	@return BigNumber
]=]
function BigNumber:div(other: any)
	if typeof(other) == "number" then
		other = BigNumber.from(other)
	end

	if other.m == 0 then
		error("BigNumber: Attempt to divide by zero")
	end

	local result = BigNumber.new(self.m / other.m, self.e - other.e)
	result:normalize()
	return result
end

--[=[
	Raises this value to a numeric power.

	@param power number
	@return BigNumber
]=]
function BigNumber:pow(power: number)
	if power == 0 then
		return BigNumber.new(1, 0)
	end
	if self.m == 0 then
		return BigNumber.new(0, 0)
	end

	local log10Self = math.log10(math.abs(self.m)) + self.e
	local newLog10 = log10Self * power

	local newExponent = math.floor(newLog10)
	local newMantissa = 10 ^ (newLog10 - newExponent)

	if self.m < 0 and math.floor(power) % 2 ~= 0 then
		newMantissa = -newMantissa
	end

	local result = BigNumber.new(newMantissa, newExponent)
	result:normalize()
	return result
end

--[=[
	Converts this value to a Lua number.

	@return number
]=]
function BigNumber:toNumber(): number
	return self.m * (10 ^ self.e)
end

--[=[
	Formats this value as a human-readable string.

	@return string
]=]
function BigNumber:toString()
	if self.m == 0 then
		return "0"
	end

	if self.e < LARGE_ENOUGH_TO_SHORTEN and self.e >= 0 then
		local num = self.m * 10 ^ self.e
		local str = BigNumber.TrimDecimal(num)

		if DECIMAL_FOR_SMALL_NUMBERS then
			local parts = string.split(tostring(str), ".")
			local integerPart = parts[1]
			local decimalPart = parts[2]

			local formatted = string.reverse(integerPart):gsub("(%d%d%d)", "%1'")
			formatted = string.reverse(formatted):gsub("^'", "")

			if decimalPart then
				return formatted .. "." .. decimalPart
			else
				return formatted
			end
		end
		return tostring(str)
	end

	for i = #Abbreviations, 1, -1 do
		local data = Abbreviations[i]
		if self.e >= data.Power then
			local num = self.m * (10 ^ (self.e - data.Power))
			if i == #Abbreviations and self.e - data.Power > 3 then
				break
			end

			local formatted = BigNumber.TrimDecimal(num)
			return formatted .. data.Suffix
		end
	end

	local formatted = BigNumber.TrimDecimal(self.m)
	return formatted .. "e+" .. tostring(self.e)
end

--[=[
	Constructs a BigNumber from table, number, or string input.

	@param value any
	@return BigNumber
]=]
function BigNumber.from(value: any)
	if typeof(value) == "table" and value.m and value.e then
		return BigNumber.new(value.m, value.e)
	elseif typeof(value) == "number" then
		if value == 0 then
			return BigNumber.new(0, 0)
		end

		local e = math.floor(math.log10(math.abs(value)))
		local m = value / (10 ^ e)

		return BigNumber.new(m, e)
	elseif typeof(value) == "string" then
		return BigNumber.parse(value)
	else
		error("Invalid value for BigNumber.from: " .. typeof(value))
	end
end

--[=[
	Parses a string representation into a BigNumber.

	@param str string
	@return BigNumber
]=]
function BigNumber.parse(str: string)
	str = string.gsub(tostring(str), "%s+", "")
	str = string.gsub(str, "'", "")

	local mantissa, exponent = string.match(str, "([%d%.%-]+)e%+(%d+)")
	if mantissa and exponent then
		return BigNumber.new(tonumber(mantissa) :: number, tonumber(exponent) :: number)
	end

	for i = #Abbreviations, 1, -1 do
		local data = Abbreviations[i]
		if string.lower(str):find(string.lower(data.Suffix) .. "$") then
			local numStr = string.sub(str, 1, #str - #data.Suffix)
			local num = tonumber(numStr)
			if num then
				return BigNumber.new(num, data.Power)
			end
		end
	end

	local num = tonumber(str)
	if num then
		return BigNumber.from(num)
	end

	error("BigNumber.parse: Invalid number format -> " .. tostring(str))
end

return BigNumber

