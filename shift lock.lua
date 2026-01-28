-- ShiftLockController.lua (sửa lỗi, thêm debounce, dùng Connect/Disconnect)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Lưu ý: UserSettings() vẫn hoạt động nhưng có thể khác trên một số môi trường
local Settings = UserSettings()
local GameSettings = Settings.GameSettings

local ShiftLockController = {}

-- Đợi LocalPlayer sẵn sàng
while not Players.LocalPlayer do
    wait()
end

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- UI (nếu bạn có ScreenGui/ShiftLockIcon, gán vào đây)
local ScreenGui, ShiftLockIcon

-- Trạng thái
local InputCn
local IsShiftLockMode = true
local IsShiftLocked = true
local IsActionBound = false
local IsInFirstPerson = false

-- Debounce để tránh bật/tắt quá nhanh
local toggleDebounce = false
local TOGGLE_COOLDOWN = 0.12

ShiftLockController.OnShiftLockToggled = Instance.new("BindableEvent")

local function isShiftLockMode()
    -- Kiểm tra điều kiện bật shift lock
    return LocalPlayer.DevEnableMouseLock
        and GameSettings.ControlMode == Enum.ControlMode.MouseLockSwitch
        and LocalPlayer.DevComputerMovementMode ~= Enum.DevComputerMovementMode.ClickToMove
        and GameSettings.ComputerMovementMode ~= Enum.ComputerMovementMode.ClickToMove
        and LocalPlayer.DevComputerMovementMode ~= Enum.DevComputerMovementMode.Scriptable
end

if not UserInputService.TouchEnabled then
    IsShiftLockMode = isShiftLockMode()
end

local function applyShiftLockVisuals(enable)
    -- Thao tác với camera / chuột để tránh xung đột và giảm giật
    if enable then
        -- Khóa con trỏ ở giữa màn hình
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        -- Nếu muốn can thiệp camera trực tiếp, cân nhắc đặt Scriptable và dùng RenderStepped để nội suy
        -- workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
    else
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        -- workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    end
end

local function onShiftLockToggled()
    if toggleDebounce then return end
    toggleDebounce = true
    task.delay(TOGGLE_COOLDOWN, function()
        toggleDebounce = false
    end)

    IsShiftLocked = not IsShiftLocked
    applyShiftLockVisuals(IsShiftLocked)
    ShiftLockController.OnShiftLockToggled:Fire(IsShiftLocked)
end

local function initialize()
    -- Khởi tạo UI hoặc trạng thái ban đầu nếu cần
    print("ShiftLockController enabled")
end

function ShiftLockController:IsShiftLocked()
    return IsShiftLockMode and IsShiftLocked
end

function ShiftLockController:SetIsInFirstPerson(isInFirstPerson)
    IsInFirstPerson = isInFirstPerson
end

-- Xử lý khi nhấn phím (chỉ quan tâm LeftShift / RightShift)
local function onShiftInputBegan(inputObject, isProcessed)
    if isProcessed then return end
    if inputObject.UserInputType == Enum.UserInputType.Keyboard then
        local kc = inputObject.KeyCode
        if kc == Enum.KeyCode.LeftShift or kc == Enum.KeyCode.RightShift then
            if IsShiftLockMode then
                onShiftLockToggled()
            end
        end
    end
end

local function mouseLockSwitchFunc(actionName, inputState, inputObject)
    if IsShiftLockMode then
        onShiftLockToggled()
    end
end

local function disableShiftLock()
    if ScreenGui then
        ScreenGui.Parent = nil
    end
    IsShiftLockMode = false
    Mouse.Icon = ""
    if InputCn then
        InputCn:Disconnect()
        InputCn = nil
    end
    IsActionBound = false
    applyShiftLockVisuals(false)
    ShiftLockController.OnShiftLockToggled:Fire(false)
end

local function enableShiftLock()
    IsShiftLockMode = isShiftLockMode()
    if IsShiftLockMode then
        if ScreenGui then
            ScreenGui.Parent = PlayerGui
        end
        if IsShiftLocked then
            ShiftLockController.OnShiftLockToggled:Fire(true)
            applyShiftLockVisuals(true)
        end
        if not IsActionBound then
            InputCn = UserInputService.InputBegan:Connect(onShiftInputBegan)
            IsActionBound = true
        end
    end
end

-- Lắng nghe thay đổi cài đặt
GameSettings.Changed:Connect(function(property)
    if property == "ControlMode" then
        if GameSettings.ControlMode == Enum.ControlMode.MouseLockSwitch then
            enableShiftLock()
        else
            disableShiftLock()
        end
    elseif property == "ComputerMovementMode" then
        if GameSettings.ComputerMovementMode == Enum.ComputerMovementMode.ClickToMove then
            disableShiftLock()
        else
            enableShiftLock()
        end
    end
end)

-- Lắng nghe thay đổi LocalPlayer
LocalPlayer.Changed:Connect(function(property)
    if property == "DevEnableMouseLock" then
        if LocalPlayer.DevEnableMouseLock then
            enableShiftLock()
        else
            disableShiftLock()
        end
    elseif property == "DevComputerMovementMode" then
        if LocalPlayer.DevComputerMovementMode == Enum.DevComputerMovementMode.ClickToMove
            or LocalPlayer.DevComputerMovementMode == Enum.DevComputerMovementMode.Scriptable then
            disableShiftLock()
        else
            enableShiftLock()
        end
    end
end)

-- Khi respawn
LocalPlayer.CharacterAdded:Connect(function(character)
    if not UserInputService.TouchEnabled then
        initialize()
    end
end)

-- Khởi tạo ban đầu
if not UserInputService.TouchEnabled then
    initialize()
    if isShiftLockMode() then
        InputCn = UserInputService.InputBegan:Connect(onShiftInputBegan)
        IsActionBound = true
    end
end

enableShiftLock()

return ShiftLockController
