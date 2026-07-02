-- [[ SAFEGROUND.LUA - SISTEMA PARRUDO DE PROTEÇÃO TRIDIMENSIONAL ]] --
-- Módulo responsável por garantir que o jogador nunca caia no vácuo ou atravesse o mapa.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local SafeGround = {}
SafeGround.Ativo = false
SafeGround.Plataforma = nil
SafeGround.SeguirJogador = true
SafeGround.AlturaOffset = 3.5 -- Distância ideal abaixo dos pés do personagem

local ConexoesInternas = {}
local UltimaPosicaoSegura = nil

-- -----------------------------------------------------------------------------
-- CONSTRUÇÃO DA PLATAFORMA ULTRA RESISTENTE
-- -----------------------------------------------------------------------------
local function CriarSuperPlataforma()
    if SafeGround.Plataforma then SafeGround.Plataforma:Destroy() end
    
    -- Criando um bloco robusto (grosso) para a física do Roblox não falhar
    local part = Instance.new("Part")
    part.Name = "AntiVoid_SafeGround_BR"
    part.Size = Vector3.new(25, 3, 25) -- 3 de espessura evita o efeito "ghost clip"
    part.Material = Enum.Material.ForceField -- Visual futurista/neon sutil
    part.Color = Color3.fromRGB(0, 255, 120) -- Verde esmeralda de segurança
    part.Transparency = 0.7 -- Semi-transparente para não tapar totalmente a visão do mapa
    part.Anchored = true
    part.CanCollide = true
    part.CanTouch = false -- Evita disparar sensores de toque do próprio jogo
    part.CastShadow = false
    
    -- Garante que modificações no cenário não arrastem ou deletem nossa plataforma
    part.Locked = true 
    
    part.Parent = Workspace
    SafeGround.Plataforma = part
    
    print("[SAFEGROUND] Super Plataforma de segurança injetada no ambiente local.")
end

-- -----------------------------------------------------------------------------
-- LOOPS DE ATUALIZAÇÃO E MONITORAMENTO (HEARTBEAT)
-- -----------------------------------------------------------------------------
function SafeGround.Ativar()
    if SafeGround.Ativo then return end
    SafeGround.Ativo = true
    
    CriarSuperPlataforma()
    
    -- Loop sincronizado diretamente com o motor físico do Roblox (roda antes da renderização)
    local conexaoFisica = RunService.Heartbeat:Connect(function()
        if not SafeGround.Ativo or not SafeGround.Plataforma then return end
        
        local char = LocalPlayer.Character
        local rootPart = char and char:FindFirstChild("HumanoidRootPart")
        
        if rootPart then
            local posJogador = rootPart.Position
            
            -- Salva a última coordenada estável se o jogador não estiver caindo no vácuo
            if posJogador.Y > -50 then
                UltimaPosicaoSegura = rootPart.CFrame
            end
            
            -- 1. Mecânica de Acompanhamento Dinâmico (Eixos X e Z)
            if SafeGround.SeguirJogador then
                -- A plataforma desliza horizontalmente embaixo do jogador, mantendo a altura (Y) fixa
                local novaPosicaoPlataforma = Vector3.new(posJogador.X, SafeGround.Plataforma.Position.Y, posJogador.Z)
                SafeGround.Plataforma.CFrame = CFrame.new(novaPosicaoPlataforma)
            end
            
            -- 2. Tranca Anti-Modificação (Garante colisão e ancoragem contra scripts inimigos)
            if not SafeGround.Plataforma.CanCollide then
                SafeGround.Plataforma.CanCollide = true
            end
            
            -- 3. Mecânica Anti-Vácuo (Se o player passar direto ou cair fora, é resgatado)
            if posJogador.Y < -80 or (posJogador.Y < SafeGround.Plataforma.Position.Y - 10) then
                if UltimaPosicaoSegura then
                    rootPart.Velocity = Vector3.new(0, 0, 0) -- Zera a força da queda livre
                    rootPart.CFrame = UltimaPosicaoSegura + Vector3.new(0, 4, 0)
                    print("[SAFEGROUND] Resgate ativado! Queda livre interceptada com sucesso.")
                end
            end
        end
    end)
    table.insert(ConexoesInternas, conexaoFisica)
end

-- -----------------------------------------------------------------------------
-- CONTROLE DE ALTURA E CONFIGURAÇÃO MANUAL
-- -----------------------------------------------------------------------------
function SafeGround.DefinirAlturaFixa(alturaY)
    if SafeGround.Plataforma then
        SafeGround.Plataforma.CFrame = CFrame.new(SafeGround.Plataforma.Position.X, alturaY, SafeGround.Plataforma.Position.Z)
    end
end

function SafeGround.TravarAbaixoDoPlayer()
    local char = LocalPlayer.Character
    local rootPart = char and char:FindFirstChild("HumanoidRootPart")
    if rootPart and SafeGround.Plataforma then
        local alturaPes = rootPart.Position.Y - SafeGround.AlturaOffset
        SafeGround.DefinirAlturaFixa(alturaPes)
    end
end

-- -----------------------------------------------------------------------------
-- DESATIVAÇÃO E LIMPEZA
-- -----------------------------------------------------------------------------
function SafeGround.Desativar()
    SafeGround.Ativo = false
    
    -- Desconecta os loops da memória do processador
    for _, conexao in pairs(ConexoesInternas) do
        if conexao then conexao:Disconnect() end
    end
    table.clear(ConexoesInternas)
    
    -- Remove o objeto do mapa com segurança
    if SafeGround.Plataforma then
        SafeGround.Plataforma:Destroy()
        SafeGround.Plataforma = nil
    end
    
    print("[SAFEGROUND] Sistema de proteção desativado e memória limpa.")
end

return SafeGround
