-- NumberFormatter.lua
-- Converts large numbers to human-readable strings with suffix notation.
-- Examples:
--   999        → "999"
--   1000       → "1.0K"
--   1500000    → "1.5M"
--   2340000000 → "2.3B"

local NumberFormatter = {}

local SUFFIXES = {
	{ 1e33, "Dc" },
	{ 1e30, "No" },
	{ 1e27, "Oc" },
	{ 1e24, "Sp" },
	{ 1e21, "Sx" },
	{ 1e18, "Qi" },
	{ 1e15, "Qa" },
	{ 1e12, "T"  },
	{ 1e9,  "B"  },
	{ 1e6,  "M"  },
	{ 1e3,  "K"  },
}

-- Format a number with one decimal place and a suffix.
-- Numbers below 1000 are returned as integers.
-- Numbers above 999.9Dc (>= 1e36) are clamped and displayed as "999.9Dc+".
function NumberFormatter.format(n)
	n = tonumber(n) or 0
	if n < 0 then
		return "-" .. NumberFormatter.format(-n)
	end

	-- Cap display at the largest defined suffix tier
	if n >= 1e36 then
		return "999.9Dc+"
	end

	for _, entry in ipairs(SUFFIXES) do
		local threshold, suffix = entry[1], entry[2]
		if n >= threshold then
			local scaled = n / threshold
			-- One decimal place, e.g. 1.5K
			return string.format("%.1f%s", scaled, suffix)
		end
	end

	-- Below 1000 — plain integer
	return tostring(math.floor(n))
end

-- Format a rate (per-second) value, e.g. "1.2K/s"
function NumberFormatter.formatRate(n)
	return NumberFormatter.format(n) .. "/s"
end

return NumberFormatter
