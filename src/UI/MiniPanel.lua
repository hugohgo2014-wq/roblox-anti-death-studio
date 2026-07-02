-- [[ MINIPANEL.LUA - INTERFACE GRÁFICA COMPACTA E PARRUDA ]] --
-- Módulo responsável pela UI mobile, controlando os sistemas de Bypass e SafeGround.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local MiniPanel = {}
local AnalisadorRef = nil
local BypassRef = nil
local GroundRef = nil

local GUI = nil
local ContadorDeRiscos = nil

-- -----------------------------------------------------------------------------
-- CONSTRUÇÃO DA INTERFACE (UI DESIGN)
-- -----------------------------------------------------------------------------
function MiniPanel.Iniciar(analisador, bypass, ground)
    AnalisadorRef = analisador
    BypassRef = bypass
    GroundRef = ground
    
    -- Evita duplicar o painel caso o script seja executado duas vezes
    pcall(function()
        if CoreGui:FindFirstChild("AntiDeathStudioPanel") then
            CoreGui.AntiDeathStudioPanel:Destroy()
        end
    end)
    
    GUI = Instance.new("ScreenGui")
    GUI.Name = "AntiDeathStudioPanel"
    GUI.ResetOnSpawn = false
    pcall(function() GUI.Parent = gethui and gethui() or CoreGui end)
    if not GUI.Parent then GUI.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    
    -- Moldura Principal (Draggable e Compacta)
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 160, 0, 180)
    MainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = GUI
    
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Thickness = 1
    UIStroke.Color = Color3.fromRGB(4, 211, 97) -- Verde Neon (Identidade visual)
    UIStroke.Parent = MainFrame
    
    -- Barra de Título / Botão de Minimizar
    local TitleBar = Instance.new("TextButton")
    TitleBar.Size = UDim2.new(1, 0, 0, 25)
    TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
    TitleBar.Text = "  ANTI-DEATH STUDIO"
    TitleBar.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleBar.Font = Enum.Font.SourceSansBold
    TitleBar.TextSize = 12
    TitleBar.TextXAlignment = Enum.TextXAlignment.Left
    TitleBar.Parent = MainFrame
    
    local MinimizarBtn = Instance.new("TextLabel")
    MinimizarBtn.Size = UDim2.new(0, 25, 1, 0)
    MinimizarBtn.Position = UDim2.new(1, -25, 0, 0)
    MinimizarBtn.BackgroundTransparency = 1
    MinimizarBtn.Text = "-"
    MinimizarBtn.TextColor3 = Color3.fromRGB(4, 211, 97)
    MinimizarBtn.Font = Enum.Font.SourceSansBold
    MinimizarBtn.TextSize = 18
    MinimizarBtn.Parent = TitleBar
    
    -- Área de Conteúdo com Scroll (Para caber tudo em tela de celular)
    local ScrollArea = Instance.new("ScrollingFrame")
    ScrollArea.Size = UDim2.new(1, 0, 1, -25)
    ScrollArea.Position = UDim2.new(0, 0, 0, 25)
    ScrollArea.BackgroundTransparency = 1
    ScrollArea.ScrollBarThickness = 2
    ScrollArea.CanvasSize = UDim2.new(0, 0, 0, 220)
    ScrollArea.Parent = MainFrame
    
    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 5)
    Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Parent = ScrollArea
    
    -- Espaçador
    local Spacer = Instance.new("Frame")
    Spacer.Size = UDim2.new(1, 0, 0, 2)
    Spacer.BackgroundTransparency = 1
    Spacer.Parent = ScrollArea
    
    -- -----------------------------------------------------------------------------
    -- CRIADOR DE BOTÕES PADRONIZADOS
    -- -----------------------------------------------------------------------------
    local function CriarBotao(texto, corBorda)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.9, 0, 0, 28)
        btn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        btn.Text = texto
        btn.TextColor3 = Color3.fromRGB(220, 220, 220)
        btn.Font = Enum.Font.SourceSansBold
        btn.TextSize = 11
        btn.Parent = ScrollArea
        
        local btnStroke = Instance.new("UIStroke")
        btnStroke.Thickness = 1
        btnStroke.Color = corBorda or Color3.fromRGB(50, 50, 50)
        btnStroke.Parent = btn
        
        return btn
    end
    
    -- -----------------------------------------------------------------------------
    -- ELEMENTOS DA INTERFACE (BOTÕES E LABELS)
    -- -----------------------------------------------------------------------------
    
    -- Módulo SafeGround
    local GroundLabel = Instance.new("TextLabel")
    GroundLabel.Size = UDim2.new(0.9, 0, 0, 15)
    GroundLabel.BackgroundTransparency = 1
    GroundLabel.Text = "🛡️ PLATAFORMA SEGURA"
    GroundLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    GroundLabel.Font = Enum.Font.SourceSansBold
    GroundLabel.TextSize = 10
    GroundLabel.TextXAlignment = Enum.TextXAlignment.Left
    GroundLabel.Parent = ScrollArea
    
    local BtnGroundAtivar = CriarBotao("CHÃO SEGURO: OFF")
    local BtnGroundFixar = CriarBotao("TRAVAR ALTURA ATUAL")
    
    -- Módulo LoopBypass e Analisador
    local BypassLabel = Instance.new("TextLabel")
    BypassLabel.Size = UDim2.new(0.9, 0, 0, 15)
    BypassLabel.BackgroundTransparency = 1
    BypassLabel.Text = "⚡ ANTI-HITBOX"
    BypassLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    BypassLabel.Font = Enum.Font.SourceSansBold
    BypassLabel.TextSize = 10
    BypassLabel.TextXAlignment = Enum.TextXAlignment.Left
    BypassLabel.Parent = ScrollArea
    
    local BtnBypassAtivar = CriarBotao("PROTEÇÃO (LOOP): OFF", Color3.fromRGB(200, 50, 50))
    local BtnLimparLog = CriarBotao("LIMPAR MEMÓRIA DE RISCOS")
    
    ContadorDeRiscos = Instance.new("TextLabel")
    ContadorDeRiscos.Size = UDim2.new(0.9, 0, 0, 20)
    ContadorDeRiscos.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    ContadorDeRiscos.Text = "AMEAÇAS IDENTIFICADAS: 0"
    ContadorDeRiscos.TextColor3 = Color3.fromRGB(4, 211, 97)
    ContadorDeRiscos.Font = Enum.Font.SourceSansBold
    ContadorDeRiscos.TextSize = 10
    ContadorDeRiscos.Parent = ScrollArea
    
    -- -----------------------------------------------------------------------------
    -- LÓGICA DE INTERAÇÃO DOS BOTÕES
    -- -----------------------------------------------------------------------------
    
    -- Minimizar/Maximizar Painel
    local Minimizado = false
    TitleBar.MouseButton1Click:Connect(function()
        Minimizado = not Minimizado
        if Minimizado then
            MainFrame.Size = UDim2.new(0, 160, 0, 25)
            MinimizarBtn.Text = "+"
        else
            MainFrame.Size = UDim2.new(0, 160, 0, 180)
            MinimizarBtn.Text = "-"
        end
    end)
    
    -- SafeGround: Ligar/Desligar
    BtnGroundAtivar.MouseButton1Click:Connect(function()
        if GroundRef.Ativo then
            GroundRef.Desativar()
            BtnGroundAtivar.Text = "CHÃO SEGURO: OFF"
            BtnGroundAtivar.TextColor3 = Color3.fromRGB(220, 220, 220)
        else
            GroundRef.Ativar()
            BtnGroundAtivar.Text = "CHÃO SEGURO: ON"
            BtnGroundAtivar.TextColor3 = Color3.fromRGB(4, 211, 97)
        end
    end)
    
    -- SafeGround: Fixar Altura
    BtnGroundFixar.MouseButton1Click:Connect(function()
        if GroundRef.Ativo then
            GroundRef.TravarAbaixoDoPlayer()
            BtnGroundFixar.Text = "ALTURA TRAVADA!"
            task.wait(1)
            BtnGroundFixar.Text = "TRAVAR ALTURA ATUAL"
        end
    end)
    
    -- LoopBypass: Ligar/Desligar
    BtnBypassAtivar.MouseButton1Click:Connect(function()
        if BypassRef.Ativo then
            BypassRef.Parar()
            BtnBypassAtivar.Text = "PROTEÇÃO (LOOP): OFF"
            BtnBypassAtivar.TextColor3 = Color3.fromRGB(220, 220, 220)
        else
            BypassRef.Iniciar(AnalisadorRef)
            BtnBypassAtivar.Text = "PROTEÇÃO (LOOP): ON"
            BtnBypassAtivar.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end)
    
    -- Analisador: Limpar Memória
    BtnLimparLog.MouseButton1Click:Connect(function()
        if AnalisadorRef then
            AnalisadorRef.LimparHistorico()
            ContadorDeRiscos.Text = "AMEAÇAS IDENTIFICADAS: 0"
        end
    end)
    
    -- Atualização em tempo real do Contador usando a referência do Analisador
    RunService.RenderStepped:Connect(function()
        if AnalisadorRef and AnalisadorRef.LogDeColisoes then
            local count = 0
            for _ in pairs(AnalisadorRef.LogDeColisoes) do
                count = count + 1
            end
            ContadorDeRiscos.Text = "AMEAÇAS IDENTIFICADAS: " .. count
        end
    end)
    
    print("[UI] MiniPanel renderizado com sucesso no ambiente Mobile.")
end

return MiniPanel
