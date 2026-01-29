local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IsJailedStore = DataStoreService:GetDataStore("IsJailed")
local JailTimeStore = DataStoreService:GetDataStore("JailTime")

local function getAsyncSafe(store, key, default)
	local success, result = pcall(function()
		return store:GetAsync(key)
	end)
	if success and result ~= nil then
		return result
	end
	return default
end

local function setAsyncSafe(store, key, value)
	pcall(function()
		store:SetAsync(key, value)
	end)
end

Players.PlayerAdded:Connect(function(plr)
	local folder = Instance.new("Folder")
	folder.Name = "Jail_Values"
	folder.Parent = plr

	local isJailed = Instance.new("BoolValue")
	isJailed.Name = "IsJailedData"
	isJailed.Value = getAsyncSafe(IsJailedStore, plr.UserId, false)
	isJailed.Parent = folder

	local jailTime = Instance.new("NumberValue")
	jailTime.Name = "JailTimeData"
	jailTime.Value = getAsyncSafe(JailTimeStore, plr.UserId, 0)
	jailTime.Parent = folder

	plr.CharacterAdded:Connect(function()
		task.wait(0.5)

		if isJailed.Value and jailTime.Value > 0 and plr.Team == Teams.Combine then
			local gui = plr:WaitForChild("PlayerGui")
			gui.Returntomenu.Enabled = false
			gui.JailTime.Enabled = true
			gui.JailTime.JailFrame.TimeValue.Value = jailTime.Value
			gui.JailTime.JailFrame.Time.LocalScript.Enabled = true

			plr.Team = Teams.Jailed
			ReplicatedStorage.SendToJail:FireClient(plr, jailTime.Value)
		end
	end)
end)

ReplicatedStorage.ArrestEvent.OnServerEvent:Connect(function(_, detaineeName, jailtime)
	local plr = Players:FindFirstChild(detaineeName)
	if not plr then return end

	local gui = plr:WaitForChild("PlayerGui")
	gui.Returntomenu.Enabled = false
	gui.JailTime.Enabled = true
	gui.JailTime.JailFrame.TimeValue.Value = jailtime
	gui.JailTime.JailFrame.Time.LocalScript.Enabled = true

	plr.Team = Teams.Jailed
	plr:LoadCharacter()

	plr.Jail_Values.IsJailedData.Value = true
	plr.Jail_Values.JailTimeData.Value = jailtime

	setAsyncSafe(IsJailedStore, plr.UserId, true)
	setAsyncSafe(JailTimeStore, plr.UserId, jailtime)

	ReplicatedStorage.SendToJail:FireClient(plr, jailtime)
end)

ReplicatedStorage.ReleaseEvent.OnServerEvent:Connect(function(plr)
	local gui = plr:WaitForChild("PlayerGui")
	gui.Returntomenu.Enabled = true
	gui.JailTime.Enabled = false
	gui.JailTime.JailFrame.TimeValue.Value = 0
	gui.JailTime.JailFrame.Time.LocalScript.Enabled = false

	plr.Team = Teams.Combine
	plr:LoadCharacter()

	plr.Jail_Values.IsJailedData.Value = false
	plr.Jail_Values.JailTimeData.Value = 0

	setAsyncSafe(IsJailedStore, plr.UserId, false)
	setAsyncSafe(JailTimeStore, plr.UserId, 0)
end)
