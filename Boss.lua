-- Services
local player = game:GetService('Players')
local tweenservice = game:GetService('TweenService')
local repl = game:GetService('ReplicatedStorage')
local RunService = game:GetService("RunService")

-- Modules
local janitor = require(repl._Shared.Janitor) -- Handles cleanup of instances/connections
local cameraPreset = require(script.cameraPreset) -- Camera shake / camera effects preset

-- Main boss module table
local _main = {
	bossFolder = script.bossList -- Folder containing boss models
}

_main.__index = _main

-- Constructor for boss instance
function _main.new(model: Model?, Properties: {})
	local self = setmetatable({}, _main)

	-- Clone boss character model
	self.character = model:Clone()

	-- Disable collision for all parts in the boss model
	for _, v in self.character:GetDescendants() do
		if v:IsA('BasePart') or v:IsA('MeshPart') then
			v.CanCollide = false
		end
	end

	-- Parent boss to workspace
	self.character.Parent = workspace
	self.character.Name = `{model.Name}_Id: {math.random(111,999)}`

	-- Anchor boss and move to spawn position
	self.character.PrimaryPart.Anchored = true
	self.character:MoveTo(Properties.Vector)

	-- Animation controller reference
	self.AnimationController = self.character.AnimationController

	-- Base part used to spawn boss
	self.basePart = Properties.basePart

	-- Health attributes
	self.character:SetAttribute("MaxHealth", Properties.Health)
	self.character:SetAttribute("Health", self.character:GetAttribute("MaxHealth"))

	-- Janitor for cleanup
	self.janitor = janitor.new()

	-- Players currently inside boss arena
	self.playerIn = {}

	self.nextCollision = nil
	self.barrier = nil

	-- Setup validation and listeners
	self:validation()

	-- Safety checks
	assert(self.AnimationController, "AnimationController NILL")
	assert(self.character, "CHARACTER EMPTY")

	-- Delay before boss starts attacking
	task.spawn(function()
		for count = 3, 1, -1 do
			warn("start attack in " .. count)
			task.wait(1)
		end
		self:routine()
	end)

	return self
end

-- Emit all ParticleEmitters inside a part
function Emit(part: Instance?)
	for _, v in part:GetDescendants() do
		if v:IsA('ParticleEmitter') then
			coroutine.wrap(function()
				wait(v:GetAttribute("EmitDelay"))
				v:Emit(v:GetAttribute("EmitCount"))
			end)()
		end
	end
end

-- Get random point inside a radius (XZ plane)
local function getRandomPointInRadius(center, radius)
	local theta = math.random() * 2 * math.pi
	local phi = math.acos(2 * math.random() - 1)
	local r = math.random() * radius

	local x = r * math.sin(phi) * math.cos(theta)
	local z = r * math.cos(phi)

	return center + Vector3.new(x, 0, z)
end

-- Smoothly move beam attachments over time (server-side)
local function lerpBeamMotionServer(vfx: Attachment?, targetCFrame: CFrame?, duration: number?)
	local startTime = tick()
	local startCFrame = vfx.WorldCFrame

	local conn
	conn = RunService.Heartbeat:Connect(function()
		local alpha = (tick() - startTime) / duration
		if alpha >= 1 then
			vfx.WorldCFrame = targetCFrame
			conn:Disconnect()
			return
		end
		vfx.WorldCFrame = startCFrame:Lerp(targetCFrame, alpha)
	end)
end

-- Barrier destruction visual effect
local function barrierDeadAnimation(Barrier: BasePart)
	if Barrier then
		Barrier.Material = Enum.Material.Neon
		Barrier.CanCollide = false
		Barrier.Transparency = .5

		local _tween = tweenservice:Create(
			Barrier,
			TweenInfo.new(.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
			{
				Color = Color3.fromRGB(255, 255, 255),
				Size = Barrier.Size + Vector3.new(20, 20, 20),
				Transparency = 1
			}
		)

		_tween:Play()
		_tween.Completed:Wait()
		Barrier:Destroy()
	end
end

-- Validation and health monitoring
function _main:validation()
	self.janitor:Add(
		self.character:GetAttributeChangedSignal("Health"):Connect(function()
			-- If no players remain, kill boss
			if #self.playerIn <= 0 then
				barrierDeadAnimation(self.barrier)
				self:cleaning()
			end

			-- Boss death check
			if self.character and self.character:GetAttribute("Health") <= 0 then
				barrierDeadAnimation(self.barrier)
				self:cleaning()
			end
		end),
		"Disconnect"
	)

	-- Ensure debris folder exists
	if workspace:FindFirstChild("debris") then
		self.debris = workspace:FindFirstChild("debris")
	else
		self.debris = Instance.new("Folder")
		self.debris.Name = "debris"
		self.debris.Parent = workspace
	end
end

-- Cleanup boss and reward players
function _main:cleaning()
	warn("Boss defeated")

	coroutine.wrap(function()
		for _, CharacterTable in self.playerIn do
			-- Reset collision groups
			for _, Part in CharacterTable:GetDescendants() do
				if Part:IsA("BasePart") or Part:IsA("MeshPart") then
					Part.CollisionGroup = tostring(self.basePart:GetAttribute("Collission"))
				end
			end

			-- Reward player
			local getPlayer = player:GetPlayerFromCharacter(CharacterTable)
			if getPlayer then
				local status = getPlayer:FindFirstChildOfClass("Configuration")
				local chestFolder: Folder? = status.chestCollect
				chestFolder:ClearAllChildren()

				status:SetAttribute("Parkour", "")

				local Gacha = require(script.Parent.Gacha)
				local rewards = self.character:GetAttribute("Reward")

				Gacha.Instant(getPlayer, {
					Tier = "Legendary";
					Item = tostring(rewards)
				})
			end
		end
	end)()

	-- Reset base part
	self.basePart:SetAttribute("bossStarted", false)
	self.basePart.Parent = workspace

	-- Cleanup instances
	self.character:Destroy()
	self.janitor:Cleanup()
	self.character = nil
	self.playerIn = {}
end
