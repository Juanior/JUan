--[[
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
		local humanoide = obtenerHumanoide(otra)
		if humanoide and humanoide.Health > 0 then
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
		etiqueta.Size = UDim2.new(0.8, 0, 0, 60)
		etiqueta.Position = UDim2.new(0.1, 0, 0.12, 0)
		etiqueta.BackgroundTransparency = 0.3
		etiqueta.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
		etiqueta.TextColor3 = Color3.fromRGB(255, 230, 120)
		etiqueta.TextScaled = true
		etiqueta.Font = Enum.Font.FredokaOne
		etiqueta.Visible = false
		etiqueta.Parent = pantalla
	end
	local etiqueta = pantalla.Texto
	etiqueta.Text = texto
	etiqueta.Visible = true
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
-- Jugadores: tabla de puntos, reaparecer en el punto de control, ganar
---------------------------------------------------------------------
local yaGano = {}

local function reiniciar(jugador)
	controlDeJugador[jugador] = 0
	tiempoInicio[jugador] = os.clock()
	yaGano[jugador] = false
end

Players.PlayerAdded:Connect(function(jugador)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = jugador

	local escapes = Instance.new("IntValue")
	escapes.Name = "Escapes"
	escapes.Parent = stats

	local muertes = Instance.new("IntValue")
	muertes.Name = "Muertes"
	muertes.Parent = stats

	reiniciar(jugador)

	jugador.CharacterAdded:Connect(function(personaje)
		local humanoide = personaje:WaitForChild("Humanoid")
		local raiz = personaje:WaitForChild("HumanoidRootPart")
		task.wait() -- espera a que el personaje aparezca
		local numero = controlDeJugador[jugador] or 0
		raiz.CFrame = puntosDeControl[numero] or puntoInicio
		if numero == 0 then
			mostrarMensaje(jugador, "Escapa de la isla y llega al barco... si puedes", 4)
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

barco.Touched:Connect(function(otra)
	local humanoide, jugador = obtenerHumanoide(otra)
	if not jugador or humanoide.Health <= 0 or yaGano[jugador] then return end
	yaGano[jugador] = true
	local segundos = math.floor(os.clock() - (tiempoInicio[jugador] or os.clock()))
	local stats = jugador:FindFirstChild("leaderstats")
	if stats then
		stats.Escapes.Value = stats.Escapes.Value + 1
	end
	mostrarMensaje(jugador, "¡ESCAPASTE! Tiempo: " .. segundos .. " s. ¿Puedes hacerlo más rápido?", 6)
	task.wait(6)
	reiniciar(jugador)
	if jugador.Character then
		jugador:LoadCharacter()
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
