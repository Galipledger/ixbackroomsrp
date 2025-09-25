PLUGIN = PLUGIN or {}
local PLUGIN = PLUGIN

PLUGIN.name = "Monolith Weapon Select"
PLUGIN.author = "Synapse, nicwtf, Romani Quinque"
PLUGIN.description = "Monolith-style weapon selector for Helix."

if (SERVER) then return end

do
    local GENERIC = "Roboto"
    local ITALIC  = "Roboto"
    local BOLD    = "Roboto"

    local function mkfont(name, font, size, weight, italic, extended)
        surface.CreateFont(name, {
            font = font,
            size = size,
            weight = weight or 500,
            italic = italic or false,
            extended = extended ~= false
        })
    end

    local function S(px) return math.Round(px * (ScrH() / 1080)) end

    mkfont("WPNSEL_Roboto_62_BOLD", BOLD,   S(62), 900, false, true)
    mkfont("WPNSEL_Roboto_28",       GENERIC, S(28), 600, false, true)
    mkfont("WPNSEL_Roboto_24",       GENERIC, S(24), 600, false, true)
    mkfont("WPNSEL_Roboto_24I",      ITALIC,  S(24), 500,  true,  true)
    mkfont("WPNSEL_Roboto_22",       GENERIC, S(22), 600, false, true)
    mkfont("WPNSEL_Roboto_20",       GENERIC, S(20), 600, false, true)
    mkfont("WPNSEL_Roboto_15",       GENERIC, S(15), 500, false, true)
end

do
    local outlineLight = Color(160, 160, 160, 255)
    local outlineDark  = Color(0, 0, 0, 200)

    local function DrawCuteRect(x, y, w, h, gasp, alpha, outlineColor)
        gasp = gasp or 4
        alpha = alpha or 100

        surface.SetDrawColor(0, 0, 0, alpha)
        surface.DrawRect(x, y, w, h)

        local c = outlineColor or color_white
        surface.SetDrawColor(c.r, c.g, c.b, c.a or 255)

        surface.DrawRect(x, y, 4 * gasp, gasp)
        surface.DrawRect(x + w - 4 * gasp, y, 4 * gasp, gasp)
        surface.DrawRect(x, y + h - gasp, 4 * gasp, gasp)
        surface.DrawRect(x + w - 4 * gasp, y + h - gasp, 4 * gasp, gasp)
        surface.DrawRect(x, y + gasp, gasp, 3 * gasp)
        surface.DrawRect(x + w - gasp, y + gasp, gasp, 3 * gasp)
        surface.DrawRect(x, y + h - 4 * gasp, gasp, 3 * gasp)
        surface.DrawRect(x + w - gasp, y + h - 4 * gasp, gasp, 3 * gasp)
    end

    PLUGIN._DrawCuteRect = DrawCuteRect
    PLUGIN._OutlineLight = outlineLight
    PLUGIN._OutlineDark  = outlineDark
end

local matVignette = Material("mrp/menu_stuff/vignette.png", "noclamp smooth")

local MAX_SLOTS       = 6
local CACHE_TIME      = 1
local tWeaponCache    = {}
for i = 1, MAX_SLOTS do
    tWeaponCache[i] = {}
    tWeaponCache[i + MAX_SLOTS] = 0
end

local iCurSlot        = 0
local iCurPos         = 1
local selTime         = 0
local flNextPrecache  = 0
local iWeaponCount    = 0

local alpha           = 50
local alpha_target    = 0

local nextSound       = 0

local colWep          = Color(235, 235, 235)
local colSlot         = Color(80, 80, 80)
local colSlot2        = Color(50, 50, 50)
local colSlotPos      = Color(60, 60, 60)
local DARK            = Color(50, 50, 50, 100)
local colText         = Color(255, 255, 255)
local BLACK_COL       = Color(0, 0, 0, 150)
local darkOutlineCol  = Color(0, 0, 0, 200)
local lightOutlineCol = Color(160, 160, 160, 255)

local cl_drawhud = GetConVar("cl_drawhud")

local function PrecacheWeps()
    for i = 1, MAX_SLOTS do
        tWeaponCache[i + MAX_SLOTS] = 0
        table.Empty(tWeaponCache[i])
    end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local count = 0
    for _, wep in pairs(ply:GetWeapons() or {}) do
        count = count + 1
        local slot = (wep.GetSlot and wep:GetSlot() or 0) + 1
        if slot <= MAX_SLOTS then
            local len = tWeaponCache[slot + MAX_SLOTS] + 1
            tWeaponCache[slot + MAX_SLOTS] = len
            tWeaponCache[slot][len] = wep
        end
    end
    iWeaponCount = count
    flNextPrecache = UnPredictedCurTime() + CACHE_TIME
end

function PLUGIN:HUDShouldDraw(name)
    if (name == "CHudWeaponSelection") then
        return false
    end
end

function PLUGIN:PlayerBindPress(client, bind, pressed)
    bind = bind:lower()

    if (not pressed) then return end
    if (not (bind:find("invprev") or bind:find("invnext") or bind:find("slot") or bind == "+attack" or bind == "+attack2" or bind == "lastinv")) then
        return
    end

    if (not IsValid(client) or not client:Alive() or client:InVehicle()) then return end

    local wep = client:GetActiveWeapon()
    local bValid = IsValid(wep)

    if (bValid and wep:GetClass() == "weapon_physgun" and client:KeyDown(IN_ATTACK)) then
        return
    end

    if bind == "lastinv" and iWeaponCount > 0 then
        PrecacheWeps()
        iCurSlot = iCurSlot > 0 and (bValid and (wep:GetSlot() + 1) or 0) or 0
        iCurPos = 1

        if bValid then
            local temp = {}
            for _, v in ipairs(client:GetWeapons()) do
                if v:GetSlot() == wep:GetSlot() then
                    temp[#temp + 1] = v
                end
            end
            for k, v in ipairs(temp) do
                if v == wep then
                    iCurPos = k
                    break
                end
            end
        end
        return true
    end

    if (bind == "invnext" or bind == "invprev") and not client:KeyDown(IN_ATTACK) then
        PrecacheWeps()
        if iWeaponCount > 0 then
            if iCurSlot == 0 then
                iCurSlot = (bValid and wep:GetSlot() + 1 or 1)
                iCurPos = 1

                if bValid then
                    local temp = {}
                    for _, v in ipairs(client:GetWeapons()) do
                        if v:GetSlot() == wep:GetSlot() then
                            temp[#temp + 1] = v
                        end
                    end
                    for k, v in ipairs(temp) do
                        if v == wep then
                            iCurPos = k
                            break
                        end
                    end
                end
            end

            alpha_target = 125
            local prev  = (bind == "invprev")
            local dir   = prev and -1 or 1
            local now   = UnPredictedCurTime()

            if selTime > now then
                iCurPos = iCurPos + dir
                PrecacheWeps()

                local curLen = tWeaponCache[iCurSlot + MAX_SLOTS] or 0
                if iCurPos > curLen then
                    iCurSlot = iCurSlot + dir
                    iCurPos  = 1
                elseif prev and iCurPos <= 0 then
                    iCurSlot = iCurSlot - 1
                    if iCurSlot < 1 then iCurSlot = MAX_SLOTS end
                    local cache = tWeaponCache[iCurSlot + MAX_SLOTS]
                    if isnumber(cache) then iCurPos = cache end
                end

                if iCurSlot > MAX_SLOTS then
                    iCurSlot = 1
                    iCurPos  = 1
                end
            else
                iCurSlot = (bValid and wep:GetSlot() + 1 or 1)
            end

            selTime = now + 2

            if nextSound < now then
                nextSound = now + 0.25
                client:EmitSound("helix/ui/rollover.wav", 75, 100, 0.3)
            end
        end
        return true
    end

    if bind:sub(1, 4) == "slot" then
        PrecacheWeps()
        local slot = tonumber(bind:sub(5, 6))

        if (bValid and wep:GetClass() == "mrp_gmod_camera") then
            local target = tWeaponCache[slot] and tWeaponCache[slot][1]
            if IsValid(target) then
                hook.Add("CreateMove", "ixParallaxSelectWeapon", function(cmd)
                    local lp = LocalPlayer()
                    if not IsValid(lp) or not IsValid(target) or target == lp:GetActiveWeapon() then
                        hook.Remove("CreateMove", "ixParallaxSelectWeapon")
                        return
                    end
                    cmd:SelectWeapon(target)
                end)
            end
            client:EmitSound("helix/ui/rollover.wav", 75, 100, 0.3)
            return true
        end

        alpha_target = 125
        selTime = UnPredictedCurTime() + 2

        if slot and slot <= MAX_SLOTS and slot > 0 then
            if slot == iCurSlot then
                iCurPos = iCurPos + 1
                if iCurPos > (tWeaponCache[iCurSlot + MAX_SLOTS] or 0) then
                    iCurPos = 1
                end
            else
                iCurSlot = slot
                iCurPos  = 1
            end
            client:EmitSound("helix/ui/rollover.wav", 75, 100, 0.3)
        end
        return true
    end

    if iCurSlot ~= 0 then
        if bind == "+attack" then
            client:EmitSound("helix/ui/press.wav", 75, 100, 0.3)

            local target = tWeaponCache[iCurSlot] and tWeaponCache[iCurSlot][iCurPos]
            iCurSlot = 0

            if IsValid(target) and target ~= client:GetActiveWeapon() then
                hook.Add("CreateMove", "ixParallaxSelectWeapon", function(cmd)
                    local lp = LocalPlayer()
                    if not IsValid(lp) or not IsValid(target) or target == lp:GetActiveWeapon() then
                        hook.Remove("CreateMove", "ixParallaxSelectWeapon")
                        return
                    end
                    cmd:SelectWeapon(target)
                end)
            end
            return true
        elseif bind == "+attack2" then
            iCurSlot = 0
            return true
        end
    end
end

local function IsBright(c)
    local y = 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
    return y >= 127.5
end

function PLUGIN:HUDPaint()
    if not cl_drawhud:GetBool() then return end

    local lp = LocalPlayer()
    if not IsValid(lp) or not lp:Alive() then return end
    if lp:InVehicle() then return end

    local now = UnPredictedCurTime()
    if flNextPrecache <= now then
        PrecacheWeps()
    end

    alpha = Lerp(FrameTime() * 5, alpha, alpha_target)
    colWep.a = 255

    if iCurSlot == 0 then
        alpha_target = Lerp(FrameTime() * 2, alpha_target, 0)
        return
    end

    if matVignette and not matVignette:IsError() then
        surface.SetMaterial(matVignette)
        surface.SetDrawColor(255, 255, 255, 60)
        surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
    end

    local x0 = 48
    local y0 = 200
    local slotW, slotH = 48, 48
    local yStep = 52
    local rowOffset = 72

    local active = lp:GetActiveWeapon()
    local activeSlot = (IsValid(active) and active:GetSlot() or 0) + 1

    for i = 1, MAX_SLOTS do
        rowOffset = rowOffset + yStep
        local selected = (iCurSlot == i)
        local fill = selected and colSlot or colSlot2
        local len  = tWeaponCache[i + MAX_SLOTS] or 0

        local outlineCol = IsBright(fill) and darkOutlineCol or lightOutlineCol

        if len < 1 then
            fill = Color(DARK.r, DARK.g, DARK.b, 50)
        elseif selected then
            fill = Color(fill.r, fill.g, fill.b, 200)
        else
            fill = Color(fill.r, fill.g, fill.b, 150)
        end

        draw.RoundedBox(4, x0, y0 + rowOffset, slotW, slotH, fill)
        PLUGIN._DrawCuteRect(x0, y0 + rowOffset, slotW, slotH, 2, 0, outlineCol)

        surface.SetFont("WPNSEL_Roboto_24")
        local txt = "[ " .. i .. " ]"
        local tx, ty = x0 + slotW / 2, y0 + rowOffset + slotH / 2
        local a = fill.a
        local labelCol = Color(255, 255, 255, a)

        if activeSlot ~= i then
            labelCol = selected and Color(255, 255, 255, a * 0.9) or Color(255, 255, 255, a * 0.8)
        end

        draw.SimpleText(txt, "WPNSEL_Roboto_24", tx + 2, ty + 2, Color(0, 0, 0, a * 0.5), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(txt, "WPNSEL_Roboto_24", tx,     ty,     labelCol,               TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        if selected and len > 0 then
            local boxOffset = 0
            for j = 1, len do
                local wpn = tWeaponCache[i][j]
                if IsValid(wpn) then
                    surface.SetFont("WPNSEL_Roboto_22")
                    local name = string.sub(language.GetPhrase(wpn:GetPrintName() or "hud.gui.unknown"), 1, 19)
                    local wtw = surface.GetTextSize(name)
                    local slotWidth = math.max(wtw + 24, 140)
                    local bx = x0 + slotW + 8 + boxOffset
                    local by = y0 + rowOffset
                    local selectedWeapon = (iCurPos == j)

                    if selectedWeapon then
                        local bg = Color(colSlotPos.r, colSlotPos.g, colSlotPos.b, 200)
                        draw.RoundedBox(4, bx, by, slotWidth, slotH, bg)
                        PLUGIN._DrawCuteRect(bx, by, slotWidth, slotH, 2, 0, outlineCol)

                        local ammoType = wpn:GetPrimaryAmmoType()
                        if ammoType == -1 or wpn:GetClass() == "weapon_physcannon" then
                            draw.SimpleText("∞", "WPNSEL_Roboto_20", bx + 8 + 2, by + slotH / 2 + 2, Color(BLACK_COL.r, BLACK_COL.g, BLACK_COL.b, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                            draw.SimpleText("∞", "WPNSEL_Roboto_20", bx + 8,     by + slotH / 2,     color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                        else
                            local ammo = lp:GetAmmoCount(ammoType)
                            local clip = wpn:Clip1()
                            local txtAmmo = ""
                            if clip == -1 then
                                txtAmmo = (ammo == -1) and "NO AMMO" or tostring(ammo)
                            else
                                txtAmmo = string.format("%d/%d", clip, ammo)
                            end
                            draw.SimpleText(txtAmmo, "WPNSEL_Roboto_20", bx + 8 + 2, by + slotH / 2 + 2, Color(BLACK_COL.r, BLACK_COL.g, BLACK_COL.b, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                            draw.SimpleText(txtAmmo, "WPNSEL_Roboto_20", bx + 8,     by + slotH / 2,     color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                        end
                    end

                    draw.SimpleText(name, "WPNSEL_Roboto_22", bx + 8 + 2, by + 2 + 2, Color(0, 0, 0, 50), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    draw.SimpleText(name, "WPNSEL_Roboto_22", bx + 8,     by + 2,     Color(255, 255, 255, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

                    boxOffset = boxOffset + slotWidth + 8
                end
            end
        end
    end
end

function PLUGIN:Think()
    local client = LocalPlayer()
    if not IsValid(client) or not client:Alive() then
        iCurSlot = 0
        alpha_target = 0
    end
end

function PLUGIN:ScoreboardShow()
    iCurSlot = 0
    alpha_target = 0
end
