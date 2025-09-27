local PLUGIN = PLUGIN
PLUGIN.name = "Visual"
PLUGIN.author = "nicwtf"
PLUGIN.description = "Color correction, viewbob, and viewroll."

if CLIENT then
    hook.Add("RenderScreenspaceEffects", "ixVisualPostFX", function()
        DrawColorModify({
            ["$pp_colour_brightness"] = -0.18,
            ["$pp_colour_contrast"]   = 1,
            ["$pp_colour_colour"]     = 0.4
        })
    end)

    local rollAmount = 2
    local smoothRoll = 0

    local bobRunIntensity = 0.6
    local walkBobIntensity = 0.2
    local bobRollIntensity = 0.1
    local bobSpeed = 6

    local currentBobFactor = 0

    hook.Add("CalcView", "ixVisualViewEffects", function(ply, pos, angles, fov)
        if not IsValid(ply) or not ply:Alive() or ply:InVehicle() then return end
        if ply:GetMoveType() == MOVETYPE_NOCLIP then return end

        local view = {}
        view.origin = pos
        view.fov = fov
        view.angles = angles

        if ply:OnGround() then
            local forward = ply:KeyDown(IN_FORWARD) or ply:KeyDown(IN_BACK)
            local side = ply:KeyDown(IN_MOVERIGHT) or ply:KeyDown(IN_MOVELEFT)

            local targetRoll = 0
            if side then
                if forward then
                    targetRoll = rollAmount * 0.5 * (ply:KeyDown(IN_MOVERIGHT) and 1 or -1)
                else
                    targetRoll = rollAmount * (ply:KeyDown(IN_MOVERIGHT) and 1 or -1)
                end
            end

            smoothRoll = Lerp(FrameTime() * 5, smoothRoll, targetRoll)
            view.angles.roll = view.angles.roll + smoothRoll
        end

        local velocity = ply:GetVelocity():Length2D()
        local runSpeed = ply:GetRunSpeed()
        local targetBobFactor = math.Clamp(velocity / runSpeed, 0, 1)
        currentBobFactor = Lerp(FrameTime() * 5, currentBobFactor, targetBobFactor)

        if currentBobFactor > 0 and ply:OnGround() then
            local time = CurTime() * bobSpeed

            local intensity
            if currentBobFactor < 0.5 then
                intensity = walkBobIntensity
            else
                intensity = bobRunIntensity
            end

            local verticalBob = math.sin(time * 2) * intensity * currentBobFactor
            verticalBob = verticalBob * (0.7 + 0.3 * math.sin(time * 3))

            local forwardSway = math.cos(time * 3) * intensity * 0.25 * currentBobFactor
            local bobRoll = math.cos(time * 2) * bobRollIntensity * currentBobFactor

            view.angles.pitch = view.angles.pitch + verticalBob
            view.angles.yaw = view.angles.yaw + forwardSway
            view.angles.roll = view.angles.roll + bobRoll
        end

        return view
    end)
end
