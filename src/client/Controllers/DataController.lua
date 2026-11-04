--!strict
-- DataController: Spiegel des eigenen Profils (nur zum Anzeigen – entscheiden tut der Server)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Signal = require(Shared:WaitForChild("Signal"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local StatCalc = require(Shared:WaitForChild("StatCalc"))

local DataController = {}
DataController.Data = nil :: any
DataController.Stats = nil :: any
DataController.Changed = Signal.new()

function DataController.Init() end

function DataController.Start()
	Remotes.Event("Data").OnClientEvent:Connect(function(data)
		DataController.Data = data
		DataController.Stats = StatCalc.Compute(data)
		DataController.Changed:Fire(data)
	end)
	Remotes.Event("RequestData"):FireServer()
end

-- Wartet, bis das erste Profil da ist
function DataController.Wait(): any
	while not DataController.Data do
		task.wait(0.1)
	end
	return DataController.Data
end

return DataController
