--!strict
--[=[
	@class Abbreviations
	Power/suffix definitions used by BigNumber for compact number formatting.
]=]

--[=[
	@interface Entry
	@within Abbreviations
	.Power number -- Power-of-ten threshold for this suffix.
	.Suffix string -- Short suffix displayed for numbers at this scale.

	One abbreviation entry used by BigNumber formatting.
]=]

--[=[
	@type List {Entry}
	@within Abbreviations
	Ordered list of abbreviation entries from smallest to largest scale.
]=]

return {
	{ Power = 3, Suffix = "K" },
	{ Power = 6, Suffix = "M" },
	{ Power = 9, Suffix = "B" },
	{ Power = 12, Suffix = "T" },
	{ Power = 15, Suffix = "Qa" },
	{ Power = 18, Suffix = "Qi" },
	{ Power = 21, Suffix = "Sx" },
	{ Power = 24, Suffix = "Sp" },
	{ Power = 27, Suffix = "Oc" },
	{ Power = 30, Suffix = "No" },
	{ Power = 33, Suffix = "Dc" },
}

