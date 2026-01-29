local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local referenceDummy = ReplicatedStorage:WaitForChild("Shield")

local blacklist = {
	["Colt Python"] = true,
	["USP"] = true,
}

local toggleTransparencyEvent = Instance.new("RemoteEvent")
toggleTransparencyEvent.Name = "ToggleTransparencyEvent"
toggleTransparencyEvent.Parent = ReplicatedStorage

local transparencyState = true

local function weld(partA, partB, offset)
	if not (partA and partB) then return end
	partA.CFrame = partB.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = partA
	w.Part1 = partB
	w.Parent = partA
end

local function createShieldModel(character)
	local shieldModel = Instance.new("Model")
	shieldModel.Name = "Shield"

	for _, name in ipairs({ "Primary", "Cover", "Barrier" }) do
		local ref = referenceDummy:FindFirstChild(name)
		if ref and ref:FindFirstChild("WeldPart") then
			local clone = ref:Clone()
			local weldTo = character:FindFirstChild(clone.WeldPart.Value.Name)
			if weldTo then
				weld(
					clone,
					weldTo,
					clone.WeldPart.Value.CFrame:Inverse() * clone.CFrame
				)
				clone.Parent = shieldModel
			else
				clone:Destroy()
			end
		end
	end

	shieldModel.Parent = Workspace
	return shieldModel
end

local function updateShieldTransparency(shieldModel)
	transparencyState = not transparencyState

	for _, part in ipairs(shieldModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CanQuery = false

			if transparencyState then
				part.Transparency = 1
			else
				if part.Name == "Primary" then
					part.Transparency = 1
				elseif part.Name == "Barrier" then
					part.Transparency = 0.5
				elseif part.Name == "Cover" then
					part.Transparency = 0
					part.CanQuery = true
				end
			end
		end
	end
end

toggleTransparencyEvent.OnServerEvent:Connect(function(player)
	if not player.Character then return end
	if not player:IsInGroup(16910813) then return end
	if not player.Team or player.Team.Name ~= "Combine" then return end

	local tool = player.Character:FindFirstChildWhichIsA("Tool")
	if not tool then return end

	local shield = tool:FindFirstChild("Shield")
	if shield then
		updateShieldTransparency(shield)
	end
end)

local function equipShieldToTool(character, shieldModel, tool)
	if blacklist[tool.Name] then return end
	shieldModel.Parent = tool
end

local function onCharacterAdded(character)
	local shieldModel = createShieldModel(character)

	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			equipShieldToTool(character, shieldModel, child)
		end
	end)

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then
			equipShieldToTool(character, shieldModel, child)
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(onCharacterAdded)
end)

for _, player in ipairs(Players:GetPlayers()) do
	if player.Character then
		onCharacterAdded(player.Character)
	end
	player.CharacterAdded:Connect(onCharacterAdded)
end
