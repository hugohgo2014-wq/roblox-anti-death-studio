-- [[ ANTI-DEATH STUDIO - VERSÃO ULTRA UNIFICADA E CONFIGURÁVEL ]] --

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- -----------------------------------------------------------------------------
-- 1. SUBSISTEMA: HITBOX ANALYZER (MÓDULO DE ANÁLISE)
-- -----------------------------------------------------------------------------
local HitboxAnalyzer = {
    LogDeColisoes = {},
    AoAtualizarLog = nil
}

local CLASSES_RISCO = {
    [1] = "Classe 1 (Seguro)",
    [2] = "Classe 2 (Interativo)",
    [3] = "Classe 3 (Região Invisível)",
    [4] = "Classe 4 (Alto Risco)",
    [5] = "Classe 5 (Letal/Sensor)"
}

local function ClassificarPeca(part)
    if not part or not part:IsA("BasePart") then return nil end
    local nomeLower = string.lower(part.Name)
    
    if part:FindFirstChildOfClass("TouchTransmitter") or string.find(nomeLower, "kill") or string.find(nomeLower, "morte") or string.find(nomeLower, "piggy") then
        return 5
    elseif string.find(nomeLower, "dmg") or string.find(nomeLower, "dano") or string.find(nomeLower, "trap") or string.find(nomeLower, "hitbox") then
        return 4
    elseif part.CanCollide == false and part.Transparency > 0.4 then
        return 3
    elseif part:FindFirstChildOfClass("Script") or part:FindFirstChildOfClass("LocalScript") then
        return 2
    end
    return 1
end

function HitboxAnalyzer.AnalisarToque(parteTocada)
    if not parteTocada or not parteTocada:IsA("BasePart") or parteTocada:IsDescendantOf(LocalPlayer.Character) then return end
    
    local nomeObjeto = parteTocada.Name
    local classe = ClassificarPeca(parteTocada)
    
    if HitboxAnalyzer.LogDeColisoes[nomeObjeto] and HitboxAnalyzer.LogDeColisoes[nomeObjeto].Classe >= classe then return end
    
    HitboxAnalyzer.LogDeColisoes[nomeObjeto] = {
        Instancia = parteTocada,
        Classe = classe,
        Timestamp = os.date("%X")
    }
    
    print(string.format("[ANALISADOR] %s detectado como %s", nomeObjeto, CLASSES_RISCO[classe]))
end

function HitboxAnalyzer.IniciarMonitoramento()
    local conexoes = {}
    local function ConectarCorpo(char)
        if not char then return end
        for _, c in pairs(conexoes) do if c then c:Disconnect() end end
        table.clear(conexoes)
        
        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                table.insert(conexoes, part.Touched:Connect(HitboxAnalyzer.AnalisarToque))
            end
        end
    end
    if LocalPlayer.Character then ConectarCorpo(LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(ConectarCorpo)
end

function HitboxAnalyzer.Limpar()
    table.clear(HitboxAnalyzer.LogDeColisoes)
end

-- -----------------------------------------------------------------------------
-- 2. SUBSISTEMA: LOOP BYPASS (MÓDULO DE LIMPEZA)
-- -----------------------------------------------------------------------------
local LoopBypass = {
    Ativo = false,
    ClassesAlvo = {[1]=false, [2]=false, [3]=true, [4]=true, [5]=true},
    Conexoes = {}
}

local function NeutralizarPeca(instancia, classe)
    if not instancia or not instancia:IsA("BasePart") then return end
    pcall(function()
        if instancia.CanTouch then instancia.CanTouch = false end
        local t = instancia:FindFirstChildOfClass("TouchTransmitter")
        if t then t:Destroy() end
        if classe == 5 then instancia.CanCollide = false end
    end)
end

function LoopBypass.Iniciar()
    if LoopBypass.Ativo then return end
    LoopBypass.Ativo = true
    
    table.insert(LoopBypass.Conexoes, Workspace.DescendantAdded:Connect(function(desc)
        if not LoopBypass.Ativo then return end
        local dados = HitboxAnalyzer.LogDeColisoes[desc.Name]
        if dados and LoopBypass.ClassesAlvo[dados.Classe] then
            NeutralizarPeca(desc, dados.Classe)
        end
    end))
    
    table.insert(LoopBypass.Conexoes, RunService.Stepped:Connect(function()
        if not LoopBypass.Ativo then return end
        for nome, dados in pairs(HitboxAnalyzer.LogDeColisoes) do
            if LoopBypass.ClassesAlvo[dados.Classe] then
                if dados.Instancia and dados.Instancia.Parent then
                    NeutralizarPeca(dados.Instancia, dados.Classe)
                else
                    for _, p in pairs(Workspace:GetDescendants()) do
                        if p.Name == nome then NeutralizarPeca(p, dados.Classe) end
                    end
                end
            end
        end
    end))
end

function LoopBypass.Parar()
    LoopBypass.Ativo = false
    for _, c in pairs(LoopBypass.Conexoes) do if c then c:Disconnect() end end
    table.clear(LoopBypass.Conexoes)
end

-- -----------------------------------------------------------------------------
-- 3. SUBSISTEMA: SAFE GROUND (MÓDULO DO CHÃO SEGURO)
-- -----------------------------------------------------------------------------
local SafeGround = {
    Ativo = false,
    Plataforma = nil,
    Conexoes = {},
    AlturaOffset = 3.5
}
local UltimaPosicaoSegura = nil

function SafeGround.Ativar()
    if SafeGround.Ativo then return end
    SafeGround.Ativo = true
    
    local part = Instance.new("Part")
    part.Name = "AntiVoid_Ground_Unified"
    part.Size = Vector3.new(35, 3, 35)
    part.Material = Enum.Material.ForceField
    part.Color = Color3.fromRGB(4, 211, 97)
    part.Transparency = 0.7
    part.Anchored = true
    part.CanCollide = true
    part.CanTouch = false
    part.Parent = Workspace
    SafeGround.Plataforma = part
    
    table.insert(SafeGround.Conexoes, RunService.Heartbeat:Connect(function()
        if not SafeGround.Ativo or not SafeGround.Plataforma then return end
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        
        if root then
            local pos = root.Position
            if pos.Y > -50 then UltimaPosicaoSegura = root.CFrame end
            
            SafeGround.Plataforma.CFrame = CFrame.new(pos.X, SafeGround.Plataforma.Position.Y, pos.Z)
            if not SafeGround.Plataforma.CanCollide then SafeGround.Plataforma.CanCollide = true end
            
            if pos.Y < -80 or (pos.Y < SafeGround.Plataforma.Position.Y - 10) then
                if UltimaPosicaoSegura then
                    root.Velocity = Vector3.new(0,0,0)
                    root.CFrame = UltimaPosicaoSegura + Vector3.new(0, 4, 0)
                end
            end
        end
    end))
end

function SafeGround.TravarAltura()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root and SafeGround.Plataforma then
        SafeGround.Plataforma.CFrame = CFrame.new(SafeGround.Plataforma.Position.X, root.Position.Y - SafeGround.AlturaOffset, SafeGround.Plataforma.Position.Z)
    end
end

function SafeGround.Desativar()
    SafeGround.Ativo = false
    for _, c in pairs(SafeGround.Conexoes) do if c then c:Disconnect() end end
    table.clear(SafeGround.Conexoes)
    if SafeGround.Plataforma then SafeGround.Plataforma:Destroy() SafeGround.Plataforma = nil end
end

-- -----------------------------------------------------------------------------
-- 4. SUBSISTEMA: UNIFIED UI (INTERFACE GRÁFICA PARRIADA COM REDIMENSIONAMENTO)
-- -----------------------------------------------------------------------------
pcall(function()
    if CoreGui:FindFirstChild("AntiDeathStudioPanel") then CoreGui.AntiDeathStudioPanel:Destroy() end
end)

local GUI = Instance.new("ScreenGui")
GUI.Name = "AntiDeathStudioPanel"
GUI.ResetOnSpawn = false
pcall(function() GUI.Parent = gethui and gethui() or CoreGui end)
if not GUI.Parent then GUI.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- Tamanhos predefinidos da interface (Customizáveis)
local TamanhosUI = {
    Pequeno = {Janela = UDim2.new(0, 150, 0, 190), Canvas = 230, Fonte = 10},
    Medio   = {Janela = UDim2.new(0, 185, 0, 240), Canvas = 270, Fonte = 12},
    Grande  = {Janela = UDim2.new(0, 220, 0, 300), Canvas = 330, Fonte = 14}
}
local TamanhoAtual = "Medio"

local MainFrame = Instance.new("Frame")
MainFrame.Size = TamanhosUI[TamanhoAtual].Janela
MainFrame.Position = UDim2.new(0.05, 0, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = GUI

local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 1
UIStroke.Color = Color3.fromRGB(4, 211, 97)
UIStroke.Parent = MainFrame

local TitleBar = Instance.new("TextButton")
TitleBar.Size = UDim2.new(1, 0, 0, 26)
TitleBar.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
TitleBar.Text = " ⚙️ ANTI-DEATH V4"
TitleBar.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleBar.Font = Enum.Font.SourceSansBold
TitleBar.TextSize = 12
TitleBar.TextXAlignment = Enum.TextXAlignment.Left
TitleBar.Parent = MainFrame

local MinimizarBtn = Instance.new("TextButton")
MinimizarBtn.Size = UDim2.new(0, 26, 1, 0)
MinimizarBtn.Position = UDim2.new(1, -26, 0, 0)
MinimizarBtn.BackgroundTransparency = 1
MinimizarBtn.Text = "-"
MinimizarBtn.TextColor3 = Color3.fromRGB(4, 211, 97)
MinimizarBtn.Font = Enum.Font.SourceSansBold
MinimizarBtn.TextSize = 16
MinimizarBtn.Parent = TitleBar

-- Scroll de Itens Principal
local ScrollArea = Instance.new("ScrollingFrame")
ScrollArea.Size = UDim2.new(1, 0, 1, -26)
ScrollArea.Position = UDim2.new(0, 0, 0, 26)
ScrollArea.BackgroundTransparency = 1
ScrollArea.ScrollBarThickness = 2
ScrollArea.CanvasSize = UDim2.new(0, 0, 0, TamanhosUI[TamanhoAtual].Canvas)
ScrollArea.Parent = MainFrame

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 5)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = ScrollArea

-- Painel de Configuração de Tamanho (Escondido por padrão)
local SettingsFrame = Instance.new("Frame")
SettingsFrame.Size = UDim2.new(1, 0, 0, 45)
SettingsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
SettingsFrame.BorderSizePixel = 0
SettingsFrame.Visible = false
SettingsFrame.LayoutOrder = 0
SettingsFrame.Parent = ScrollArea

local SizeLabel = Instance.new("TextLabel")
SizeLabel.Size = UDim2.new(1, 0, 0, 15)
SizeLabel.BackgroundTransparency = 1
SizeLabel.Text = "Dimensionar Interface:"
SizeLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
SizeLabel.Font = Enum.Font.SourceSansBold
SizeLabel.TextSize = 10
SizeLabel.Parent = SettingsFrame

local function CriarBotaoTamanho(nome, xPos)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.3, -2, 0, 20)
    b.Position = UDim2.new(xPos, 0, 0, 18)
    b.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    b.Text = nome
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Font = Enum.Font.SourceSansBold
    b.TextSize = 9
    b.Parent = SettingsFrame
    return b
end

local BtnP = CriarBotaoTamanho("Pequeno", 0.03)
local BtnM = CriarBotaoTamanho("Médio", 0.36)
local BtnG = CriarBotaoTamanho("Grande", 0.69)

-- -----------------------------------------------------------------------------
-- BOTÕES DE CONTROLE DOS COMPONENTES
-- -----------------------------------------------------------------------------
local bList = {}
local function CriarBotaoMenu(texto, order, cor)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    btn.Text = texto
    btn.TextColor3 = Color3.fromRGB(230, 230, 230)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = TamanhosUI[TamanhoAtual].Fonte
    btn.LayoutOrder = order
    btn.Parent = ScrollArea
    
    local s = Instance.new("UIStroke")
    s.Thickness = 1
    s.Color = cor or Color3.fromRGB(50, 50, 55)
    s.Parent = btn
    
    table.insert(bList, {Button = btn, Stroke = s})
    return btn
end

local BtnGround = CriarBotaoMenu("CHÃO SEGURO: OFF", 1)
local BtnFixar = CriarBotaoMenu("TRAVAR ALTURA", 2)
local BtnBypass = CriarBotaoMenu("BYPASS EM LOOP: OFF", 3, Color3.fromRGB(200, 60, 60))
local BtnLimpar = CriarBotaoMenu("LIMPAR DADOS DE IMPACTO", 4)

local Contador = Instance.new("TextLabel")
Contador.Size = UDim2.new(0.9, 0, 0, 22)
Contador.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
Contador.Text = "RISCOS DETECTADOS: 0"
Contador.TextColor3 = Color3.fromRGB(4, 211, 97)
Contador.Font = Enum.Font.SourceSansBold
Contador.TextSize = 10
Contador.LayoutOrder = 5
Contador.Parent = ScrollArea

-- -----------------------------------------------------------------------------
-- LÓGICA DE GERENCIAMENTO DA INTERFACE E REDIMENSIONAMENTO
-- -----------------------------------------------------------------------------
local function AplicarTamanho(tipo)
    TamanhoAtual = tipo
    local cfg = TamanhosUI[tipo]
    MainFrame.Size = cfg.Janela
    ScrollArea.CanvasSize = UDim2.new(0, 0, 0, cfg.Canvas)
    for _, item in pairs(bList) do
        item.Button.TextSize = cfg.Fonte
    end
end

BtnP.MouseButton1Click:Connect(function() AplicarTamanho("Pequeno") end)
BtnM.MouseButton1Click:Connect(function() AplicarTamanho("Medio") end)
BtnG.MouseButton1Click:Connect(function() AplicarTamanho("Grande") end)

-- Expandir painel de engrenagem ao clicar no título
local EngrenagemAtiva = false
TitleBar.MouseButton1Click:Connect(function()
    EngrenagemAtiva = not EngrenagemAtiva
    SettingsFrame.Visible = EngrenagemAtiva
end)

-- Minimizar Painel Completo
local Minimizado = false
MinimizarBtn.MouseButton1Click:Connect(function()
    Minimizado = not Minimizado
    if Minimizado then
        MainFrame.Size = UDim2.new(0, MainFrame.Size.X.Offset, 0, 26)
        MinimizarBtn.Text = "+"
    else
        MainFrame.Size = TamanhosUI[TamanhoAtual].Janela
        MinimizarBtn.Text = "-"
    end
end)

-- Conexões Físicas dos Botões
BtnGround.MouseButton1Click:Connect(function()
    if SafeGround.Ativo then
        SafeGround.Desativar()
        BtnGround.Text = "CHÃO SEGURO: OFF"
        BtnGround.TextColor3 = Color3.fromRGB(230, 230, 230)
    else
        SafeGround.Ativar()
        BtnGround.Text = "CHÃO SEGURO: ON"
        BtnGround.TextColor3 = Color3.fromRGB(4, 211, 97)
    end
end)

BtnFixar.MouseButton1Click:Connect(function()
    if SafeGround.Ativo then
        SafeGround.TravarAltura()
        BtnFixar.Text = "ALTURA DEFINIDA!"
        task.wait(0.8)
        BtnFixar.Text = "TRAVAR ALTURA"
    end
end)

BtnBypass.MouseButton1Click:Connect(function()
    if LoopBypass.Ativo then
        LoopBypass.Parar()
        BtnBypass.Text = "BYPASS EM LOOP: OFF"
        BtnBypass.TextColor3 = Color3.fromRGB(230, 230, 230)
    else
        LoopBypass.Iniciar()
        BtnBypass.Text = "BYPASS EM LOOP: ON"
        BtnBypass.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end)

BtnLimpar.MouseButton1Click:Connect(function()
    HitboxAnalyzer.Limpar()
    Contador.Text = "RISCOS DETECTADOS: 0"
end)

-- Atualização em tempo real do display numérico
RunService.RenderStepped:Connect(function()
    local c = 0
    for _ in pairs(HitboxAnalyzer.LogDeColisoes) do c = c + 1 end
    Contador.Text = "RISCOS DETECTADOS: " .. c
end)

-- Inicializa o monitoramento do corpo
HitboxAnalyzer.IniciarMonitoramento()
AplicarTamanho("Medio")
print("[ANTI-DEATH STUDIO] Arquitetura unificada injetada com sucesso localmente!")
