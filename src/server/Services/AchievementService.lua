--!strict
--[[
	AchievementService: Sammel-Abzeichen (Konfig: Badges.lua).
	Prüft regelmäßig, ob neue Abzeichen verdient sind. Optional zusätzlich echte Roblox-Badges.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RobloxBadges = game:GetService("BadgeService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Badges = require(Shared:WaitForChild("Config"):WaitForChild("Badges")) :: any
local Remotes = require(Shared:WaitForChild("Remotes"))
local Goals = require(Shared:WaitForChild("Goals"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local AchievementService = {}

local dirty: { [Player]: boolean } = {}

local function awardRoblox(player: Player, badgeId: number)
	if badgeId <= 0 then
		return
	end
	task.spawn(function()
		local ok, err = pcall(function()
			if not RobloxBadges:UserHasBadgeAsync(player.UserId, badgeId) then
				RobloxBadges:AwardBadge(player.UserId, badgeId)
			end
		end)
		if not ok then
			warn("[Abzeichen] Roblox-Badge fehlgeschlagen:", badgeId, err)
		end
	end)
end

function AchievementService.Check(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local new = {}
	for _, b in Badges do
		if not data.Badges[b.Id] and Goals.BadgeValue(b.Art, data) >= b.Wert then
			table.insert(new, b)
		end
	end
	if #new == 0 then
		return
	end
	DataService.Update(player, function(d)
		for _, b in new do
			d.Badges[b.Id] = true
		end
	end)
	for i, b in new do
		task.delay((i - 1) * 1.2, function()
			if player.Parent then
				Remotes.Event("Toast"):FireClient(player, ("%s Neues Abzeichen: %s!"):format(b.Symbol, b.Name), "gut")
			end
		end)
		awardRoblox(player, b.RobloxBadgeId or 0)
	end
end

function AchievementService.Init() end

function AchievementService.Start()
	DataService.Changed:Connect(function(player)
		dirty[player] = true
	end)
	DataService.OnLoaded(function(player)
		dirty[player] = true
	end)
	task.spawn(function()
		while true do
			task.wait(1.5)
			for player in dirty do
				dirty[player] = nil
				if player.Parent then
					AchievementService.Check(player)
				end
			end
		end
	end)
end

return AchievementService
