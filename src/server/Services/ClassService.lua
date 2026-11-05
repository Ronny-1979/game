--!strict
--[[
	ClassService: Klasse wählen (am Anfang gratis), Klasse wechseln (am Uhrturm-Platz beim Skill-Lehrer, kostet Energie),
	Skill-Baum freischalten und zurücksetzen.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Settings = require(Config:WaitForChild("Settings")) :: any
local Classes = require(Config:WaitForChild("Classes")) :: any
local Tags = require(Shared:WaitForChild("Tags"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Util = require(Shared:WaitForChild("Util"))
local StatCalc = require(Shared:WaitForChild("StatCalc"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local QuestEvents = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("QuestEvents"))
local Validate = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("Validate"))

local ClassService = {}

local function nearTeacher(player: Player): boolean
	for _, p in CollectionService:GetTagged(Tags.MenuPrompt) do
		if p:GetAttribute("Menu") == "Skills" then
			local part = if p:IsA("BasePart") then p else p:FindFirstAncestorWhichIsA("BasePart")
			if part and Validate.Near(player, part.Position, 30) then
				return true
			end
		end
	end
	return false
end

-- Ausgegebene Skill-Punkte zurückgeben
local function refundSkills(d: any)
	local spent = 0
	for _, node in StatCalc.GetTreeNodes(d.Class) do
		if d.Skills[node.Id] then
			spent += node.Kosten
		end
	end
	d.SkillPoints += spent
	d.Skills = {}
end

function ClassService.Init() end

function ClassService.Start()
	Remotes.OnInvoke("ChooseClass", 1, function(player, classId)
		if not Validate.Key(classId, Classes) or classId == "Reihenfolge" then
			return { ok = false, msg = "Unbekannte Klasse." }
		end
		local data = DataService.Get(player)
		if not data then
			return { ok = false }
		end
		if data.Class == classId then
			return { ok = true }
		end
		if data.Class ~= "" then
			if not nearTeacher(player) then
				return { ok = false, msg = "Klassenwechsel nur beim Skill-Lehrer am Uhrturm-Platz 🎓" }
			end
			if not DataService.Spend(player, Settings.ClassChangeCost) then
				return { ok = false, msg = ("Klassenwechsel kostet %s ⚡"):format(Util.FormatNumber(Settings.ClassChangeCost)) }
			end
		end
		DataService.Update(player, function(d)
			if d.Class ~= "" then
				refundSkills(d)
			end
			d.Class = classId
		end)
		Remotes.Event("Toast"):FireClient(player, ("%s Du bist jetzt %s!"):format(Classes[classId].Symbol, Classes[classId].Name), "gut")
		QuestEvents.Fire(player, "Klasse")
		return { ok = true }
	end)

	Remotes.OnInvoke("UnlockSkill", 4, function(player, nodeId)
		if not Validate.String(nodeId, 20) then
			return { ok = false }
		end
		local data = DataService.Get(player)
		if not data or data.Class == "" then
			return { ok = false, msg = "Wähle zuerst eine Klasse." }
		end
		local node, branchIndex, index = StatCalc.FindNode(data.Class, nodeId)
		if not node or not branchIndex or not index then
			return { ok = false, msg = "Dieser Skill gehört nicht zu deiner Klasse." }
		end
		if data.Skills[nodeId] then
			return { ok = false, msg = "Schon gelernt!" }
		end
		if index > 1 then
			local tree = require(Config:WaitForChild("Skills")).Baeume[data.Class]
			local prev = tree[branchIndex].Knoten[index - 1]
			if not data.Skills[prev.Id] then
				return { ok = false, msg = ("Lerne zuerst \"%s\"."):format(prev.Name) }
			end
		end
		if data.SkillPoints < node.Kosten then
			return { ok = false, msg = ("Du brauchst %d Skill-Punkte."):format(node.Kosten) }
		end
		DataService.Update(player, function(d)
			d.SkillPoints -= node.Kosten
			d.Skills[nodeId] = true
		end)
		return { ok = true }
	end)

	Remotes.OnInvoke("ResetSkills", 1, function(player)
		local data = DataService.Get(player)
		if not data then
			return { ok = false }
		end
		if not nearTeacher(player) then
			return { ok = false, msg = "Zurücksetzen nur beim Skill-Lehrer am Uhrturm-Platz 🎓" }
		end
		DataService.Update(player, refundSkills)
		return { ok = true, msg = "Skill-Punkte zurückbekommen!" }
	end)
end

return ClassService
