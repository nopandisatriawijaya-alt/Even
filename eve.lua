--// EVENT DETECTOR
--// DISCORD: EMOJI + NAMA EVENT SAJA
--// 1 NOTIFIKASI PER KEMUNCULAN EVENT

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--------------------------------------------------
-- CONFIG
--------------------------------------------------

local SCAN_INTERVAL = 0.25
local NO_EVENT_LOG_INTERVAL = 1
local MAX_LOGS = 8

--------------------------------------------------
-- EVENT ASSET
--------------------------------------------------

local EVENT_ICONS = {
    ["132941749130533"] = {
        name = "ANGSA EMAS",
        emoji = "🦢",
    },

    ["124768713967948"] = {
        name = "DINOSAURUS",
        emoji = "🦖",
    },

    ["138056176344406"] = {
        name = "METEOR",
        emoji = "☄️",
    },

    ["88536886295174"] = {
        name = "UFO",
        emoji = "🛸",
    },
}

--------------------------------------------------
-- STATE
--------------------------------------------------

local running = true
local elapsed = 0
local lastNoEventLog = 0

local watchedObjects = {}
local activeEvents = {}
local logItems = {}

--------------------------------------------------
-- WEBHOOK
--------------------------------------------------

local DISCORD_WEBHOOK = ""

local function sendWebhook(eventData)
    if DISCORD_WEBHOOK == "" then
        return
    end

    local requestFunction =
        request
        or http_request
        or (syn and syn.request)

    if not requestFunction then
        return
    end

    -- HANYA EMOJI + NAMA EVENT
    local body = {
        content = eventData.emoji .. " " .. eventData.name
    }

    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(body)
    end)

    if not ok then
        return
    end

    pcall(function()
        requestFunction({
            Url = DISCORD_WEBHOOK,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = encoded
        })
    end)
end

--------------------------------------------------
-- ASSET ID
--------------------------------------------------

local function getAssetId(image)
    if image == nil then
        return nil
    end

    local value = tostring(image)

    if value == "" then
        return nil
    end

    local id = value:match("rbxassetid://(%d+)")

    if id then
        return id
    end

    id = value:match("[?&]id=(%d+)")

    if id then
        return id
    end

    id = value:match("[?&]assetId=(%d+)")

    if id then
        return id
    end

    return value:match("(%d+)")
end

--------------------------------------------------
-- DETECT ICON
--------------------------------------------------

local function detectIcon(object)
    if not object then
        return nil
    end

    if not (
        object:IsA("ImageLabel")
        or object:IsA("ImageButton")
    ) then
        return nil
    end

    local image

    pcall(function()
        image = object.Image
    end)

    local assetId = getAssetId(image)

    if not assetId then
        return nil
    end

    local eventData = EVENT_ICONS[assetId]

    if eventData then
        return eventData, assetId
    end

    return nil
end

--------------------------------------------------
-- UI
--------------------------------------------------

local guiParent = PlayerGui

pcall(function()
    if gethui then
        guiParent = gethui()
    end
end)

local oldUI = guiParent:FindFirstChild("EventDetectorUI")

if oldUI then
    oldUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EventDetectorUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = guiParent

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(390, 430)
Main.Position = UDim2.new(0.5, -195, 0.5, -215)
Main.BackgroundColor3 = Color3.fromRGB(18, 20, 27)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(55, 60, 75)
MainStroke.Thickness = 1
MainStroke.Parent = Main

--------------------------------------------------
-- HEADER
--------------------------------------------------

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 58)
Header.BackgroundColor3 = Color3.fromRGB(25, 28, 38)
Header.BorderSizePixel = 0
Header.Parent = Main

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 14)
HeaderCorner.Parent = Header

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Position = UDim2.fromOffset(18, 7)
Title.Size = UDim2.fromOffset(270, 27)
Title.Font = Enum.Font.GothamBold
Title.Text = "⚡ EVENT DETECTOR"
Title.TextColor3 = Color3.fromRGB(245, 247, 255)
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.BackgroundTransparency = 1
Subtitle.Position = UDim2.fromOffset(19, 33)
Subtitle.Size = UDim2.fromOffset(250, 17)
Subtitle.Font = Enum.Font.Gotham
Subtitle.Text = "FULL AUTO SCANNER"
Subtitle.TextColor3 = Color3.fromRGB(130, 138, 155)
Subtitle.TextSize = 10
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.fromOffset(9, 9)
StatusDot.Position = UDim2.new(1, -76, 0, 19)
StatusDot.BackgroundColor3 = Color3.fromRGB(70, 220, 120)
StatusDot.BorderSizePixel = 0
StatusDot.Parent = Header

local DotCorner = Instance.new("UICorner")
DotCorner.CornerRadius = UDim.new(1, 0)
DotCorner.Parent = StatusDot

local Live = Instance.new("TextLabel")
Live.BackgroundTransparency = 1
Live.Position = UDim2.new(1, -62, 0, 12)
Live.Size = UDim2.fromOffset(48, 22)
Live.Font = Enum.Font.GothamBold
Live.Text = "LIVE"
Live.TextColor3 = Color3.fromRGB(90, 225, 135)
Live.TextSize = 11
Live.TextXAlignment = Enum.TextXAlignment.Left
Live.Parent = Header

--------------------------------------------------
-- LOG TITLE
--------------------------------------------------

local LogTitle = Instance.new("TextLabel")
LogTitle.BackgroundTransparency = 1
LogTitle.Position = UDim2.fromOffset(18, 70)
LogTitle.Size = UDim2.fromOffset(200, 22)
LogTitle.Font = Enum.Font.GothamBold
LogTitle.Text = "EVENT LOG"
LogTitle.TextColor3 = Color3.fromRGB(220, 224, 235)
LogTitle.TextSize = 12
LogTitle.TextXAlignment = Enum.TextXAlignment.Left
LogTitle.Parent = Main

local Counter = Instance.new("TextLabel")
Counter.BackgroundTransparency = 1
Counter.Position = UDim2.new(1, -120, 0, 70)
Counter.Size = UDim2.fromOffset(100, 22)
Counter.Font = Enum.Font.Code
Counter.Text = "[0.0]"
Counter.TextColor3 = Color3.fromRGB(120, 130, 150)
Counter.TextSize = 11
Counter.TextXAlignment = Enum.TextXAlignment.Right
Counter.Parent = Main

--------------------------------------------------
-- LOG BOX
--------------------------------------------------

local LogBox = Instance.new("ScrollingFrame")
LogBox.Position = UDim2.fromOffset(16, 96)
LogBox.Size = UDim2.new(1, -32, 0, 205)
LogBox.BackgroundColor3 = Color3.fromRGB(10, 12, 17)
LogBox.BorderSizePixel = 0
LogBox.ScrollBarThickness = 3
LogBox.ScrollBarImageColor3 = Color3.fromRGB(70, 78, 95)
LogBox.ScrollingDirection = Enum.ScrollingDirection.Y
LogBox.ClipsDescendants = true
LogBox.CanvasSize = UDim2.fromScale(0, 0)
LogBox.Parent = Main

local LogCorner = Instance.new("UICorner")
LogCorner.CornerRadius = UDim.new(0, 10)
LogCorner.Parent = LogBox

local LogPadding = Instance.new("UIPadding")
LogPadding.PaddingTop = UDim.new(0, 8)
LogPadding.PaddingBottom = UDim.new(0, 8)
LogPadding.PaddingLeft = UDim.new(0, 10)
LogPadding.PaddingRight = UDim.new(0, 10)
LogPadding.Parent = LogBox

local LogLayout = Instance.new("UIListLayout")
LogLayout.Padding = UDim.new(0, 2)
LogLayout.SortOrder = Enum.SortOrder.LayoutOrder
LogLayout.Parent = LogBox

--------------------------------------------------
-- LOG SYSTEM
--------------------------------------------------

local function updateCanvas()
    LogBox.CanvasSize = UDim2.fromOffset(
        0,
        math.max(
            LogLayout.AbsoluteContentSize.Y + 16,
            LogBox.AbsoluteSize.Y
        )
    )
end

local function addLog(text)
    while #logItems >= MAX_LOGS do
        local oldest = table.remove(logItems, 1)

        if oldest then
            oldest:Destroy()
        end
    end

    local label = Instance.new("TextLabel")

    label.Size = UDim2.new(1, -2, 0, 20)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Code
    label.Text = tostring(text)
    label.TextColor3 = Color3.fromRGB(195, 200, 214)
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.ClipsDescendants = true
    label.Parent = LogBox

    table.insert(logItems, label)

    updateCanvas()

    task.defer(function()
        LogBox.CanvasPosition = Vector2.new(
            0,
            math.max(
                0,
                LogLayout.AbsoluteContentSize.Y
                - LogBox.AbsoluteSize.Y
            )
        )
    end)
end

--------------------------------------------------
-- WEBHOOK INPUT
--------------------------------------------------

local WebhookBox = Instance.new("Frame")
WebhookBox.Position = UDim2.fromOffset(16, 313)
WebhookBox.Size = UDim2.new(1, -32, 0, 55)
WebhookBox.BackgroundColor3 = Color3.fromRGB(25, 28, 38)
WebhookBox.BorderSizePixel = 0
WebhookBox.Parent = Main

local WebhookCorner = Instance.new("UICorner")
WebhookCorner.CornerRadius = UDim.new(0, 10)
WebhookCorner.Parent = WebhookBox

local WebhookInput = Instance.new("TextBox")
WebhookInput.Position = UDim2.fromOffset(10, 8)
WebhookInput.Size = UDim2.new(1, -95, 0, 38)
WebhookInput.BackgroundColor3 = Color3.fromRGB(15, 17, 23)
WebhookInput.BorderSizePixel = 0
WebhookInput.ClearTextOnFocus = false
WebhookInput.Font = Enum.Font.Gotham
WebhookInput.PlaceholderText = "Discord Webhook..."
WebhookInput.Text = ""
WebhookInput.TextColor3 = Color3.fromRGB(230, 233, 240)
WebhookInput.PlaceholderColor3 = Color3.fromRGB(100, 106, 120)
WebhookInput.TextSize = 10
WebhookInput.TextTruncate = Enum.TextTruncate.AtEnd
WebhookInput.Parent = WebhookBox

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 8)
InputCorner.Parent = WebhookInput

local SetButton = Instance.new("TextButton")
SetButton.Position = UDim2.new(1, -78, 0, 8)
SetButton.Size = UDim2.fromOffset(68, 38)
SetButton.BackgroundColor3 = Color3.fromRGB(55, 110, 210)
SetButton.BorderSizePixel = 0
SetButton.Font = Enum.Font.GothamBold
SetButton.Text = "SET"
SetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SetButton.TextSize = 11
SetButton.Parent = WebhookBox

local SetCorner = Instance.new("UICorner")
SetCorner.CornerRadius = UDim.new(0, 8)
SetCorner.Parent = SetButton

SetButton.MouseButton1Click:Connect(function()
    DISCORD_WEBHOOK = WebhookInput.Text

    if DISCORD_WEBHOOK ~= "" then
        SetButton.Text = "OK"

        task.delay(1, function()
            if SetButton.Parent then
                SetButton.Text = "SET"
            end
        end)
    end
end)

--------------------------------------------------
-- DRAG
--------------------------------------------------

local dragging = false
local dragStart
local startPosition

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = Main.Position
    end
end)

Header.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then
        return
    end

    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local delta = input.Position - dragStart

    Main.Position = UDim2.new(
        startPosition.X.Scale,
        startPosition.X.Offset + delta.X,
        startPosition.Y.Scale,
        startPosition.Y.Offset + delta.Y
    )
end)

--------------------------------------------------
-- EVENT PROCESS
--------------------------------------------------

local function processIcon(object)
    if not object then
        return false
    end

    local eventData, assetId = detectIcon(object)

    --------------------------------------------------
    -- ICON BUKAN EVENT
    -- RESET STATUS OBJECT
    --------------------------------------------------

    if not eventData then
        if activeEvents[object] then
            activeEvents[object] = nil
        end

        return false
    end

    --------------------------------------------------
    -- EVENT SUDAH AKTIF PADA OBJECT INI
    --------------------------------------------------

    if activeEvents[object] == assetId then
        return true
    end

    --------------------------------------------------
    -- EVENT BARU MUNCUL
    --------------------------------------------------

    activeEvents[object] = assetId

    addLog(
        eventData.emoji
        .. " "
        .. eventData.name
        .. string.format(
            " [%.1f]",
            elapsed
        )
    )

    --------------------------------------------------
    -- KIRIM SEKALI
    --------------------------------------------------

    task.spawn(function()
        sendWebhook(eventData)
    end)

    return true
end

--------------------------------------------------
-- WATCH IMAGE
--------------------------------------------------

local function watchIcon(object)
    if watchedObjects[object] then
        return
    end

    if not (
        object:IsA("ImageLabel")
        or object:IsA("ImageButton")
    ) then
        return
    end

    watchedObjects[object] = true

    object:GetPropertyChangedSignal("Image"):Connect(function()
        if running then
            processIcon(object)
        end
    end)

    object.AncestryChanged:Connect(function(_, parent)
        if not parent then
            watchedObjects[object] = nil
            activeEvents[object] = nil
        end
    end)

    processIcon(object)
end

--------------------------------------------------
-- SCAN
--------------------------------------------------

local function scanContainer(container)
    local found = false

    local success, objects = pcall(function()
        return container:GetDescendants()
    end)

    if not success or not objects then
        return false
    end

    for _, object in ipairs(objects) do
        if object:IsA("ImageLabel")
            or object:IsA("ImageButton") then

            watchIcon(object)

            if processIcon(object) then
                found = true
            end
        end
    end

    return found
end

--------------------------------------------------
-- INITIAL SCAN
--------------------------------------------------

scanContainer(PlayerGui)
scanContainer(CoreGui)

--------------------------------------------------
-- NEW OBJECT PLAYERGUI
--------------------------------------------------

PlayerGui.DescendantAdded:Connect(function(object)
    if not running then
        return
    end

    if object:IsA("ImageLabel")
        or object:IsA("ImageButton") then

        task.defer(function()
            watchIcon(object)
            processIcon(object)
        end)
    end
end)

--------------------------------------------------
-- NEW OBJECT COREGUI
--------------------------------------------------

pcall(function()
    CoreGui.DescendantAdded:Connect(function(object)
        if not running then
            return
        end

        if object:IsA("ImageLabel")
            or object:IsA("ImageButton") then

            task.defer(function()
                watchIcon(object)
                processIcon(object)
            end)
        end
    end)
end)

--------------------------------------------------
-- FULL SCANNER
--------------------------------------------------

task.spawn(function()
    while running do

        elapsed += SCAN_INTERVAL

        elapsed = math.round(
            elapsed * 10
        ) / 10

        Counter.Text = string.format(
            "[%.1f]",
            elapsed
        )

        local foundPlayer =
            scanContainer(PlayerGui)

        local foundCore =
            scanContainer(CoreGui)

        local foundEvent =
            foundPlayer or foundCore

        --------------------------------------------------
        -- LOG TIDAK ADA
        --------------------------------------------------

        if not foundEvent
            and elapsed - lastNoEventLog
                >= NO_EVENT_LOG_INTERVAL then

            lastNoEventLog = elapsed

            addLog(
                string.format(
                    "[Event] tidak ada [%.1f]",
                    elapsed
                )
            )
        end

        task.wait(SCAN_INTERVAL)
    end
end)

--------------------------------------------------
-- START
--------------------------------------------------

addLog("[Event] tidak ada [0.0]")
