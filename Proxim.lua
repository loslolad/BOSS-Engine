local repl = game:GetService('ReplicatedStorage')
local serverScriptService = game:GetService('ServerScriptService')
local bossModule = require(serverScriptService.Libs.bossAdd)
local Player = game:GetService("Players")
local basePart_ = script.Parent.Parent.Parent
print(bossModule.bossFolder:GetChildren()[math.random(1,#bossModule.bossFolder:GetChildren())])
script.Parent.Triggered:Connect(function()
	if basePart_:GetAttribute("bossStarted") == true then return end
	print("Triggered")
	basePart_:SetAttribute("bossStarted",true)
	basePart_.Parent = game.ServerStorage

--[[	script.Parent.Enabled = false
	script.Parent.Parent.Wind2.Enabled = false]]

	for counting = 3,1,-1 do
		print(`timer set {counting}`)
		task.wait(1)
	end

	print("Boss Started")
	local Pick  = bossModule.bossFolder:GetChildren()[math.random(1,#bossModule.bossFolder:GetChildren())]
	local partBarrier = Instance.new("Part",workspace.debris)
	partBarrier.Name  = `{Pick}_Barrier`
	partBarrier.Anchored = true
	partBarrier.CastShadow = false
	partBarrier.Transparency = .6
	partBarrier.Color = Color3.fromRGB(255,0,0)
	partBarrier.Material = Enum.Material.ForceField
	partBarrier.CFrame = basePart_.CFrame --[[CFramePos]]

	local InitBos = bossModule.new(Pick,{
		Health = 15*20,
		Vector = partBarrier.Position + Vector3.new(0,1,0),
		cFrame = partBarrier.CFrame,
		basePart = basePart_,

	})
		
	warn('InitializedBox')
	print(InitBos)
	partBarrier.Size = Vector3.new(250,250,250)
	
	local hits = workspace:GetPartsInPart(partBarrier, OverlapParams.new())
	for _, v in hits do
		local modelName :Model? = v.Parent
		local getPlayer = Player:GetPlayerFromCharacter(modelName)

		if modelName and modelName:FindFirstChildOfClass('Humanoid') and modelName.Name ~= InitBos.character.Name and getPlayer then
			if not table.find(InitBos.playerIn,modelName) and #InitBos.playerIn <= 5 then
				local status = getPlayer._status

				if status and status:GetAttribute("Parkour") ~= "Boss" then
					table.insert(InitBos.playerIn,modelName)
					
					repl.Remotes.Event.bossCheck:FireClient(getPlayer,{
						Listener = "Health";
						character = InitBos.character;
						listPlayer = InitBos.playerIn;
					})
					
					InitBos.barrier = partBarrier
					modelName.Humanoid.Died:Connect(function()
						table.remove(InitBos.playerIn,table.find(InitBos.playerIn,modelName))
						print(InitBos.playerIn)
					end)
					
					for _,v in modelName:GetDescendants() do
						if v:IsA("BasePart") or v:IsA("MeshPart") then
							v.CollisionGroup = "BossBarrier"
						end
					end
					
					
					print(modelName)
				else
					warn(`{status} tidak ditemukan`)
				end
			end
		end
	end


	--[[coroutine.wrap(function()
		InitBos.character:GetAttributeChangedSignal("Health"):Connect(function()
			if InitBos.character:GetAttribute("Health") <= 0 then
				script.Parent.Wind2.Enabled = true
				self.basePart:SetAttribute("bossStarted",false)
				self.basePart.Attachment.ProximityPrompt.Enabled = true
				self.basePart.Attachment.Wind2.Enabled = true
			end
		end)
	end)()]]
	print(InitBos.playerIn)
	partBarrier.CollisionGroup = "BossBarrier"
end)
