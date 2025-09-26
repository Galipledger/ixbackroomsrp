FACTION.name = "Research Department"
FACTION.description = "Research Department mostly does researches and inspections on backrooms and its objects , they can access the lower levels without hesitation"
FACTION.color = Color(150, 125, 100, 255)
FACTION.isDefault = false
FACTION.models = {
		"models/bmscientistcits/female_02.mdl",
		"models/bmscientistcits/female_03.mdl",
		"models/bmscientistcits/female_04.mdl",
		"models/bmscientistcits/female_06.mdl",
		"models/bmscientistcits/female_07.mdl",
		"models/bmscientistcits/male_01.mdl",
		"models/bmscientistcits/male_02.mdl",
		"models/bmscientistcits/male_03.mdl",
		"models/bmscientistcits/male_04.mdl",
		"models/bmscientistcits/male_05.mdl",
		"models/bmscientistcits/male_06.mdl",
		"models/bmscientistcits/male_07.mdl",
		"models/bmscientistcits/male_08.mdl",
		"models/bmscientistcits/male_09.mdl",
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

FACTION_RESEARCH = FACTION.index