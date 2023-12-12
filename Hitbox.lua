local DebugOn = false

local DefaultDebounce = 0.6


local HitboxFolder = workspace:WaitForChild("Hitboxes")
local TagService = game:GetService("CollectionService")
local ClientRemotes = TagService:GetTagged("ClientRemotes")[1]
local HitboxRemote = ClientRemotes:WaitForChild("Hitbox")
----STUFF

local DebugTransparency = 1
if DebugOn then 
	DebugTransparency = 0.7 end



local CreateUniqueID = function(Folder, Name)
	local ID = Instance.new("StringValue")
	ID.Name = Name

	ID.Parent = Folder

	return ID
end

local CheckForFolder = function(Character)
	local Folder = Character:FindFirstChild("States")
	if Folder then return Folder else
		local Folder = Instance.new("Folder")
		Folder.Name = "States"

		Folder.Parent = Character
		return Folder
	end
end

local CreateBox = function(MoveName, Size, OriginInstancePlayer, Shape)
	local Box = Instance.new("Part")
	Box.Size = Size

	-----------------Technical Stuff
	Box.Name = OriginInstancePlayer.Name..MoveName

	Box.Anchored = true
	Box.Massless = true
	Box.CanCollide = false
	------Red Appearance Stuff vv
	Box.Color = Color3.fromRGB(255, 17, 17)
	Box.Transparency = DebugTransparency
	Box.Material = Enum.Material.Neon

	------ ^^

	if Shape == "Spherical" then
		Box.Shape = "Ball"
	end

	Box.Parent = HitboxFolder
	return Box
end

local CreateSphere = function(Name, Size, OriginInstancePlayer)
	return CreateBox(Name, Size, OriginInstancePlayer, "Spherical")
end

local hitbox = {}
hitbox.__index = hitbox

function hitbox.Create(Player, Name, Size, Offset)
	local self = setmetatable({}, hitbox)

	----Index List
	self.Player = Player
	self.Character = Player.Character
	self.Name = Name
	self.Size = Size
	self.Hitbox = CreateBox(Name, Size, Player)

	-----Position List
	self.FollowPart = self.Character.HumanoidRootPart
	self.Offset = Offset
	
	self.ObjVal = Instance.new("ObjectValue")
	self.ObjVal.Name = "FollowPart"
	self.ObjVal.Value = self.FollowPart
	self.ObjVal.Parent = self.Hitbox

	----Configuration
	self.DebounceTime = DefaultDebounce
	self.FollowState = true
	self.ClientFollow = true

	---Actives
	self.PosCoroutine = coroutine.create(function()
		while self.Hitbox do
			if self.FollowState then else return end
			task.wait(0.05)
			self.Hitbox.CFrame = self.FollowPart.CFrame * self.Offset
		end

		self.HitCoroutine = nil
	end)

	coroutine.resume(self.PosCoroutine)

	return self
end

function hitbox.CreateServer(ServerChar, Name, Size, Offset)
	local self = setmetatable({}, hitbox)

	----Index List
	self.Character = ServerChar
	self.Name = Name
	self.Size = Size
	self.Hitbox = CreateBox(Name, Size, ServerChar)

	-----Position List
	self.FollowPart = self.Character.HumanoidRootPart
	self.Offset = Offset

	self.ObjVal = Instance.new("ObjectValue")
	self.ObjVal.Name = "FollowPart"
	self.ObjVal.Value = self.FollowPart
	self.ObjVal.Parent = self.Hitbox

	----Configuration
	self.DebounceTime = DefaultDebounce
	self.FollowState = true
	self.ClientFollow = true

	---Actives
	self.PosCoroutine = coroutine.create(function()
		while self.Hitbox do
			if self.FollowState then else return end
			task.wait(0.05)
			self.Hitbox.CFrame = self.FollowPart.CFrame * self.Offset
		end

		self.HitCoroutine = nil
	end)

	coroutine.resume(self.PosCoroutine)

	return self
end

function hitbox:SetOnHit(FunctionReturn)
	self.OnHit = function(Character)
		FunctionReturn(Character)
	end
end

function hitbox:SetOnDebris(FunctionReturn)
	self.OnDebris = function(Debris)
		FunctionReturn(Debris)
	end
end

function hitbox:SetOnProjectile(FunctionReturn)
	self.OnProjectile = function(Projectile)
		FunctionReturn(Projectile)
	end
end

function hitbox:ChangeFollowpart(NewFollowpart)
	self.FollowPart = NewFollowpart
	self.ObjVal.Value = NewFollowpart
end

function hitbox:SetToWeld(PartToWeld)
	self.Hitbox.Anchored = false
	if not PartToWeld then
		self.FollowState = false
		self.Weld = _G.Weld(self.FollowPart, self.Hitbox, self.Hitbox)
		self.Weld.C0 = self.Offset
	else
		self.FollowPart = PartToWeld
		
		self.FollowState = false
		self.Weld = _G.Weld(self.FollowPart, self.Hitbox, self.Hitbox)
		self.Weld.C0 = self.Offset
	end
end

function hitbox:SetDebounceTime(Time)	 --Normal time is 0.5 seconds
	self.DebounceTime = Time
end

function hitbox:ToSpherical()
	self.Hitbox:Destroy()
	self.Hitbox = CreateSphere(self.Name, self.Size, self.Player)
end

function hitbox:ChangeToPosition(cframePos) --Lock part in a position rather than the player
	self.FollowState = false
	
	self.Hitbox.CFrame = cframePos
end

function hitbox:ChangeToPlayer() --Lock part back to player
	self.FollowState = true
end

function hitbox:Stop() --Stop On Hit
	if self.HitCoroutine then coroutine.yield(self.HitCoroutine) coroutine.close(self.HitCoroutine) end
	self.ON_HIT_CONNECTION:Disconnect() 
end

function hitbox:Destroy() --Effectively Destroys the Hitbox for good
	self:Stop()
	if self.Hitbox then self.Hitbox:Destroy() end

	self = nil
end

function hitbox:Init() --Start On Hit
	self.ON_HIT_CONNECTION = self.Hitbox.Touched:Connect(function() return end)

	self.Hitbox:SetAttribute("Offset", self.Offset)
	
	if self.ClientFollow and self.FollowState then 
		self.Hitbox:AddTag("ClientAllowed")
	end
	
	local HitConnection
	HitConnection = self.Hitbox.ChildAdded:Connect(function(Child)
		if Child.ClassName == "ObjectValue" then
			game.Debris:AddItem(Child, 0.1)
			local Character = Child.Value
			local Folder = CheckForFolder(Character)

			if not Folder:FindFirstChild(self.Hitbox.Name) then
				if self.OnHit and not Character:HasTag("Down") then task.spawn(function() self.OnHit(Character) end) end
				
				if self.DebounceTime ~= 0 then
					local HitID = CreateUniqueID(Folder, self.Hitbox.Name)
					game.Debris:addItem(HitID, self.DebounceTime)
				end
			end
		end
	end)

	
	self.HitCoroutine = coroutine.create(function()
		while self.Hitbox do

			for i, Part : Instance in self.Hitbox:GetTouchingParts() do
				local HitChar = Part.Parent
				if HitChar:FindFirstChild("Humanoid") and HitChar ~= self.Character then
					local Folder = HitChar:FindFirstChild("States")
					if not Folder then continue end

					if not Folder:FindFirstChild(self.Hitbox.Name) then 
						local Value = Instance.new("ObjectValue")
						Value.Value = HitChar
						Value.Parent = self.Hitbox
					end
					
				elseif Part:FindFirstAncestor("Destructible") then
					Part.Parent = workspace.Debris
					if self.OnDebris then self.OnDebris(Part) end
				end
				
			end
			task.wait(0.05)
		end
		
		coroutine.resume(self.HitCoroutine)
		
		HitConnection:Disconnect()
	end)
	
	self.ONDESTROY_CONNECTION = self.Hitbox.Destroying:Connect(function() --start checking if hitbox gets deleted
		self.ONDESTROY_CONNECTION:Disconnect()
		self:Stop()

		self = nil
	end)

	coroutine.resume(self.HitCoroutine)
end

function hitbox:GetInstance()
	return self.Hitbox
end


return hitbox
