--!strict
--[[
	ChatController: Kinderschutz – kein freier Chat im Spiel.
	Der Roblox-Chat wird ausgeblendet, stattdessen gibt es Schnellnachrichten als Sprechblasen.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = require(Shared:WaitForChild("Config"):WaitForChild("Settings")) :: any
local Remotes = require(Shared:WaitForChild("Remotes"))

local ChatController = {}

local function disableChat()
	for _ = 1, 10 do
		local ok = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
		end)
		if ok then
			break
		end
		task.wait(0.5)
	end
	pcall(function()
		local window = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
		if window then
			window.Enabled = false
		end
		local bar = TextChatService:FindFirstChildOfClass("ChatInputBarConfiguration")
		if bar then
			bar.Enabled = false
		end
	end)
end

local function showBubble(userId: number, index: number)
	local text = Settings.QuickChat[index]
	local plr = Players:GetPlayerByUserId(userId)
	local head = plr and plr.Character and plr.Character:FindFirstChild("Head")
	if not text or not head or not head:IsA("BasePart") then
		return
	end
	local old = head:FindFirstChild("Schnellnachricht")
	if old then
		old:Destroy()
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "Schnellnachricht"
	gui.Size = UDim2.fromOffset(220, 56)
	gui.StudsOffset = Vector3.new(0, 4.6, 0)
	gui.MaxDistance = 100
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(255, 250, 235)
	frame.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.4, 0)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(215, 170, 80)
	stroke.Thickness = 2
	stroke.Parent = frame
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(0.92, 0.8)
	label.Position = UDim2.fromScale(0.04, 0.1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(70, 50, 35)
	label.Text = text
	label.Parent = frame
	gui.Parent = head
	task.delay(4, function()
		if gui.Parent then
			gui:Destroy()
		end
	end)
end

function ChatController.Send(index: number)
	Remotes.Event("QuickChat"):FireServer(index)
end

function ChatController.Init() end

function ChatController.Start()
	task.spawn(disableChat)
	Remotes.Event("QuickChatShow").OnClientEvent:Connect(showBubble)
end

return ChatController
