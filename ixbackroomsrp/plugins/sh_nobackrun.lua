PLUGIN.name = "No Backward Running"
PLUGIN.author = "Devizion"
PLUGIN.description = "Disables running backwards."

-- Hook into player movement
function PLUGIN:Move(client, mv)
    if client:IsValid() and client:Alive() then
        local velocity = mv:GetVelocity()
        local forwardSpeed = velocity:Dot(client:GetForward())

        -- Check if the player is moving backwards
        if forwardSpeed < 0 then
            local isSprinting = mv:KeyDown(IN_SPEED)

            -- If the player is sprinting and moving backwards, limit the backward speed to walking speed
            if isSprinting then
                mv:SetForwardSpeed(mv:GetMaxSpeed() / 2) -- Set to walking speed
            end
        end
    end
end

-- Prevent the player from sprinting backwards
function PLUGIN:StartCommand(client, cmd)
    if client:IsValid() and client:Alive() then
        if cmd:KeyDown(IN_SPEED) and cmd:GetForwardMove() < 0 then
            cmd:SetButtons(cmd:GetButtons() - IN_SPEED) -- Remove the sprint button press
        end
    end
end
