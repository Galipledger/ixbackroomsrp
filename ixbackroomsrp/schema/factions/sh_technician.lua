FACTION.name = "Technician Department"
FACTION.description = "Technician Department is tasked with repairing and keeping the facility in check , can access lower levels with guard escort"
FACTION.color = Color(150, 125, 100, 255)
FACTION.isDefault = false
FACTION.models = {
		"models/player/cheddar/bms/bms_technician.mdl",
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

FACTION_TECHNICIAN = FACTION.index