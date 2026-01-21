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
local COOLDOWN_TIME = 23
local pluginEnabled = false
local bombEquipped = false
local cooldownCoroutine

-- Credits
my_own_section:AddLabel("Credits: @Kenzie (Edited)")
my_own_section:AddParagraph(
    "Gold Bomb Jump",
    "Press BOMB once to get bomb.\nAuto place + jump.\nCooldown 23s."
)

--------------------------------------------------
-- GUI
--------------------------------------------------
function CreateGUI()
    if ScreenGui then ScreenGui:Destroy() end

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "GoldBombGUI"
    ScreenGui.Parent = game:GetService("CoreGui")

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 90, 0, 90)
    MainFrame.Position = UDim2.new(0, 20, 0, 200)
    MainFrame.BackgroundTransparency = 1
    MainFrame.Parent = ScreenGui

    -- Outer black circle
    local Outer = Instance.new("Frame")
    Outer.Size = UDim2.new(1, 0, 1, 0)
    Outer.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Outer.Parent = MainFrame

    local OuterCorner = Instance.new("UICorner")
    OuterCorner.CornerRadius = UDim.new(1, 0)
    OuterCorner.Parent = Outer

    -- Inner blue button
    CircleButton = Instance.new("TextButton")
    CircleButton.Size = UDim2.new(0.75, 0, 0.75, 0)
    CircleButton.Position = UDim2.new(0.125, 0, 0.125, 0)
    CircleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    CircleButton.Text = "BOMB"
    CircleButton.TextColor3 = Color3.new(1,1,1)
    CircleButton.Font = Enum.Font.GothamBold
    CircleButton.TextScaled = true
    CircleButton.Parent = Outer

    local InnerCorner = Instance.new("UICorner")
    InnerCorner.CornerRadius = UDim.new(1, 0)
    InnerCorner.Parent = CircleButton
end

--------------------------------------------------
-- POSITION
--------------------------------------------------
function GetCenterPosition()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    local cam = workspace.CurrentCamera
    local hrp = char.HumanoidRootPart
    return CFrame.new(hrp.Position + cam.CFrame.LookVector * 5)
end

--------------------------------------------------
-- JUMP
--------------------------------------------------
function MakeCharacterJump()
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end

--------------------------------------------------
-- COOLDOWN
--------------------------------------------------
function StartCooldown()
    CircleButton.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
    CircleButton.Active = false

    cooldownCoroutine = coroutine.create(function()
        for i = COOLDOWN_TIME, 1, -1 do
            CircleButton.Text = tostring(i)
            wait(1)
        end

        onCooldown = false
        bombEquipped = false
        CircleButton.Text = "BOMB"
        CircleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        CircleButton.Active = true
    end)

    coroutine.resume(cooldownCoroutine)
end

--------------------------------------------------
-- GET BOMB
--------------------------------------------------
function GetGoldBomb()
    local args = {"GoldBomb"}
    pcall(function()
        ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer(unpack(args))
    end)
    bombEquipped = true
end

--------------------------------------------------
-- PLACE + JUMP
--------------------------------------------------
function PlaceGoldBombAndJump()
    local char = LocalPlayer.Character
    if not char then return end

    local bomb = char:FindFirstChild("GoldBomb")
    if bomb and bomb:FindFirstChild("Remote") then
        bomb.Remote:FireServer(GetCenterPosition(), 50)
        MakeCharacterJump()
        StartCooldown()
    else
        onCooldown = false
        CircleButton.Active = true
    end
end

--------------------------------------------------
-- CLICK
--------------------------------------------------
function OnButtonClick()
    if dragging or onCooldown or not pluginEnabled then return end

    onCooldown = true
    CircleButton.Active = false

    GetGoldBomb()
    task.wait(0.15)
    PlaceGoldBombAndJump()
end

--------------------------------------------------
-- DRAG + CLICK
--------------------------------------------------
function SetupDragSystem()
    CircleButton.MouseButton1Click:Connect(OnButtonClick)

    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)

    MainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch and dragStart then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    MainFrame.InputEnded:Connect(function()
        dragStart = nil
    end)
end

--------------------------------------------------
-- RESET ON DEATH
--------------------------------------------------
LocalPlayer.CharacterAdded:Connect(function()
    onCooldown = false
    bombEquipped = false
end)

--------------------------------------------------
-- TOGGLE
--------------------------------------------------
my_own_section:AddToggle("Enable Gold Bomb Jump", function(v)
    pluginEnabled = v
    if v then
        CreateGUI()
        SetupDragSystem()
        shared.Notify("Gold Bomb Jump Enabled", 2)
    else
        if ScreenGui then ScreenGui:Destroy() end
        ScreenGui = nil
        onCooldown = false
        bombEquipped = false
    end
end)

print("Gold Bomb Jump Loaded (Perfect Version)")
