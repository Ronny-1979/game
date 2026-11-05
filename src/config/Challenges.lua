--[[
	🎯 CHALLENGES – Herausforderungen pro Zone (für Profis!)
	Jede Herausforderung gibt einmalig eine Belohnung und zählt für die Abzeichen.

	Arten:
	  "AlleStrecken" – alle 3 Strecken der Zone auf Diff (oder schwerer) schaffen
	  "Strecke"      – eine bestimmte Strecke (Strecke = 1–3) auf Diff schaffen
	  "Gegner"       – Anzahl Gegner in dieser Zone besiegen
	  "Kristall"     – Anzahl Kristall-Klicks in dieser Zone
	  "Boss"         – den Boss der Zone so oft besiegen
	  "Coop"         – alle Co-op-Rätsel der Zone lösen

	Beispiel:
	{ Id = "Z1_Turbo", Titel = "Turbo-Hüpfer", Art = "Strecke", Strecke = 2, Diff = "Profi", Belohnung = { Energie = 500, XP = 100 } },
	Die Id muss eindeutig sein und darf später nicht mehr geändert werden.
]]
local Challenges = {}

Challenges[1] = {
	{ Id = "Z1_Leicht", Titel = "Wiesen-Wanderer", Text = "Alle 3 Strecken auf 🟢 Leicht", Art = "AlleStrecken", Diff = "Leicht", Belohnung = { Energie = 300, XP = 80 } },
	{ Id = "Z1_Normal", Titel = "Wiesen-Kenner", Text = "Alle 3 Strecken auf 🟡 Normal", Art = "AlleStrecken", Diff = "Normal", Belohnung = { Energie = 800, XP = 150 } },
	{ Id = "Z1_Profi", Titel = "Wiesen-Profi", Text = "Alle 3 Strecken auf 🔴 Profi", Art = "AlleStrecken", Diff = "Profi", Belohnung = { Energie = 2000, XP = 300, Ei = "WiesenEi" } },
	{ Id = "Z1_Kristall", Titel = "Klick-König", Text = "300 Kristall-Klicks in der Zahnrad-Wiese", Art = "Kristall", Anzahl = 300, Belohnung = { Energie = 400, XP = 60 } },
	{ Id = "Z1_Gegner", Titel = "Bot-Jäger", Text = "25 Gegner in der Zahnrad-Wiese besiegen", Art = "Gegner", Anzahl = 25, Belohnung = { Energie = 600, XP = 120 } },
	{ Id = "Z1_Boss", Titel = "Königsbezwinger", Text = "Den Zahnrad-König 3-mal besiegen", Art = "Boss", Anzahl = 3, Belohnung = { Energie = 1500, XP = 250 } },
}

Challenges[2] = {
	{ Id = "Z2_Leicht", Titel = "Werkstatt-Lehrling", Text = "Alle 3 Strecken auf 🟢 Leicht", Art = "AlleStrecken", Diff = "Leicht", Belohnung = { Energie = 3000, XP = 150 } },
	{ Id = "Z2_Normal", Titel = "Werkstatt-Geselle", Text = "Alle 3 Strecken auf 🟡 Normal", Art = "AlleStrecken", Diff = "Normal", Belohnung = { Energie = 8000, XP = 250 } },
	{ Id = "Z2_Profi", Titel = "Werkstatt-Meister", Text = "Alle 3 Strecken auf 🔴 Profi", Art = "AlleStrecken", Diff = "Profi", Belohnung = { Energie = 20000, XP = 500, Ei = "WerkstattEi" } },
	{ Id = "Z2_Coop", Titel = "Dream-Team", Text = "Alle Co-op-Rätsel der Werkstatt lösen", Art = "Coop", Belohnung = { Energie = 10000, XP = 300 } },
	{ Id = "Z2_Gegner", Titel = "Schrott-Sammler", Text = "40 Gegner in der Rost-Werkstatt besiegen", Art = "Gegner", Anzahl = 40, Belohnung = { Energie = 6000, XP = 200 } },
	{ Id = "Z2_Boss", Titel = "Rudi-Rambo", Text = "Rost-Rudi 3-mal besiegen", Art = "Boss", Anzahl = 3, Belohnung = { Energie = 15000, XP = 400 } },
}

Challenges[3] = {
	{ Id = "Z3_Leicht", Titel = "Schluchten-Gänger", Text = "Alle 3 Strecken auf 🟢 Leicht", Art = "AlleStrecken", Diff = "Leicht", Belohnung = { Energie = 30000, XP = 250 } },
	{ Id = "Z3_Normal", Titel = "Pendel-Tänzer", Text = "Alle 3 Strecken auf 🟡 Normal", Art = "AlleStrecken", Diff = "Normal", Belohnung = { Energie = 80000, XP = 400 } },
	{ Id = "Z3_Profi", Titel = "Pendel-Profi", Text = "Alle 3 Strecken auf 🔴 Profi", Art = "AlleStrecken", Diff = "Profi", Belohnung = { Energie = 200000, XP = 800, Ei = "SchluchtEi" } },
	{ Id = "Z3_Coop", Titel = "Zeit-Team", Text = "Alle Co-op-Rätsel der Schlucht lösen", Art = "Coop", Belohnung = { Energie = 90000, XP = 450 } },
	{ Id = "Z3_Gegner", Titel = "Glocken-Läuter", Text = "50 Gegner in der Pendel-Schlucht besiegen", Art = "Gegner", Anzahl = 50, Belohnung = { Energie = 60000, XP = 350 } },
	{ Id = "Z3_Boss", Titel = "Paula-Pauker", Text = "Pendel-Paula 3-mal besiegen", Art = "Boss", Anzahl = 3, Belohnung = { Energie = 150000, XP = 700 } },
}

Challenges[4] = {
	{ Id = "Z4_Leicht", Titel = "Kristall-Gucker", Text = "Alle 3 Strecken auf 🟢 Leicht", Art = "AlleStrecken", Diff = "Leicht", Belohnung = { Energie = 300000, XP = 400 } },
	{ Id = "Z4_Normal", Titel = "Ring-Reiter", Text = "Alle 3 Strecken auf 🟡 Normal", Art = "AlleStrecken", Diff = "Normal", Belohnung = { Energie = 800000, XP = 650 } },
	{ Id = "Z4_Profi", Titel = "Laser-Legende", Text = "Alle 3 Strecken auf 🔴 Profi", Art = "AlleStrecken", Diff = "Profi", Belohnung = { Energie = 2000000, XP = 1200, Ei = "KristallEi" } },
	{ Id = "Z4_Coop", Titel = "Prismen-Partner", Text = "Alle Co-op-Rätsel im Kristall-Getriebe lösen", Art = "Coop", Belohnung = { Energie = 900000, XP = 700 } },
	{ Id = "Z4_Gegner", Titel = "Drohnen-Fänger", Text = "60 Gegner im Kristall-Getriebe besiegen", Art = "Gegner", Anzahl = 60, Belohnung = { Energie = 600000, XP = 550 } },
	{ Id = "Z4_Boss", Titel = "Koloss-Knacker", Text = "Den Kristall-Koloss 3-mal besiegen", Art = "Boss", Anzahl = 3, Belohnung = { Energie = 1500000, XP = 1000 } },
}

Challenges[5] = {
	{ Id = "Z5_Leicht", Titel = "Uhrwerk-Besucher", Text = "Alle 3 Strecken auf 🟢 Leicht", Art = "AlleStrecken", Diff = "Leicht", Belohnung = { Energie = 3000000, XP = 700 } },
	{ Id = "Z5_Normal", Titel = "Uhrwerk-Kenner", Text = "Alle 3 Strecken auf 🟡 Normal", Art = "AlleStrecken", Diff = "Normal", Belohnung = { Energie = 8000000, XP = 1100 } },
	{ Id = "Z5_Profi", Titel = "Herr der Zeit", Text = "Alle 3 Strecken auf 🔴 Profi", Art = "AlleStrecken", Diff = "Profi", Belohnung = { Energie = 20000000, XP = 2500, Ei = "UhrwerkEi" } },
	{ Id = "Z5_Coop", Titel = "Unzertrennlich", Text = "Alle Co-op-Rätsel im Großen Uhrwerk lösen", Art = "Coop", Belohnung = { Energie = 9000000, XP = 1200 } },
	{ Id = "Z5_Gegner", Titel = "Wächter-Bezwinger", Text = "80 Gegner im Großen Uhrwerk besiegen", Art = "Gegner", Anzahl = 80, Belohnung = { Energie = 6000000, XP = 900 } },
	{ Id = "Z5_Boss", Titel = "Unruh-Stopper", Text = "Meister Unruh 3-mal besiegen", Art = "Boss", Anzahl = 3, Belohnung = { Energie = 15000000, XP = 2000 } },
}

return Challenges
