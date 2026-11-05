--[[
	🗼 TOWER – der Endlos-Turm
	Etage für Etage nach oben, jede Etage ist eine kurze, zufällige Hindernis-Strecke.
	Jeden Montag gibt es einen NEUEN Turm (andere Hindernisse) und eine neue Wochen-Bestenliste.
	Etagen werden erst gebaut, wenn jemand sie erreicht – der Turm ist also wirklich endlos.

	Schwierigkeit steigt mit der Etage:
	  bis Etage "LeichtBis" → 🟢, bis "NormalBis" → 🟡, danach 🔴
	  Faktor (wie "Schwierigkeit" bei Zonen) = 1 + Etage × FaktorProEtage (höchstens FaktorMax)
	Abschnitte pro Etage = AbschnitteStart + Etage / AbschnitteAlle (höchstens AbschnitteMax)
]]
local Tower = {}

Tower.Ursprung = Vector3.new(-3200, 100, 0) -- weit weg von allem anderen
Tower.EtagenHoehe = 55 -- Abstand zwischen zwei Etagen
Tower.EtagenProSaeule = 50 -- danach beginnt eine neue Säule daneben (damit es nicht zu hoch wird)
Tower.SaeulenAbstand = 420

Tower.LeichtBis = 8
Tower.NormalBis = 25
Tower.FaktorProEtage = 0.015
Tower.FaktorMax = 2.6
Tower.AbschnitteStart = 3
Tower.AbschnitteAlle = 12
Tower.AbschnitteMax = 7

-- Diese Hindernisse kommen im Turm vor
Tower.Hindernisse = { "Sprung", "Zahnrad", "Pendel", "Foerderband", "Bewegt", "Zeitplattform", "Wackel", "Laser", "Sprungpad", "Funken", "Drehring" }

-- Belohnung pro geschaffter Etage. Energie = Energiewert der besten freien Zone × (Basis + Etage × ProEtage)
Tower.Belohnung = { EnergieBasis = 60, EnergieProEtage = 15, XPBasis = 20, XPProEtage = 4 }
-- Alle 10 Etagen: Gratis-Ei der besten Zone + Start-Etage (man kann dort später wieder einsteigen)
Tower.MeilensteinAlle = 10

return Tower
