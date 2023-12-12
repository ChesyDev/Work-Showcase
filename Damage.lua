local DamageVisual = require(script.DamageNumbers)

local Flinch = {
	[1] = "rbxassetid://15190570348",
	[2] = "rbxassetid://15184723859",
}

local module = {}
	module.__index = module
	module.KnockbackTrue = false
	module.AdditionalFunction = false
	module.BreakGuard = false
	module.AntiCounter = false
	module.OnKill = false
	module.StaggerTime = .5
	module.IgnoreBlock = false

	module.VFXEnabled = true
	module.AnimationEnabled = true

	module.Humanoid = false
	module.Character = false

	module.Damage = 0

module.Add = function(Humanoid, Damage, OriginCharacter)
	local self = setmetatable({}, module)
	self.Damage = Damage
	self.Humanoid = Humanoid
	self.Character = Humanoid.Parent
	self.OriginCharacter = OriginCharacter
	
	if not OriginCharacter then end

	return self
end

function module:Destroy()
	self = nil
end

function module:Execute()
	--if self.Character.States:FindFirstChild("Ragdoll") then return end
	if self.Character.States:FindFirstChild("Blocking") and not self.BreakGuard and not self.IgnoreBlock then self.Damage = math.ceil(self.Damage * 0.3) end
	if self.Character.States:FindFirstChild("Safe") then return end
	
	if self.BreakGuard then 
		if self.Character.States:FindFirstChild("Blocking") then
			_G.RemoveState(self.Character, "Blocking", 0)
			_G.AddState(self.Character, "Stunned", 1)
			local Animation = _G.AnimLoad(self.Humanoid, "rbxassetid://15380218172")
			Animation:Play()
		end
	end
	
	if self.Character:HasTag("Dodging") then return end
	
	if self.Character.States:FindFirstChild("Counter") and not self.BreakGuard and not self.AntiCounter then
		local CounterValue = self.Character.States:FindFirstChild("Counter")
		CounterValue.Value = self.OriginCharacter
		return end

	if self.Character and self.Humanoid then
		
		if self.Humanoid.Health - self.Damage == 0 then
			if self.OnKill then self.OnKill() end
		end

		if self.VFXEnabled then
			local HitVFX = game:GetService("ReplicatedStorage").VFX.General.Hit.Attachment:Clone()
			HitVFX.Parent = self.Character.PrimaryPart
			for _, particle in pairs(HitVFX:GetDescendants()) do
				if particle:IsA("ParticleEmitter") then
					particle:Emit(15)
				end
			end
			game.Debris:AddItem(HitVFX, 2)
		end
		
		if self.StaggerTime > 0 and not self.Character:HasTag("Blocking") and not self.Character.States:FindFirstChild("Stunned") then
			local Folder = self.Character:FindFirstChild("States")
			if Folder then else return end
			
			local StaggerValue = _G.AddState(self.Character, "Stagger", self.StaggerTime)
			_G.AddState(self.Character, "WalkspeedLock", self.StaggerTime, 2)
			_G.AddState(self.Character, "JumpLock", self.StaggerTime, 0)
			StaggerValue.Parent = Folder
		end
		
		if self.AdditionalFunction then self.AdditionalFunction() end
		
		--DamageVisual.Create(self.Character, self.Damage)
		self.Humanoid:TakeDamage(self.Damage)
		
		_G.AddState(self.Character, "StopRunning", .1)
		
		if not self.Character:HasTag("Blocking") then
			local FoundHighlight = self.Character:FindFirstChildWhichIsA("Highlight")
			if FoundHighlight then FoundHighlight:Destroy() end
			
			local Highlight = script.DamageHighlight:Clone()
			Highlight.Parent = self.Character
			
			_G.Tween(Highlight, {0.5}, {FillTransparency = 1, OutlineTransparency = 1})
			game.Debris:AddItem(Highlight, 0.5)
			
			
			local AnimSpeed = 1+self.StaggerTime if AnimSpeed == 0 then AnimSpeed = 1 end
			if self.AnimationEnabled == true then
				if not self.Humanoid:GetAttribute("hitside") then
					local anim = _G.AnimLoad(self.Humanoid, Flinch[1])
					_G.AnimPlay(self.Humanoid, anim, 0.1, "Hit")
					anim.Name = "Cancellable"
					anim:AdjustSpeed(AnimSpeed)
					self.Humanoid:SetAttribute("hitside", 1)
				else
					local anim : AnimationTrack = _G.AnimLoad(self.Humanoid, Flinch[2])
					_G.AnimPlay(self.Humanoid, anim, 0.1, "Hit")
					anim.Name = "Cancellable"
					anim:AdjustSpeed(AnimSpeed)
					self.Humanoid:SetAttribute("hitside", nil)
				end
			end
		end
		
		self:Destroy()
	end

	return
end

function module:NoCounter()
	self.AntiCounter = true
	return
end

function module:Revert() --Heal, may be deprecated some time in the future
	self.Humanoid.Health += self.Damage
	self:Destroy()

	return
end


return module
