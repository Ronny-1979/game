--!strict
-- Gemeinsame Typen

export type PetEntry = { Id: string, Type: string, Name: string }

export type Profile = {
	Version: number,
	Level: number,
	XP: number,
	Class: string,
	Energy: number,
	TotalEnergy: number,
	Upgrades: { [string]: number },
	Rebirths: number,
	RebirthPoints: number,
	Pets: { PetEntry },
	Equipped: { string },
	PetCounter: number,
	UnlockedZones: { [string]: boolean },
	BossesDefeated: { [string]: boolean },
	BestTimes: { [string]: { [string]: number } },
	Completed: { [string]: boolean },
	SkillPoints: number,
	Skills: { [string]: boolean },
	Titles: { string },
	ActiveTitle: string,
	CoopSolved: { [string]: boolean },
	Settings: { Music: number, Sfx: number, Graphics: string, Difficulty: string },
	Stats: { PlayTime: number, Defeated: number, Courses: number, Hatched: number },
}

export type Reply = { ok: boolean, msg: string?, [string]: any }

return {}
