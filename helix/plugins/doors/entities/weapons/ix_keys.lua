AddCSLuaFile()

SWEP.PrintName = "Keys"
SWEP.Slot = 0
SWEP.SlotPos = 0
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.Author = "Chessnut, nicwtf, WebKnight"
SWEP.Instructions = "Primary Fire: Lock/Push\nSecondary Fire: Unlock/Block\nReload: Holster"
SWEP.Purpose = "Interact with the world using your hands and keys."
SWEP.Drop = false
SWEP.ViewModelFOV = 80
SWEP.ViewModelFlip = false
SWEP.AnimPrefix = "wbk"
SWEP.ViewTranslation = 4
SWEP.BobScale = 1.3
SWEP.SwayScale = 1.3
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Primary.Damage = 5
SWEP.Primary.Delay = 0.75
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.ViewModel = Model("models/weapons/c_arms_wbk_unarmed.mdl")
SWEP.WorldModel = ""
SWEP.UseHands = true
SWEP.HoldType = "normal"
SWEP.AllowViewAttachment = true
SWEP.HitDistance = 0
SWEP.LowerAngles = Angle(0, 0, 0)

function SWEP:SetupDataTables()
	self:NetworkVar("Float", 1, "NextIdle")
end

function SWEP:Initialize()
	self.canWbkUseJumpAnimoutlast = true
	self.isInBlockDam = false
	self:SetHoldType(self.HoldType)
end

function SWEP:UpdateNextIdle()
	local vm = self.Owner:GetViewModel()
	if IsValid(vm) then
		self:SetNextIdle(CurTime() + vm:SequenceDuration() / vm:GetPlaybackRate())
	end
end

function SWEP:GetSequenceName(sequenceID)
	local vm = self.Owner:GetViewModel()
	if IsValid(vm) then
		return vm:GetSequenceName(sequenceID)
	end
	return nil
end

function SWEP:DoTrace()
	local owner = self:GetOwner()
	if !IsValid(owner) then return end
	local data = {
		start = owner:GetShootPos(),
		endpos = owner:GetShootPos() + owner:GetAimVector() * 96,
		filter = owner
	}
	return util.TraceLine(data).Entity
end

function SWEP:Think()
	if not IsValid(self) then return end
	if (!IsValid(self:GetOwner())) then return end
	local vm = self.Owner:GetViewModel()
	if !IsValid(vm) then return end
	local curtime = CurTime()
	local idletime = self:GetNextIdle()
	local owner = self.Owner

	if (owner:KeyPressed(IN_JUMP) and owner:WaterLevel() < 2 and self.canWbkUseJumpAnimoutlast) then
		self.canWbkUseJumpAnimoutlast = false
		vm:SendViewModelMatchingSequence(vm:LookupSequence(owner:GetVelocity():Length() > owner:GetRunSpeed() - 10 and "WbkIdle_JumpRun" or "WbkIdle_JumpStand"))
		owner:ViewPunch(Angle(-1.5, 0, 0))
		self:UpdateNextIdle()
	elseif owner:OnGround() and !self.canWbkUseJumpAnimoutlast then
		self.canWbkUseJumpAnimoutlast = true
		owner:ViewPunch(Angle(11.5, 0, 0))
		if (self:GetSequenceName(vm:GetSequence()) == "WbKInAir") then
			vm:SendViewModelMatchingSequence(vm:LookupSequence("WbkIdle_Lowered"))
		end
	end

	if (!owner:OnGround() and owner:WaterLevel() == 0) then
		if owner:GetMoveType() == 9 then
			vm:SendViewModelMatchingSequence(vm:LookupSequence("WbkIdle_Lowered"))
			self:UpdateNextIdle()
		elseif (idletime > 0 and curtime > idletime) then
			owner:ViewPunch(Angle(-0.5, 0, 0))
			vm:SendViewModelMatchingSequence(vm:LookupSequence("WbKInAir"))
			self:UpdateNextIdle()
		end
	end

	local isCrouchAnim = self:GetSequenceName(vm:GetSequence())
	if owner:Crouching() and owner:OnGround() and isCrouchAnim != "WbkCrouch" and isCrouchAnim != "WbkDefendHimself" and isCrouchAnim != "WbkPush" then
		vm:SendViewModelMatchingSequence(vm:LookupSequence("WbkCrouch"))
	end

	if (idletime > 0 and curtime > idletime and !owner:Crouching()) then
		if owner:WaterLevel() >= 2 then
			vm:SendViewModelMatchingSequence(vm:LookupSequence(owner:IsSprinting() and "WbKInSwim" or "WbkIdle_Lowered"))
		elseif owner:OnGround() then
			vm:SendViewModelMatchingSequence(vm:LookupSequence(owner:GetVelocity():Length() > owner:GetRunSpeed() - 10 and "WbKSprint" or "WbkIdle_Lowered"))
		end
		self:UpdateNextIdle()
	end
end

function SWEP:ToggleLock(door, state)
	if !IsValid(self.Owner) or self.Owner:GetPos():Distance(door:GetPos()) > 96 then return end
	if door:IsDoor() then
		local partner = door:GetDoorPartner()
		local sound = state and "doors/door_latch3.wav" or "doors/door_latch1.wav"
		door:Fire(state and "lock" or "unlock")
		if IsValid(partner) then partner:Fire(state and "lock" or "unlock") end
		self.Owner:EmitSound(sound)
		hook.Run(state and "PlayerLockedDoor" or "PlayerUnlockedDoor", self.Owner, door, partner)
	elseif door:IsVehicle() then
		door:Fire(state and "lock" or "unlock")
		if door.IsSimfphyscar then door.IsLocked = state end
		self.Owner:EmitSound(state and "doors/door_latch3.wav" or "doors/door_latch1.wav")
		hook.Run(state and "PlayerLockedVehicle" or "PlayerUnlockedVehicle", self.Owner, door)
	end
end

function SWEP:PrimaryAttack()
	if !IsFirstTimePredicted() then return end
	local owner = self:GetOwner()
	local vm = owner:GetViewModel()
	local entity = self:DoTrace()

	if IsValid(entity) and ((entity:IsDoor() and entity:CheckDoorAccess(owner)) or (entity:IsVehicle() and entity.CPPIGetOwner and entity:CPPIGetOwner() == owner)) then
		local time = ix.config.Get("doorLockTime", 1)
		local time2 = math.max(time, 1)
		self:SetNextPrimaryFire(CurTime() + time2)
		self:SetNextSecondaryFire(CurTime() + time2)
		owner:SetAction("@locking", time, function() self:ToggleLock(entity, true) end)
		return
	end

	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
	local phys = IsValid(entity) and entity:GetPhysicsObject() or nil
	if IsValid(phys) and owner:GetPos():Distance(entity:GetPos()) <= 80 then
		owner:SetAnimation(PLAYER_ATTACK1)
		local randomsounds = {"physics/body/body_medium_impact_soft1.wav", "physics/body/body_medium_impact_soft2.wav", "physics/body/body_medium_impact_soft3.wav", "physics/body/body_medium_impact_soft4.wav", "physics/body/body_medium_impact_soft5.wav", "physics/body/body_medium_impact_soft6.wav", "physics/body/body_medium_impact_soft7.wav"}
		entity:EmitSound(randomsounds[math.random(1, 7)])
		vm:SendViewModelMatchingSequence(vm:LookupSequence("WbkPush"))
		self:UpdateNextIdle()
		owner:ViewPunch(Angle(-10, 0, 0))
		if SERVER then
			if entity:IsNPC() and (entity:GetClass() == "npc_headcrab_fast" or entity:GetClass() == "npc_headcrab_black" or entity:GetClass() == "npc_headcrab") then
				local dmg = DamageInfo()
				dmg:SetDamage(math.random(5, 10))
				dmg:SetAttacker(owner)
				dmg:SetInflictor(self)
				dmg:SetDamageForce(owner:GetAimVector() * 2300)
				dmg:SetDamageType(DMG_CLUB)
				entity:TakeDamageInfo(dmg)
				owner:ViewPunch(Angle(-10, 0, 0))
			else
				local velAng = owner:EyeAngles():Forward()
				phys:SetVelocity(velAng * (phys:GetMass() >= 70 and 100 or 200))
			end
		end
		return
	end
	
	if SERVER and ix.plugin.Get("stamina") then
		local staminaUse = ix.config.Get("punchStamina", 0)
		if staminaUse > 0 and owner:GetLocalVar("stm", 0) < staminaUse then return end
		owner:ConsumeStamina(staminaUse)
	end
	owner:EmitSound("npc/vort/claw_swing" .. math.random(1, 2) .. ".wav")
	owner:SetAnimation(PLAYER_ATTACK1)
	owner:ViewPunch(Angle(2, 5, 0.125))
	vm:SendViewModelMatchingSequence(vm:LookupSequence("WbkPush"))
	self:UpdateNextIdle()
	owner:ViewPunch(Angle(-10, 0, 0))
	timer.Simple(0.055, function()
		if IsValid(self) and IsValid(owner) then
			local damage = self.Primary.Damage
			local context = { damage = damage }
			local result = hook.Run("GetPlayerPunchDamage", owner, damage, context)
			damage = result or context.damage
			owner:LagCompensation(true)
			local trace = self:DoTrace()
			if SERVER and IsValid(trace) then
				local damageInfo = DamageInfo()
				damageInfo:SetAttacker(owner)
				damageInfo:SetInflictor(self)
				damageInfo:SetDamage(damage)
				damageInfo:SetDamageType(DMG_GENERIC)
				damageInfo:SetDamagePosition(trace.HitPos)
				damageInfo:SetDamageForce(owner:GetAimVector() * 1024)
				trace:DispatchTraceAttack(damageInfo, owner:GetShootPos(), owner:GetShootPos() + owner:GetAimVector() * 96)
				owner:EmitSound("physics/body/body_medium_impact_hard" .. math.random(1, 6) .. ".wav", 80)
			end
			hook.Run("PlayerThrowPunch", owner, trace)
			owner:LagCompensation(false)
		end
	end)
end

function SWEP:SecondaryAttack()
	if !IsFirstTimePredicted() then return end
	local owner = self:GetOwner()
	local vm = owner:GetViewModel()
	local entity = self:DoTrace()

	if IsValid(entity) and ((entity:IsDoor() and entity:CheckDoorAccess(owner)) or (entity:IsVehicle() and entity.CPPIGetOwner and entity:CPPIGetOwner() == owner)) then
		local time = ix.config.Get("doorLockTime", 1)
		local time2 = math.max(time, 1)
		self:SetNextPrimaryFire(CurTime() + time2)
		self:SetNextSecondaryFire(CurTime() + time2)
		owner:SetAction("@unlocking", time, function() self:ToggleLock(entity, false) end)
	else
		if owner:OnGround() and self:GetSequenceName(vm:GetSequence()) != "WbkDefendHimself" then
			vm:SendViewModelMatchingSequence(vm:LookupSequence("WbkDefendHimself"))
			self:SetHoldType("slam")
			self.isInBlockDam = true
			timer.Simple(1.35, function()
				if IsValid(self) then
					self:SetHoldType("normal")
					self.isInBlockDam = false
				end
			end)
			self:UpdateNextIdle()
			owner:ViewPunch(Angle(-1.4, 0, 1.5))
			timer.Simple(0.3, function() if IsValid(owner) then owner:ViewPunch(Angle(1.4, 0, 1.5)) end end)
			timer.Simple(0.6, function() if IsValid(owner) then owner:ViewPunch(Angle(-1.4, 0, 1.5)) end end)
			timer.Simple(0.9, function() if IsValid(owner) then owner:ViewPunch(Angle(1.4, 0, 1.5)) end end)
			timer.Simple(1.2, function() if IsValid(owner) then owner:ViewPunch(Angle(-1.4, 0, 1.5)) end end)
			timer.Simple(1.5, function() if IsValid(owner) then owner:ViewPunch(Angle(1.4, 0, 1.5)) end end)
		end
	end
end

function SWEP:Holster()
	return true
end

function SWEP:Deploy()
	self.canWbkUseJumpAnimoutlast = true
	self.isInBlockDam = false
	self:SetHoldType("normal")
	local vm = self.Owner:GetViewModel()
	if IsValid(vm) then
		vm:SetWeaponModel("models/weapons/c_arms_wbk_unarmed.mdl", self)
		vm:SendViewModelMatchingSequence(vm:LookupSequence("WbkIdle_Lowered"))
	end
	self:UpdateNextIdle()
end
