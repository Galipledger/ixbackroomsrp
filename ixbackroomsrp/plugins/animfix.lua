PLUGIN.name = "Animation Fix"
PLUGIN.author = "nicwtf"
PLUGIN.description = "Fixes animations for factions"

local modelClasses = {
    ["player"] = {
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
        "models/willardnetworks_custom/citizens/male10.mdl"
    },

    --[[
    ["metrocop"] = {
        "models/police.mdl"
    }
    ]]
}

for class, models in pairs(modelClasses) do
    for _, model in ipairs(models) do
        ix.anim.SetModelClass(model, class)
    end
end