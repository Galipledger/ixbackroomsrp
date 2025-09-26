local PLUGIN = PLUGIN
PLUGIN.name = "Monolith HUD"
PLUGIN.author = "nicwtf"
PLUGIN.description = "Can't sue me Synapse, I made it!"

function PLUGIN:ShouldHideBars()
    return true
end

function Schema:CanDrawAmmoHUD(weapon)
    return false
end

if CLIENT then
    -- Config
    local HUD_X = 15
    local HUD_Y = ScrH() - 75
    local ICON_SIZE = 60
    local SPACING = 40
    local ICON_TEXT_SPACING = 10
    local CURRENT_VALUE_FONT_SIZE = 30
    local MAX_VALUE_FONT_SIZE = 15
    local staminaWidth = 300
    local staminaHeight = 16
    local cornerSize = 8
    local FadeSpeed = 5
    local HEALTH_THRESHOLD = 100
    local ARMOR_THRESHOLD = 100
    local HUNGER_THRESHOLD = 75
    local THIRST_THRESHOLD = 75
    local STAMINA_THRESHOLD = 100
    local OVERRIDE_KEY = KEY_LALT
    local PulseSpeed = 2

    -- Materials
    local materials = {
        barCenter = Material("mrp/hud/bar/center.png", "smooth"),
        barCornerLeft = Material("mrp/hud/bar/corner.png", "smooth"),
        barCornerRight = Material("mrp/hud/bar/corner_right.png", "smooth"),
        fillCenter = Material("mrp/hud/bar/center_fill.png", "smooth"),
        fillCornerLeft = Material("mrp/hud/bar/corner_fill.png", "smooth"),
        fillCornerRight = Material("mrp/hud/bar/corner_fillb.png", "smooth")
    }

    -- Fonts
    surface.CreateFont("Monolith_HUD_Font", { font = "Roboto", size = CURRENT_VALUE_FONT_SIZE, weight = 500, antialias = true })
    surface.CreateFont("Monolith_HUD_Font_Small", { font = "Roboto", size = MAX_VALUE_FONT_SIZE, weight = 500, antialias = true })

    local smoothStamina = 1
    local alphaValues = { health = 0, armor = 0, hunger = 0, thirst = 0, stamina = 0 }

    -- HUD
    ix.hud = ix.hud or {}
    function ix.hud.DrawAll()
        ix.hud.DrawItemPickup()
        local client = LocalPlayer()
        if not IsValid(client) then return end

        local override = input.IsKeyDown(OVERRIDE_KEY)
        local currentX = HUD_X
        local textY = HUD_Y + ICON_SIZE / 2 - CURRENT_VALUE_FONT_SIZE / 2

        local stats = {
            { key = "health", value = client:Health(), max = 100, threshold = HEALTH_THRESHOLD, icon = materials.barCenter },
            { key = "armor", value = client:Armor(), max = 100, threshold = ARMOR_THRESHOLD, icon = materials.barCenter },
            { key = "hunger", value = client.GetHunger and client:GetHunger() or 100, max = 100, threshold = HUNGER_THRESHOLD, icon = materials.barCenter },
            { key = "thirst", value = client.GetThirst and client:GetThirst() or 100, max = 100, threshold = THIRST_THRESHOLD, icon = materials.barCenter }
        }

        for _, stat in ipairs(stats) do
            local target = (stat.value < stat.threshold or override) and 1 or 0
            alphaValues[stat.key] = Lerp(FrameTime() * FadeSpeed, alphaValues[stat.key], target)

            local alphaMod = 1
            if stat.value <= 0 then
                alphaMod = 0.5 + 0.5 * math.sin(CurTime() * PulseSpeed)
            end

            if alphaValues[stat.key] > 0.01 then
                surface.SetDrawColor(255, 255, 255, 255 * alphaValues[stat.key] * alphaMod)
                surface.SetMaterial(Material("mrp/hud/" .. stat.key .. ".png"))
                surface.DrawTexturedRect(currentX, HUD_Y, ICON_SIZE, ICON_SIZE)

                surface.SetFont("Monolith_HUD_Font")
                local valueText = tostring(stat.value)
                local valueTextWidth = surface.GetTextSize(valueText)
                surface.SetTextColor(255, 255, 255, 255 * alphaValues[stat.key] * alphaMod)
                local textX = currentX + ICON_SIZE + ICON_TEXT_SPACING
                surface.SetTextPos(textX, textY)
                surface.DrawText(valueText)

                local maxText = " | " .. tostring(stat.max)
                surface.SetFont("Monolith_HUD_Font_Small")
                surface.SetTextColor(255, 255, 255, 150 * alphaValues[stat.key] * alphaMod)
                surface.SetTextPos(textX + valueTextWidth + 2, textY + (CURRENT_VALUE_FONT_SIZE - MAX_VALUE_FONT_SIZE) / 2)
                surface.DrawText(maxText)

                local totalTextWidth = valueTextWidth + surface.GetTextSize(maxText) + ICON_TEXT_SPACING
                currentX = currentX + ICON_SIZE + totalTextWidth + SPACING
            end
        end

        local stamina = client:GetLocalVar("stm", 100)
        smoothStamina = Lerp(FrameTime() * 5, smoothStamina, stamina / 100)

        local showStamina = (stamina < STAMINA_THRESHOLD or override)
        alphaValues.stamina = Lerp(FrameTime() * FadeSpeed, alphaValues.stamina, showStamina and 1 or 0)

        local staminaAlphaMod = 1
        if stamina <= 0 then
            staminaAlphaMod = 0.5 + 0.5 * math.sin(CurTime() * PulseSpeed)
        end

        if alphaValues.stamina > 0.01 then
            local barX = ScrW() / 2 - staminaWidth / 2
            local barY = HUD_Y + ICON_SIZE - 35

            surface.SetDrawColor(255, 255, 255, 80 * alphaValues.stamina * staminaAlphaMod)
            surface.SetMaterial(materials.barCornerLeft)
            surface.DrawTexturedRect(barX - cornerSize, barY, cornerSize, staminaHeight)
            surface.SetMaterial(materials.barCenter)
            surface.DrawTexturedRect(barX, barY, staminaWidth, staminaHeight)
            surface.SetMaterial(materials.barCornerRight)
            surface.DrawTexturedRect(barX + staminaWidth, barY, cornerSize, staminaHeight)

            local fillW = staminaWidth * smoothStamina
            if fillW > 0 then
                surface.SetDrawColor(255, 255, 255, 255 * alphaValues.stamina * staminaAlphaMod)
                surface.SetMaterial(materials.fillCornerLeft)
                surface.DrawTexturedRect(barX - cornerSize, barY, cornerSize, staminaHeight)
                surface.SetMaterial(materials.fillCenter)
                surface.DrawTexturedRect(barX, barY, fillW, staminaHeight)
                surface.SetMaterial(materials.fillCornerRight)
                surface.DrawTexturedRect(barX + fillW, barY, cornerSize, staminaHeight)
            end
        end
    end

    -- Hooks
    hook.Add("HUDPaint", "Monolith_HUD_Draw", function()
        ix.hud.DrawAll()
    end)
    hook.Add("HUDShouldDraw", "Monolith_HUD_HideDefault", function(name)
        local hide = {
            ["CHudHealth"] = true,
            ["CHudBattery"] = true,
            ["CHudAmmo"] = true,
            ["CHudSecondaryAmmo"] = true
        }
        return not hide[name]
    end)
end