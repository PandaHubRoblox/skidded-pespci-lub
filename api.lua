local API = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
 local Weapons = ReplicatedStorage.Weapons
API.GunMods = {}
API.OriginalValues = {
	FireRate = {},
	Spread = {},
	ReloadTime = {},
	EquipTime = {},
	Ammo = {},
	StoredAmmo = {}
}

API.Util = {}
API.mainEnabled = false  -- Variable to keep track of whether mods are enabled

--// Utility Functions
function API.Util.setChildValue(weapon, childName, value)
	local child = weapon:FindFirstChild(childName)
	if child then
		child.Value = value
	end
end

function API.Util.saveOriginalValue(weapon, childName, originalValuesTable)
	local child = weapon:FindFirstChild(childName)
	if child then
		if not originalValuesTable[weapon.Name] then
			originalValuesTable[weapon.Name] = child.Value
		end
	end
end

function API.Util.setSpreadValues(spread, value)
	for _, subSpread in ipairs(spread:GetChildren()) do
		subSpread.Value = value
	end
end

function API.Util.saveSpreadValues(spread)
	local values = {}
	for _, subSpread in ipairs(spread:GetChildren()) do
		values[subSpread.Name] = subSpread.Value
	end
	return values
end

function API.Util.restoreSpreadValues(spread, values)
	for _, subSpread in ipairs(spread:GetChildren()) do
		subSpread.Value = values[subSpread.Name]
	end
end

--// GunMod Functions
function API.GunMods.noFireRate(enable)
	if not API.mainEnabled then return end
	for _, weapon in ipairs(Weapons:GetChildren()) do
		if enable then
			API.Util.saveOriginalValue(weapon, "FireRate", API.OriginalValues.FireRate)
			API.Util.setChildValue(weapon, "FireRate", 0)
		else
			API.Util.setChildValue(weapon, "FireRate", API.OriginalValues.FireRate[weapon.Name])
		end
	end
end

function API.GunMods.noSpread(enable)
	if not API.mainEnabled then return end
	for _, weapon in ipairs(Weapons:GetChildren()) do
		local spread = weapon:FindFirstChild("Spread")
		if spread then
			if enable then
				if not API.OriginalValues.Spread[weapon.Name] then
					API.OriginalValues.Spread[weapon.Name] = {
						mainValue = spread.Value,
						subValues = API.Util.saveSpreadValues(spread)
					}
				end
				spread.Value = 0
				API.Util.setSpreadValues(spread, 0)
			else
				local originalSpread = API.OriginalValues.Spread[weapon.Name]
				if originalSpread then
					spread.Value = originalSpread.mainValue
					API.Util.restoreSpreadValues(spread, originalSpread.subValues)
				end
			end
		end
	end
end

function API.GunMods.instantReloadTime(enable)
	if not API.mainEnabled then return end
	for _, weapon in ipairs(Weapons:GetChildren()) do
		if enable then
			API.Util.saveOriginalValue(weapon, "ReloadTime", API.OriginalValues.ReloadTime)
			API.Util.setChildValue(weapon, "ReloadTime", 0.05)
		else
			API.Util.setChildValue(weapon, "ReloadTime", API.OriginalValues.ReloadTime[weapon.Name])
		end
	end
end

function API.GunMods.instantEquipTime(enable)
	if not API.mainEnabled then return end
	for _, weapon in ipairs(Weapons:GetChildren()) do
		if enable then
			API.Util.saveOriginalValue(weapon, "EquipTime", API.OriginalValues.EquipTime)
			API.Util.setChildValue(weapon, "EquipTime", 0.05)
		else
			API.Util.setChildValue(weapon, "EquipTime", API.OriginalValues.EquipTime[weapon.Name])
		end
	end
end

function API.GunMods.infiniteAmmo(enable)
	if not API.mainEnabled then return end
	for _, weapon in ipairs(Weapons:GetChildren()) do
		if enable then
			API.Util.saveOriginalValue(weapon, "Ammo", API.OriginalValues.Ammo)
			API.Util.saveOriginalValue(weapon, "StoredAmmo", API.OriginalValues.StoredAmmo)
			API.Util.setChildValue(weapon, "Ammo", 9999999999)
			API.Util.setChildValue(weapon, "StoredAmmo", 9999999999)
		else
			API.Util.setChildValue(weapon, "Ammo", API.OriginalValues.Ammo[weapon.Name])
			API.Util.setChildValue(weapon, "StoredAmmo", API.OriginalValues.StoredAmmo[weapon.Name])
		end
	end
end


function API.toggleMods(enable)
	API.mainEnabled = enable
	API.GunMods.noFireRate(Weapons, enable)
	API.GunMods.noSpread(Weapons, enable)
	API.GunMods.instantReloadTime(Weapons, enable)
	API.GunMods.instantEquipTime(Weapons, enable)
	API.GunMods.infiniteAmmo(Weapons, enable)
end

return API