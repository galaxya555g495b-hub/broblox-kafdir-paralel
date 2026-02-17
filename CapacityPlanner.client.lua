--!strict
-- Roblox Studio LocalScript (single file)
-- Place this script under StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

type NumberMap = {[string]: number}
type AdminCode = {
	code: string,
	name: string,
	usage: string,
}

local function create(className: string, props: {[string]: any}, parent: Instance?): Instance
	local instance = Instance.new(className)
	for key, value in pairs(props) do
		(instance :: any)[key] = value
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

local function calculatePlan(rpm: number, avgMs: number, utilization: number, burst: number)
	if rpm <= 0 or avgMs <= 0 or burst < 1 then
		return nil, "RPM ve job süresi 0'dan büyük, burst factor en az 1 olmalı."
	end

	if utilization < 0.1 or utilization > 0.95 then
		return nil, "Target utilization 0.1 ile 0.95 arasında olmalı."
	end

	local requestsPerSecond = rpm / 60
	local serviceTimeSeconds = avgMs / 1000

	local recommendedWorkers = math.ceil((requestsPerSecond * serviceTimeSeconds) / utilization)
	local recommendedQueueLimit = math.ceil(recommendedWorkers * 100 * burst)
	local recommendedMaxCapacity = math.ceil(recommendedWorkers * 60 * utilization * burst)

	return {
		recommendedWorkers = recommendedWorkers,
		recommendedQueueLimit = recommendedQueueLimit,
		recommendedMaxCapacity = recommendedMaxCapacity,
	}, nil
end

local function buildAdminCodes(): {AdminCode}
	local actions = {
		{"KICK", "Oyuncuyu oyundan at"},
		{"BAN", "Oyuncuya ban uygula"},
		{"MUTE", "Oyuncunun sohbetini kapat"},
		{"UNMUTE", "Sohbet kısıtını kaldır"},
		{"FREEZE", "Oyuncuyu sabitle"},
		{"UNFREEZE", "Sabitliği kaldır"},
		{"HEAL", "Canını doldur"},
		{"GOD", "Ölümsüz mod aç"},
		{"UNGOD", "Ölümsüz modu kapat"},
		{"SPEED", "Hızı ayarla"},
		{"JUMP", "Zıplama gücünü ayarla"},
		{"TP", "Belirtilen konuma ışınla"},
		{"BRING", "Oyuncuyu yanına çek"},
		{"GIVE", "Item verme komutu"},
		{"ANNOUNCE", "Sunucu duyurusu yayınla"},
	}

	local list: {AdminCode} = {}
	for _, actionInfo in ipairs(actions) do
		local action = actionInfo[1]
		local desc = actionInfo[2]
		for tier = 1, 10 do
			local level = string.format("L%02d", tier)
			local code = string.format("ADM-%s-%s", action, level)
			table.insert(list, {
				code = code,
				name = string.format("%s Seviye %d", action, tier),
				usage = string.format("%s (yetki seviyesi %d)", desc, tier),
			})
		end
	end

	return list
end

local ADMIN_CODES = buildAdminCodes() -- 15 * 10 = 150

local gui = create("ScreenGui", {
	Name = "CapacityPlannerGui",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local frame = create("Frame", {
	Name = "MainCard",
	Size = UDim2.fromOffset(980, 540),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BorderSizePixel = 0,
}, gui)

create("UICorner", {CornerRadius = UDim.new(0, 14)}, frame)
create("UIStroke", {Color = Color3.fromRGB(217, 224, 239), Thickness = 1}, frame)

create("TextLabel", {
	Size = UDim2.new(1, -24, 0, 30),
	Position = UDim2.fromOffset(12, 10),
	BackgroundTransparency = 1,
	Text = "Kapasite + Admin Kod Paneli (LocalScript)",
	Font = Enum.Font.GothamBold,
	TextSize = 20,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(29, 35, 48),
}, frame)

create("TextLabel", {
	Size = UDim2.new(1, -24, 0, 20),
	Position = UDim2.fromOffset(12, 40),
	BackgroundTransparency = 1,
	Text = "Solda kapasite planlayıcı, sağda 150 admin kodu listesi.",
	Font = Enum.Font.Gotham,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(92, 104, 130),
}, frame)

local leftPanel = create("Frame", {
	Size = UDim2.fromOffset(440, 450),
	Position = UDim2.fromOffset(20, 75),
	BackgroundColor3 = Color3.fromRGB(248, 250, 255),
	BorderSizePixel = 0,
}, frame)
create("UICorner", {CornerRadius = UDim.new(0, 10)}, leftPanel)
create("UIStroke", {Color = Color3.fromRGB(217, 224, 239), Thickness = 1}, leftPanel)

create("TextLabel", {
	Size = UDim2.new(1, -20, 0, 24),
	Position = UDim2.fromOffset(10, 8),
	BackgroundTransparency = 1,
	Text = "Kapasite Planlayıcı",
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(29, 35, 48),
}, leftPanel)

local function createField(parent: Instance, y: number, labelText: string, defaultValue: string)
	create("TextLabel", {
		Size = UDim2.fromOffset(300, 18),
		Position = UDim2.fromOffset(14, y),
		BackgroundTransparency = 1,
		Text = labelText,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(92, 104, 130),
	}, parent)

	local input = create("TextBox", {
		Size = UDim2.fromOffset(280, 34),
		Position = UDim2.fromOffset(14, y + 20),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		TextColor3 = Color3.fromRGB(29, 35, 48),
		Text = defaultValue,
		PlaceholderText = defaultValue,
		Font = Enum.Font.Gotham,
		TextSize = 14,
		ClearTextOnFocus = false,
	}, parent)
	create("UICorner", {CornerRadius = UDim.new(0, 8)}, input)
	create("UIStroke", {Color = Color3.fromRGB(217, 224, 239), Thickness = 1}, input)

	return input
end

local rpmBox = createField(leftPanel, 44, "Requests per minute", "4800")
local avgMsBox = createField(leftPanel, 104, "Average job (ms)", "220")
local utilizationBox = createField(leftPanel, 164, "Target utilization (0.1 - 0.95)", "0.70")
local burstBox = createField(leftPanel, 224, "Burst factor (>= 1)", "1.5")

local errorLabel = create("TextLabel", {
	Size = UDim2.new(1, -24, 0, 20),
	Position = UDim2.fromOffset(14, 278),
	BackgroundTransparency = 1,
	Text = "",
	Font = Enum.Font.Gotham,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(198, 40, 40),
}, leftPanel)

local resultLabel = create("TextLabel", {
	Size = UDim2.new(1, -24, 0, 100),
	Position = UDim2.fromOffset(14, 336),
	BackgroundColor3 = Color3.fromRGB(245, 247, 251),
	Text = "Hesaplama sonucu burada görünecek.",
	Font = Enum.Font.Code,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextColor3 = Color3.fromRGB(39, 48, 74),
}, leftPanel)
create("UICorner", {CornerRadius = UDim.new(0, 8)}, resultLabel)

local calculateButton = create("TextButton", {
	Size = UDim2.fromOffset(120, 34),
	Position = UDim2.fromOffset(308, 184),
	BackgroundColor3 = Color3.fromRGB(68, 80, 240),
	Text = "Hesapla",
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextColor3 = Color3.fromRGB(255, 255, 255),
}, leftPanel)
create("UICorner", {CornerRadius = UDim.new(0, 8)}, calculateButton)

local resetButton = create("TextButton", {
	Size = UDim2.fromOffset(120, 34),
	Position = UDim2.fromOffset(308, 224),
	BackgroundColor3 = Color3.fromRGB(230, 233, 245),
	Text = "Sıfırla",
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextColor3 = Color3.fromRGB(39, 48, 74),
}, leftPanel)
create("UICorner", {CornerRadius = UDim.new(0, 8)}, resetButton)

local rightPanel = create("Frame", {
	Size = UDim2.fromOffset(500, 450),
	Position = UDim2.fromOffset(470, 75),
	BackgroundColor3 = Color3.fromRGB(248, 250, 255),
	BorderSizePixel = 0,
}, frame)
create("UICorner", {CornerRadius = UDim.new(0, 10)}, rightPanel)
create("UIStroke", {Color = Color3.fromRGB(217, 224, 239), Thickness = 1}, rightPanel)

create("TextLabel", {
	Size = UDim2.new(1, -20, 0, 24),
	Position = UDim2.fromOffset(10, 8),
	BackgroundTransparency = 1,
	Text = "Admin Kodları (150)",
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(29, 35, 48),
}, rightPanel)

local countLabel = create("TextLabel", {
	Size = UDim2.fromOffset(220, 18),
	Position = UDim2.fromOffset(12, 32),
	BackgroundTransparency = 1,
	Text = string.format("Toplam kod: %d", #ADMIN_CODES),
	Font = Enum.Font.Gotham,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(92, 104, 130),
}, rightPanel)

local searchBox = create("TextBox", {
	Size = UDim2.new(1, -24, 0, 34),
	Position = UDim2.fromOffset(12, 54),
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	Text = "",
	PlaceholderText = "Kod veya isim ara (ör: BAN, L03)",
	Font = Enum.Font.Gotham,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
	ClearTextOnFocus = false,
	TextColor3 = Color3.fromRGB(29, 35, 48),
}, rightPanel)
create("UICorner", {CornerRadius = UDim.new(0, 8)}, searchBox)
create("UIStroke", {Color = Color3.fromRGB(217, 224, 239), Thickness = 1}, searchBox)

local selectedCodeLabel = create("TextLabel", {
	Size = UDim2.new(1, -24, 0, 20),
	Position = UDim2.fromOffset(12, 94),
	BackgroundTransparency = 1,
	Text = "Seçilen kod: -",
	Font = Enum.Font.Gotham,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(68, 80, 240),
}, rightPanel)

local listContainer = create("ScrollingFrame", {
	Size = UDim2.new(1, -24, 1, -126),
	Position = UDim2.fromOffset(12, 118),
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BorderSizePixel = 0,
	ScrollBarThickness = 8,
	CanvasSize = UDim2.fromOffset(0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.None,
}, rightPanel)
create("UICorner", {CornerRadius = UDim.new(0, 8)}, listContainer)
create("UIStroke", {Color = Color3.fromRGB(217, 224, 239), Thickness = 1}, listContainer)

local listLayout = create("UIListLayout", {
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, listContainer)

local function parseNumber(text: string): number?
	local normalized = string.gsub(text, ",", ".")
	return tonumber(normalized)
end

local function matchesQuery(item: AdminCode, query: string): boolean
	if query == "" then
		return true
	end
	local q = string.lower(query)
	return string.find(string.lower(item.code), q, 1, true) ~= nil
		or string.find(string.lower(item.name), q, 1, true) ~= nil
		or string.find(string.lower(item.usage), q, 1, true) ~= nil
end

local function clearList()
	for _, child in ipairs(listContainer:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

local function renderAdminCodes(query: string)
	clearList()

	local visibleCount = 0
	for _, item in ipairs(ADMIN_CODES) do
		if matchesQuery(item, query) then
			visibleCount += 1
			local row = create("TextButton", {
				Size = UDim2.new(1, -10, 0, 44),
				BackgroundColor3 = Color3.fromRGB(245, 247, 251),
				Text = string.format("%s  |  %s\n%s", item.code, item.name, item.usage),
				AutoButtonColor = true,
				Font = Enum.Font.Gotham,
				TextSize = 12,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextColor3 = Color3.fromRGB(39, 48, 74),
			}, listContainer)
			create("UICorner", {CornerRadius = UDim.new(0, 6)}, row)
			row.MouseButton1Click:Connect(function()
				selectedCodeLabel.Text = "Seçilen kod: " .. item.code
			end)
		end
	end

	if visibleCount == 0 then
		local empty = create("TextButton", {
			Size = UDim2.new(1, -10, 0, 36),
			BackgroundColor3 = Color3.fromRGB(245, 247, 251),
			Text = "Sonuç bulunamadı.",
			AutoButtonColor = false,
			Active = false,
			Font = Enum.Font.Gotham,
			TextSize = 13,
			TextColor3 = Color3.fromRGB(92, 104, 130),
		}, listContainer)
		create("UICorner", {CornerRadius = UDim.new(0, 6)}, empty)
	end

	task.wait()
	local contentHeight = listLayout.AbsoluteContentSize.Y + 10
	listContainer.CanvasSize = UDim2.fromOffset(0, contentHeight)
	countLabel.Text = string.format("Toplam kod: %d | Filtrelenen: %d", #ADMIN_CODES, visibleCount)
end

calculateButton.MouseButton1Click:Connect(function()
	errorLabel.Text = ""

	local rpm = parseNumber(rpmBox.Text)
	local avgMs = parseNumber(avgMsBox.Text)
	local utilization = parseNumber(utilizationBox.Text)
	local burst = parseNumber(burstBox.Text)

	if not rpm or not avgMs or not utilization or not burst then
		errorLabel.Text = "Lütfen tüm alanlara geçerli sayısal değer girin."
		return
	end

	local result, err = calculatePlan(rpm, avgMs, utilization, burst)
	if err then
		errorLabel.Text = err
		return
	end

	local safeResult = result :: NumberMap
	resultLabel.Text = string.format(
		"workers=%d\nqueue_limit=%d\nmax_capacity=%d",
		safeResult.recommendedWorkers,
		safeResult.recommendedQueueLimit,
		safeResult.recommendedMaxCapacity
	)
end)

resetButton.MouseButton1Click:Connect(function()
	rpmBox.Text = "4800"
	avgMsBox.Text = "220"
	utilizationBox.Text = "0.70"
	burstBox.Text = "1.5"
	errorLabel.Text = ""
	resultLabel.Text = "Hesaplama sonucu burada görünecek."
end)

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	renderAdminCodes(searchBox.Text)
end)

renderAdminCodes("")
