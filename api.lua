local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weapons = ReplicatedStorage.Weapons
local localPlayer = game.Players.LocalPlayer
local API = {}

API.GunMods = {}
API.OriginalValues = {
	FireRate = {},
	Spread = {},
	ReloadTime = {},
	EquipTime = {},
	Ammo = {},
	StoredAmmo = {},
	Recoil = {}
}

API.Util = {}
API.mainEnabled = false
API.ModStatus = {
	noFireRate = false,
	noSpread = false,
	instantReloadTime = false,
	instantEquipTime = false,
	infiniteAmmo = false,
	removeRecoil = false
}

--// Utility Functions
function API.Util.setChildValue(weapon, childName, value)
	local child = weapon:FindFirstChild(childName)
	if child then
		child.Value = value
	end
end

function API.Util.saveOriginalValue(weapon, childName, originalValuesTable)
	local child = weapon:FindFirstChild(childName)
	if child and not originalValuesTable[weapon.Name] then
		originalValuesTable[weapon.Name] = child.Value
	end
end

function API.Util.setSpreadValues(spread, value)
	for _, subSpread in ipairs(spread:GetChildren()) do
		subSpread.Value = value
	end
end

function API.Util.saveSpreadValues(spread, originalValuesTable, weaponName)
	if not originalValuesTable[weaponName] then
		local values = {}
		for _, subSpread in ipairs(spread:GetChildren()) do
			values[subSpread.Name] = subSpread.Value
		end
		originalValuesTable[weaponName] = values
	end
end

function API.Util.restoreSpreadValues(spread, values)
	for _, subSpread in ipairs(spread:GetChildren()) do
		subSpread.Value = values[subSpread.Name]
	end
end

--// GunMod Functions
function API.GunMods.noFireRate(enable)
	API.ModStatus.noFireRate = enable
	for _, weapon in ipairs(Weapons:GetChildren()) do
		if enable then
			if not API.mainEnabled then return end
			API.Util.setChildValue(weapon, "FireRate", 0)
		else
			API.Util.setChildValue(weapon, "FireRate", API.OriginalValues.FireRate[weapon.Name])
		end
	end
end

function API.GunMods.noSpread(enable)
	API.ModStatus.noSpread = enable

	for _, weapon in ipairs(Weapons:GetChildren()) do
		local spread = weapon:FindFirstChild("Spread")
		if spread then
			if enable then
				if not API.mainEnabled then return end
				spread.Value = 0
				API.Util.setSpreadValues(spread, 0)
			else
				local originalSpread = API.OriginalValues.Spread[weapon.Name]
				if originalSpread then
					spread.Value = originalSpread.mainValue
					API.Util.restoreSpreadValues(spread, originalSpread)
				end
			end
		end
	end
end

function API.GunMods.instantReloadTime(enable)
	API.ModStatus.instantReloadTime = enable
	
	for _, weapon in ipairs(Weapons:GetChildren()) do
		if enable then
			if not API.mainEnabled then return end
			API.Util.setChildValue(weapon, "ReloadTime", 0.05)
		else
			API.Util.setChildValue(weapon, "ReloadTime", API.OriginalValues.ReloadTime[weapon.Name])
		end
	end
end

function API.GunMods.instantEquipTime(enable)
	API.ModStatus.instantEquipTime = enable
	for _, weapon in ipairs(Weapons:GetChildren()) do
		if enable then
			if not API.mainEnabled then return end
			API.Util.setChildValue(weapon, "EquipTime", 0.05)
		else
			API.Util.setChildValue(weapon, "EquipTime", API.OriginalValues.EquipTime[weapon.Name])
		end
	end
end

function API.GunMods.infiniteAmmo(enable)
	API.ModStatus.infiniteAmmo = enable
	
	for _, weapon in ipairs(Weapons:GetChildren()) do
		if enable then
			if not API.mainEnabled then return end
			print("enabling infinite ammo")
			API.Util.setChildValue(weapon, "Ammo", 9999999999)
			API.Util.setChildValue(weapon, "StoredAmmo", 9999999999)
		else
			print("disabling infinite ammo")
			API.Util.setChildValue(weapon, "Ammo", API.OriginalValues.Ammo[weapon.Name])
			API.Util.setChildValue(weapon, "StoredAmmo", API.OriginalValues.StoredAmmo[weapon.Name])
		end
	end
end

function API.GunMods.removeRecoil(enable)
	API.ModStatus.removeRecoil = enable
	for _, weapon in ipairs(Weapons:GetChildren()) do
		local spread = weapon:FindFirstChild("Spread")
		if spread then
			local recoil = spread:FindFirstChild("Recoil")
			if recoil then
				if enable then
					if not API.mainEnabled then return end
					API.Util.saveOriginalValue(spread, "Recoil", API.OriginalValues.Recoil)
					recoil.Value = 0
				else
					API.Util.setChildValue(spread, "Recoil", API.OriginalValues.Recoil[weapon.Name])
				end
			end
		end
	end
end

--// Function to Save Original Values of All Mods
function API.GunMods.SaveOriginalValues()
	for _, weapon in ipairs(Weapons:GetChildren()) do
		API.Util.saveOriginalValue(weapon, "FireRate", API.OriginalValues.FireRate)

		local spread = weapon:FindFirstChild("Spread")
		if spread then
			API.Util.saveSpreadValues(spread, API.OriginalValues.Spread, weapon.Name)
			local recoil = spread:FindFirstChild("Recoil")
			if recoil then
				API.Util.saveOriginalValue(spread, "Recoil", API.OriginalValues.Recoil)
			end
		end

		API.Util.saveOriginalValue(weapon, "ReloadTime", API.OriginalValues.ReloadTime)
		API.Util.saveOriginalValue(weapon, "EquipTime", API.OriginalValues.EquipTime)
		API.Util.saveOriginalValue(weapon, "Ammo", API.OriginalValues.Ammo)
		API.Util.saveOriginalValue(weapon, "StoredAmmo", API.OriginalValues.StoredAmmo)
	end
end

--// Main Function to Enable/Disable All Mods
function API.toggleMods(enable)
	API.mainEnabled = enable

	if enable then
		print("enabling mods")
		if API.ModStatus.noFireRate then
			API.GunMods.noFireRate(true)
		end
		if API.ModStatus.noSpread then
			API.GunMods.noSpread(true)
		end
		if API.ModStatus.instantReloadTime then
			API.GunMods.instantReloadTime(true)
		end
		if API.ModStatus.instantEquipTime then
			API.GunMods.instantEquipTime(true)
		end
		if API.ModStatus.infiniteAmmo then
			API.GunMods.infiniteAmmo(true)
		end
		if API.ModStatus.removeRecoil then
			API.GunMods.removeRecoil(true)
		end
	else
		print("disabling mods")
		API.GunMods.noFireRate(false)
		API.GunMods.noSpread(false)
		API.GunMods.instantReloadTime(false)
		API.GunMods.instantEquipTime(false)
		API.GunMods.infiniteAmmo(false)
		API.GunMods.removeRecoil(false)
	end
end

return API
