local ToolGiver = {}

local Groups = {
	Main = 16910813,
	SPEAR = 32414446,
	JURY = 33698844,
	OTA = 32414419,
	Rebel = 33749298,
	RAZOR = 33698840
}


local Teams = game:GetService("Teams")
local Combine = Teams.Combine
local Rebel = Teams.CWU
local Civil = Teams.Civilian

local ToolStore = game:GetService("ReplicatedStorage"):WaitForChild("CmdrTools")
local Tools = {}
for _, toolName in ipairs({
	"USP", "AR3", "SMG", "AR2", "SPAS-12", "OSR", "Colt Python", "Gold Python",
	"Detain", "orbattachmentAR2", "AR4", "Apply Card", "Scanner", "EDetain", "Viscerator_tool"
	}) do
	local tool = ToolStore:WaitForChild(toolName)
	Tools[tool.Name:gsub("[%s%-]", "")] = tool
end

local function giveTool(player, tool)
	if tool and tool:IsA("Tool") then
		tool:Clone().Parent = player.Backpack
	end
end

local function giveTools(player, toolList)
	for _, tool in ipairs(toolList) do
		giveTool(player, tool)
	end
end

local MainLoadouts = {
	[12] = {"AR2", "SPAS12", "ColtPython", "Detain"},
	[13] = {"AR2", "SPAS12", "ColtPython", "OSR", "AR3", "Detain"},
	[23] = {"AR2", "SPAS12", "ColtPython", "Detain"},
	[252] = {"AR2", "SPAS12", "ColtPython", "OSR", "AR3", "Detain"},
	[253] = {"SPAS12", "GoldPython", "OSR", "AR4", "Detain", "Scanner", "EDetain"},
	[254] = {"AR2", "SPAS12", "ColtPython", "OSR", "AR3", "Detain", "EDetain"},
	[255] = {"AR2", "SPAS12", "ColtPython", "OSR", "AR3", "Detain"}
}

local OTALoadouts = {
	[1] = {"SMG"},
	[4] = {"ColtPython", "SPAS12"},
	[7] = {"ColtPython", "OSR"},
	[8] = {"AR2", "SMG"},
	[10] = {"orbattachmentAR2", "AR2"},
	[13] = {"orbattachmentAR2", "AR2", "OSR"},
	[14] = {"orbattachmentAR2", "AR2", "OSR"},
	[15] = {"orbattachmentAR2", "AR2", "OSR"}
}


local function handleCombine(player, ranks)
	local rMain, rOTA, rRAZOR, rJURY, rSPEAR = ranks.Main, ranks.OTA, ranks.RAZOR, ranks.JURY, ranks.SPEAR

	if rOTA <= 0 and rMain >= 1 then
		if rMain >= 2 then giveTool(player, Tools.USP) end
		if rMain >= 4 then giveTool(player, Tools.SMG) end
		if rMain >= 12 then giveTool(player, Tools.ColtPython) end
	end

	if table.find({12, 15, 21, 22}, rMain) then
		giveTool(player, Tools.Detain)
		if rMain ~= 15 then giveTool(player, Tools.SPAS12) end
	end

	if rRAZOR >= 250 and rRAZOR <= 253 then giveTool(player, Tools.Detain) end
	if rJURY >= 1 and rJURY <= 253 then giveTools(player, {Tools.Detain, Tools.Scanner}) end
	if rSPEAR >= 1 then giveTool(player, Tools.SPAS12) end
	if rSPEAR >= 250 and rSPEAR <= 253 then
		giveTools(player, {Tools.SPAS12, Tools.Detain, Tools.Viscerator_tool})
	end

	if OTALoadouts[rOTA] then
		local loadout = {}
		for _, name in ipairs(OTALoadouts[rOTA]) do
			table.insert(loadout, Tools[name])
		end
		giveTools(player, loadout)
	end

	if MainLoadouts[rMain] then
		local loadout = {}
		for _, name in ipairs(MainLoadouts[rMain]) do
			table.insert(loadout, Tools[name])
		end
		giveTools(player, loadout)
	end
end

local function handleRebel(player)
	giveTools(player, {Tools.USP, Tools.SMG})
end

local function handleCivil(player)
	-- optional civilian tools
end


function ToolGiver.HandlePlayer(player)
	task.wait(1.5)

	local ranks = {}
	for name, id in pairs(Groups) do
		ranks[name] = player:GetRankInGroup(id)
	end

	local team = player.Team
	if team == Combine then
		handleCombine(player, ranks)
	elseif team == Rebel then
		handleRebel(player)
	elseif team == Civil then
		handleCivil(player)
	end
end

return ToolGiver
