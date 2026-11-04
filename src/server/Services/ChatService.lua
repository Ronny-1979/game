--!strict
-- ChatService: nur vorgefertigte Schnellnachrichten (kein freier Text → kein Filter nötig)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = require(Shared:WaitForChild("Config"):WaitForChild("Settings")) :: any
local Remotes = require(Shared:WaitForChild("Remotes"))
local Validate = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("Validate"))

local ChatService = {}

function ChatService.Init() end

function ChatService.Start()
	-- höchstens 1 Nachricht alle 2 Sekunden
	Remotes.OnEvent("QuickChat", 0.5, function(player, index)
		if not Validate.Int(index, 1, #Settings.QuickChat) then
			return
		end
		Remotes.Event("QuickChatShow"):FireAllClients(player.UserId, index)
	end)
end

return ChatService
