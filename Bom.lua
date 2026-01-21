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

-- UI Info
my_own_section:AddLabel("Credits: @Kenzie (Edited)")
my_own_section:AddParagraph(
    "Gold Bomb Jump",
    "Press BOMB once → place bomb & jump.\nCooldown 23s.\nDrag to move button."
)

-- CREATE GUI
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
    Outer.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
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
    CircleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CircleButton.Font = Enum.Font.GothamBold
    CircleButton.TextScaled = true
    CircleButton.Parent = Outer

    local InnerCorner = Instance.new("UICorner")
    InnerCorner.CornerRadius = UDim.new(1, 0)
    InnerCorner.Parent = CircleButton
end

-- Get position in front of player
function GetCenterPosition()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    local cam = workspace.CurrentCamera
    local hrp = char.HumanoidRootPart
    return CFrame.new(hrp.Position + cam.CFrame.LookVector * 5)
end

-- Jump
function MakeCharacterJump()
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end

-- PLACE BOMB + COOLDOWN
function PlaceGoldBombAndJump()
    local char = LocalPlayer.Character
    if not char then return end

    local bomb = char:FindFirstChild("GoldBomb")
    if bomb and bomb:FindFirstChild("Remote") then
        bomb.Remote:FireServer(GetCenterPosition(), 50)
        MakeCharacterJump()
    end

    CircleButton.Active = false
    CircleButton.BackgroundColor3 = Color3.fromRGB(120, 120, 120)

    for i = COOLDOWN_TIME, 1, -1 do
        CircleButton.Text = tostring(i)
        task.wait(1)
    end

    CircleButton.Text = "BOMB"
    CircleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    CircleButton.Active = true
    onCooldown = false
end

-- CLICK ACTION
function OnButtonClick()
    if dragging or onCooldown or not pluginEnabled then return end
    onCooldown = true

    pcall(function()
        ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer("GoldBomb")
    end)

    task.wait(0.1)
    PlaceGoldBombAndJump()
end

-- DRAG SYSTEM
function SetupDrag()
    CircleButton.MouseButton1Down:Connect(function()
        OnButtonClick()
    end)

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

-- TOGGLE
my_own_section:AddToggle("Enable Gold Bomb Jump", function(v)
    pluginEnabled = v
    if v then
        CreateGUI()
        SetupDrag()
        shared.Notify("Gold Bomb Jump enabled", 2)
    else
        if ScreenGui then ScreenGui:Destroy() end
        ScreenGui = nil
        onCooldown = false
    end
end)

print("Gold Bomb Jump Loaded (Final Version)")
