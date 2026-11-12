--[[
	© 2026 Juan. Isla Sin Salida. Todos los derechos reservados.

	CÁMARA CON EL RATÓN (para Isla Sin Salida)
	La cámara gira solo con mover el ratón, sin mantener el clic derecho,
	y tu personaje mira siempre hacia donde apuntas.

	Cómo usarlo:
	  En el Explorer, abre StarterPlayer, haz clic derecho en StarterPlayerScripts
	  > Insert Object > LocalScript, y pega todo este código.

	El ratón queda siempre bloqueado en el centro de la pantalla: no se puede soltar.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local DESPLAZAMIENTO_CAMARA = Vector3.new(1.75, 0, 0) -- la cámara un poco a la derecha, para ver mejor los saltos

local jugador = Players.LocalPlayer

-- En celulares y tablets la cámara ya se gira con el dedo, así que no cambiamos nada
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
	return
end

-- Punto blanco en el centro de la pantalla para saber hacia dónde miras
local pantalla = Instance.new("ScreenGui")
pantalla.Name = "Mira"
pantalla.ResetOnSpawn = false
pantalla.Parent = jugador:WaitForChild("PlayerGui")
local punto = Instance.new("Frame")
punto.Size = UDim2.new(0, 6, 0, 6)
punto.AnchorPoint = Vector2.new(0.5, 0.5)
punto.Position = UDim2.new(0.5, 0, 0.5, 0)
punto.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
punto.BorderSizePixel = 0
punto.Parent = pantalla
local esquinas = Instance.new("UICorner")
esquinas.CornerRadius = UDim.new(1, 0)
esquinas.Parent = punto

RunService:BindToRenderStep("CamaraConRaton", Enum.RenderPriority.Camera.Value + 1, function()
	local personaje = jugador.Character
	local humanoide = personaje and personaje:FindFirstChildOfClass("Humanoid")
	local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart")
	local camara = workspace.CurrentCamera

	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false
	punto.Visible = true
	if humanoide and raiz and humanoide.Health > 0 then
		humanoide.AutoRotate = false
		humanoide.CameraOffset = DESPLAZAMIENTO_CAMARA
		-- el personaje gira para mirar hacia donde mira la cámara
		local mira = camara.CFrame.LookVector
		local plano = Vector3.new(mira.X, 0, mira.Z)
		if plano.Magnitude > 0.01 then
			raiz.CFrame = CFrame.lookAt(raiz.Position, raiz.Position + plano)
		end
	end
end)
