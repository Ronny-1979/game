--[[
	🔍 SECRETS – versteckte goldene Zahnräder
	In jeder Zone (und im Hub) liegen kleine, leise drehende Zahnräder an versteckten Orten.
	Wer eins berührt, bekommt einmalig eine Belohnung. Alle gefunden → besonderer Titel!

	Positionen sind RELATIV zur Mitte des Ortes (Hub: (0,100,0), Zone i: (i·1400, 100, 0)).
	  x = links/rechts, y = Höhe über dem Boden, z = vorne/hinten (+z = Richtung Strecken)
	Wichtiger Hinweis: Die Stelle muss zu Fuß erreichbar sein! Nach dem Ändern Welt neu bauen.

	Hinweis = kleiner Rätsel-Tipp im Erfolge-Menü (verrät nicht alles).
]]
local Secrets = {}

-- Im Hub
Secrets.Hub = {
	{ Pos = Vector3.new(0, 0.6, -21), Hinweis = "Hinter dem Uhrturm tickt es leise …" },
	{ Pos = Vector3.new(-104, 0.6, 22), Hinweis = "Der Rebirth-Altar hütet ein Geheimnis." },
	{ Pos = Vector3.new(118, 0.6, 62), Hinweis = "Ganz am Rand, wo die Bäume stehen …" },
}

-- In jeder Zone dieselben drei Verstecke (pro Zone leicht verschoben, damit es nicht langweilig wird)
Secrets.Zone = {
	{ Pos = Vector3.new(172, 0.6, 76), Spiegeln = true, Hinweis = "Am äußersten Ende der Startterrasse." },
	{ Pos = Vector3.new(-252, 0.6, -82), Hinweis = "Hinter den Energie-Kristallen, am Inselrand." },
	{ Pos = Vector3.new(44, 0.6, -298), Hinweis = "Hinter den Säulen der Boss-Arena." },
}

-- Belohnung pro Geheimnis: Energie = Energiewert der Zone × EnergieFaktor (Hub zählt wie Zone 1)
Secrets.Belohnung = { EnergieFaktor = 400, XP = 80 }

-- Extra-Belohnung, wenn man so viele gefunden hat
Secrets.Meilensteine = {
	{ Anzahl = 6, Belohnung = { XP = 500 }, Text = "6 Geheimnisse: +500 XP ⭐" },
	{ Anzahl = 12, Belohnung = { Ei = "BestesEi" }, Text = "12 Geheimnisse: Gratis-Ei! 🥚" },
	{ Anzahl = 24, Belohnung = { Titel = "Meisterdetektiv" }, Text = "Alle Geheimnisse: Titel „Meisterdetektiv“ 🕵️" },
}

return Secrets
