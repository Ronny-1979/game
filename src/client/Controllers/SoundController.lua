--!strict
-- SoundController: Töne und Musik (Lautstärke aus den Einstellungen)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared:WaitForChild("Config"):WaitForChild("Assets")) :: any
local DataController = require(script.Parent:WaitForChild("DataController"))

local SoundController = {}

local cache: { [string]: Sound } = {}
local music: Sound? = nil
local currentMusicKey: any = nil
SoundController.UpdateZoneMusic = function() end

local function sfxVolume(): number
	local d = DataController.Data
	return if d then d.Settings.Sfx else 0.8
end

local function musicVolume(): number
	local d = DataController.Data
	return if d then d.Settings.Music else 0.5
end

function SoundController.Play(name: string, pitch: number?)
	local id = Assets.Sounds[name]
	if not id or id == "" then
		return
	end
	local s = cache[name]
	if not s then
		s = Instance.new("Sound")
		s.Name = name
		s.SoundId = id
		s.Parent = SoundService
		cache[name] = s
	end
	local snd = s :: Sound
	snd.Volume = (Assets.SoundVolume[name] or 0.5) * sfxVolume()
	snd.PlaybackSpeed = pitch or 1
	snd.TimePosition = 0
	snd:Play()
end

function SoundController.SetMusic(key: any)
	if key == currentMusicKey then
		return
	end
	currentMusicKey = key
	local id = Assets.Music[key] or ""
	if music then
		music:Stop()
		music:Destroy()
		music = nil
	end
	if id == "" then
		return
	end
	local m = Instance.new("Sound")
	m.Name = "Musik"
	m.SoundId = id
	m.Looped = true
	m.Volume = 0.4 * musicVolume()
	m.Parent = SoundService
	m:Play()
	music = m
end

function SoundController.Init() end

function SoundController.Start()
	local player = Players.LocalPlayer
	local function updateZone()
		local ort = player:GetAttribute("Ort")
		if ort == "Turm" then
			SoundController.SetMusic("Turm")
		elseif ort == "Insel" then
			SoundController.SetMusic("Werkstatt")
		else
			SoundController.SetMusic((player:GetAttribute("Zone") :: number?) or 0)
		end
	end
	SoundController.UpdateZoneMusic = updateZone
	player:GetAttributeChangedSignal("Zone"):Connect(updateZone)
	player:GetAttributeChangedSignal("Ort"):Connect(updateZone)
	updateZone()
	DataController.Changed:Connect(function()
		if music then
			music.Volume = 0.4 * musicVolume()
		end
	end)
end

return SoundController
