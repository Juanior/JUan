--[[
	© 2026 Juan. Isla Sin Salida. Todos los derechos reservados.

	PANTALLA DEL JUGADOR (para Isla Sin Salida)
	- Cronómetro arriba en el centro, con tu récord.
	- La zona en la que estás y una barra de progreso hasta el barco.
	- Aviso de derechos de autor abajo a la izquierda.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local jugador = Players.LocalPlayer
local zonas = ReplicatedStorage:WaitForChild("ZonasIsla")

local pantalla = Instance.new("ScreenGui")
pantalla.Name = "PantallaIsla"
pantalla.ResetOnSpawn = false
pantalla.IgnoreGuiInset = false
pantalla.Parent = jugador:WaitForChild("PlayerGui")

local function redondear(objeto, radio)
	local esquinas = Instance.new("UICorner")
	esquinas.CornerRadius = UDim.new(0, radio)
	esquinas.Parent = objeto
end

local function borde(objeto, color, grosor)
	local b = Instance.new("UIStroke")
	b.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	b.Color = color
	b.Thickness = grosor
	b.Parent = objeto
	return b
end

local function texto(padre, props)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.TextScaled = true
	t.TextColor3 = Color3.fromRGB(255, 255, 255)
	t.Font = Enum.Font.FredokaOne
	for clave, valor in pairs(props) do
		t[clave] = valor
	end
	t.Parent = padre
	return t
end

---------------------------------------------------------------------
-- Panel del cronómetro
---------------------------------------------------------------------
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0, 6)
panel.Size = UDim2.new(0, 260, 0, 96)
panel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
panel.Parent = pantalla
redondear(panel, 16)
local bordePanel = borde(panel, Color3.fromRGB(255, 210, 80), 3)
local degradado = Instance.new("UIGradient")
degradado.Color = ColorSequence.new(Color3.fromRGB(30, 40, 80), Color3.fromRGB(70, 25, 70))
degradado.Rotation = 90
degradado.Parent = panel

local reloj = texto(panel, {
	Position = UDim2.new(0, 0, 0, 4),
	Size = UDim2.new(1, 0, 0, 50),
	Text = "⏱ 0:00.00",
	Font = Enum.Font.GothamBlack,
})
local record = texto(panel, {
	Position = UDim2.new(0, 0, 0, 54),
	Size = UDim2.new(1, 0, 0, 18),
	Text = "🏆 Récord: ---",
	TextColor3 = Color3.fromRGB(255, 210, 80),
	Font = Enum.Font.GothamBold,
})
local nombreZona = texto(panel, {
	Position = UDim2.new(0, 0, 0, 74),
	Size = UDim2.new(1, 0, 0, 16),
	Text = "🔒 La Prisión",
	TextColor3 = Color3.fromRGB(190, 220, 255),
	Font = Enum.Font.GothamBold,
})

---------------------------------------------------------------------
-- Barra de progreso hasta el barco
---------------------------------------------------------------------
local barra = Instance.new("Frame")
barra.AnchorPoint = Vector2.new(0.5, 0)
barra.Position = UDim2.new(0.5, 0, 0, 110)
barra.Size = UDim2.new(0, 360, 0, 14)
barra.BackgroundColor3 = Color3.fromRGB(20, 25, 45)
barra.BackgroundTransparency = 0.25
barra.Parent = pantalla
redondear(barra, 7)
borde(barra, Color3.fromRGB(255, 255, 255), 1.5)

local relleno = Instance.new("Frame")
relleno.Size = UDim2.new(0, 0, 1, 0)
relleno.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
relleno.Parent = barra
redondear(relleno, 7)
local colorRelleno = Instance.new("UIGradient")
colorRelleno.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 40)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 210, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 255, 140)),
})
colorRelleno.Parent = relleno

local inicioX = zonas:GetAttribute("InicioX") or 0
local metaX = zonas:GetAttribute("MetaX") or 500
local function fraccion(x)
	return math.clamp((x - inicioX) / (metaX - inicioX), 0, 1)
end

-- iconos de cada zona encima de la barra, y el barco al final
local listaZonas = {}
for _, valor in ipairs(zonas:GetChildren()) do
	table.insert(listaZonas, valor)
end
table.sort(listaZonas, function(a, b) return a.Value < b.Value end)
for _, valor in ipairs(listaZonas) do
	texto(barra, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(fraccion(valor.Value), 0, 0, -1),
		Size = UDim2.new(0, 18, 0, 18),
		Text = valor:GetAttribute("Icono"),
	})
end
texto(barra, {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(1, 4, 0.5, 0),
	Size = UDim2.new(0, 22, 0, 22),
	Text = "⛵",
})

---------------------------------------------------------------------
-- Aviso de derechos de autor
---------------------------------------------------------------------
texto(pantalla, {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 10, 1, -8),
	Size = UDim2.new(0, 420, 0, 20),
	Text = "© 2026 Juan. Isla Sin Salida. Todos los derechos reservados.",
	TextTransparency = 0.3,
	TextStrokeTransparency = 0.6,
	TextXAlignment = Enum.TextXAlignment.Left,
	Font = Enum.Font.Gotham,
})

---------------------------------------------------------------------
-- Actualizar todo en cada fotograma
---------------------------------------------------------------------
local function formatoTiempo(centesimas)
	centesimas = math.max(0, math.floor(centesimas))
	local minutos = math.floor(centesimas / 6000)
	local segundos = math.floor(centesimas / 100) % 60
	local resto = centesimas % 100
	return string.format("%d:%02d.%02d", minutos, segundos, resto)
end

local zonaAnterior = nil
local progresoMostrado = 0

RunService.RenderStepped:Connect(function(dt)
	-- cronómetro
	local inicio = jugador:GetAttribute("InicioCarrera")
	if jugador:GetAttribute("Corriendo") and inicio then
		reloj.TextColor3 = Color3.fromRGB(255, 255, 255)
		bordePanel.Color = Color3.fromRGB(255, 210, 80)
		reloj.Text = "⏱ " .. formatoTiempo((workspace:GetServerTimeNow() - inicio) * 100)
	elseif jugador:GetAttribute("TiempoFinal") then
		reloj.TextColor3 = Color3.fromRGB(120, 255, 140)
		bordePanel.Color = Color3.fromRGB(120, 255, 140)
		reloj.Text = "🏁 " .. formatoTiempo(jugador:GetAttribute("TiempoFinal"))
	end
	local mejor = jugador:GetAttribute("MejorCentesimas")
	record.Text = mejor and ("🏆 Récord: " .. formatoTiempo(mejor)) or "🏆 Récord: ---"

	-- zona y progreso
	local personaje = jugador.Character
	local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart")
	if raiz then
		local x = raiz.Position.X
		local actual = listaZonas[1]
		for _, valor in ipairs(listaZonas) do
			if x >= valor.Value then
				actual = valor
			end
		end
		if actual and actual ~= zonaAnterior then
			zonaAnterior = actual
			nombreZona.Text = actual:GetAttribute("Icono") .. " " .. actual:GetAttribute("Nombre")
			-- pequeño salto al cambiar de zona
			nombreZona.TextColor3 = Color3.fromRGB(255, 255, 255)
			TweenService:Create(nombreZona, TweenInfo.new(1), { TextColor3 = Color3.fromRGB(190, 220, 255) }):Play()
		end
		local objetivo = jugador:GetAttribute("Celebrando") and 1 or fraccion(x)
		progresoMostrado = progresoMostrado + (objetivo - progresoMostrado) * math.min(dt * 8, 1)
		relleno.Size = UDim2.new(progresoMostrado, 0, 1, 0)
	end
end)
