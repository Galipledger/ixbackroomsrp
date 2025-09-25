AddCSLuaFile()

SWEP.PrintName = "Hands"
SWEP.Slot = 0
SWEP.SlotPos = 0
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.Author = "Chessnut, nicwtf, WebKnight"
SWEP.Instructions = [[Primary Fire: Throw/Punch
Secondary Fire: Knock/Pickup/Block
Reload: Drop]]
SWEP.Purpose = "Hitting things and picking up objects."
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
SWEP.Primary.Ammo = ""
SWEP.Primary.Damage = 5
SWEP.Primary.Delay = 0.75
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""
SWEP.Secondary.Delay = 0.5
SWEP.ViewModel = Model("models/weapons/c_arms_wbk_unarmed.mdl")
SWEP.WorldModel = ""
SWEP.UseHands = true
SWEP.HoldType = "passive"
SWEP.AllowViewAttachment = true
SWEP.holdDistance = 64
SWEP.maxHoldDistance = 96
SWEP.maxHoldStress = 4000
SWEP.HitDistance = 0
SWEP.LoweredAngle = Angle(-45, 0, 0)


function SWEP:SetupDataTables()
	self:NetworkVar("Float", 1, "NextIdle")
	self:NetworkVar("Float", 2, "NextIdleCrouch")
end

function SWEP:Initialize()
	self.canWbkUseJumpAnimoutlast = true
	self.isInBlockDam = false
	self:SetHoldType(self.HoldType)
	self.maxHoldDistanceSquared = self.maxHoldDistance ^ 2
	self.heldObjectAngle = Angle(angle_zero)
end

function SWEP:Deploy()
	if (!IsValid(self:GetOwner())) then return end
	self.canWbkUseJumpAnimoutlast = true
	self.isInBlockDam = false
	self:SetHoldType("passive")
	local vm = self.Owner:GetViewModel()
	if IsValid(vm) then
		vm:SendViewModelMatchingSequence(vm:LookupSequence("WbkIdle_Lowered"))
	end
	self:UpdateNextIdle()
	self:DropObject()
	return true
end

function SWEP:UpdateNextIdle()
	if (!IsValid(self.Owner)) then return end
	local vm = self.Owner:GetViewModel()
	if IsValid(vm) then
		self:SetNextIdle(CurTime() + vm:SequenceDuration() / vm:GetPlaybackRate())
	end
end

function SWEP:GetSequenceName(sequenceID)
	if (!IsValid(self.Owner)) then return end
	local vm = self.Owner:GetViewModel()
	if IsValid(vm) then
		return vm:GetSequenceName(sequenceID)
	end
	return nil
end

if (CLIENT) then
	hook.Add("CreateMove", "wbkHandsCreateMove", function(cmd)
		if (IsValid(LocalPlayer()) and LocalPlayer():GetLocalVar("bIsHoldingObject", false) and cmd:KeyDown(IN_ATTACK2)) then
			cmd:ClearMovement()
			local angle = RenderAngles()
			angle.z = 0
			cmd:SetViewAngles(angle)
		end
	end)
end

function SWEP:Think()
	if (!IsValid(self) or !IsValid(self:GetOwner())) then return end
	local vm = self.Owner:GetViewModel()
	if !IsValid(vm) then return end
	
	if (SERVER and self.Owner:GetActiveWeapon() == self and !self:IsHoldingObject() and !self.isInBlockDam) then
		self.Owner:SetAnimation(ACT_MP_STAND_IDLE)
	end

	local curtime = CurTime()
	local idletime = self:GetNextIdle()
	
	if (self.Owner:KeyPressed(IN_JUMP) and self.Owner:WaterLevel() < 2 and self.canWbkUseJumpAnimoutlast == true) then
		self.canWbkUseJumpAnimoutlast = false
		if self.Owner:GetVelocity():Length() > self.Owner:GetRunSpeed() - 10 then
			vm:SendViewModelMatchingSequence(vm:LookupSequence("WbkIdle_JumpRun"))
		else
			vm:SendViewModelMatchingSequence(vm:LookupSequence("WbkIdle_JumpStand"))
		end
		self.Owner:ViewPunch(Angle(-1.5, 0, 0))
		self:UpdateNextIdle()
	end
	
	if self.Owner:OnGround() and !self.canWbkUseJumpAnimoutlast then
		self.canWbkUseJumpAnimoutlast = true
		self.Owner:ViewPunch(Angle(11.5, 0, 0))
		local currentInpectAnim = self:GetSequenceName(vm:GetSequence())
		if (currentInpectAnim == "WbKInAir") then
			vm:SendViewModelMatchingSequence(vm:LookupSequence("WbkIdle_Lowered"))
		end
	end
	
	if (!self.Owner:OnGround() and self.Owner:WaterLevel() == 0) then
		if self.Owner:GetMoveType() == 9 then
			vm:SendViewModelMatchingSequence(vm:LookupSequence("WbkIdle_Lowered"))
			self:UpdateNextIdle()
		else
			self.Owner:ViewPunch(Angle(-0.5, 0, 0))
			if (idletime and CurTime() > idletime) then
				vm:SendViewModelMatchingSequence(vm:LookupSequence("WbKInAir"))
				self:UpdateNextIdle()
			end
		end
	end

	local isCrouchAnim = self:GetSequenceName(vm:GetSequence())
	if self.Owner:Crouching() and self.Owner:OnGround() and isCrouchAnim != "WbkCrouch" and isCrouchAnim != "WbkDefendHimself" and isCrouchAnim != "WbkPush" then
		vm:SendViewModelMatchingSequence(vm:LookupSequence("WbkCrouch"))
	end

	if (idletime and CurTime() > idletime and !self.Owner:Crouching()) then
		if self.Owner:WaterLevel() >= 2 then
			if self.Owner:IsSprinting() then
				vm:SendViewModelMatchingSequence(vm:LookupSequence("WbKInSwim"))
				self:UpdateNextIdle()
			else
				vm:SendViewModelMatchingSequence(vm:LookupSequence("WbkIdle_Lowered"))
				self:UpdateNextIdle()
			end
		else
			if self.Owner:OnGround() then
				if self.Owner:GetVelocity():Length() > self.Owner:GetRunSpeed() - 10 then
					vm:SendViewModelMatchingSequence(vm:LookupSequence("WbKSprint"))
					self:UpdateNextIdle()
				else
					vm:SendViewModelMatchingSequence(vm:LookupSequence("WbkIdle_Lowered"))
					self:UpdateNextIdle()
				end
			end
		end
	end

	if (SERVER and self:IsHoldingObject()) then
		local physics = self:GetHeldPhysicsObject()
		if (!IsValid(physics)) then self:DropObject() return end
		local bIsRagdoll = self.heldEntity:IsRagdoll()
		local holdDistance = bIsRagdoll and self.holdDistance * 0.5 or self.holdDistance
		local targetLocation = self:GetOwner():GetShootPos() + self:GetOwner():GetForward() * holdDistance
		
		if (bIsRagdoll) then
			targetLocation.z = math.min(targetLocation.z, self:GetOwner():GetShootPos().z - 32)
		end

		if (physics:GetPos():DistToSqr(targetLocation) > self.maxHoldDistanceSquared) then
			self:DropObject()
		else
			local physicsObject = self.holdEntity:GetPhysicsObject()
			local currentPlayerAngles = self:GetOwner():EyeAngles()
			local client = self:GetOwner()

			if (client:KeyDown(IN_ATTACK2)) then
				local cmd = client:GetCurrentCommand()
				self.heldObjectAngle:RotateAroundAxis(currentPlayerAngles:Forward(), cmd:GetMouseX() / 15)
				self.heldObjectAngle:RotateAroundAxis(currentPlayerAngles:Right(), cmd:GetMouseY() / 15)
			end

			self.lastPlayerAngles = self.lastPlayerAngles or currentPlayerAngles
			self.heldObjectAngle.y = self.heldObjectAngle.y - math.AngleDifference(self.lastPlayerAngles.y, currentPlayerAngles.y)
			self.lastPlayerAngles = currentPlayerAngles

			physicsObject:Wake()
			physicsObject:ComputeShadowControl({
				secondstoarrive = 0.01,
				pos = targetLocation,
				angle = self.heldObjectAngle,
				maxangular = 256,
				maxangulardamp = 10000,
				maxspeed = 256,
				maxspeeddamp = 10000,
				dampfactor = 0.8,
				teleportdistance = self.maxHoldDistance * 0.75,
				deltatime = FrameTime()
			})

			if (physics:GetStress() > self.maxHoldStress) then
				self:DropObject()
			end
		end
	end

	if (SERVER and !IsValid(self.heldEntity) and self:GetOwner():GetLocalVar("bIsHoldingObject", true)) then
		self:GetOwner():SetLocalVar("bIsHoldingObject", false)
		self:SetHoldType("passive")
	end
end

function SWEP:GetHeldPhysicsObject()
	return IsValid(self.heldEntity) and self.heldEntity:GetPhysicsObject() or nil
end

function SWEP:CanHoldObject(entity)
	local physics = entity:GetPhysicsObject()
	return IsValid(physics) and (physics:GetMass() <= ix.config.Get("maxHoldWeight", 100) and physics:IsMoveable()) and !self:IsHoldingObject() and !IsValid(entity.ixHeldOwner) and hook.Run("CanPlayerHoldObject", self:GetOwner(), entity)
end

function SWEP:IsHoldingObject()
	return IsValid(self.heldEntity) and IsValid(self.heldEntity.ixHeldOwner) and self.heldEntity.ixHeldOwner == self:GetOwner()
end

function SWEP:PickupObject(entity)
	if (self:IsHoldingObject() or !IsValid(entity) or !IsValid(entity:GetPhysicsObject())) then return end
	local physics = entity:GetPhysicsObject()
	physics:EnableGravity(false)
	physics:AddGameFlag(FVPHYSICS_PLAYER_HELD)
	entity.ixHeldOwner = self:GetOwner()
	entity.ixCollisionGroup = entity:GetCollisionGroup()
	entity:StartMotionController()
	entity:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	self.heldObjectAngle = entity:GetAngles()
	self.heldEntity = entity
	self.holdEntity = ents.Create("prop_physics")
	self.holdEntity:SetPos(self.heldEntity:LocalToWorld(self.heldEntity:OBBCenter()))
	self.holdEntity:SetAngles(self.heldEntity:GetAngles())
	self.holdEntity:SetModel("models/weapons/w_bugbait.mdl")
	self.holdEntity:SetOwner(self:GetOwner())
	self.holdEntity:SetNoDraw(true)
	self.holdEntity:SetNotSolid(true)
	self.holdEntity:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	self.holdEntity:DrawShadow(false)
	self.holdEntity:Spawn()
	local trace = self:GetOwner():GetEyeTrace()
	local physicsObject = self.holdEntity:GetPhysicsObject()
	if (IsValid(physicsObject)) then
		physicsObject:SetMass(2048)
		physicsObject:SetDamping(0, 1000)
		physicsObject:EnableGravity(false)
		physicsObject:EnableCollisions(false)
		physicsObject:EnableMotion(false)
	end
	if (trace.Entity:IsRagdoll()) then
		local tracedEnt = trace.Entity
		self.holdEntity:SetPos(tracedEnt:GetBonePosition(tracedEnt:TranslatePhysBoneToBone(trace.PhysicsBone)))
	end
	self.constraint = constraint.Weld(self.holdEntity, self.heldEntity, 0, trace.Entity:IsRagdoll() and trace.PhysicsBone or 0, 0, true, true)
end

function SWEP:DropObject(bThrow)
	if (!IsValid(self.heldEntity) or self.heldEntity.ixHeldOwner != self:GetOwner()) then return end
	self.lastPlayerAngles = nil
	self:GetOwner():SetLocalVar("bIsHoldingObject", false)
	if IsValid(self.constraint) then self.constraint:Remove() end
	if IsValid(self.holdEntity) then self.holdEntity:Remove() end
	self.heldEntity:StopMotionController()
	self.heldEntity:SetCollisionGroup(self.heldEntity.ixCollisionGroup or COLLISION_GROUP_NONE)
	local physics = self:GetHeldPhysicsObject()
	if IsValid(physics) then
		physics:EnableGravity(true)
		physics:Wake()
		physics:ClearGameFlag(FVPHYSICS_PLAYER_HELD)
	end
	if (bThrow) then
		timer.Simple(0, function()
			if (IsValid(physics) and IsValid(self:GetOwner())) then
				physics:AddGameFlag(FVPHYSICS_WAS_THROWN)
				physics:ApplyForceCenter(self:GetOwner():GetAimVector() * ix.config.Get("throwForce", 732))
			end
		end)
	end
	self.heldEntity.ixHeldOwner = nil
	self.heldEntity.ixCollisionGroup = nil
	self.heldEntity = nil
end

function SWEP:PlayPickupSound(surfaceProperty)
	local result = "Flesh.ImpactSoft"
	if (surfaceProperty != nil) then
		local surfaceName = util.GetSurfacePropName(surfaceProperty)
		local soundName = surfaceName:gsub("^metal$", "SolidMetal") .. ".ImpactSoft"
		if (sound.GetProperties(soundName)) then
			result = soundName
		end
	end
	self:GetOwner():EmitSound(result, 75, 100, 40)
end

function SWEP:OnRemove()
	if (SERVER) then self:DropObject() end
end

function SWEP:OwnerChanged()
	if (SERVER) then self:DropObject() end
end

function SWEP:PrimaryAttack()
	if (!IsFirstTimePredicted()) then return end
	if (SERVER and self:IsHoldingObject()) then self:DropObject(true) return end
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
	if (hook.Run("CanPlayerThrowPunch", self:GetOwner()) == false) then return end
	local data = {}
	data.start = self:GetOwner():GetShootPos()
	data.endpos = data.start + self:GetOwner():GetAimVector() * 84
	data.filter = self:GetOwner()
	local trace = util.TraceLine(data)
	local entity = trace.Entity
	local phys = IsValid(entity) and entity:GetPhysicsObject() or nil

	if IsValid(phys) and self.Owner:GetPos():Distance(trace.Entity:GetPos()) <= 80 then
		self.Owner:SetAnimation(PLAYER_ATTACK1)
		local randomsounds = {"physics/body/body_medium_impact_soft1.wav", "physics/body/body_medium_impact_soft2.wav", "physics/body/body_medium_impact_soft3.wav", "physics/body/body_medium_impact_soft4.wav", "physics/body/body_medium_impact_soft5.wav", "physics/body/body_medium_impact_soft6.wav", "physics/body/body_medium_impact_soft7.wav"}
		entity:EmitSound(randomsounds[math.floor(math.random(7))])
		local vm = self.Owner:GetViewModel()
		if IsValid(vm) then
			vm:SendViewModelMatchingSequence(vm:LookupSequence("WbkPush"))
		end
		self:UpdateNextIdle()
		self.Owner:ViewPunch(Angle(-10, 0, 0))
		if SERVER then
			if entity:IsNPC() and (entity:GetClass() == "npc_headcrab_fast" or entity:GetClass() == "npc_headcrab_black" or entity:GetClass() == "npc_headcrab") then
				local dmg = DamageInfo()
				dmg:SetDamage(math.random(5, 10))
				dmg:SetAttacker(self.Owner)
				dmg:SetInflictor(self)
				dmg:SetDamageForce(self.Owner:GetAimVector() * 2300)
				dmg:SetDamageType(DMG_CLUB)
				entity:TakeDamageInfo(dmg)
				self.Owner:ViewPunch(Angle(-10, 0, 0))
			else
				local velAng = self.Owner:EyeAngles():Forward()
				phys:SetVelocity(velAng * (phys:GetMass() >= 70 and 100 or 200))
			end
		end
	end

	if SERVER and (!IsValid(entity) or !IsValid(phys) or self.Owner:GetPos():Distance(entity:GetPos()) > 80) then
		if (ix.plugin.Get("stamina")) then
			local staminaUse = ix.config.Get("punchStamina")
			if (staminaUse > 0) then
				local value = self:GetOwner():GetLocalVar("stm", 0) - staminaUse
				if (value < 0) then return end
				if (SERVER) then self:GetOwner():ConsumeStamina(staminaUse) end
			end
		end
		self:GetOwner():EmitSound("npc/vort/claw_swing" .. math.random(1, 2) .. ".wav")
		self:GetOwner():SetAnimation(PLAYER_ATTACK1)
		self:GetOwner():ViewPunch(Angle(2, 5, 0.125))
		local vm = self:GetOwner():GetViewModel()
		if IsValid(vm) then
			vm:SendViewModelMatchingSequence(vm:LookupSequence("WbkPush"))
		end
		self:UpdateNextIdle()
		self:GetOwner():ViewPunch(Angle(-10, 0, 0))
		timer.Simple(0.055, function()
			if (IsValid(self) and IsValid(self:GetOwner())) then
				local damage = self.Primary.Damage
				local context = { damage = damage }
				local result = hook.Run("GetPlayerPunchDamage", self:GetOwner(), damage, context)
				if (result != nil) then damage = result else damage = context.damage end
				self:GetOwner():LagCompensation(true)
				local data = {}
				data.start = self:GetOwner():GetShootPos()
				data.endpos = data.start + self:GetOwner():GetAimVector() * 96
				data.filter = self:GetOwner()
				local trace = util.TraceLine(data)
				if (SERVER and trace.Hit) then
					local entity = trace.Entity
					if (IsValid(entity)) then
						local damageInfo = DamageInfo()
						damageInfo:SetAttacker(self:GetOwner())
						damageInfo:SetInflictor(self)
						damageInfo:SetDamage(damage)
						damageInfo:SetDamageType(DMG_GENERIC)
						damageInfo:SetDamagePosition(trace.HitPos)
						damageInfo:SetDamageForce(self:GetOwner():GetAimVector() * 1024)
						entity:DispatchTraceAttack(damageInfo, data.start, data.endpos)
						self:GetOwner():EmitSound("physics/body/body_medium_impact_hard" .. math.random(1, 6) .. ".wav", 80)
					end
				end
				hook.Run("PlayerThrowPunch", self:GetOwner(), trace)
				self:GetOwner():LagCompensation(false)
			end
		end)
	end
end

function SWEP:SecondaryAttack()
	if (!IsFirstTimePredicted()) then return end
	local owner = self:GetOwner()
	local vm = owner:GetViewModel()
	if (self:IsHoldingObject()) then return end
	local data = {start = owner:GetShootPos(), endpos = owner:GetShootPos() + owner:GetAimVector() * 84, filter = {self, owner}}
	local trace = util.TraceLine(data)
	local entity = trace.Entity

	if (SERVER) then
		local interacted = false
		if (IsValid(entity) and !self.isInBlockDam) then
			if (entity:IsDoor()) then
				if (hook.Run("CanPlayerKnock", owner, entity) == false) then return end
				owner:ViewPunch(Angle(-1.3, 1.8, 0))
				owner:EmitSound("physics/wood/wood_crate_impact_hard" .. math.random(2, 3) .. ".wav")
				owner:SetAnimation(PLAYER_ATTACK1)
				self:SetNextSecondaryFire(CurTime() + 0.4)
				self:SetNextPrimaryFire(CurTime() + 1)
				interacted = true
			elseif (entity:IsPlayer() and ix.config.Get("allowPush", true)) then
				local direction = owner:GetAimVector() * (300 + (owner:GetCharacter():GetAttribute("str", 0) * 3))
				direction.z = 0
				entity:SetVelocity(direction)
				owner:EmitSound("Weapon_Crossbow.BoltHitBody")
				self:SetNextSecondaryFire(CurTime() + 1.5)
				self:SetNextPrimaryFire(CurTime() + 1.5)
				interacted = true
			elseif (!entity:IsNPC() and self:CanHoldObject(entity)) then
				owner:SetLocalVar("bIsHoldingObject", true)
				self:PickupObject(entity)
				self:PlayPickupSound(trace.SurfaceProps)
				self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
				interacted = true
			end
		end

		if not interacted and owner:OnGround() then
			local isInBlockAnim = self:GetSequenceName(vm:GetSequence())
			if isInBlockAnim != "WbkDefendHimself" then
				if IsValid(vm) then
					vm:SendViewModelMatchingSequence(vm:LookupSequence("WbkDefendHimself"))
				end
				self.isInBlockDam = true
				timer.Simple(1.35, function()
					if IsValid(self) then
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
end

function SWEP:Reload()
	if (!IsFirstTimePredicted()) then return end
	if (SERVER and IsValid(self.heldEntity)) then self:DropObject() end
	self:SetHoldType("passive")
	local vm = self.Owner:GetViewModel()
	if IsValid(vm) then
		vm:SendViewModelMatchingSequence(vm:LookupSequence("WbkIdle_Lowered"))
	end
	self:UpdateNextIdle()
end

function SWEP:OnDrop()
	if (SERVER) then self:DropObject() end
end

function SWEP:OwnerChanged()
	if (SERVER) then self:DropObject() end
end
