local player = game:GetService('Players')
local tweenservice = game:GetService('TweenService')
local repl = game:GetService('ReplicatedStorage')
local RunService = game:GetService("RunService")


local janitor = require(repl._Shared.Janitor)
local cameraPreset = require(script.cameraPreset)
local _main = {

	bossFolder = script.bossList
}

_main.__index = _main
function _main.new(model: Model?,Properties: {})
	local self = setmetatable({},_main)
	self.character = model:Clone()

	for _,v in self.character:GetDescendants() do
		if v:IsA('BasePart') or v:IsA('MeshPart') then
			v.CanCollide = false
		end
	end

	self.character.Parent = workspace
	self.character.Name = `{model.Name}_Id: {math.random(111,999)}`
	self.character.PrimaryPart.Anchored = true
	self.character:MoveTo(Properties.Vector)
	--self.character.PrimaryPart.CFrame = Properties.cFrame

	self.AnimationController = self.character.AnimationController

	self.basePart = Properties.basePart
	self.character:SetAttribute("MaxHealth",Properties.Health) 
	self.character:SetAttribute("Health",self.character:GetAttribute("MaxHealth")) 

	self.janitor = janitor.new()
	self.playerIn = {}

	self.nextCollision = nil
	self.barrier = nil

	--self:playerEntry()
	self:validation()

	assert(self.AnimationController,"AnimationControllerNILL")
	assert(self.character,"EMPTYYY")
	task.spawn(function()
		for count = 3,1,-1 do
			warn("start attack in ".. count)
			task.wait(1)
		end
		self:routine()	
	end)


	return self
end



function Emit(part: Instance?)
	for _,v in part:GetDescendants() do
		if v:IsA('ParticleEmitter') then
			coroutine.wrap(function()
				wait(v:GetAttribute("EmitDelay"))
				v:Emit(v:GetAttribute("EmitCount"))
			end)()

		end
	end
end

local function getRandomPointInRadius(center, radius)
	local theta = math.random() * 2 * math.pi
	local phi = math.acos(2 * math.random() - 1)
	local r = math.random() * radius

	local x = r * math.sin(phi) * math.cos(theta)
	local z = r * math.cos(phi)

	return center + Vector3.new(x, 0, z)
end


local function lerpBeamMotionServer(vfx: Attachment?, targetCFrame: CFrame?, duration: number?)
	local startTime = tick()
	local startCFrame = vfx.WorldCFrame

	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		local alpha = (tick() - startTime) / duration
		if alpha >= 1 then
			vfx.WorldCFrame = targetCFrame
			conn:Disconnect()
			return
		end
		vfx.WorldCFrame = startCFrame:Lerp(targetCFrame, alpha)
	end)
end


--[[
function _main:playerEntry()
	for _,v in player:GetDescendants() do
		if v:IsA('Configuration') and v.Name == "_status" then
			if v:GetAttribute("parkour") == "Hard" then
				if #self.playerIn <= 5 then
					table.insert(self.playerIn,v.Parent)
					print(v.Parent)
				end
			end
		end
	end

	print("setup playerEntry Finished")
end]]


local function barrierDeadAnimation(Barrier: BasePart)
	if Barrier then
		Barrier.Material = Enum.Material.Neon
		Barrier.CanCollide = false
		Barrier.Transparency = .5

		local _tween = tweenservice:Create(Barrier,TweenInfo.new(.5,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out),{Color = Color3.fromRGB(255, 255, 255),Size = Barrier.Size + Vector3.new(20,20,20),Transparency = 1})
		_tween:Play()
		_tween.Completed:Wait()
		Barrier:Destroy()
	end
end


function _main:validation()
--[[	coroutine.wrap(function()
		for i,CharacterTable in self.playerIn do

			for _,Part in CharacterTable:GetDescendants() do
				if Part:IsA("BasePart") or Part:IsA("MeshPart") then
					Part.CollisionGroup = "Player"
				end
			end

			local getPlayer = player:GetPlayerFromCharacter(CharacterTable)
			if getPlayer then
			end
		end
	end)()
]]
	self.janitor:Add(self.character:GetAttributeChangedSignal("Health"):Connect(function()
		if #self.playerIn <= 0 then
			barrierDeadAnimation(self.barrier)
			self:cleaning()
		end
		
		if self.character then
			if self.character:GetAttribute("Health") <= 0 then
				barrierDeadAnimation(self.barrier)
				self:cleaning()

			end
		end
	end),"Disconnect")

	if workspace:FindFirstChild("debris") then
		self.debris = workspace:FindFirstChild("debris")
	else
		self.debris = Instance.new("Folder")
		self.debris.Name = "debris"
		self.debris.Parent = workspace

	end

end

function _main:cleaning()
	warn("boss Mati Jir")
	print(self.basePart)
	coroutine.wrap(function()
		for i,CharacterTable in self.playerIn do

			for _,Part in CharacterTable:GetDescendants() do
				if Part:IsA("BasePart") or Part:IsA("MeshPart") then
					Part.CollisionGroup = tostring(self.basePart:GetAttribute("Collission"))
				end
			end

			local getPlayer = player:GetPlayerFromCharacter(CharacterTable)
			if getPlayer then
				local status = getPlayer:FindFirstChildOfClass("Configuration")
				local chestFolder :Folder? = status.chestCollect
				chestFolder:ClearAllChildren()

				status:SetAttribute("Parkour","")
				local Gacha = require(script.Parent.Gacha)
				local rewards = self.character:GetAttribute("Reward")

				Gacha.Instant(getPlayer,{
					Tier = "Legendary";
					Item = tostring(rewards)
				})	
					--Gacha.new(getPlayer,"HardParkour")

			end
		end
	end)()

	self.basePart:SetAttribute("bossStarted",false)
	self.basePart.Parent = game.Workspace
	
	--[[self.basePart.Attachment.ProximityPrompt.Enabled = true
	self.basePart.Attachment.Wind2.Enabled = true
]]
	self.character:Destroy()
	self.janitor:Cleanup()
	self.character = nil
	self.playerIn = {}

end

function _main:addHitbox(data: {}, Damage:number?)
	coroutine.wrap(function()
		local playerCatch = {}
		local hitbox = self.janitor:Add(Instance.new("Part"),"Destroy")
		hitbox.Size = data.Size
		hitbox.Anchored = true
		hitbox.CanCollide = false
		hitbox.CastShadow = false
		hitbox.Transparency = 1

		hitbox.Color = Color3.fromRGB(255,0,0)
		hitbox.Parent = workspace
		hitbox.Shape = data.Shape
		hitbox.CFrame = data.CFrame
		hitbox.Name = "Hitbox"

		local hits = workspace:GetPartsInPart(hitbox, OverlapParams.new())
		for _, v in hits do
			local modelName = v.Parent
			if modelName and modelName:FindFirstChildOfClass('Humanoid') and modelName.Name ~= self.character.Name then
				if not playerCatch[modelName] then
					playerCatch[modelName] = true
					local humanoid = modelName:FindFirstChildOfClass('Humanoid')
					if humanoid and typeof(Damage) == "number" then
						humanoid:TakeDamage(Damage)
					end
				end
			end
		end

		game.Debris:AddItem(hitbox,1)
	end)()
end

function _main:wosshSkill(bosCF: CFrame?)

	if not self.character then print("bos sudah mati") return end

	assert(self.debris,`debrisFolder Nill`)

	print("Starting Skillwoosh")

	local debris = self.janitor:Add(Instance.new("Part",self.debris),"Destroy")
	local anim :AnimationTrack= self.AnimationController:LoadAnimation(self.character.Recharge)
	debris.Transparency = .5
	debris.Anchored = true
	debris.CanCollide = false
	debris.CastShadow = false

	debris.CFrame = bosCF * CFrame.new(0,-1,0) * CFrame.Angles(0,0,math.rad(90))
	debris.Size = Vector3.new(0,.5,0)
	debris.Color = Color3.fromRGB(0, 0, 0)

	debris.Material = Enum.Material.Neon
	debris.Shape = Enum.PartType.Cylinder

	local _tween = tweenservice:Create(debris,TweenInfo.new(1.16),{Color = Color3.fromRGB(255, 62, 62),Size = Vector3.new(1, 120, 120)})
	_tween:Play()
	anim:Play()
	anim.Looped = false
	anim.Priority = Enum.AnimationPriority.Action

	--anim:AdjustSpeed(.5)
	coroutine.wrap(function()
		for i = 0,10 do
			debris.Transparency = 1
			task.wait(.1)
			debris.Transparency = .5
			task.wait(.1)
		end
	end)()
	anim:GetMarkerReachedSignal("Attack"):Connect(function()
		self:addHitbox({
			Shape = debris.Shape;
			Size = Vector3.new(120,120,120);
			CFrame = debris.CFrame
		},20)

		local vfx = self.janitor:Add(script.Folder.AOE:Clone(),"Destroy")
		vfx.CFrame = CFrame.Angles(0,0,math.rad(-90))
		vfx.Parent = debris
		coroutine.wrap(Emit)(vfx)

		for _,v in self.playerIn do
			local getPlayer = player:GetPlayerFromCharacter(v)
			if getPlayer then
				print("playerGet")
				repl.Remotes.Event:WaitForChild('bossCheck'):FireClient(getPlayer,cameraPreset.Explosion)
				repl.Remotes.Event:WaitForChild('bossCheck'):FireClient(getPlayer,{
					Listener = "vfxLighting",
					saturate = 1,
					contrast = 10
				})

			else warn("playerEmpty")
			end

		end
		_tween = tweenservice:Create(debris,TweenInfo.new(1,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out),{Color = Color3.fromRGB(255, 255, 255),Size = Vector3.new(1, 140, 140),Transparency = 1})
		_tween:Play()
		game.Debris:AddItem(debris,1.1)

	end)





end



function _main:semburan(radius: number?,bosPos: Vector3?)
	if not self.character then print("bos sudah mati") return end
	assert(self.debris,`debrisFolder Nill`)
	local anim = self.AnimationController:LoadAnimation(self.character.Attack)

	anim:Play()
	anim.Priority = Enum.AnimationPriority.Action2
	anim.Looped = false
	for _polaSemburan = 0, 10 do
		if not self.character then print("bos sudah mati") return end
		coroutine.wrap(function()
			local debris = self.janitor:Add(Instance.new("Part",self.debris),"Destroy")
			debris.Transparency = .5
			debris.Anchored = true
			debris.CanCollide = false
			debris.CastShadow = false

			debris.CFrame = CFrame.new(getRandomPointInRadius(bosPos,radius)) * CFrame.new(0,-1,0) * CFrame.Angles(0,0,math.rad(90))

			debris.Size = Vector3.new(0,.5,0)
			debris.Color = Color3.fromRGB(0, 0, 0)

			debris.Material = Enum.Material.Neon
			debris.Shape = Enum.PartType.Cylinder

			local _tween = tweenservice:Create(debris,TweenInfo.new(1,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Color = Color3.fromRGB(255, 62, 62),Size = Vector3.new(1, 25, 25)})
			_tween:Play()

			--anim:AdjustSpeed(.75)
			coroutine.wrap(function()
				for i = 0,10 do
					debris.Transparency = 1
					task.wait(.1)
					debris.Transparency = .5
					task.wait(.1)
				end
			end)()
			anim:GetMarkerReachedSignal("Attack"):Connect(function()


				self:addHitbox({
					Shape = debris.Shape;
					Size = debris.Size + Vector3.new(30,0,0);
					CFrame = debris.CFrame
				},15)


				local vfx = self.janitor:Add(script.Folder.kaboom:Clone(),"Destroy")
				vfx.CFrame = CFrame.Angles(0,0,math.rad(-90))
				vfx.Parent = debris
				coroutine.wrap(Emit)(vfx)


				for _,v in self.playerIn do
					local getPlayer = player:GetPlayerFromCharacter(v)
					if getPlayer then
						repl.Remotes.Event:WaitForChild('bossCheck'):FireClient(getPlayer,cameraPreset.Bomber)
						repl.Remotes.Event:WaitForChild('bossCheck'):FireClient(getPlayer,{
							Listener = "vfxLighting",
							saturate = 0,
							contrast = 10
						})	

					end
				end

				_tween = tweenservice:Create(debris,TweenInfo.new(.1,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out),{Color = Color3.fromRGB(255, 255, 255),Size = Vector3.new(1, 45, 45),Transparency = 1})
				_tween:Play()
				game.Debris:AddItem(debris,.5)
			end)
		end)()

		task.wait()

	end
end



function _main:spawnCannon(data: {},bosPos: Vector3?, bosCF: CFrame?)
	if not self.character then print("bos sudah mati") return end
	local Resting = self.janitor:Add(script.Booting:Clone(),"Destroy")
	Resting.Parent = self.character
	game.Debris:AddItem(Resting,11)
	local amount = data.amount
	local radius = data.radius
	local spawned = {}

	assert(self.debris,`debrisFolder Nill`)
	local function Effect()

		for _, v in self.playerIn do
			local getPlayer = player:GetPlayerFromCharacter(v)
			if getPlayer then
				repl.Remotes.Event:WaitForChild("bossCheck"):FireClient(getPlayer, cameraPreset.Explosion)
				repl.Remotes.Event:WaitForChild("bossCheck"):FireClient(getPlayer, {
					Listener = "vfxLighting",
					saturate = -10,
					contrast = 100
				})
			else
				warn("playerEmpty")
			end
		end
	end

	local function connectCannon(debris, prox, tween)
		local cannonJanitor = janitor.new()
		cannonJanitor:Add(prox.AncestryChanged:Connect(function(_, parent)
			if not parent then
				cannonJanitor:Cleanup()
			end
		end), "Disconnect")

		cannonJanitor:Add(prox.Triggered:Connect(function()
			local vfx = self.janitor:Add(script.Folder.Water:Clone(),"Destroy")
			vfx.Parent = debris
			debris.Transparency = 1
			local Canon = debris.Canon
			if Canon then
				local anim = Canon.AnimationController:LoadAnimation(Canon.Shot)
				anim:Play()
				anim.Priority = Enum.AnimationPriority.Action2
				anim.Looped = false
				
			end
			prox:Destroy()
			debris:FindFirstChildWhichIsA("BillboardGui"):Destroy()


			Effect()
			lerpBeamMotionServer(vfx.BeamEnd, bosCF, .2)

			task.delay(0.6, function()
				lerpBeamMotionServer(vfx.BeamStart, bosCF, 0.5)
			end)

			task.delay(.3, function()
				cannonJanitor:Add(Instance.new("Highlight",self.character),"Destroy")

				coroutine.wrap(Emit)(vfx)
				Effect()

				self.character:SetAttribute("Health",self.character:GetAttribute("Health") - 50)
				vfx.Black.Enabled = false
				vfx.Black1.Enabled = false
				vfx.Black1_.Enabled = false
				cannonJanitor:Cleanup() 
			end)
		end), "Disconnect")
	end


	for i = 1, amount do
		if not self.character then
			print("Bos sudah mati")
			return
		end

		--=== Buat debris ===--
		local debris = self.janitor:Add(Instance.new("Part"), "Destroy")
		debris.Size = Vector3.new(5, 5, 5)
		debris.Color = Color3.fromRGB(0, 255, 0)
		debris.Material = Enum.Material.Neon
		debris.Anchored = true
		debris.CanCollide = false
		debris.CastShadow = false
		debris.Transparency = 1
		debris.CFrame = CFrame.new(getRandomPointInRadius(self.basePart.Position, radius))
		debris.Parent = self.debris

		local billboard = script.BillboardGui:Clone()
		billboard.Parent = debris

		local cannon = script.Canon:Clone()
		cannon.Parent = debris
		cannon.PrimaryPart.CanCollide = false
		cannon:SetPrimaryPartCFrame(debris.CFrame)

		local weldCons = Instance.new("WeldConstraint")
		weldCons.Part0 = debris
		weldCons.Part1 = cannon.PrimaryPart
		weldCons.Parent = debris

		local targetPos = Vector3.new(self.basePart.Position.X, debris.Position.Y, self.basePart.Position.Z)
		debris.CFrame = CFrame.lookAt(debris.Position, targetPos) * CFrame.new(0,-3.5,0)

		local tween = tweenservice:Create(
			debris,
			TweenInfo.new(1.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ CFrame = debris.CFrame * CFrame.new(0, 5, 0) }
		)
		tween:Play()
		tween.Completed:Wait()

		local prox = Instance.new("ProximityPrompt")
		prox.HoldDuration = 1
		prox.Parent = cannon.PrimaryPart:WaitForChild("Attach")

		coroutine.wrap(connectCannon)(debris, prox, tween)
		table.insert(spawned, debris)
	end

	-- Debug timer loop
	for count = 1, 10 do
		print(count)
		task.wait(1)
	end

	for _,v in spawned do
		v:Destroy()
	end
end



function _main:routine ()
	warn("Starting Behivor")
	local originPos : Vector3 = self.character.PrimaryPart.Position
	local originCFrame : CFrame = self.character.PrimaryPart.CFrame
	local anim:AnimationTrack? = self.AnimationController:LoadAnimation(self.character.Idle)
	anim.Priority = Enum.AnimationPriority.Idle
	anim:Play()
	
	
	coroutine.wrap(function()
		while true do
			if #self.playerIn <= 0 then
				if self.character then
					self.character:SetAttribute("Health",0)
					break
				end
			end
			task.wait()
		end
	end)()

	coroutine.wrap(function()
		while #self.playerIn > 0 do
			if not self.character then
				break
			end
			if self.character:GetAttribute("Health") <= 0 then break end
			local timer = 5
			local Rest = 10
			local percent = (self.character:GetAttribute("Health") / math.max(self.character:GetAttribute("MaxHealth"), 1)) * 100
			local radiusCannon = 50

			if percent >=80 then
				warn("Stage 1")
				self:wosshSkill(originCFrame)
				task.wait(timer)
				self:semburan(120,originPos)
				print("Resting")
				self:spawnCannon({
					amount = 3,
					radius = radiusCannon
				},originPos,originCFrame)
				task.wait(Rest*1)


			elseif percent > 20 and percent < 80 then
				warn("Stage 2")
				task.wait(timer*.7)
				self:wosshSkill(originCFrame)
				self:wosshSkill(originCFrame)


				task.wait(timer*.7)
				for amount = 0,math.random(1,3) do
					local random = math.random(.8,1.5)
					local radiusRandom = math.random(120,180)

					self:semburan(radiusRandom,originPos)
					task.wait(random)
				end

				print("Resting")

				self:spawnCannon({
					amount = 3,
					radius = radiusCannon
				},originPos,originCFrame)
				task.wait(Rest*.7)

			elseif percent <= 20 then
				warn("Stage 3")
				task.wait(timer*.4)
				self:semburan(180,originPos)
				self:wosshSkill(originCFrame)
				self:semburan(180,originPos)
				self:wosshSkill(originCFrame)


				task.wait(timer*.4)

				for amount = 0,math.random(2,5) do
					local random = math.random(.5,1)
					local radiusRandom = math.random(70,180)

					self:semburan(radiusRandom,originPos)
					task.wait(random)
				end


				print("Resting")
				
				self:spawnCannon({
					amount = 3,
					radius = radiusCannon
				},originPos,originCFrame)
				task.wait(Rest*1)

			end 


		end



--[[		if self.character then
			self.character:SetAttribute("Health",0)
		end]]
		warn("player Index Empty")
	end)()

end

function _main:Init()
	--[[local model = _main.new(script.Testing,{
		Health = 100;
		cFrame = CFrame.new(132.842, -15.04, -1354.125)
	})]]
end



return _main

