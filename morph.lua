local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Morphs = ServerStorage:WaitForChild("Morphs")

local BODY_PARTS = {
	"Head","UpperTorso","LowerTorso",
	"LeftUpperArm","RightUpperArm","LeftLowerArm","RightLowerArm",
	"LeftHand","RightHand",
	"LeftUpperLeg","RightUpperLeg","LeftLowerLeg","RightLowerLeg",
	"LeftFoot","RightFoot"
}

local function getOrCreateFolder(parent, name)
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end

local function weldModelToPart(charPart, model)
	for _, v in ipairs(model:GetChildren()) do
		if v:IsA("BasePart") then
			local w = Instance.new("Weld")
			w.Part0 = model.Middle
			w.Part1 = v
			local cf = CFrame.new(model.Middle.Position)
			w.C0 = model.Middle.CFrame:Inverse() * cf
			w.C1 = v.CFrame:Inverse() * cf
			w.Parent = model.Middle
			v.Anchored = false
			v.CanCollide = false
		end
	end

	local rootWeld = Instance.new("Weld")
	rootWeld.Part0 = charPart
	rootWeld.Part1 = model.Middle
	rootWeld.C0 = CFrame.new()
	rootWeld.Parent = charPart
end

local function morph(char, partName, source, modelName, folderName)
	local charPart = char:FindFirstChild(partName)
	local sourceModel = source:FindFirstChild(modelName)
	if not (charPart and sourceModel) then return end

	local folder = getOrCreateFolder(char, folderName)
	if folder:FindFirstChild(modelName) then return end

	local clone = sourceModel:Clone()
	clone.Parent = folder
	weldModelToPart(charPart, clone)
end

local function applyMorphParts(char, model, folderName)
	for _, part in ipairs(BODY_PARTS) do
		if model:FindFirstChild(part) then
			morph(char, part, model, part, folderName)
		end
	end
end

local function Body(depth, height, width, char)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	for _, v in ipairs(hum:GetChildren()) do
		if v:IsA("NumberValue") then
			if v.Name == "BodyDepthScale" then
				v.Value = depth
			elseif v.Name == "BodyHeightScale" then
				v.Value = height
			elseif v.Name == "BodyWidthScale" then
				v.Value = width
			end
		end
	end
end

local function Finale(char)
	for _, v in ipairs(char:GetChildren()) do
		if v:IsA("Accessory") or v:IsA("Hat") then
			if v:FindFirstChild("Handle") then
				v.Handle.Transparency = 1
			end
		end
	end
end

local function MorphUser(player, team, class, morphName, folderName)
	local char = player.Character
	if not char then return end

	local root = Morphs[team][class]:WaitForChild(morphName)
	local model = root:Clone()

	applyMorphParts(char, model, folderName)

	if model:FindFirstChild("Tools") then
		for _, tool in ipairs(model.Tools:GetChildren()) do
			if tool:IsA("Tool") and
			   not (player.Backpack:FindFirstChild(tool.Name)
			   or char:FindFirstChild(tool.Name)
			   or player.StarterGear:FindFirstChild(tool.Name)) then

				tool:Clone().Parent = player.Backpack
				tool:Clone().Parent = player.StarterGear
			end
		end
	end

	getOrCreateFolder(char, "MorphName").Value = morphName
	getOrCreateFolder(char, "MorphTeam").Value = team
	getOrCreateFolder(char, "MorphClass").Value = class

	local hum = char:FindFirstChildOfClass("Humanoid")
	local armor = model:FindFirstChild("Armor")
	if hum and armor and armor:IsA("IntValue") then
		hum.MaxHealth += armor.Value
		hum.Health += armor.Value
	end
end

Players.PlayerAdded:Connect(function(player)
	local custom = Instance.new("BoolValue")
	custom.Name = "CustomCharacter"
	custom.Value = false
	custom.Parent = player

	player.CharacterAdded:Connect(function(char)
		if custom.Value then return end

		task.wait(2)
		for _, v in ipairs(char:GetChildren()) do
			if v:IsA("BasePart") then
				v.Material = Enum.Material.SmoothPlastic
			end
		end

		Body(1,1,1,char)
		Finale(char)
	end)
end)

ReplicatedStorage.CMDR_events.MorphEvent.OnServerEvent:Connect(function(_, plr, morphteam, morphdivision, morphname)
	local char = plr.Character
	if not char then return end

	local old = char:FindFirstChild("Morph")
	if old then old:Destroy() end

	for _, v in ipairs(char:GetChildren()) do
		if v:IsA("BasePart") then
			v.Material = Enum.Material.SmoothPlastic
		end
	end

	getOrCreateFolder(char, "Morph")
	task.wait(0.1)

	Body(1,1,1,char)
	MorphUser(plr, morphteam.Name, morphdivision.Name, morphname.Name, "Morph")
end)
