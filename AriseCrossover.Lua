--!strict
local getgenv: () -> ({[string]: any}) = getfenv().getgenv

getgenv().ScriptVersion = "v0.1.0a"

getgenv().Changelog = [[
v0.1.0a
- Updated GUI + Core
v0.0.1a
- Initial Release
]]

do
  local Core = loadstring(game:HttpGet("https://github.com/aw4e/Cheese/raw/dev/Core.lua"))
  if not Core then return warn("Failed to load the Cheese Core") end
  Core()
end

-- Types

type Element = {
	CurrentValue: any,
	CurrentOption: {string},
	Set: (self: Element, any) -> ()
}

type Flags = {[string]: Element}

type Tab = {
	CreateSection: (self: Tab, Name: string) -> Element,
	CreateDivider: (self: Tab) -> Element,
	CreateToggle: (self: Tab, any) -> Element,
	CreateSlider: (self: Tab, any) -> Element,
	CreateDropdown: (self: Tab, any) -> Element,
	CreateButton: (self: Tab, any) -> Element,
	CreateLabel: (self: Tab, any, any?) -> Element,
	CreateParagraph: (self: Tab, any) -> Element,
}


-- Variable

local Notify: (Title: string, Content: string, Image: string?) -> () = getgenv().Notify
local CreateFeature: (Tab: Tab, FeatureName: string) -> () = getgenv().CreateFeature
local HandleConnection: (Connection: RBXScriptConnection, Name: string) -> () = getgenv().HandleConnection

local queue_on_teleport: (Code: string) -> () = getfenv().queue_on_teleport

local Player = game:GetService("Players").LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("HumanoidRootPart")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local Remotes = ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent")

local Pets = workspace:WaitForChild("__Main"):WaitForChild("__Pets")
local Mobs = workspace:WaitForChild("__Main"):WaitForChild("__Enemies")
local Worlds = workspace:WaitForChild("__Main"):WaitForChild("__World")
local Spawns = workspace:WaitForChild("__Extra"):WaitForChild("__Spawns")
local Dungeon = workspace:WaitForChild("__Main"):WaitForChild("__Dungeon")

-- GamePass
Player.Settings:SetAttribute("AutoAttack", true)
Player.leaderstats.Passes:SetAttribute("AutoAttack", true)
Player.leaderstats.Passes:SetAttribute("AutoClicker", true)

Player.Settings:SetAttribute("UnitySends", false)

Player.CharacterAdded:Connect(function(NewCharacater)
	Character = NewCharacater
  Humanoid = Character:WaitForChild("HumanoidRootPart")
end)

Player.OnTeleport:Connect(function()
	if game.GameId == 7074860883 then
		queue_on_teleport([[
      task.spawn(function()
        task.wait(5)
        loadstring(game:HttpGet("https://github.com/aw4e/Cheese/raw/dev/Loader.lua"))()
      end)
    ]])
	end
end)

local AllMobWorlds = {
	["SoloWorld"] = {"Soondoo", "Gonshee", "Daek", "Longin", "Anders", "Largalgan"},
	["NarutoWorld"] = {"Snake Man", "Blossom", "Black Crow"},
	["OPWorld"] = {"Shark Man", "Eminel", "Light Admiral"},
	["BleachWorld"] = {"Luryu", "Fyakuya", "Genji"},
	["BCWorld"] = {"Sortudo", "Michille", "Wind"},
	["ChainsawWorld"] = {"Heaven", "Zere", "Ika"},
	["JojoWorld"] = {"Diablo", "Gosuke", "Golyne"},
	["DBWorld"] = {"Turtle", "Green", "Sky"},
	["OPMWorld"] = {"Rider", "Cyborg", "Hurricane"}
}

local Islands = {}
for _, Island in pairs(Spawns:GetChildren()) do
	Islands[Island.Name] = Island.CFrame
end

local IslandKeys = {}
for key, _ in pairs(Islands) do
	table.insert(IslandKeys, key)
end

local CodeWorlds = {
	SL = "SoloWorld",
	NR = "NarutoWorld",
	OP = "OPWorld",
	BL = "BleachWorld",
	BC = "BCWorld",
	CH = "ChainsawWorld",
	JB = "JojoWorld",
	DB = "DBWorld",
	OPM = "OPMWorld",
}

local VillageNames = {
	["Grass Village"] = "NarutoWorld",
	["Brum Island"] = "OPWorld",
	["Leveling City"] = "SoloWorld",
	["Faceheal Town"] = "BleachWorld",
	["Lucky Kingdom"] = "BCWorld",
	["Nipon City"] = "ChainsawWorld",
	["Mori Town"] = "JojoWorld",
	["Dragon City"] = "DBWorld",
	["XZ City"] = "OPMWorld"
}

local VillageSpawns = {}
for Key, Value in pairs(VillageNames) do
	VillageSpawns[string.lower(Key)] = Value
end

local RankMaps = {
	"E", "D", "C", "B", "A", "S", "SS", "G", "N", "N+"
}

local RankValues = {}
for _, Value in ipairs(RankMaps) do
	table.insert(RankValues, "Rank " .. Value)
end

local MobTypes = { "Normal", "Big" }

local Runes = {
	["Rune Leveling City"] = "DgSoloRune",
	["Rune Grass Village"] = "DgNarutoRune",
	["Rune Brum Island"] = "DgOPRune",
	["Rune Dragon City"] = "DgDBRune",
	["Rune Fcaeheal"] = "DgBleachRune",
	["Rune Lucky Kingdom"] = "DgBCRune",
	["Rune Nipon City"] = "DgChainsawRune",
	["Rune Mori Town"] = "DgJojoRune",
	["Rune Rank Up"] = "DgRankUpRune"
}

local DgRunes = {}
for Key, _ in pairs(Runes) do
	table.insert(DgRunes, Key)
end

-- AntiCheat

task.spawn(function()
  while true and task.wait(.1) do
    if Player and Character then
      local CharacterScripts = Character:FindFirstChild("CharacterScripts")
      if CharacterScripts then
        for _, Child in ipairs(CharacterScripts:GetChildren()) do
          Child:Destroy()
        end
      end
    end
  end
end)

-- Features

local Flags: Flags = getgenv().Flags

local Window = getgenv().Window

local Tab: Tab = Window:CreateTab({
	Name = "Automation",
	Icon = "code",
	ImageSource = "Lucide",
	ShowTitle = false
})

Tab:CreateSection("Mobs")

Tab:CreateDropdown({
  Name = "Select World's",
  Description = "Select the world you want to farm",
  Options = IslandKeys,
  CurrentOption = {},
  MultipleOptions = false,
  SpecialType = nil,
  Callback = function(Value)
    local MobList = AllMobWorlds[Value]
    if MobList and #MobList > 0 then
      Flags.SelectMob:Set({
        Options = MobList,
        CurrentOption = {}
      })
    end
  end
}, "SelectWorld")

Tab:CreateDropdown({
  Name = "Select Mob's",
  Description = "Select the mob you want to farm",
  Options = {},
  CurrentOption = {},
  MultipleOptions = true,
  SpecialType = nil,
  Callback = function()end
}, "SelectMob")

Tab:CreateDropdown({
  Name = "Select Type",
  Description = "Select the mob type you want to farm",
  Options = MobTypes,
  CurrentOption = {},
  MultipleOptions = true,
  SpecialType = nil,
  Callback = function()end
}, "SelectType")

Tab:CreateSlider({
  Name = "Delay Farm",
  Range = {0.1, 5},
  Increment = 0.1,
  CurrentValue = 0.5,
  Callback = function()end
}, "DelayFarm")

local function IsInDungeon()
  return game.PlaceId ~= 87039211657390
end

local function HasAvailablePrompt(Mob)
  local RootPart = Mob:FindFirstChild("HumanoidRootPart")
  if not RootPart then return false end

  for _, Prompt in pairs(RootPart:GetChildren()) do
    if Prompt:IsA("ProximityPrompt") and Prompt.Enabled then
      return true
    end
  end

  return false
end

local function GetMobNameFromModel(Model)
	local Code, Id = Model:match("(%a+)(%d+)$")
	local _, Mob = CodeWorlds[Code], Id and CodeWorlds[Code] and AllMobWorlds[CodeWorlds[Code]]
	return Mob and Mob[tonumber(Id)] or nil
end

local function GetMobTypeFromId(Id)
	return #Id > 3 and Id:match("B%d$") and "Big" or "Normal"
end

local function GetNearestMob(Options)
  Options = Options or {}
  local MaxDistance = Options.MaxDistance
  local UseFilter = Options.UseFilter

  local NearestMob, ShortestDistance = nil, math.huge
  local PlayerPos = Humanoid.Position

  local ServerFolder = Mobs:FindFirstChild("Server")
  local ClientFolder = Mobs:FindFirstChild("Client")

  local SelectedMobs = Flags.SelectMob.CurrentOption
  local SelectedTypes = Flags.SelectType.CurrentOption

  for _, SubFolder in pairs(ServerFolder:GetChildren()) do
    if not SubFolder:IsA("Folder") and not SubFolder:GetAttribute("Dead") then
      if UseFilter then
        local Model = SubFolder:GetAttribute("Model")
        local Id = SubFolder:GetAttribute("Id")

        local MobType = GetMobTypeFromId(Id)
        local MobName = GetMobNameFromModel(Model)

        if not table.find(SelectedMobs, MobName) or not table.find(SelectedTypes, MobType) then
          continue
        end
      end

      local MobPos = SubFolder:GetPivot().Position
      local Distance = (PlayerPos - MobPos).Magnitude

      if MaxDistance and Distance > MaxDistance then
        continue
      end

      if Distance < ShortestDistance then
        ShortestDistance = Distance
        NearestMob = SubFolder
      end
    elseif SubFolder:IsA("Folder") and #SubFolder:GetChildren() > 0 then
      for _, Mob in pairs(SubFolder:GetChildren()) do
        if Mob:IsA("Instance") and not Mob:GetAttribute("Dead") then
          if UseFilter then
            local Model = Mob:GetAttribute("Model")
            local Id = Mob:GetAttribute("Id")

            local MobType = GetMobTypeFromId(Id)
            local MobName = GetMobNameFromModel(Model)

            if not table.find(SelectedMobs, MobName) or not table.find(SelectedTypes, MobType) then
              continue
            end
          end

          local MobPos = Mob:GetPivot().Position
          local Distance = (PlayerPos - MobPos).Magnitude

          if MaxDistance and Distance > MaxDistance then
            continue
          end

          if Distance < ShortestDistance then
            ShortestDistance = Distance
            NearestMob = Mob
          end
        end
      end
    end
  end

  return NearestMob
end

local function GetAnyMob()
	local ServerFolder = Mobs:FindFirstChild("Server")

	for _, SubFolder in ipairs(ServerFolder:GetChildren()) do
		if not SubFolder:IsA("Folder") and not SubFolder:GetAttribute("Dead") then
      return SubFolder
    end

		if SubFolder:IsA("Folder") and #SubFolder:GetChildren() > 0 then
			for _, Mob in ipairs(SubFolder:GetChildren()) do
				if Mob:IsA("Instance") and not Mob:GetAttribute("Dead") then
					return Mob
				end
			end
		end
	end

	return nil
end

local function ShadowAttack(Mob)
  local Args = {
    [1] = {
      [1] = {
        ["PetPos"] = {},
        ["AttackType"] = "All",
        ["Event"] = "Attack",
        ["Enemy"] = Mob.Name
      },
      [2] = "\5"
    }
  }
  Remotes:FireServer(unpack(Args))
end

Tab:CreateToggle({
  Name = "Auto Farm Selected Mobs",
  Callback = function()
    while Flags.AutoFarmSelectedMobs.CurrentValue and task.wait(.1) do
      local Target
			repeat
				Target = GetNearestMob({
          UseFilter = true,
        })
				task.wait(.1)
			until Target and Target:IsA("Instance") and not Target:GetAttribute("Dead")

      if Target then
        local TargetPos = Target:GetPivot().Position
        local PlayerPos = Character:GetPivot().Position
        local Distance = (PlayerPos - TargetPos).Magnitude

        if Distance > 10 then
          Character:PivotTo(CFrame.new(TargetPos) * CFrame.new(0, 0, 6))
          task.wait(tonumber(Flags.DelayFarm.CurrentValue))
          ShadowAttack(Target)
        end
      end
    end
  end
}, "AutoFarmSelectedMobs")

Tab:CreateToggle({
  Name = "Auto Farm Any Mobs",
  Callback = function()
    while Flags.AutoFarmAnyMobs.CurrentValue and task.wait(.1) do
      local Target
      repeat
        Target = GetAnyMob()
        task.wait(.1)
      until Target and Target:IsA("Instance") and not Target:GetAttribute("Dead")

      if Target then
        local TargetPos = Target:GetPivot().Position
        local PlayerPos = Character:GetPivot().Position
        local Distance = (PlayerPos - TargetPos).Magnitude

        if Distance > 10 then
          Character:PivotTo(CFrame.new(TargetPos) * CFrame.new(0, 0, 6))
          task.wait(tonumber(Flags.DelayFarm.CurrentValue))
          ShadowAttack(Target)
        end
      end
    end
  end
}, "AutoFarmAnyMobs")

Tab:CreateDivider()

local function AttackMob(Mob)
  local Args = {
    [1] = {
      [1] = {
        ["Event"] = "PunchAttack",
        ["Enemy"] = Mob.Name
      },
      [2] = "\4"
    }
  }
  Remotes:FireServer(unpack(Args))
end

Tab:CreateToggle({
  Name = "Auto Attack Mob",
  Callback = function()
    while Flags.AutoAttackMob.CurrentValue and task.wait(.01) do
      local Target
      repeat
        Target = GetNearestMob({
          MaxDistance = 10,
          UseFilter = false
        })
        task.wait(.1)
      until Target and Target:IsA("Instance") and not Target:GetAttribute("Dead")

      AttackMob(Target)
    end
  end
}, "AutoAttackMob")

Tab:CreateToggle({
  Name = "Auto Arise Mob",
  Callback = function()
    while Flags.AutoAriseMob.CurrentValue and task.wait() do
      local ClientFolder = Mobs:FindFirstChild("Client")
      for _, Mob in ipairs(ClientFolder:GetChildren()) do
        local Prompt = Mob:FindFirstChild("HumanoidRootPart") and Mob.HumanoidRootPart:FindFirstChild("ArisePrompt")
        if Prompt then
          local Args = {
            [1] = {
              [1] = {
                ["Event"] = "EnemyCapture",
                ["Enemy"] = Mob.Name
              },
              [2] = "\4"
            }
          }
          Remotes:FireServer(unpack(Args))
        end
      end
    end
  end
}, "AutoAriseMob")

Tab:CreateToggle({
  Name = "Auto Destroy Mob",
  Callback = function()
    while Flags.AutoDestroyMob.CurrentValue and task.wait() do
      local ClientFolder = Mobs:FindFirstChild("Client")
      for _, Mob in ipairs(ClientFolder:GetChildren()) do
        local Prompt = Mob:FindFirstChild("HumanoidRootPart") and Mob.HumanoidRootPart:FindFirstChild("DestroyPrompt")
        if Prompt then
          local Args = {
            [1] = {
              [1] = {
                ["Event"] = "EnemyDestroy",
                ["Enemy"] = Mob.Name
              },
              [2] = "\4"
            }
          }
          Remotes:FireServer(unpack(Args))
        end
      end
    end
  end
}, "AutoDestroyMob")

Tab:CreateSection("Shop")

Tab:CreateDropdown({
  Name = "Select Shadow Rank",
  Description = "Select the rank you want to sell",
  Options = RankValues,
  CurrentOption = {},
  MultipleOptions = true,
  SpecialType = nil,
  Callback = function()end
}, "SelectShadowRank")

Tab:CreateToggle({
  Name = "Auto Sell Shadow Rank",
  Callback = function()
    while Flags.AutoSellShadowRank.CurrentValue and task.wait(.1) do
      local Pets = Player.leaderstats.Inventory:FindFirstChild("Pets")
      local RankNumbers = {}

      for _, RankString in ipairs(Flags.SelectShadowRank.CurrentOption) do
        local RankLetter = string.sub(RankString, 6)
        
        for Num, Letter in ipairs(RankMaps) do
          if Letter == RankLetter then
            table.insert(RankNumbers, Num)
            break
          end
        end
      end

      if #RankNumbers > 0 then
        for _, Pet in ipairs(Pets:GetChildren()) do
          local RankValue = Pet:GetAttribute("Rank")
          
          if typeof(RankValue) == "number" then
            for _, Rank in ipairs(RankNumbers) do
              if RankValue == Rank then
                local Args = {
                  [1] = {
                    [1] = {
                      ["Event"] = "SellPet",
                      ["Pets"] = {Pet.Name}
                    },
                    [2] = "\5"
                  }
                }
                Remotes:FireServer(unpack(Args))
                task.wait(.3)
                break
              end
            end
          end
        end
      end
    end
  end
}, "AutoSellShadowRank")

local Tab: Tab = Window:CreateTab({
  Name = "Dungeon",
  Icon = "swords",
  ImageSource = "Lucide",
  ShowTitle = false
})

Tab:CreateSection("Dungeon")

Tab:CreateButton({
  Name = "Rank Up Dungeon",
  Description = "Go to the rank up dungeon",
  Callback = function()
    local Args = {
      [1] = {
        [1] = {
          ["Event"] = "DungeonAction",
          ["Action"] = "TestEnter"
        },
        [2] = "\n"
      }
    }
    Remotes:FireServer(unpack(Args))
  end
})

Tab:CreateDivider()

local function TeleportToSpawn(SpawnName)
	local Args = {
		[1] = {
			[1] = {
				["Event"] = "ChangeSpawn",
				["Spawn"] = SpawnName
			},
			[2] = "\n"
		}
	}
	Remotes:FireServer(unpack(Args))
	task.wait(.5)
	if Character then
		Character:BreakJoints()
	end
end

local function CreateAndStartDungeon(dungeonId)
	local Args = {
		[1] = {
			[1] = {
				["Event"] = "DungeonAction",
				["Action"] = "Create"
			},
			[2] = "\n" 
		}
	}
	Remotes:FireServer(unpack(Args))
	task.wait(.2)
	
	if #Flags.DungeonRune.CurrentOption > 0 then
		for key, Rune in ipairs(Flags.DungeonRune.CurrentOption) do
			local Args = {
				[1] = {
					[1] = {
						["Dungeon"] = dungeonId,
						["Action"] = "AddItems",
						["Slot"] = key,
						["Event"] = "DungeonAction",
						["Item"] = Runes[Rune]
					},
					[2] = "\n"
				}
			}
			Remotes:FireServer(unpack(Args))
			task.wait(.2)
		end
	end
	
	local Args = {
		[1] = {
			[1] = {
				["Dungeon"] = dungeonId,
				["Event"] = "DungeonAction",
				["Action"] = "Start"
			},
			[2] = "\n"
		}
	}
	Remotes:FireServer(unpack(Args))
end

Tab:CreateDropdown({
  Name = "Select Dungeon",
  Description = "Select the dungeon you want to do",
  Options = IslandKeys,
  CurrentOption = {},
  MultipleOptions = true,
  SpecialType = nil,
  Callback = function()end
}, "SelectDungeon")

Tab:CreateDropdown({
  Name = "Select Dungeon Rune",
  Description = "Select the rune you want to use",
  Options = DgRunes,
  CurrentOption = {},
  MultipleOptions = true,
  SpecialType = nil,
  Callback = function(Value)
    if #Value > 5 then
			table.remove(Value, #Value)
			Notify("Dungeon", "You can only select 5 Runes", "swords", "Lucide")
			Flags.DungeonRune:Set({
        CurrentOption = Value
      })
		end
  end
}, "DungeonRune")

function Rejoin(Id)
	TeleportService:Teleport(Id)
end

Tab:CreateToggle({
  Name = "Auto Detect Dungeon",
  Callback = function()
    while Flags.AutoDetectDungeon.CurrentValue and task.wait(.1) do
      local WarnGui = Player.PlayerGui:FindFirstChild("Warn")
			if not WarnGui then continue end

      for _, Dungeon in ipairs(WarnGui:GetChildren()) do
        if not Dungeon:IsA("Frame") then continue end

        for _, Child in ipairs(Dungeon:GetChildren()) do
          if not Child:IsA("ImageLabel") then continue end

          local WarnMessage = Child:FindFirstChild("WarnMessage")
					if WarnMessage and WarnMessage:IsA("TextLabel") then
            local Text = WarnMessage.Text
						if not string.find(Text, "SPAWNED") then continue end

						local CodeIsland = NormalizedVillageSpawn[string.lower(Text)]
						local SelectedList = #Flags.SelectDungeon.CurrentOption > 0 and Flags.SelectDungeon.CurrentOption or IslandKeys

						for _, Selected in ipairs(SelectedList) do
							if CodeIsland == Selected then
								Notify("Dungeon", "Teleporting to " .. Text, "swords", "Lucide")
								TeleportToSpawn(CodeIsland)
								break
							end
						end
          end
        end
      end
    end
  end
}, "AutoDetectDungeon")

Tab:CreateDropdown({
  Name = "Dungeon Mode",
  Description = "Select the dungeon mode you want to do",
  Options = { "Teleport", "Bypass" },
  CurrentOption = {},
  MultipleOptions = false,
  SpecialType = nil,
  Callback = function()end
}, "DungeonMode")

local function BuyTicket()
  local Args = {
    [1] = {
      [1] = {
        ["Type"] = "Gems",
        ["Event"] = "DungeonAction",
        ["Action"] = "BuyTicket"
      },
      [2] = "\n"
    }
  }
  Remotes:FireServer(unpack(Args))
end

Tab:CreateToggle({
  Name = "Auto Buy Ticket",
  Callback = function()
    if not IsInDungeon() then BuyTicket() end
    while Flags.AutoBuyTicket.CurrentValue and task.wait(.1) do
      local WarnGui = Player.PlayerGui:FindFirstChild("Warn")
			if not WarnGui then continue end

			for _, Dungeon in ipairs(WarnGui:GetChildren()) do
				if not Dungeon:IsA("Frame") then continue end

				for _, Child in ipairs(Dungeon:GetChildren()) do
					if not Child:IsA("ImageLabel") then continue end

					local WarnMessage = Child:FindFirstChild("WarnMessage")
					if WarnMessage and WarnMessage:IsA("TextLabel") then
						if string.find(string.lower(WarnMessage.Text), "completed") then
              BuyTicket()
							break
						end
					end
				end
			end
    end
  end
}, "AutoBuyTicket")

Tab:CreateToggle({
  Name = "Auto Dungeon",
  Callback = function()
    if Flags.DungeonMode.CurrentOption == "Bypass" and not IsInDungeon() then
			CreateAndStartDungeon(Player.UserId)
		end

    task.spawn(function()
      while Flags.AutoDungeon.CurrentValue and task.wait(0.1) do
        local UpContainer = Player.PlayerGui.Hud:FindFirstChild("UpContanier")
        if UpContainer then
          local InfoText = UpContainer:FindFirstChild("DungeonInfo") and UpContainer.DungeonInfo.TextLabel.Text
          if InfoText and string.find(InfoText, "Dungeon End") then
            if Flags.DungeonMode.CurrentOption == "Teleport" then
              Rejoin(87039211657390)
            else
              CreateAndStartDungeon(Player.UserId)
            end
          end
        end
  
        if Flags.DungeonMode.CurrentOption == "Teleport" then
          for _, Obj in ipairs(Dungeon:GetChildren()) do
            if Obj:IsA("Part") then
              task.wait(0.1)
              Character:PivotTo(Obj.CFrame * CFrame.new(0, 0, 6))
              task.wait(0.3)
              CreateAndStartDungeon(Player.UserId)
            end
          end
        else
          local WarnGui = Player.PlayerGui:FindFirstChild("Warn")
          if not WarnGui then continue end
  
          for _, DungeonFrame in ipairs(WarnGui:GetChildren()) do
            if not DungeonFrame:IsA("Frame") then continue end
  
            for _, Child in ipairs(DungeonFrame:GetChildren()) do
              if not Child:IsA("ImageLabel") then continue end
  
              local WarnMessage = Child:FindFirstChild("WarnMessage")
              if WarnMessage and WarnMessage:IsA("TextLabel") then
                if string.find(string.lower(WarnMessage.Text), "reset!") then
                  CreateAndStartDungeon(Player.UserId)
                end
              end
            end
          end
        end
      end
    end)

    task.spawn(function()
      while Flags.AutoDungeon.CurrentValue and task.wait(0.1) do
        local Target
        repeat
          Target = GetAnyMob()
          task.wait(0.1)
        until Target and Target:IsA("Instance") and not Target:GetAttribute("Dead")

        if Target then
          local TargetPos = Target:GetPivot().Position
          local PlayerPos = Character:GetPivot().Position
          local Distance = (PlayerPos - TargetPos).Magnitude

          if Distance > 10 then
            Character:PivotTo(CFrame.new(TargetPos) * CFrame.new(0, 0, 6))
            task.wait(tonumber(Flags.DelayFarm.CurrentValue))
            ShadowAttack(Target)
          end
        end
      end
    end)
  end
}, "AutoDungeon")

local Tab: Tab = Window:CreateTab({
  Name = "Castle",
  Icon = "castle",
  ImageSource = "Lucide",
  ShowTitle = false
})

Tab:CreateSection("Farming")

Tab:CreateToggle({
  Name = "Use Last Checkpoint",
  Callback = function()end
}, "UseLastCheckpoint")

Tab:CreateToggle({
  Name = "Auto Castle",
  Callback = function()
    local LastFloor = nil

    while Flags.AutoCastle.CurrentValue and task.wait(0.1) do
      local Args = {
        [1] = {
          [1] = {
            ["Check"] = Flags.UseLastCheckpoint.CurrentValue,
            ["Event"] = "CastleAction",
            ["Action"] = "Join"
          },
          [2] = "\n"
        }
      }
      Remotes:FireServer(unpack(Args))

      local Target = GetAnyMob()
      if Target and Target:IsA("Instance") and not Target:GetAttribute("Dead") then
        if Target then
          local TargetPos = Target:GetPivot().Position
          local PlayerPos = Character:GetPivot().Position
          local Distance = (PlayerPos - TargetPos).Magnitude

          if Distance > 10 then
            Character:PivotTo(CFrame.new(TargetPos) * CFrame.new(0, 0, 6))
            task.wait(tonumber(Flags.DelayFarm.CurrentValue))
            ShadowAttack(Target)
          end
        end
      else
        local Worlds = workspace:FindFirstChild("__Main"):FindFirstChild("__World")
        local UpContainer = Player.PlayerGui.Hud:FindFirstChild("UpContanier")
        local RoomText = UpContainer and UpContainer:FindFirstChild("Room")

        if Worlds and RoomText and RoomText:IsA("TextLabel") then
          local UpText = RoomText.Text
          local CurrentFloor = tonumber(UpText:match("Floor: (%d+)/%d+"))

          if CurrentFloor then
            if LastFloor ~= CurrentFloor then
              LastFloor = CurrentFloor
              local TargetFloor = CurrentFloor + 1

              local TargetWorld
              repeat
                task.wait(.1)
                TargetWorld = Worlds:FindFirstChild("Room_" .. TargetFloor)
              until TargetWorld

              local PlayersSpawns
              repeat
                task.wait(.1)
                PlayersSpawns = TargetWorld:FindFirstChild("PlayersSpawns")
              until PlayersSpawns

              task.wait(.1)
              Character:PivotTo(PlayersSpawns:GetPivot())

              Notify("Floor", "Teleporting to Floor " .. TargetFloor, "castle", "Lucide")
            end
          end
        end
      end
    end
  end
}, "AutoCastle")

Tab:CreateInput({
  Name = "Floor",
  Description = "Automatically leave when reaching +1 this floor.",
  PlaceholderText = "25",
  CurrentValue = "",
  Numeric = true,
  MaxCharacters = 100,
  Enter = false,
  Callback = function(Value)
    local Number = tonumber(Value)
		if not Number or Number < 1 or Number > 100 then
			Notify("Invalid Floor", "Please enter a number between 1 and 100", "_error")
			Flags.FloorToLeave:Set({
        CurrentValue = 25
      })
		end
  end
}, "FloorToLeave")

Tab:CreateToggle({
  Name = "Auto Leave Floor",
  Callback = function()
    while Flags.AutoLeaveFloor.CurrentValue and task.wait(0.1) do
      local UpContainer = Player.PlayerGui.Hud:FindFirstChild("UpContanier")
			if not (UpContainer and UpContainer:FindFirstChild("Room") and UpContainer.Room:IsA("TextLabel")) then
				continue
			end

			local UpText = UpContainer.Room.Text
			local CurrentFloor = tonumber(UpText:match("Floor: (%d+)/%d+"))

			if CurrentFloor and CurrentFloor > tonumber(Flags.FloorToLeave.CurrentValue) then
				Rejoin(87039211657390)
			end
    end
  end
}, "AutoLeaveFloor")

local Tab: Tab = Window:CreateTab({
  Name = "Teleport",
  Icon = "sailboat",
  ImageSource = "Lucide",
  ShowTitle = false
})

Tab:CreateSection("Spawn")

Tab:CreateToggle({
  Name = "Save Spawn",
  Callback = function()end
}, "SaveSpawn")

local function TeleportToIsland(IslandName)
	if IslandName and Islands[IslandName] then
		if Flags.SaveSpawn.CurrentValue then
			local Args = {
				[1] = {
					[1] = {
						["Event"] = "ChangeSpawn",
						["Spawn"] = IslandName
					},
					[2] = "\n"
				}
			}
			Remotes:FireServer(unpack(Args))
			task.wait(.5)
		end
		task.wait(.1)
		Character:PivotTo(Islands[IslandName])
	end
end

Tab:CreateDropdown({
  Name = "Select Spawn",
  Description = "Select the spawn you want to teleport to",
  Options = IslandKeys,
  CurrentOption = {},
  MultipleOptions = false,
  SpecialType = nil,
  Callback = function(Value)
    if Value and Value ~= "" then
			Notify("Teleport", "Teleporting to " .. Value, "sailboat", "Lucide")
			TeleportToIsland(Value)
		else
			Notify("Teleport", "Invalid Island Name", "_error")
		end
  end
}, "SelectSpawn")

Tab:CreateButton({
	Name = "Dedu Island",
  Description = "Teleport to Dedu Island",
	Callback = function()
		Notify("Teleport", "Teleporting to Dedu Island", "sailboat", "Lucide")
		task.wait(.1)
		Character:PivotTo(CFrame.new(3856.48486, 60.1204987, 3077.04736, 0.3869977, -1.41971441e-07, 0.922080696, -2.65326292e-07, 1, 2.65326122e-07, -0.922080696, -3.47332843e-07, 0.3869977))
	end,
})

Tab:CreateButton({
  Name = "Winter Island",
  Description = "Teleport to Winter Raid",
  Callback = function()
    Notify("Teleport", "Teleporting to Winter Island", "sailboat", "Lucide")
    task.wait(.1)
    Character:PivotTo(CFrame.new(4782.6416, 29.7264385, -2043.24084, -0.953545272, -1.8529015e-09, 0.301249772, -2.27541319e-11, 1, 6.07869133e-09, -0.301249772, 5.78945292e-09, -0.953545272))
  end
})

local Tab: Tab = Window:CreateTab({
	Name = "QoL",
	Icon = "leaf",
	ImageSource = "Lucide",
	ShowTitle = false
})

Tab:CreateSection("QoL")

CreateFeature(Tab, "QoL")

local Tab: Tab = Window:CreateTab({
	Name = "Safety",
	Icon = "shield",
	ImageSource = "Material",
	ShowTitle = false
})

Tab:CreateSection("Identity")

CreateFeature(Tab, "HideIdentity")

local Tab: Tab = Window:CreateTab({
	Name = "Settings",
	Icon = "settings",
	ImageSource = "Lucide",
	ShowTitle = false
})

Tab:BuildConfigSection()

getgenv().CreateUniversalTabs()
