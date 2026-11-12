--[[
	© 2026 Juan. Isla Sin Salida. Todos los derechos reservados.

	CRONÓMETRO (para Isla Sin Salida)
	Muestra arriba en la pantalla cuánto tiempo llevas intentando escapar.
	El tiempo empieza cada vez que apareces en la prisión y se para al llegar al barco.

	Cómo usarlo:
	  En el Explorer, abre StarterPlayer, haz clic derecho en StarterPlayerScripts
	  > Insert Object > LocalScript, y pega todo este código.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local jugador = Players.LocalPlayer

local pantalla = Instance.new("ScreenGui")
pantalla.Name = "Cronometro"
pantalla.ResetOnSpawn = false
pantalla.Parent = jugador:WaitForChild("PlayerGui")

local fondo = Instance.new("Frame")
fondo.Size = UDim2.new(0, 220, 0, 70)
fondo.AnchorPoint = Vector2.new(0.5, 0)
fondo.Position = UDim2.new(0.5, 0, 0, 8)
fondo.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
fondo.BackgroundTransparency = 0.3
fondo.Parent = pantalla
local esquinas = Instance.new("UICorner")
esquinas.CornerRadius = UDim.new(0, 12)
esquinas.Parent = fondo

local reloj = Instance.new("TextLabel")
reloj.Size = UDim2.new(1, 0, 0.65, 0)
reloj.BackgroundTransparency = 1
reloj.TextColor3 = Color3.fromRGB(255, 255, 255)
reloj.TextScaled = true
reloj.Font = Enum.Font.GothamBold
reloj.Text = "0:00.00"
reloj.Parent = fondo

local record = Instance.new("TextLabel")
record.Size = UDim2.new(1, 0, 0.35, 0)
record.Position = UDim2.new(0, 0, 0.65, 0)
record.BackgroundTransparency = 1
record.TextColor3 = Color3.fromRGB(255, 210, 80)
record.TextScaled = true
record.Font = Enum.Font.Gotham
record.Text = "Récord: ---"
record.Parent = fondo

-- Aviso de derechos de autor, abajo a la izquierda
local derechos = Instance.new("TextLabel")
derechos.Size = UDim2.new(0, 420, 0, 22)
derechos.AnchorPoint = Vector2.new(0, 1)
derechos.Position = UDim2.new(0, 10, 1, -8)
derechos.BackgroundTransparency = 1
derechos.TextColor3 = Color3.fromRGB(255, 255, 255)
derechos.TextTransparency = 0.3
derechos.TextStrokeTransparency = 0.6
derechos.TextXAlignment = Enum.TextXAlignment.Left
derechos.TextScaled = true
derechos.Font = Enum.Font.Gotham
derechos.Text = "© 2026 Juan. Isla Sin Salida. Todos los derechos reservados."
derechos.Parent = pantalla

local function formatoTiempo(centesimas)
	centesimas = math.max(0, math.floor(centesimas))
	local minutos = math.floor(centesimas / 6000)
	local segundos = math.floor(centesimas / 100) % 60
	local resto = centesimas % 100
	return string.format("%d:%02d.%02d", minutos, segundos, resto)
end

RunService.RenderStepped:Connect(function()
	local inicio = jugador:GetAttribute("InicioCarrera")
	if jugador:GetAttribute("Corriendo") and inicio then
		reloj.TextColor3 = Color3.fromRGB(255, 255, 255)
		reloj.Text = formatoTiempo((workspace:GetServerTimeNow() - inicio) * 100)
	elseif jugador:GetAttribute("TiempoFinal") then
		reloj.TextColor3 = Color3.fromRGB(120, 255, 120) -- verde: ¡llegaste!
		reloj.Text = formatoTiempo(jugador:GetAttribute("TiempoFinal"))
	end
	local mejor = jugador:GetAttribute("MejorCentesimas")
	record.Text = mejor and ("Récord: " .. formatoTiempo(mejor)) or "Récord: ---"
end)
