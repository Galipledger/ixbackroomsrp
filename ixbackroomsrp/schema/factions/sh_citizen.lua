FACTION.name = "Survivor"
FACTION.description = "You noclipped out of reality and into the Backrooms, a desolate, yellow labyrinth of endless hums and fluorescent lights. Your only goal is to survive the entities that hunt you, as your old life is now a fading memory."
FACTION.color = Color(150, 125, 100, 255)
FACTION.isDefault = true

FACTION.models = {
	"models/willardnetworks_custom/citizens/female_01.mdl",
	"models/willardnetworks_custom/citizens/female_02.mdl",
	"models/willardnetworks_custom/citizens/female_03.mdl",
	"models/willardnetworks_custom/citizens/female_04.mdl",
	"models/willardnetworks_custom/citizens/female_06.mdl",
	"models/willardnetworks_custom/citizens/female_07.mdl",
	
	"models/willardnetworks_custom/citizens/male01.mdl",
	"models/willardnetworks_custom/citizens/male02.mdl",
	"models/willardnetworks_custom/citizens/male03.mdl",
	"models/willardnetworks_custom/citizens/male04.mdl",
	"models/willardnetworks_custom/citizens/male05.mdl",
	"models/willardnetworks_custom/citizens/male06.mdl",
	"models/willardnetworks_custom/citizens/male07.mdl",
	"models/willardnetworks_custom/citizens/male08.mdl",
	"models/willardnetworks_custom/citizens/male09.mdl",
	"models/willardnetworks_custom/citizens/male10.mdl",
}

function FACTION:OnCharacterCreated(client, character)
	local id = Schema:ZeroNumber(math.random(1, 99999), 5)
	local inventory = character:GetInventory()

	character:SetData("cid", id)

	inventory:Add("camera", 1)
	inventory:Add("cid", 1, {
		name = character:GetName(),
		id = id
	})
end

FACTION_CITIZEN = FACTION.index
