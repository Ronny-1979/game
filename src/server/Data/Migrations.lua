--!strict
--[[
	Migrationen: bringen alte Spielstände auf die aktuelle Schema-Version.
	Migrations[2] macht aus Version 1 → Version 2 usw.
	Neue Migration: Settings.SchemaVersion erhöhen und hier Migrations[neu] hinzufügen.
]]
local Migrations: { [number]: (any) -> any } = {}

-- v1 → v2: Pets waren eine Liste von Namen, jetzt Tabellen mit Id/Typ/Name. Einstellungen neu.
Migrations[2] = function(data)
	if type(data.Pets) == "table" then
		local newPets = {}
		local counter = data.PetCounter or 0
		for _, p in data.Pets do
			if type(p) == "string" then
				counter += 1
				table.insert(newPets, { Id = "P" .. counter, Type = p, Name = "" })
			elseif type(p) == "table" then
				table.insert(newPets, p)
			end
		end
		data.Pets = newPets
		data.PetCounter = counter
	end
	if type(data.Settings) ~= "table" then
		data.Settings = { Music = 0.5, Sfx = 0.8, Graphics = "Hoch", Difficulty = "Normal" }
	end
	return data
end

return Migrations
