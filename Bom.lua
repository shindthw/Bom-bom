-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- CONFIG
local COOLDOWN_TIME = 23
local onCooldown = false

-- ====== HÀM CHÍNH ======
local function DoActionOnce()
	if onCooldown then return end
	onCooldown = true

	-- ==== HÀNH ĐỘNG BẠN MUỐN (VD: Gold Bomb Jump) ====
	local character = LocalPlayer.Character
	if character then
		local bomb = character:FindFirstChild("GoldBomb")
		if bomb and bomb:FindFirstChild("Remote") then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local cf = hrp.CFrame * CFrame.new(0, 0, -5)
				pcall(function()
					bomb.Remote:FireServer(cf, 50)
				end)
			end
		end

		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
	-- ================================================

	-- Cooldown
	task.delay(COOLDOWN_TIME, function()
		onCooldown = false
	end)
end

-- ====== BẮT SỰ KIỆN CHẠM MÀN HÌNH ======
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end

	if input.UserInputType == Enum.UserInputType.Touch
	or input.UserInputType == Enum.UserInputType.MouseButton1 then
		DoActionOnce()
	end
end)

print("✔ One Tap Screen System Loaded | Cooldown:", COOLDOWN_TIME)
