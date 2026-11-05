--!strict
--[[
	QuestEvents: Briefkasten für Aufgaben-Fortschritt.
	Services melden hier Ereignisse (z.B. "Gegner besiegt"), der QuestService hört zu.
	So müssen sich die Services nicht gegenseitig kennen.
	Nutzung: QuestEvents.Fire(player, "Gegner", { Zone = 1 })
]]
local Signal = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Signal"))

local QuestEvents = {}
QuestEvents.Signal = Signal.new()

function QuestEvents.Fire(player: Player, kind: string, info: { [string]: any }?, amount: number?)
	QuestEvents.Signal:Fire(player, kind, info or {}, amount or 1)
end

return QuestEvents
