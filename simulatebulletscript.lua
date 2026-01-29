local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")
local ReplicatedStrorage = game:GetService("ReplicatedStorage").TankGunsFolder
local Players = game:GetService("Players")

local Remotes = ReplicatedStrorage.Remotes
local Modules = ReplicatedStrorage.Modules

local VisualizeHitEffect = Remotes.VisualizeHitEffect
local VisualizeBullet = Remotes.VisualizeBullet
local VisualizeMuzzle = Remotes.VisualizeMuzzle
local PlayAudio = Remotes.PlayAudio
local ShatterGlass = Remotes.ShatterGlass
local InflictTarget = Remotes.InflictTarget

local GlassShattering = require(Modules.GlassShattering)
local DamageModule = require(Modules.DamageModule)
local Utilities = require(Modules.Utilities)
local Math = Utilities.Math

_G.TempBannedPlayers = {}

local KickPlayer = true
local PhysicEffect = true

local function CompareTables(arr1, arr2)
	for i, v in pairs(arr1) do
		if typeof(v) == "table" then
			if CompareTables(arr2[i], v) == false then
				return false
			end
		else
			if v ~= arr2[i] then
				return false
			end
		end
	end
	return true
end

local function SecureSettings(Player, Gun, Module)
	if not Player then return end
	local PreNewModule = Gun and Gun:FindFirstChild("Setting")
	if PreNewModule then
		local NewModule = require(PreNewModule)
		if CompareTables(Module, NewModule) == false then
			if KickPlayer then
				Player:Kick("You have been kicked and blocked from rejoining this specific server for exploiting gun stats.")
				table.insert(_G.TempBannedPlayers, Player.Name)
			end
			return
		end
	else
		return
	end
end

function _G.SecureSettings(Player, Gun, Module)
	SecureSettings(Player, Gun, Module)
end

VisualizeHitEffect.OnServerEvent:Connect(function(Player, Type, Replicate, Hit, Position, Normal, Material, ...)
	local Table = { ... }
	for _, plr in next, Players:GetPlayers() do
		if plr ~= Player then
			if Type == "Normal" then
				VisualizeHitEffect:FireClient(plr, Type, Replicate, Hit, Position, Normal, Material, Table[1], Table[2], Table[3], nil)
			elseif Type == "Blood" then
				VisualizeHitEffect:FireClient(plr, Type, Replicate, Hit, Position, Normal, Material, Table[1], Table[2], nil)
			end
		end
	end
end)

VisualizeBullet.OnServerEvent:Connect(function(Player, Module, Tool, Handle, Directions, FirePointObject, HitEffectData, BloodEffectData, BulletHoleData, ExplosiveData, BulletData, WhizData, ClientData)
	SecureSettings(Player, Tool, Module)
	for _, plr in next, Players:GetPlayers() do
		if plr ~= Player then
			VisualizeBullet:FireClient(plr, Module, Tool, Handle, Directions, FirePointObject, HitEffectData, BloodEffectData, BulletHoleData, ExplosiveData, BulletData, WhizData, ClientData)
		end
	end
end)

VisualizeMuzzle.OnServerEvent:Connect(function(Player, Handle, MuzzleFlashEnabled, MuzzleLightData, MuzzleEffect, Replicate)
	for _, plr in next, Players:GetPlayers() do
		if plr ~= Player then
			VisualizeMuzzle:FireClient(plr, Handle, MuzzleFlashEnabled, MuzzleLightData, MuzzleEffect, Replicate)
		end
	end
end)

PlayAudio.OnServerEvent:Connect(function(Player, Audio, LowAmmoAudio, Replicate)
	for _, plr in next, Players:GetPlayers() do
		if plr ~= Player then
			PlayAudio:FireClient(plr, Audio, LowAmmoAudio, Replicate)
		end
	end
end)

ShatterGlass.OnServerEvent:Connect(function(Player, Hit, Pos, Dir)
	if not Hit or Hit.Name ~= "_glass" or Hit.Transparency == 1 then return end

	local Sound = Instance.new("Sound")
	Sound.SoundId = ""
	Sound.TimePosition = 0.1
	Sound.Volume = 1
	Sound.Parent = Hit
	Sound:Play()
	Sound.Ended:Connect(function()
		Sound:Destroy()
	end)

	if PhysicEffect then
		GlassShattering:Shatter(Hit, Pos, Dir + Vector3.new(math.random(-25,25), math.random(-25,25), math.random(-25,25)))
	else
		local Particle = script.Shatter:Clone()
		Particle.Color = ColorSequence.new(Hit.Color)
		Particle.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, Hit.Transparency),
			NumberSequenceKeypoint.new(1, 1)
		})
		Particle.Parent = Hit
		task.delay(0.01, function()
			Particle:Emit(10 * math.abs(Hit.Size.Magnitude))
			Debris:AddItem(Particle, Particle.Lifetime.Max)
		end)
		Hit.CanCollide = false
		Hit.Transparency = 1
	end
end)

local function CalculateDamage(Damage, TravelDistance, ZeroDamageDistance, FullDamageDistance)
	ZeroDamageDistance = ZeroDamageDistance or 10000
	FullDamageDistance = FullDamageDistance or 1000
	local DistRange = ZeroDamageDistance - FullDamageDistance
	local FallOff = math.clamp(1 - (math.max(0, TravelDistance - FullDamageDistance) / math.max(1, DistRange)), 0, 1)
	return math.max(Damage * FallOff, 0)
end

InflictTarget.OnServerInvoke = function(Player, Module, Tool, Tagger, TargetHumanoid, TargetTorso, Damage, Misc, Critical, Hit, GoreData, ExplosiveData)
	SecureSettings(Player, Tool, Module)

	local TrueDamage
	if ExplosiveData and ExplosiveData[1] then
		local DamageMultiplier = 1 - math.clamp(ExplosiveData[3] / ExplosiveData[2], 0, 1)
		TrueDamage = ((Hit and Hit.Name == "Head" and Damage[3]) and Damage[1] * Damage[2] or Damage[1]) * DamageMultiplier
	else
		TrueDamage = Damage[5] and CalculateDamage((Hit and Hit.Name == "Head" and Damage[3]) and Damage[1] * Damage[2] or Damage[1], Damage[4], Damage[6], Damage[7])
			or ((Hit and Hit.Name == "Head" and Damage[3]) and Damage[1] * Damage[2] or Damage[1])
	end

	if not Tagger then return end
	if not TargetHumanoid or TargetHumanoid.Health <= 0 then return end
	if not TargetTorso then return end
	if not DamageModule.CanDamage(TargetHumanoid.Parent, Tagger) then return end

	while TargetHumanoid:FindFirstChild("creator") do
		TargetHumanoid.creator:Destroy()
	end

	local creator = Instance.new("ObjectValue")
	creator.Name = "creator"
	creator.Value = Tagger
	creator.Parent = TargetHumanoid
	Debris:AddItem(creator, 5)

	if Critical[1] and Random.new():NextInteger(0,100) <= Critical[2] then
		TargetHumanoid:TakeDamage(math.abs(TrueDamage * Critical[3]))
	else
		TargetHumanoid:TakeDamage(math.abs(TrueDamage))
	end

	if Misc[1] > 0 then
		local Shover = Tagger.Character:FindFirstChild("HumanoidRootPart") or Tagger.Character.Head
		local Duration = 0.1
		local Speed = Misc[1] / Duration
		local Velocity = (TargetTorso.Position - Shover.Position).Unit * Speed
		local Force = Instance.new("BodyVelocity")
		Force.MaxForce = Vector3.new(1e9,1e9,1e9)
		Force.Velocity = Velocity
		Force.Parent = TargetTorso
		Debris:AddItem(Force, Duration)
	end

	if Misc[2] > 0 and Tagger.Character.Humanoid.Health > 0 then
		Tagger.Character.Humanoid.Health += TrueDamage * Misc[2]
	end

	if Misc[3] and math.random(1,100) <= Misc[5] then
		if not TargetHumanoid.Parent:FindFirstChild(Misc[4]) then
			local Debuff = Tool.GunScript_Server[Misc[4]]:Clone()
			Debuff.creator.Value = creator.Value
			Debuff.Parent = TargetHumanoid.Parent
			Debuff.Disabled = false
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	for _, name in pairs(_G.TempBannedPlayers) do
		if name == player.Name then
			player:Kick("You cannot rejoin a server where you were kicked from.")
			break
		end
	end
end)
