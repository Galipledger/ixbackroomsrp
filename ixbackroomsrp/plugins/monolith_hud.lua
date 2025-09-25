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
    local HUD_X = 15
    local HUD_Y = ScrH() - 75
    local ICON_SIZE = 60
    local SPACING = 40
    local ICON_TEXT_SPACING = 10

    local CURRENT_VALUE_FONT_SIZE = 30
    local MAX_VALUE_FONT_SIZE = 15

    local staminaWidth   = 300
    local staminaHeight  = 16
    local cornerSize     = 8
    local smoothStamina  = 1

    local barCenter      = Material("mrp/hud/bar/center.png", "smooth")
    local barCornerLeft  = Material("mrp/hud/bar/corner.png", "smooth")
    local barCornerRight = Material("mrp/hud/bar/corner_right.png", "smooth")

    local fillCenter      = Material("mrp/hud/bar/center_fill.png", "smooth")
    local fillCornerLeft  = Material("mrp/hud/bar/corner_fill.png", "smooth")
    local fillCornerRight = Material("mrp/hud/bar/corner_fillb.png", "smooth")

    surface.CreateFont("Monolith_HUD_Font", {
        font = "Roboto",
        size = CURRENT_VALUE_FONT_SIZE,
        weight = 500,
        antialias = true,
    })

    surface.CreateFont("Monolith_HUD_Font_Small", {
        font = "Roboto",
        size = MAX_VALUE_FONT_SIZE,
        weight = 500,
        antialias = true,
    })

    ix.hud = ix.hud or {}
    
    function ix.hud.DrawAll()
        ix.hud.DrawItemPickup()

        local client = LocalPlayer()
        if not IsValid(client) then return end

        local currentX = HUD_X
        local textY = HUD_Y + ICON_SIZE / 2 - CURRENT_VALUE_FONT_SIZE / 2

        local stats = {
            { value = client:Health(), max = 100, icon = "mrp/hud/health.png" },
            { value = client:Armor(), max = 100, icon = "mrp/hud/armor.png" },
            { value = client.GetHunger and client:GetHunger() or 100, max = 100, icon = "mrp/hud/hunger.png" },
            { value = client.GetThirst and client:GetThirst() or 100, max = 100, icon = "mrp/hud/thirst.png" },
        }

        for _, stat in ipairs(stats) do
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(Material(stat.icon))
            surface.DrawTexturedRect(currentX, HUD_Y, ICON_SIZE, ICON_SIZE)
            
            surface.SetFont("Monolith_HUD_Font")
            local valueText = tostring(stat.value)
            local valueTextWidth = surface.GetTextSize(valueText)
            surface.SetTextColor(color_white)
            
            local textX = currentX + ICON_SIZE + ICON_TEXT_SPACING
            surface.SetTextPos(textX, textY)
            surface.DrawText(valueText)

            local maxText = " | " .. tostring(stat.max)
            surface.SetFont("Monolith_HUD_Font_Small")
            surface.SetTextColor(Color(255, 255, 255, 150))
            local maxTextX = textX + valueTextWidth + 2
            surface.SetTextPos(maxTextX, textY + (CURRENT_VALUE_FONT_SIZE - MAX_VALUE_FONT_SIZE) / 2)
            surface.DrawText(maxText)

            local totalTextWidth = valueTextWidth + surface.GetTextSize(maxText) + ICON_TEXT_SPACING
            currentX = currentX + ICON_SIZE + totalTextWidth + SPACING
        end

        local stamina = client:GetLocalVar("stm", 100) / 100
        smoothStamina = Lerp(FrameTime() * 5, smoothStamina, stamina)

        local barX = ScrW() / 2 - staminaWidth / 2
        local barY = HUD_Y + ICON_SIZE + -35

        surface.SetDrawColor(255, 255, 255, 80)
        surface.SetMaterial(barCornerLeft)
        surface.DrawTexturedRect(barX - cornerSize, barY, cornerSize, staminaHeight)

        surface.SetMaterial(barCenter)
        surface.DrawTexturedRect(barX, barY, staminaWidth, staminaHeight)

        surface.SetMaterial(barCornerRight)
        surface.DrawTexturedRect(barX + staminaWidth, barY, cornerSize, staminaHeight)

        local fillW = staminaWidth * smoothStamina
        if fillW > 0 then
            surface.SetDrawColor(255, 255, 255)

            surface.SetMaterial(fillCornerLeft)
            surface.DrawTexturedRect(barX - cornerSize, barY, cornerSize, staminaHeight)

            surface.SetMaterial(fillCenter)
            surface.DrawTexturedRect(barX, barY, fillW, staminaHeight)

            surface.SetMaterial(fillCornerRight)
            surface.DrawTexturedRect(barX + fillW, barY, cornerSize, staminaHeight)
        end
    end

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
