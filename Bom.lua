local shared = odh_shared_plugins
local my_own_section = shared.AddSection("GOLD BOMB JUMP")

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- Variables
local ScreenGui
local MainFrame
local CircleButton
local dragging = false
local dragStart
local startPos

local onCooldown = false
local COOLDOWN_TIME = 23 -- ✅ 23 GIÂY
local pluginEnabled = false
local bombEquipped = false
local cooldownCoroutine
local hardLock = false -- 🔒 KHÓA CỨNG INPUT

-- Credits
my_own_section:AddLabel("Credits: @Kenzie")
my_own_section:AddParagraph(
    "Gold Bomb Jump",
    "Tap once only. Auto GET → PLACE. 23s cooldown. Mobile safe."
)

-- GUI
local function CreateGUI()
    if ScreenGui then ScreenGui:Destroy() end

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "GoldBombGUI"
    ScreenGui.Parent = game:GetService("CoreGui")

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 70, 0, 70)
    MainFrame.Position = UDim2.new(0, 20, 0, 20)
    MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    MainFrame.BackgroundTransparency = 0.2
    MainFrame.Parent = ScreenGui

    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0.3, 0)

    CircleButton = Instance.new("TextButton")
    CircleButton.Size = UDim2.new(0, 50, 0, 50)
    CircleButton.Position = UDim2.new(0, 10, 0, 10)
    CircleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    CircleButton.Text = "GET"
    CircleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CircleButton.Font = Enum.Font.GothamBold
    CircleButton.TextSize = 12
    CircleButton.Parent = MainFrame

    Instance.new("UICorner", CircleButton).CornerRadius = UDim.new(0.3, 0)
end

-- Button animation
local function AnimateButtonPress()
    if not CircleButton then return end
    TweenService:Create(
        CircleButton,
        TweenInfo.new(0.08),
        {Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(0, 15, 0, 15)}
    ):Play()

    task.delay(0.08, function()
        TweenService:Create(
            CircleButton,
            TweenInfo.new(0.08),
            {Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(0, 10, 0, 10)}
        ):Play()
    end)
end

-- Position
local function GetCenterPosition()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local cam = workspace.CurrentCamera
    return CFrame.new(
        char.HumanoidRootPart.Position + cam.CFrame.LookVector * 5,
        char.HumanoidRootPart.Position
    )
end

local function Jump()
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end

local function ResetState()
    onCooldown = false
    bombEquipped = false
    hardLock = false
    if CircleButton then
        CircleButton.Text = "GET"
        CircleButton.Active = true
        CircleButton.BackgroundColor3 = Color3.fromRGB(0,170,255)
    end
end

local function StartCooldown()
    onCooldown = true
    CircleButton.Active = false
    CircleButton.BackgroundColor3 = Color3.fromRGB(100,100,100)

    cooldownCoroutine = coroutine.create(function()
        for i = COOLDOWN_TIME, 0, -1 do
            CircleButton.Text = tostring(i)
            task.wait(1)
        end
        onCooldown = false
        bombEquipped = false
        CircleButton.Text = "GET"
        CircleButton.Active = true
        CircleButton.BackgroundColor3 = Color3.fromRGB(0,170,255)
    end)
    coroutine.resume(cooldownCoroutine)
end

local function GetBomb()
    if onCooldown or bombEquipped then return end
    pcall(function()
        ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer("GoldBomb")
    end)
    bombEquipped = true
    CircleButton.Text = "PLACE"
    CircleButton.BackgroundColor3 = Color3.fromRGB(255,170,0)
end

local function PlaceBomb()
    local bomb = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("GoldBomb")
    if not bomb or not bomb:FindFirstChild("Remote") then
        ResetState()
        return
    end
    bomb.Remote:FireServer(GetCenterPosition(), 50)
    Jump()
    StartCooldown()
end

-- 🔥 BẤM 1 LẦN DUY NHẤT
local function OnPress()
    if hardLock or dragging or onCooldown or not pluginEnabled then return end
    hardLock = true

    if not bombEquipped then
        GetBomb()
    else
        PlaceBomb()
    end

    task.delay(0.15, function()
        hardLock = false
    end)
end

-- Input
local function SetupInput()
    CircleButton.Activated:Connect(function()
        AnimateButtonPress()
        OnPress()
    end)

    MainFrame.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch then
            dragStart = i.Position
            startPos = MainFrame.Position
        end
    end)

    MainFrame.InputChanged:Connect(function(i)
        if dragStart then
            local d = (i.Position - dragStart)
            if d.Magnitude > 10 then
                dragging = true
                MainFrame.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + d.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + d.Y
                )
            end
        end
    end)

    MainFrame.InputEnded:Connect(function()
        dragging = false
        dragStart = nil
    end)
end

-- Toggle
my_own_section:AddToggle("Enable Gold Bomb Jump", function(v)
    pluginEnabled = v
    if v then
        CreateGUI()
        SetupInput()
        shared.Notify("Gold Bomb Jump ON",2)
    else
        if ScreenGui then ScreenGui:Destroy() end
        ResetState()
    end
end)

print("Gold Bomb Jump loaded | FIXED | ONE TAP ONLY")
