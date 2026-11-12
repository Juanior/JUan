--[[
	© 2026 Juan. Isla Sin Salida. Todos los derechos reservados.

	ISLA SIN SALIDA
	Un juego de obstáculos MUY difícil: escapa de la isla y llega al barco.

	Cómo usarlo:
	  1. Abre Roblox Studio y crea un juego nuevo con la plantilla "Baseplate".
	  2. Borra la pieza "Baseplate" del Workspace (el agua de este juego la reemplaza).
	  3. En el Explorer, haz clic derecho en ServerScriptService > Insert Object > Script.
	  4. Pega todo este código en el Script y pulsa Play.

	Todo el mapa se construye solo cuando empieza el juego.
	Puedes cambiar la dificultad en la sección CONFIGURACIÓN de abajo.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

---------------------------------------------------------------------
-- CONFIGURACIÓN (cambia estos números para hacerlo más fácil o difícil)
---------------------------------------------------------------------
local CONFIG = {
	VelocidadBarras = 2.4,       -- qué tan rápido giran las barras (más = más difícil)
	TiempoAntesDeCaer = 0.35,    -- segundos antes de que caiga una plataforma frágil
	TiempoParaVolver = 3,        -- segundos hasta que la plataforma frágil vuelve
	VelocidadPlataformas = 1.3,  -- qué tan rápido se mueven las plataformas del mar
	DistanciaPlataformas = 14,   -- cuánto se mueven de lado a lado
	VelocidadMarea = 0.6,        -- cuánto sube la marea por segundo en la torre final
}

---------------------------------------------------------------------
-- Herramientas para construir
---------------------------------------------------------------------
local mapa = Instance.new("Folder")
mapa.Name = "IslaSinSalida"
mapa.Parent = workspace

local function crearPieza(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for clave, valor in pairs(props) do
		if clave ~= "Parent" then
			p[clave] = valor
		end
	end
	p.Parent = props.Parent or mapa
	return p
end

local function obtenerHumanoide(pieza)
	local modelo = pieza:FindFirstAncestorOfClass("Model")
	if modelo then
		local humanoide = modelo:FindFirstChildOfClass("Humanoid")
		if humanoide and Players:GetPlayerFromCharacter(modelo) then
			return humanoide, Players:GetPlayerFromCharacter(modelo)
		end
	end
	return nil, nil
end

-- Hace que una pieza mate al tocarla
local function hacerMortal(pieza)
	pieza.Touched:Connect(function(otra)
		local humanoide, jugador = obtenerHumanoide(otra)
		if humanoide and humanoide.Health > 0 and not jugador:GetAttribute("Celebrando") then
			humanoide.Health = 0
		end
	end)
end

---------------------------------------------------------------------
-- Mensajes en pantalla
---------------------------------------------------------------------
local function mostrarMensaje(jugador, texto, segundos)
	local gui = jugador:FindFirstChild("PlayerGui")
	if not gui then return end
	local pantalla = gui:FindFirstChild("MensajesIsla")
	if not pantalla then
		pantalla = Instance.new("ScreenGui")
		pantalla.Name = "MensajesIsla"
		pantalla.ResetOnSpawn = false
		pantalla.Parent = gui
		local etiqueta = Instance.new("TextLabel")
		etiqueta.Name = "Texto"
		etiqueta.AnchorPoint = Vector2.new(0.5, 0.5)
		etiqueta.Size = UDim2.new(0.6, 0, 0, 56)
		etiqueta.Position = UDim2.new(0.5, 0, 0, 160)
		etiqueta.BackgroundTransparency = 0.15
		etiqueta.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		etiqueta.TextColor3 = Color3.fromRGB(255, 255, 255)
		etiqueta.TextStrokeTransparency = 0.4
		etiqueta.TextScaled = true
		etiqueta.Font = Enum.Font.FredokaOne
		etiqueta.Visible = false
		etiqueta.Parent = pantalla
		local esquinas = Instance.new("UICorner")
		esquinas.CornerRadius = UDim.new(0, 14)
		esquinas.Parent = etiqueta
		local borde = Instance.new("UIStroke")
		borde.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		borde.Color = Color3.fromRGB(255, 220, 90)
		borde.Thickness = 3
		borde.Parent = etiqueta
		local degradado = Instance.new("UIGradient")
		degradado.Color = ColorSequence.new(Color3.fromRGB(255, 120, 60), Color3.fromRGB(200, 50, 140))
		degradado.Parent = etiqueta
		local margen = Instance.new("UIPadding")
		margen.PaddingLeft = UDim.new(0, 12)
		margen.PaddingRight = UDim.new(0, 12)
		margen.PaddingTop = UDim.new(0, 6)
		margen.PaddingBottom = UDim.new(0, 6)
		margen.Parent = etiqueta
	end
	local etiqueta = pantalla.Texto
	etiqueta.Text = texto
	etiqueta.Visible = true
	-- aparece con un pequeño salto
	etiqueta.Size = UDim2.new(0.45, 0, 0, 40)
	game:GetService("TweenService"):Create(etiqueta, TweenInfo.new(0.35, Enum.EasingStyle.Back), {
		Size = UDim2.new(0.6, 0, 0, 56),
	}):Play()
	local marca = tick()
	etiqueta:SetAttribute("Marca", marca)
	task.delay(segundos or 3, function()
		if etiqueta:GetAttribute("Marca") == marca then
			etiqueta.Visible = false
		end
	end)
end

---------------------------------------------------------------------
-- Puntos de control (¡solo hay 2, por eso es tan difícil!)
---------------------------------------------------------------------
local puntoInicio = CFrame.new(0, 9, 0)
local controlDeJugador = {}   -- jugador -> número de punto de control
local puntosDeControl = {}    -- número -> CFrame
local tiempoInicio = {}       -- jugador -> cuándo empezó

local function crearPuntoDeControl(numero, posicion)
	local base = crearPieza({
		Name = "PuntoDeControl" .. numero,
		Size = Vector3.new(14, 1, 14),
		Position = posicion,
		Color = Color3.fromRGB(60, 200, 90),
		Material = Enum.Material.Grass,
	})
	local bandera = crearPieza({
		Name = "Bandera",
		Size = Vector3.new(0.5, 10, 0.5),
		Position = posicion + Vector3.new(5, 5.5, 5),
		Color = Color3.fromRGB(240, 240, 240),
	})
	crearPieza({
		Name = "Tela",
		Size = Vector3.new(0.2, 3, 4),
		Position = bandera.Position + Vector3.new(0, 3, -2),
		Color = Color3.fromRGB(255, 60, 60),
		Material = Enum.Material.Fabric,
	})
	puntosDeControl[numero] = CFrame.new(posicion + Vector3.new(0, 4, 0))
	base.Touched:Connect(function(otra)
		local humanoide, jugador = obtenerHumanoide(otra)
		if jugador and humanoide.Health > 0 and (controlDeJugador[jugador] or 0) < numero then
			controlDeJugador[jugador] = numero
			mostrarMensaje(jugador, "¡Punto de control " .. numero .. " de 2!", 3)
		end
	end)
end

---------------------------------------------------------------------
-- EL MAR (con tiburones: si te caes, pierdes)
---------------------------------------------------------------------
local mar = crearPieza({
	Name = "MarConTiburones",
	Size = Vector3.new(2048, 2, 2048),
	Position = Vector3.new(300, -1, 0),
	Color = Color3.fromRGB(30, 110, 200),
	Material = Enum.Material.Glass,
	Transparency = 0.25,
})
hacerMortal(mar)

-- Aletas de tiburón que dan vueltas (solo decoración)
local aletas = {}
for i = 1, 8 do
	local aleta = crearPieza({
		Name = "Tiburon",
		Size = Vector3.new(0.6, 3, 2.5),
		Color = Color3.fromRGB(90, 100, 110),
		CanCollide = false,
		CanTouch = false,
	})
	table.insert(aletas, { pieza = aleta, centro = Vector3.new(60 * i, 0, 0), radio = 18 + i * 2, fase = i })
end

---------------------------------------------------------------------
-- ZONA 0: La isla y la prisión (aquí empiezas)
---------------------------------------------------------------------
crearPieza({
	Name = "Isla",
	Shape = Enum.PartType.Cylinder,
	Size = Vector3.new(8, 80, 80),
	CFrame = CFrame.new(0, 1, 0) * CFrame.Angles(0, 0, math.rad(90)),
	Color = Color3.fromRGB(230, 210, 150),
	Material = Enum.Material.Sand,
})

-- Muros de la prisión, con un hueco hacia el este
local alturaMuro = 12
local muros = {
	{ Vector3.new(0, 11, -14), Vector3.new(28, alturaMuro, 1) },
	{ Vector3.new(0, 11, 14), Vector3.new(28, alturaMuro, 1) },
	{ Vector3.new(-14, 11, 0), Vector3.new(1, alturaMuro, 28) },
	{ Vector3.new(14, 11, -9), Vector3.new(1, alturaMuro, 10) },
	{ Vector3.new(14, 11, 9), Vector3.new(1, alturaMuro, 10) },
}
for _, m in ipairs(muros) do
	crearPieza({
		Name = "MuroPrision",
		Position = m[1],
		Size = m[2],
		Color = Color3.fromRGB(120, 120, 130),
		Material = Enum.Material.Concrete,
	})
end

-- Palmeras
for i = 1, 6 do
	local angulo = i * math.pi / 3
	local pos = Vector3.new(math.cos(angulo) * 30, 5, math.sin(angulo) * 30)
	crearPieza({
		Name = "Tronco",
		Size = Vector3.new(1.5, 14, 1.5),
		Position = pos + Vector3.new(0, 7, 0),
		Color = Color3.fromRGB(120, 80, 40),
		Material = Enum.Material.Wood,
	})
	crearPieza({
		Name = "Hojas",
		Size = Vector3.new(9, 1, 9),
		Position = pos + Vector3.new(0, 14, 0),
		Color = Color3.fromRGB(40, 160, 60),
		Material = Enum.Material.Grass,
	})
end

---------------------------------------------------------------------
-- ZONA 1: Saltos sobre el volcán (lava)
---------------------------------------------------------------------
crearPieza({
	Name = "Volcan",
	Size = Vector3.new(130, 6, 50),
	Position = Vector3.new(105, 0, 0),
	Color = Color3.fromRGB(60, 40, 35),
	Material = Enum.Material.Basalt,
})
local lava = crearPieza({
	Name = "Lava",
	Size = Vector3.new(126, 1, 46),
	Position = Vector3.new(105, 3.5, 0),
	Color = Color3.fromRGB(255, 90, 20),
	Material = Enum.Material.Neon,
})
hacerMortal(lava)

local saltosLava = {
	{ 48, 8, 0 }, { 60, 9, 4 }, { 72, 10, -3 }, { 84, 11, 3 }, { 96, 10, -4 },
	{ 108, 12, 2 }, { 119, 13, -2 }, { 131, 12, 4 }, { 143, 13, 0 }, { 154, 12, -3 },
}
for i, s in ipairs(saltosLava) do
	local tam = (i % 3 == 0) and 2.5 or 3.5 -- algunas son más pequeñas
	crearPieza({
		Name = "PiedraVolcanica" .. i,
		Size = Vector3.new(tam, 1, tam),
		Position = Vector3.new(s[1], s[2], s[3]),
		Color = Color3.fromRGB(40, 40, 40),
		Material = Enum.Material.Slate,
	})
end

crearPuntoDeControl(1, Vector3.new(170, 12, 0))

---------------------------------------------------------------------
-- ZONA 2: Plataformas de hielo que se rompen
---------------------------------------------------------------------
local function hacerFragil(pieza)
	local rompiendose = false
	local colorOriginal = pieza.Color
	pieza.Touched:Connect(function(otra)
		if rompiendose then return end
		local humanoide = obtenerHumanoide(otra)
		if not humanoide then return end
		rompiendose = true
		pieza.Color = Color3.fromRGB(255, 120, 120)
		task.wait(CONFIG.TiempoAntesDeCaer)
		pieza.Transparency = 1
		pieza.CanCollide = false
		task.wait(CONFIG.TiempoParaVolver)
		pieza.Transparency = 0.2
		pieza.CanCollide = true
		pieza.Color = colorOriginal
		rompiendose = false
	end)
end

for i = 1, 11 do
	local z = (i % 2 == 0) and 3 or -3
	local hielo = crearPieza({
		Name = "HieloFragil" .. i,
		Size = Vector3.new(4, 1, 4),
		Position = Vector3.new(170 + i * 11, 12, z),
		Color = Color3.fromRGB(170, 230, 255),
		Material = Enum.Material.Ice,
		Transparency = 0.2,
	})
	hacerFragil(hielo)
end

---------------------------------------------------------------------
-- ZONA 3: El puente de las barras giratorias
---------------------------------------------------------------------
local inicioPuente = 300
local largoPuente = 90
crearPieza({
	Name = "PuenteEstrecho",
	Size = Vector3.new(largoPuente, 1, 3),
	Position = Vector3.new(inicioPuente + largoPuente / 2, 12, 0),
	Color = Color3.fromRGB(150, 100, 60),
	Material = Enum.Material.WoodPlanks,
})

local barras = {}
for i = 1, 4 do
	local centro = Vector3.new(inicioPuente + i * 18, 14, 0)
	crearPieza({
		Name = "Eje",
		Size = Vector3.new(1, 3, 1),
		Position = centro + Vector3.new(0, 0.5, 0),
		Color = Color3.fromRGB(50, 50, 50),
		CanCollide = false,
	})
	local barra = crearPieza({
		Name = "BarraGiratoria" .. i,
		Size = Vector3.new(22, 1, 1),
		Color = Color3.fromRGB(255, 40, 40),
		Material = Enum.Material.Neon,
		CanCollide = false,
	})
	hacerMortal(barra)
	-- las barras pares giran al revés y algunas son más altas
	local altura = (i % 2 == 0) and 0.6 or 0
	table.insert(barras, {
		pieza = barra,
		centro = centro + Vector3.new(0, altura, 0),
		sentido = (i % 2 == 0) and -1 or 1,
	})
end

crearPuntoDeControl(2, Vector3.new(inicioPuente + largoPuente + 10, 12, 0))

---------------------------------------------------------------------
-- ZONA 4: Balsas que se mueven sobre el mar
---------------------------------------------------------------------
local balsas = {}
for i = 1, 6 do
	local balsa = crearPieza({
		Name = "Balsa" .. i,
		Size = Vector3.new(5, 1, 5),
		Position = Vector3.new(inicioPuente + largoPuente + 10 + i * 13, 12, 0),
		Color = Color3.fromRGB(160, 110, 60),
		Material = Enum.Material.Wood,
	})
	table.insert(balsas, { pieza = balsa, base = balsa.Position, fase = i * 1.1 })
end
local finBalsas = inicioPuente + largoPuente + 10 + 7 * 13 -- x donde termina la zona 4

---------------------------------------------------------------------
-- ZONA 5: La torre del faro (¡la marea sube!)
---------------------------------------------------------------------
local xTorre = finBalsas - 2
crearPieza({
	Name = "BaseFaro",
	Size = Vector3.new(10, 1, 10),
	Position = Vector3.new(xTorre, 12, 0),
	Color = Color3.fromRGB(200, 200, 200),
	Material = Enum.Material.Marble,
})

local escalones = 12
local alturaEscalon = 4.5
for i = 1, escalones do
	local angulo = i * (math.pi / 3)
	crearPieza({
		Name = "EscalonFaro" .. i,
		Size = Vector3.new(2.5, 1, 2.5),
		Position = Vector3.new(xTorre + math.cos(angulo) * 8, 12 + i * alturaEscalon, math.sin(angulo) * 8),
		Color = (i % 2 == 0) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(220, 40, 40),
		Material = Enum.Material.SmoothPlastic,
	})
end
crearPieza({
	Name = "ColumnaFaro",
	Size = Vector3.new(5, escalones * alturaEscalon, 5),
	Position = Vector3.new(xTorre, 12 + escalones * alturaEscalon / 2, 0),
	Color = Color3.fromRGB(240, 240, 240),
	Material = Enum.Material.Marble,
})
local alturaCima = 12 + escalones * alturaEscalon + 3
crearPieza({
	Name = "CimaFaro",
	Size = Vector3.new(8, 1, 8),
	Position = Vector3.new(xTorre, alturaCima, 0),
	Color = Color3.fromRGB(255, 220, 60),
	Material = Enum.Material.Neon,
})

-- La marea: sube cuando alguien está en la torre y baja cuando no hay nadie
local marea = crearPieza({
	Name = "Marea",
	Size = Vector3.new(30, 1, 30),
	Position = Vector3.new(xTorre, 10, 0),
	Color = Color3.fromRGB(20, 80, 180),
	Material = Enum.Material.Glass,
	Transparency = 0.35,
	CanCollide = false,
})
hacerMortal(marea)
local alturaMarea = 10

---------------------------------------------------------------------
-- ¡EL BARCO DE ESCAPE! (la meta)
---------------------------------------------------------------------
-- Hay que dar un último salto largo desde la cima del faro hasta el barco
local xBarco = xTorre + 16
local barco = crearPieza({
	Name = "BarcoDeEscape",
	Size = Vector3.new(8, 3, 16),
	Position = Vector3.new(xBarco, alturaCima - 4, 0),
	Color = Color3.fromRGB(110, 70, 40),
	Material = Enum.Material.Wood,
})
crearPieza({
	Name = "Mastil",
	Size = Vector3.new(0.6, 12, 0.6),
	Position = barco.Position + Vector3.new(0, 7.5, 0),
	Color = Color3.fromRGB(90, 60, 30),
	CanCollide = false,
})
crearPieza({
	Name = "Vela",
	Size = Vector3.new(0.2, 8, 8),
	Position = barco.Position + Vector3.new(0.5, 8, 0),
	Color = Color3.fromRGB(250, 250, 240),
	Material = Enum.Material.Fabric,
	CanCollide = false,
})

---------------------------------------------------------------------
-- ZONAS: carteles flotantes, farolillos y datos para la barra de progreso
---------------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local zonas = {
	{ nombre = "La Prisión", icono = "🔒", x = -20 },
	{ nombre = "El Volcán", icono = "🌋", x = 42 },
	{ nombre = "Hielo Frágil", icono = "🧊", x = 177 },
	{ nombre = "Puente de las Barras", icono = "⚔️", x = 298 },
	{ nombre = "Las Balsas", icono = "🌊", x = 407 },
	{ nombre = "El Faro", icono = "🗼", x = xTorre - 6 },
}
local carpetaZonas = Instance.new("Folder")
carpetaZonas.Name = "ZonasIsla"
carpetaZonas:SetAttribute("InicioX", 0)
carpetaZonas:SetAttribute("MetaX", xBarco)
carpetaZonas.Parent = ReplicatedStorage
for i, z in ipairs(zonas) do
	local valor = Instance.new("NumberValue")
	valor.Name = tostring(i)
	valor.Value = z.x
	valor:SetAttribute("Nombre", z.nombre)
	valor:SetAttribute("Icono", z.icono)
	valor.Parent = carpetaZonas

	if i > 1 then
		-- cartel flotante al empezar cada zona
		local soporte = crearPieza({
			Name = "Cartel" .. i,
			Size = Vector3.new(1, 1, 1),
			Position = Vector3.new(z.x + 6, 24, 0),
			Transparency = 1,
			CanCollide = false,
			CanTouch = false,
			CanQuery = false,
		})
		local cartel = Instance.new("BillboardGui")
		cartel.Size = UDim2.new(0, 360, 0, 70)
		cartel.MaxDistance = 140
		cartel.LightInfluence = 0
		cartel.Parent = soporte
		local texto = Instance.new("TextLabel")
		texto.Size = UDim2.new(1, 0, 1, 0)
		texto.BackgroundTransparency = 1
		texto.Text = z.icono .. " " .. string.upper(z.nombre)
		texto.TextColor3 = Color3.fromRGB(255, 240, 200)
		texto.TextStrokeColor3 = Color3.fromRGB(60, 20, 10)
		texto.TextStrokeTransparency = 0
		texto.TextScaled = true
		texto.Font = Enum.Font.FredokaOne
		texto.Parent = cartel
	end
end

-- Farolillos a los lados del camino (fuera del alcance de las barras)
local function farolillo(pos)
	crearPieza({
		Name = "Poste",
		Size = Vector3.new(0.6, pos.Y, 0.6),
		Position = Vector3.new(pos.X, pos.Y / 2, pos.Z),
		Color = Color3.fromRGB(60, 45, 35),
		Material = Enum.Material.Wood,
		CanCollide = false,
		CanTouch = false,
	})
	local farol = crearPieza({
		Name = "Farol",
		Size = Vector3.new(1.4, 1.8, 1.4),
		Position = pos + Vector3.new(0, 1, 0),
		Color = Color3.fromRGB(255, 190, 90),
		Material = Enum.Material.Neon,
		CanCollide = false,
		CanTouch = false,
	})
	local luz = Instance.new("PointLight")
	luz.Color = Color3.fromRGB(255, 180, 90)
	luz.Range = 18
	luz.Brightness = 1.5
	luz.Parent = farol
end
for x = 180, xTorre - 10, 24 do
	farolillo(Vector3.new(x, 17, 14))
	farolillo(Vector3.new(x + 12, 17, -14))
end

-- Bordes brillantes en los puntos de control
for _, numero in ipairs({ 1, 2 }) do
	local base = mapa:FindFirstChild("PuntoDeControl" .. numero)
	if base then
		local aro = crearPieza({
			Name = "AroControl",
			Size = Vector3.new(15, 0.3, 15),
			Position = base.Position + Vector3.new(0, -0.45, 0),
			Color = Color3.fromRGB(120, 255, 150),
			Material = Enum.Material.Neon,
			CanCollide = false,
			CanTouch = false,
		})
		aro.Transparency = 0.2
	end
end

---------------------------------------------------------------------
-- RANKING: los que menos tardan en escapar
---------------------------------------------------------------------
-- Para que el ranking se guarde para siempre (aunque se cierre el servidor):
-- publica el juego y en Roblox Studio ve a Game Settings > Security y activa
-- "Enable Studio Access to API Services". Si no, el ranking funciona igual,
-- pero solo dura mientras el servidor esté abierto.
local DataStoreService = game:GetService("DataStoreService")
local rankingGuardado = nil
pcall(function()
	rankingGuardado = DataStoreService:GetOrderedDataStore("MejoresTiemposIslaSinSalida")
end)

local mejoresDelServidor = {} -- userId -> { nombre, centesimas }
local nombres = {}            -- userId -> nombre (para no preguntarlo muchas veces)

local function formatoTiempo(centesimas)
	local minutos = math.floor(centesimas / 6000)
	local segundos = math.floor(centesimas / 100) % 60
	local resto = centesimas % 100
	return string.format("%d:%02d.%02d", minutos, segundos, resto)
end

local function nombreDe(userId)
	if nombres[userId] then return nombres[userId] end
	local ok, nombre = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	nombres[userId] = ok and nombre or ("Jugador " .. userId)
	return nombres[userId]
end

-- El tablero del ranking, en la playa junto a la salida de la prisión
local tablero = crearPieza({
	Name = "TableroRanking",
	Size = Vector3.new(16, 14, 1),
	CFrame = CFrame.lookAt(Vector3.new(27, 13, -22), Vector3.new(14, 11, 0)),
	Color = Color3.fromRGB(60, 40, 25),
	Material = Enum.Material.WoodPlanks,
})
for _, dx in ipairs({ -6, 6 }) do
	crearPieza({
		Name = "PataTablero",
		Size = Vector3.new(1, 8, 1),
		CFrame = tablero.CFrame * CFrame.new(dx, -10, 0.6),
		Color = Color3.fromRGB(80, 55, 30),
		Material = Enum.Material.Wood,
	})
end
local superficie = Instance.new("SurfaceGui")
superficie.Face = Enum.NormalId.Front
superficie.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
superficie.PixelsPerStud = 40
superficie.Parent = tablero
local titulo = Instance.new("TextLabel")
titulo.Size = UDim2.new(1, 0, 0.15, 0)
titulo.BackgroundTransparency = 1
titulo.Text = "LOS MÁS RÁPIDOS EN ESCAPAR"
titulo.TextColor3 = Color3.fromRGB(255, 210, 80)
titulo.TextScaled = true
titulo.Font = Enum.Font.FredokaOne
titulo.Parent = superficie
local filas = {}
for i = 1, 10 do
	local fila = Instance.new("TextLabel")
	fila.Size = UDim2.new(0.9, 0, 0.075, 0)
	fila.Position = UDim2.new(0.05, 0, 0.16 + (i - 1) * 0.078, 0)
	fila.BackgroundTransparency = 1
	fila.TextXAlignment = Enum.TextXAlignment.Left
	fila.TextColor3 = (i == 1) and Color3.fromRGB(255, 215, 0)
		or (i == 2) and Color3.fromRGB(210, 210, 220)
		or (i == 3) and Color3.fromRGB(215, 140, 70)
		or Color3.fromRGB(255, 255, 255)
	fila.TextScaled = true
	fila.Font = Enum.Font.GothamBold
	fila.Text = i .. ". ---"
	fila.Parent = superficie
	filas[i] = fila
end

local pieTablero = Instance.new("TextLabel")
pieTablero.Size = UDim2.new(1, 0, 0.05, 0)
pieTablero.Position = UDim2.new(0, 0, 0.95, 0)
pieTablero.BackgroundTransparency = 1
pieTablero.Text = "© 2026 Juan. Isla Sin Salida. Todos los derechos reservados."
pieTablero.TextColor3 = Color3.fromRGB(200, 180, 150)
pieTablero.TextScaled = true
pieTablero.Font = Enum.Font.Gotham
pieTablero.Parent = superficie

local function actualizarTablero()
	local lista = {}
	local ok = false
	if rankingGuardado then
		ok = pcall(function()
			local pagina = rankingGuardado:GetSortedAsync(true, 10):GetCurrentPage()
			for _, dato in ipairs(pagina) do
				table.insert(lista, { nombre = nombreDe(tonumber(dato.key)), centesimas = dato.value })
			end
		end)
	end
	if not ok then
		-- sin guardado: usamos los tiempos de este servidor
		lista = {}
		for _, dato in pairs(mejoresDelServidor) do
			table.insert(lista, dato)
		end
		table.sort(lista, function(a, b) return a.centesimas < b.centesimas end)
	end
	for i = 1, 10 do
		local dato = lista[i]
		filas[i].Text = dato and (i .. ". " .. dato.nombre .. "   " .. formatoTiempo(dato.centesimas)) or (i .. ". ---")
	end
end

local function guardarTiempo(jugador, centesimas)
	local anterior = mejoresDelServidor[jugador.UserId]
	if anterior == nil or centesimas < anterior.centesimas then
		mejoresDelServidor[jugador.UserId] = { nombre = jugador.Name, centesimas = centesimas }
	end
	if rankingGuardado then
		pcall(function()
			rankingGuardado:UpdateAsync(tostring(jugador.UserId), function(viejo)
				if viejo == nil or centesimas < viejo then
					return centesimas
				end
				return nil -- no era mejor: no cambiamos nada
			end)
		end)
	end
	task.spawn(actualizarTablero)
end

task.spawn(function()
	while true do
		actualizarTablero()
		task.wait(60)
	end
end)

---------------------------------------------------------------------
-- Jugadores: tabla de puntos, reaparecer, cronómetro y ganar
---------------------------------------------------------------------
local yaGano = {}

-- El cronómetro empieza cada vez que apareces en la prisión
local function empezarCronometro(jugador)
	tiempoInicio[jugador] = workspace:GetServerTimeNow()
	jugador:SetAttribute("InicioCarrera", tiempoInicio[jugador])
	jugador:SetAttribute("Corriendo", true)
end

local function reiniciar(jugador)
	controlDeJugador[jugador] = 0
	yaGano[jugador] = false
end

Players.PlayerAdded:Connect(function(jugador)
	nombres[jugador.UserId] = jugador.Name

	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = jugador

	local mejor = Instance.new("StringValue")
	mejor.Name = "Mejor tiempo"
	mejor.Value = "---"
	mejor.Parent = stats

	local escapes = Instance.new("IntValue")
	escapes.Name = "Escapes"
	escapes.Parent = stats

	local muertes = Instance.new("IntValue")
	muertes.Name = "Muertes"
	muertes.Parent = stats

	reiniciar(jugador)

	-- buscar su mejor tiempo guardado
	if rankingGuardado then
		task.spawn(function()
			local ok, guardado = pcall(function()
				return rankingGuardado:GetAsync(tostring(jugador.UserId))
			end)
			if ok and guardado and mejor.Value == "---" then
				mejor.Value = formatoTiempo(guardado)
				jugador:SetAttribute("MejorCentesimas", guardado)
			end
		end)
	end

	jugador.CharacterAdded:Connect(function(personaje)
		local humanoide = personaje:WaitForChild("Humanoid")
		local raiz = personaje:WaitForChild("HumanoidRootPart")
		task.wait() -- espera a que el personaje aparezca
		local numero = controlDeJugador[jugador] or 0
		raiz.CFrame = puntosDeControl[numero] or puntoInicio
		if numero == 0 then
			empezarCronometro(jugador)
			mostrarMensaje(jugador, "Escapa de la isla y llega al barco... ¡el tiempo corre!", 4)
		end
		humanoide.Died:Connect(function()
			muertes.Value = muertes.Value + 1
		end)
	end)
end)

Players.PlayerRemoving:Connect(function(jugador)
	controlDeJugador[jugador] = nil
	tiempoInicio[jugador] = nil
	yaGano[jugador] = nil
end)

---------------------------------------------------------------------
-- EL GRAN FINAL: el barco zarpa contigo, con fuegos artificiales y confeti
---------------------------------------------------------------------
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local coloresFiesta = {
	Color3.fromRGB(255, 70, 70), Color3.fromRGB(255, 200, 40), Color3.fromRGB(80, 220, 120),
	Color3.fromRGB(70, 160, 255), Color3.fromRGB(220, 90, 255), Color3.fromRGB(255, 140, 200),
}

local function fuegoArtificial(desde)
	local color = coloresFiesta[math.random(1, #coloresFiesta)]
	local cohete = crearPieza({
		Name = "Cohete",
		Size = Vector3.new(0.6, 1.5, 0.6),
		Position = desde,
		Color = color,
		Material = Enum.Material.Neon,
		CanCollide = false,
		CanTouch = false,
	})
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, -0.7, 0)
	a0.Parent = cohete
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, 0.7, 0)
	a1.Parent = cohete
	local estela = Instance.new("Trail")
	estela.Attachment0 = a0
	estela.Attachment1 = a1
	estela.Color = ColorSequence.new(color)
	estela.LightEmission = 1
	estela.Lifetime = 0.4
	estela.Parent = cohete

	local altura = math.random(28, 45)
	local subida = TweenService:Create(cohete, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = desde + Vector3.new(math.random(-6, 6), altura, math.random(-6, 6)),
	})
	subida:Play()
	subida.Completed:Wait()

	-- ¡BOOM!
	cohete.Transparency = 1
	local chispas = Instance.new("ParticleEmitter")
	chispas.Rate = 0
	chispas.Color = ColorSequence.new(color, Color3.fromRGB(255, 255, 255))
	chispas.LightEmission = 1
	chispas.Size = NumberSequence.new(1.2, 0)
	chispas.Lifetime = NumberRange.new(1, 1.6)
	chispas.Speed = NumberRange.new(25, 40)
	chispas.SpreadAngle = Vector2.new(180, 180)
	chispas.Drag = 2
	chispas.Acceleration = Vector3.new(0, -12, 0)
	chispas.Parent = cohete
	chispas:Emit(90)
	local destello = Instance.new("PointLight")
	destello.Color = color
	destello.Range = 50
	destello.Brightness = 6
	destello.Parent = cohete
	TweenService:Create(destello, TweenInfo.new(0.8), { Brightness = 0 }):Play()
	Debris:AddItem(cohete, 2.5)
end

local function crearBarcoDeFiesta(cframe)
	local partes = {}
	partes.casco = crearPieza({
		Name = "BarcoDeFiesta",
		Size = Vector3.new(8, 3, 16),
		CFrame = cframe,
		Color = Color3.fromRGB(110, 70, 40),
		Material = Enum.Material.Wood,
		CanCollide = false,
		CanTouch = false,
	})
	partes.mastil = crearPieza({
		Name = "Mastil",
		Size = Vector3.new(0.6, 12, 0.6),
		Color = Color3.fromRGB(90, 60, 30),
		CanCollide = false,
		CanTouch = false,
	})
	partes.vela = crearPieza({
		Name = "Vela",
		Size = Vector3.new(0.2, 8, 8),
		Color = Color3.fromRGB(250, 250, 240),
		Material = Enum.Material.Fabric,
		CanCollide = false,
		CanTouch = false,
	})
	-- confeti saliendo del barco
	local confeti = Instance.new("ParticleEmitter")
	confeti.Rate = 70
	confeti.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, coloresFiesta[1]),
		ColorSequenceKeypoint.new(0.25, coloresFiesta[2]),
		ColorSequenceKeypoint.new(0.5, coloresFiesta[3]),
		ColorSequenceKeypoint.new(0.75, coloresFiesta[4]),
		ColorSequenceKeypoint.new(1, coloresFiesta[5]),
	})
	confeti.Size = NumberSequence.new(0.35)
	confeti.Lifetime = NumberRange.new(2, 3)
	confeti.Speed = NumberRange.new(18, 28)
	confeti.SpreadAngle = Vector2.new(35, 35)
	confeti.Acceleration = Vector3.new(0, -25, 0)
	confeti.Rotation = NumberRange.new(0, 360)
	confeti.RotSpeed = NumberRange.new(-300, 300)
	confeti.EmissionDirection = Enum.NormalId.Top
	confeti.Parent = partes.casco
	return partes
end

local function colocarBarco(partes, cframe)
	partes.casco.CFrame = cframe
	partes.mastil.CFrame = cframe * CFrame.new(0, 7.5, 0)
	partes.vela.CFrame = cframe * CFrame.new(0.5, 8, 0)
end

local function celebrar(jugador, texto)
	local personaje = jugador.Character
	local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart")
	if not raiz then return end

	jugador:SetAttribute("Celebrando", true) -- así el mar y la lava no le hacen daño
	mostrarMensaje(jugador, texto, 8)

	local salida = barco.CFrame
	local partes = crearBarcoDeFiesta(salida)
	raiz.Anchored = true

	-- fuegos artificiales mientras dura la fiesta
	local fiesta = true
	task.spawn(function()
		while fiesta do
			task.spawn(fuegoArtificial, partes.casco.Position + Vector3.new(math.random(10, 30), 2, math.random(-20, 20)))
			task.wait(0.45)
		end
	end)

	-- el barco baja al mar y navega hacia el horizonte
	local duracion = 8
	local inicio = os.clock()
	while os.clock() - inicio < duracion do
		local t = (os.clock() - inicio) / duracion
		local bajada = math.min(t * 3, 1) -- en el primer tercio baja hasta el agua
		local y = salida.Position.Y + (3 - salida.Position.Y) * (1 - (1 - bajada) ^ 2)
		local x = salida.Position.X + t * t * 160
		local balanceo = math.sin(os.clock() * 2) * 0.08
		local cf = CFrame.new(x, y + math.sin(os.clock() * 3) * 0.4, 0) * CFrame.Angles(balanceo, 0, balanceo * 0.5)
		colocarBarco(partes, cf)
		if raiz.Parent then
			raiz.CFrame = cf * CFrame.new(0, 4.5, 3) * CFrame.Angles(0, math.rad(-90), 0)
		end
		task.wait()
	end

	fiesta = false
	for _, parte in pairs(partes) do
		parte:Destroy()
	end
	jugador:SetAttribute("Celebrando", false)
	reiniciar(jugador)
	if jugador.Parent then
		jugador:LoadCharacter()
	end
end

barco.Touched:Connect(function(otra)
	local humanoide, jugador = obtenerHumanoide(otra)
	if not jugador or humanoide.Health <= 0 or yaGano[jugador] or not tiempoInicio[jugador] then return end
	yaGano[jugador] = true
	local centesimas = math.floor((workspace:GetServerTimeNow() - tiempoInicio[jugador]) * 100)
	jugador:SetAttribute("Corriendo", false)
	jugador:SetAttribute("TiempoFinal", centesimas)

	local stats = jugador:FindFirstChild("leaderstats")
	local anterior = jugador:GetAttribute("MejorCentesimas")
	local esRecord = anterior == nil or centesimas < anterior
	if stats then
		stats.Escapes.Value = stats.Escapes.Value + 1
		if esRecord then
			jugador:SetAttribute("MejorCentesimas", centesimas)
			stats["Mejor tiempo"].Value = formatoTiempo(centesimas)
		end
	end
	guardarTiempo(jugador, centesimas)

	local texto = "¡ESCAPASTE! Tiempo: " .. formatoTiempo(centesimas)
	if esRecord then
		texto = texto .. "  ¡NUEVO RÉCORD!"
	else
		texto = texto .. "  (tu récord: " .. formatoTiempo(anterior) .. ")"
	end
	celebrar(jugador, texto)
end)

---------------------------------------------------------------------
-- DECORACIÓN: el paisaje alrededor del mapa
-- (nada de esto se puede tocar: es solo para que se vea bonito)
---------------------------------------------------------------------
local Lighting = game:GetService("Lighting")
local azar = Random.new(2026) -- siempre sale el mismo paisaje

local decoracion = Instance.new("Folder")
decoracion.Name = "Decoracion"
decoracion.Parent = mapa

local function deco(props)
	props.Parent = props.Parent or decoracion
	local p = crearPieza(props)
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	return p
end

-- Atardecer tropical
Lighting.ClockTime = 17.3
Lighting.Brightness = 2.5
Lighting.OutdoorAmbient = Color3.fromRGB(150, 130, 120)
Lighting.Ambient = Color3.fromRGB(70, 60, 70)
local atmosfera = Instance.new("Atmosphere")
atmosfera.Density = 0.3
atmosfera.Haze = 1.6
atmosfera.Glare = 0.6
atmosfera.Color = Color3.fromRGB(255, 200, 160)
atmosfera.Decay = Color3.fromRGB(120, 90, 140)
atmosfera.Parent = Lighting
local brillo = Instance.new("BloomEffect")
brillo.Intensity = 0.6
brillo.Threshold = 1.1
brillo.Parent = Lighting
local rayos = Instance.new("SunRaysEffect")
rayos.Intensity = 0.08
rayos.Parent = Lighting
local colores = Instance.new("ColorCorrectionEffect")
colores.Saturation = 0.15
colores.TintColor = Color3.fromRGB(255, 245, 235)
colores.Parent = Lighting

-- Palmera con el tronco curvado y cocos
local function palmera(base, alto)
	local inclinacion = azar:NextNumber(-0.25, 0.25)
	local pos = base
	local segmentos = 6
	for i = 1, segmentos do
		local siguiente = pos + Vector3.new(inclinacion * i * 0.6, alto / segmentos, 0)
		deco({
			Name = "Tronco",
			Size = Vector3.new(1.4 - i * 0.08, alto / segmentos + 0.3, 1.4 - i * 0.08),
			CFrame = CFrame.lookAt((pos + siguiente) / 2, siguiente) * CFrame.Angles(math.rad(90), 0, 0),
			Color = Color3.fromRGB(130, 90, 50),
			Material = Enum.Material.Wood,
		})
		pos = siguiente
	end
	for h = 1, 6 do
		local ang = h * math.pi / 3 + azar:NextNumber(0, 0.4)
		deco({
			Name = "Hoja",
			Size = Vector3.new(7, 0.3, 1.8),
			CFrame = CFrame.new(pos) * CFrame.Angles(0, ang, 0) * CFrame.new(3, -0.6, 0) * CFrame.Angles(0, 0, math.rad(-18)),
			Color = Color3.fromRGB(50, 170, 70),
			Material = Enum.Material.Grass,
		})
	end
	for c = 1, 3 do
		deco({
			Name = "Coco",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(0.9, 0.9, 0.9),
			Position = pos + Vector3.new(math.cos(c * 2) * 0.7, -0.8, math.sin(c * 2) * 0.7),
			Color = Color3.fromRGB(90, 60, 30),
		})
	end
end

local function roca(pos, tam)
	deco({
		Name = "Roca",
		Size = Vector3.new(tam, tam * azar:NextNumber(0.6, 1.4), tam * azar:NextNumber(0.7, 1.2)),
		CFrame = CFrame.new(pos) * CFrame.Angles(azar:NextNumber(0, 1), azar:NextNumber(0, 6), azar:NextNumber(0, 1)),
		Color = Color3.fromRGB(105, 100, 95),
		Material = Enum.Material.Rock,
	})
end

-- Palmeras curvadas extra en la isla de la prisión
for i = 1, 8 do
	local ang = i * math.pi / 4 + 0.4
	palmera(Vector3.new(math.cos(ang) * 36, 5, math.sin(ang) * 36), azar:NextNumber(12, 17))
end

-- Islotes pequeños por todo el mar
for i = 1, 16 do
	local lado = (i % 2 == 0) and 1 or -1
	local centro = Vector3.new(azar:NextNumber(-120, 640), 0, lado * azar:NextNumber(55, 190))
	local radio = azar:NextNumber(10, 22)
	deco({
		Name = "Islote",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(4, radio * 2, radio * 2),
		CFrame = CFrame.new(centro + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(235, 215, 155),
		Material = Enum.Material.Sand,
	})
	deco({
		Name = "Cesped",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1, radio * 1.3, radio * 1.3),
		CFrame = CFrame.new(centro + Vector3.new(0, 2.7, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(80, 170, 70),
		Material = Enum.Material.Grass,
	})
	for _ = 1, azar:NextInteger(1, 3) do
		local a = azar:NextNumber(0, math.pi * 2)
		palmera(centro + Vector3.new(math.cos(a) * radio * 0.4, 3, math.sin(a) * radio * 0.4), azar:NextNumber(10, 16))
	end
	for _ = 1, 3 do
		local a = azar:NextNumber(0, math.pi * 2)
		roca(centro + Vector3.new(math.cos(a) * radio, 1.5, math.sin(a) * radio), azar:NextNumber(2, 4))
	end
end

-- Rocas grandes saliendo del mar (lejos del camino)
for _ = 1, 30 do
	local lado = azar:NextNumber() > 0.5 and 1 or -1
	local pos = Vector3.new(azar:NextNumber(-150, 680), azar:NextNumber(0, 5), lado * azar:NextNumber(38, 230))
	roca(pos, azar:NextNumber(4, 12))
end

-- El gran volcán humeante detrás de la zona de lava
local xVolcan, zVolcan = 105, -130
for i = 0, 7 do
	local radio = 70 - i * 8
	deco({
		Name = "Montana",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(10, radio * 2, radio * 2),
		CFrame = CFrame.new(xVolcan, 5 + i * 10, zVolcan) * CFrame.Angles(0, 0, math.rad(90)),
		Color = (i % 2 == 0) and Color3.fromRGB(70, 55, 50) or Color3.fromRGB(85, 65, 55),
		Material = Enum.Material.Basalt,
	})
end
local crater = deco({
	Name = "Crater",
	Shape = Enum.PartType.Cylinder,
	Size = Vector3.new(1, 18, 18),
	CFrame = CFrame.new(xVolcan, 80.6, zVolcan) * CFrame.Angles(0, 0, math.rad(90)),
	Color = Color3.fromRGB(255, 100, 20),
	Material = Enum.Material.Neon,
})
local luzCrater = Instance.new("PointLight")
luzCrater.Color = Color3.fromRGB(255, 120, 40)
luzCrater.Range = 60
luzCrater.Brightness = 3
luzCrater.Parent = crater
local humo = Instance.new("Smoke")
humo.Color = Color3.fromRGB(90, 80, 80)
humo.Opacity = 0.4
humo.RiseVelocity = 20
humo.Size = 30
humo.Parent = crater
local fuego = Instance.new("Fire")
fuego.Size = 20
fuego.Heat = 20
fuego.Parent = crater
-- ríos de lava bajando por el volcán
for i = 1, 3 do
	local ang = math.rad(60 + i * 30)
	local arriba = Vector3.new(xVolcan, 78, zVolcan)
	local abajo = Vector3.new(xVolcan + math.cos(ang) * 60, 6, zVolcan + math.sin(ang) * 60)
	deco({
		Name = "RioDeLava",
		Size = Vector3.new(3, 1, (arriba - abajo).Magnitude),
		CFrame = CFrame.lookAt((arriba + abajo) / 2, abajo) * CFrame.new(0, 2, 0),
		Color = Color3.fromRGB(255, 110, 30),
		Material = Enum.Material.Neon,
	})
end

-- Brillo naranja sobre la zona de lava
for i = 0, 4 do
	local luz = Instance.new("PointLight")
	luz.Color = Color3.fromRGB(255, 120, 40)
	luz.Range = 30
	luz.Brightness = 1.5
	local soporte = deco({ Name = "LuzLava", Size = Vector3.new(1, 1, 1), Position = Vector3.new(50 + i * 28, 4, 0), Transparency = 1 })
	luz.Parent = soporte
end

-- Barco hundido junto al puente
local xRestos, zRestos = 340, 60
deco({
	Name = "CascoHundido",
	Size = Vector3.new(30, 7, 10),
	CFrame = CFrame.new(xRestos, 1, zRestos) * CFrame.Angles(math.rad(20), math.rad(25), math.rad(-12)),
	Color = Color3.fromRGB(80, 55, 35),
	Material = Enum.Material.WoodPlanks,
})
deco({
	Name = "MastilRoto",
	Size = Vector3.new(1, 18, 1),
	CFrame = CFrame.new(xRestos + 4, 8, zRestos) * CFrame.Angles(math.rad(25), 0, math.rad(30)),
	Color = Color3.fromRGB(70, 45, 30),
	Material = Enum.Material.Wood,
})
deco({
	Name = "VelaRota",
	Size = Vector3.new(0.2, 7, 9),
	CFrame = CFrame.new(xRestos + 7, 11, zRestos + 1) * CFrame.Angles(math.rad(10), math.rad(20), math.rad(30)),
	Color = Color3.fromRGB(200, 190, 170),
	Material = Enum.Material.Fabric,
})
for i = 1, 4 do
	deco({
		Name = "Barril",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2.5, 2, 2),
		Position = Vector3.new(xRestos - 18 + i * 4, 0.6, zRestos - 10 - i * 2),
		Color = Color3.fromRGB(120, 80, 45),
		Material = Enum.Material.Wood,
	})
end

-- Torres de vigilancia de la prisión con focos
local focos = {}
for _, esquina in ipairs({ Vector3.new(-22, 5, -22), Vector3.new(-22, 5, 22) }) do
	for _, dx in ipairs({ -1.5, 1.5 }) do
		for _, dz in ipairs({ -1.5, 1.5 }) do
			deco({
				Name = "PataTorre",
				Size = Vector3.new(0.6, 16, 0.6),
				Position = esquina + Vector3.new(dx, 8, dz),
				Color = Color3.fromRGB(90, 90, 90),
				Material = Enum.Material.Metal,
			})
		end
	end
	deco({
		Name = "Caseta",
		Size = Vector3.new(5, 4, 5),
		Position = esquina + Vector3.new(0, 18, 0),
		Color = Color3.fromRGB(110, 110, 120),
		Material = Enum.Material.Metal,
	})
	local foco = deco({
		Name = "Foco",
		Size = Vector3.new(1, 1, 1),
		Position = esquina + Vector3.new(0, 20.5, 0),
		Color = Color3.fromRGB(255, 255, 200),
		Material = Enum.Material.Neon,
	})
	local luz = Instance.new("SpotLight")
	luz.Range = 60
	luz.Angle = 30
	luz.Brightness = 4
	luz.Face = Enum.NormalId.Front
	luz.Parent = foco
	table.insert(focos, foco)
end

-- Luz giratoria en la cima del faro
local lampara = deco({
	Name = "LamparaFaro",
	Size = Vector3.new(3, 3, 3),
	Position = Vector3.new(xTorre, alturaCima + 4, 0),
	Color = Color3.fromRGB(255, 240, 160),
	Material = Enum.Material.Neon,
	Shape = Enum.PartType.Ball,
})
local luzFaro = Instance.new("PointLight")
luzFaro.Range = 40
luzFaro.Brightness = 3
luzFaro.Color = Color3.fromRGB(255, 230, 150)
luzFaro.Parent = lampara
local haz = deco({
	Name = "HazDeLuz",
	Size = Vector3.new(0.5, 3, 120),
	Color = Color3.fromRGB(255, 245, 190),
	Material = Enum.Material.Neon,
	Transparency = 0.75,
})
-- columnas que sostienen la lámpara (sin tapar el salto al barco)
for _, d in ipairs({ Vector3.new(-3, 0, -3), Vector3.new(-3, 0, 3) }) do
	deco({
		Name = "ColumnaLampara",
		Size = Vector3.new(0.6, 4, 0.6),
		Position = Vector3.new(xTorre, alturaCima + 2.5, 0) + d,
		Color = Color3.fromRGB(220, 40, 40),
	})
end

-- Nubes
for _ = 1, 22 do
	local centro = Vector3.new(azar:NextNumber(-200, 750), azar:NextNumber(120, 170), azar:NextNumber(-300, 300))
	for _ = 1, 4 do
		deco({
			Name = "Nube",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1, 1, 1) * azar:NextNumber(14, 26),
			Position = centro + Vector3.new(azar:NextNumber(-14, 14), azar:NextNumber(-3, 3), azar:NextNumber(-8, 8)),
			Color = Color3.fromRGB(255, 240, 235),
			Material = Enum.Material.SmoothPlastic,
			Transparency = 0.15,
			CastShadow = false,
		})
	end
end

-- Gaviotas volando en círculos
local gaviotas = {}
for i = 1, 10 do
	local cuerpo = deco({
		Name = "Gaviota",
		Size = Vector3.new(0.8, 0.6, 1.6),
		Color = Color3.fromRGB(245, 245, 245),
	})
	local ala = deco({
		Name = "Ala",
		Size = Vector3.new(5, 0.15, 1),
		Color = Color3.fromRGB(230, 230, 235),
	})
	table.insert(gaviotas, {
		cuerpo = cuerpo,
		ala = ala,
		centro = Vector3.new(azar:NextNumber(0, 520), azar:NextNumber(45, 80), azar:NextNumber(-60, 60)),
		radio = azar:NextNumber(15, 40),
		fase = i,
	})
end

-- Animación de la decoración
local tiempoDeco = 0
RunService.Heartbeat:Connect(function(dt)
	tiempoDeco = tiempoDeco + dt
	haz.CFrame = CFrame.new(lampara.Position) * CFrame.Angles(0, tiempoDeco * 0.8, 0) * CFrame.new(0, 0, -60)
	for i, foco in ipairs(focos) do
		-- los focos barren la playa buscando fugitivos
		local giro = math.sin(tiempoDeco * 0.7 + i * 2) * 1.2
		foco.CFrame = CFrame.new(foco.Position) * CFrame.Angles(0, giro + math.pi / 2, 0) * CFrame.Angles(math.rad(-25), 0, 0)
	end
	for _, g in ipairs(gaviotas) do
		local ang = tiempoDeco * 0.35 + g.fase
		local pos = g.centro + Vector3.new(math.cos(ang) * g.radio, math.sin(tiempoDeco + g.fase) * 2, math.sin(ang) * g.radio)
		local frente = pos + Vector3.new(-math.sin(ang), 0, math.cos(ang))
		local cf = CFrame.lookAt(pos, frente)
		g.cuerpo.CFrame = cf
		g.ala.CFrame = cf * CFrame.Angles(0, 0, math.sin(tiempoDeco * 6 + g.fase) * 0.4)
	end
end)

---------------------------------------------------------------------
-- Todo lo que se mueve (cada fotograma)
---------------------------------------------------------------------
local tiempo = 0
RunService.Heartbeat:Connect(function(dt)
	tiempo = tiempo + dt

	-- barras giratorias
	for _, b in ipairs(barras) do
		local angulo = tiempo * CONFIG.VelocidadBarras * b.sentido
		b.pieza.CFrame = CFrame.new(b.centro) * CFrame.Angles(0, angulo, 0)
	end

	-- balsas: se mueven de lado a lado y llevan al jugador encima
	for _, b in ipairs(balsas) do
		local t = tiempo * CONFIG.VelocidadPlataformas + b.fase
		local z = math.sin(t) * CONFIG.DistanciaPlataformas
		local velocidadZ = math.cos(t) * CONFIG.DistanciaPlataformas * CONFIG.VelocidadPlataformas
		b.pieza.CFrame = CFrame.new(b.base + Vector3.new(0, 0, z))
		b.pieza.AssemblyLinearVelocity = Vector3.new(0, 0, velocidadZ)
	end

	-- marea del faro: sube si hay alguien en la torre
	local alguienEnTorre = false
	for _, jugador in ipairs(Players:GetPlayers()) do
		local personaje = jugador.Character
		local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart")
		if raiz and math.abs(raiz.Position.X - xTorre) < 14 and raiz.Position.Y > 13 then
			alguienEnTorre = true
		end
	end
	if alguienEnTorre then
		alturaMarea = math.min(alturaMarea + CONFIG.VelocidadMarea * dt, alturaCima - 2)
	else
		alturaMarea = math.max(alturaMarea - CONFIG.VelocidadMarea * 3 * dt, 10)
	end
	marea.Size = Vector3.new(30, alturaMarea - 10 + 1, 30)
	marea.Position = Vector3.new(xTorre, 10 + (alturaMarea - 10) / 2, 0)

	-- tiburones nadando en círculos
	for _, a in ipairs(aletas) do
		local ang = tiempo * 0.6 + a.fase
		local pos = a.centro + Vector3.new(math.cos(ang) * a.radio, 1, math.sin(ang) * a.radio)
		a.pieza.CFrame = CFrame.lookAt(pos, pos + Vector3.new(-math.sin(ang), 0, math.cos(ang)))
	end
end)

print("Isla Sin Salida cargada. ¡Buena suerte!")
