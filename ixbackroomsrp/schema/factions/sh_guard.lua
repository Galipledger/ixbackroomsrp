FACTION.name = "Guard"
FACTION.description = "A guard working at A-Sync to protect the facility at all costs"
FACTION.color = Color(150, 125, 100, 255)
FACTION.isDefault = false
FACTION.models = {
		"models/maolong/bms_security_guard_01_cp.mdl",
		"models/maolong/bms_security_guard_02_cp.mdl",
		"models/maolong/bms_security_guard_03_cp.mdl",
		"models/maolong/female/guard_female_npc.mdl",
		"models/maolong/bms_security_guard_01_sleeveless_cp.mdl",
		"models/maolong/bms_security_guard_02_sleeveless_cp.mdl",
		"models/maolong/bms_security_guard_03_sleeveless_cp.mdl",
	}
	
function FACTION:OnCharacterCreated(client, character)
	local id = Schema:ZeroNumber(math.random(1, 99999), 5)
	local inventory = character:GetInventory()

	character:SetData("cid", id)

	inventory:Add("suitcase", 1)
	inventory:Add("cid", 1, {
		name = character:GetName(),
		id = id
	})
end

FACTION_GUARD = FACTION.index