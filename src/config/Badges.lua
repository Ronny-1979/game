--[[
	🏅 BADGES – Sammel-Abzeichen
	Abzeichen bekommt man automatisch, sobald die Bedingung erfüllt ist.
	Art + Wert = Bedingung, z.B. Art = "Level", Wert = 10 → ab Level 10.

	Arten:
	  "Level", "Rebirths", "Pets" (Anzahl Pets), "Legendaer" (legendäre Pets), "Bosse" (verschiedene Bosse),
	  "Herausforderungen", "Serie" (beste Tages-Serie), "Energie" (insgesamt gesammelt), "Strecken" (geschafft),
	  "Profi" (Profi-Bahnen geschafft), "Gegner", "Coop" (Rätsel gelöst), "Aufgaben", "Eier", "Zonen"

	RobloxBadgeId (optional): Wenn ihr im Creator Dashboard echte Roblox-Badges anlegt,
	hier die Badge-ID eintragen – dann gibt es zusätzlich das echte Roblox-Badge. 0 = nur im Spiel.
]]
local Badges = {
	{ Id = "Start", Name = "Willkommen!", Symbol = "👋", Text = "Wähle eine Klasse", Art = "Aufgaben", Wert = 1, RobloxBadgeId = 0 },
	{ Id = "Aufgaben10", Name = "Fleißig", Symbol = "📜", Text = "10 Aufgaben geschafft", Art = "Aufgaben", Wert = 10, RobloxBadgeId = 0 },
	{ Id = "AufgabenAlle", Name = "Uhrwerk-Meister", Symbol = "🏆", Text = "Alle Aufgaben geschafft", Art = "Aufgaben", Wert = 23, RobloxBadgeId = 0 },
	{ Id = "Level10", Name = "Aufsteiger", Symbol = "⭐", Text = "Level 10 erreichen", Art = "Level", Wert = 10, RobloxBadgeId = 0 },
	{ Id = "Level25", Name = "Erfahren", Symbol = "🌟", Text = "Level 25 erreichen", Art = "Level", Wert = 25, RobloxBadgeId = 0 },
	{ Id = "Level50", Name = "Legende", Symbol = "💫", Text = "Level 50 erreichen", Art = "Level", Wert = 50, RobloxBadgeId = 0 },
	{ Id = "Strecken10", Name = "Hüpf-Fan", Symbol = "🏁", Text = "10 Strecken geschafft", Art = "Strecken", Wert = 10, RobloxBadgeId = 0 },
	{ Id = "Strecken100", Name = "Obby-Maschine", Symbol = "🚀", Text = "100 Strecken geschafft", Art = "Strecken", Wert = 100, RobloxBadgeId = 0 },
	{ Id = "Profi5", Name = "Profi", Symbol = "🔴", Text = "5 Profi-Bahnen geschafft", Art = "Profi", Wert = 5, RobloxBadgeId = 0 },
	{ Id = "ProfiAlle", Name = "Ultra-Profi", Symbol = "💎", Text = "Alle 15 Profi-Bahnen geschafft", Art = "Profi", Wert = 15, RobloxBadgeId = 0 },
	{ Id = "Gegner50", Name = "Schrottplatz", Symbol = "🤖", Text = "50 Gegner besiegt", Art = "Gegner", Wert = 50, RobloxBadgeId = 0 },
	{ Id = "Gegner500", Name = "Bot-Albtraum", Symbol = "⚔️", Text = "500 Gegner besiegt", Art = "Gegner", Wert = 500, RobloxBadgeId = 0 },
	{ Id = "Boss1", Name = "Boss-Bezwinger", Symbol = "👑", Text = "Den ersten Boss besiegt", Art = "Bosse", Wert = 1, RobloxBadgeId = 0 },
	{ Id = "BossAlle", Name = "Retter der Insel", Symbol = "🕰️", Text = "Alle 5 Bosse besiegt", Art = "Bosse", Wert = 5, RobloxBadgeId = 0 },
	{ Id = "Pets10", Name = "Pet-Sammler", Symbol = "🐾", Text = "10 Pets besitzen", Art = "Pets", Wert = 10, RobloxBadgeId = 0 },
	{ Id = "Legendaer1", Name = "Glückspilz", Symbol = "🍀", Text = "Ein legendäres Pet besitzen", Art = "Legendaer", Wert = 1, RobloxBadgeId = 0 },
	{ Id = "Eier50", Name = "Eier-Experte", Symbol = "🥚", Text = "50 Eier geöffnet", Art = "Eier", Wert = 50, RobloxBadgeId = 0 },
	{ Id = "Energie1M", Name = "Energie-Riese", Symbol = "⚡", Text = "1 Million Energie gesammelt", Art = "Energie", Wert = 1000000, RobloxBadgeId = 0 },
	{ Id = "Energie1B", Name = "Energie-Titan", Symbol = "🔋", Text = "1 Milliarde Energie gesammelt", Art = "Energie", Wert = 1000000000, RobloxBadgeId = 0 },
	{ Id = "Rebirth1", Name = "Neu geboren", Symbol = "♻️", Text = "Ersten Rebirth gemacht", Art = "Rebirths", Wert = 1, RobloxBadgeId = 0 },
	{ Id = "Rebirth10", Name = "Zeitreisender", Symbol = "🌀", Text = "10 Rebirths gemacht", Art = "Rebirths", Wert = 10, RobloxBadgeId = 0 },
	{ Id = "Coop1", Name = "Teamplayer", Symbol = "🤝", Text = "Ein Co-op-Rätsel gelöst", Art = "Coop", Wert = 1, RobloxBadgeId = 0 },
	{ Id = "CoopAlle", Name = "Beste Freunde", Symbol = "💞", Text = "Alle 10 Co-op-Rätsel gelöst", Art = "Coop", Wert = 10, RobloxBadgeId = 0 },
	{ Id = "Serie7", Name = "Treue Seele", Symbol = "📅", Text = "7 Tage hintereinander gespielt", Art = "Serie", Wert = 7, RobloxBadgeId = 0 },
	{ Id = "Herausforderung5", Name = "Herausforderer", Symbol = "🎯", Text = "5 Zonen-Herausforderungen", Art = "Herausforderungen", Wert = 5, RobloxBadgeId = 0 },
	{ Id = "HerausforderungAlle", Name = "Perfektionist", Symbol = "🥇", Text = "Alle 30 Zonen-Herausforderungen", Art = "Herausforderungen", Wert = 30, RobloxBadgeId = 0 },
	{ Id = "Zonen5", Name = "Weltenbummler", Symbol = "🗺️", Text = "Alle 5 Zonen freigeschaltet", Art = "Zonen", Wert = 5, RobloxBadgeId = 0 },
}

return Badges
