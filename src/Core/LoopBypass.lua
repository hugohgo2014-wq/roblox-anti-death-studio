-- [[ LOOPBYPASS.LUA - MÓDULO DE MODIFICAÇÃO E LIMPEZA EM LOOP ]] --
-- Este módulo monitora a criação de novos objetos e neutraliza os gatilhos de risco em tempo real.

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LoopBypass = {}
LoopBypass.Ativo = false

-- Configura em quais classes de risco o loop deve agir de forma agressiva
LoopBypass.ClassesAlvo = {
    [1] = false, -- Classe 1: Ignora (Cenário seguro)
    [2] = false, -- Classe 2: Ignora (Botões/Interações básicas)
    [3] = true,  -- Classe 3: Monitora (Zonas invisíveis suspeitas)
    [4] = true,  -- Classe 4: Modifica (Armadilhas e perigos)
    [5] = true   -- Classe 5: Neutraliza imediatamente (Gatilhos letais / Killparts)
}

local ConexoesInternas = {}
local AnalisadorReferencia = nil

-- -----------------------------------------------------------------------------
-- LÓGICA DE NEUTRALIZAÇÃO LOCAL (CLIENT-SIDE BYPASS)
-- -----------------------------------------------------------------------------
local function NeutralizarGatilho(instancia, classe)
    if not instancia or not instancia:IsA("BasePart") then return end
    
    -- Pcall garante que o script não trave se tentarmos modificar uma peça trancada pelo jogo
    pcall(function()
        -- Mecânica 1: Corta a capacidade física da peça de emitir sinais de toque (.Touched)
        if instancia.CanTouch == true then
            instancia.CanTouch = false
        end
        
        -- Mecânica 2: Procura e destrói o transmissor de rede que avisa o servidor sobre o impacto
        local transmissor = instancia:FindFirstChildOfClass("TouchTransmitter")
        if transmissor then
            transmissor:Destroy()
        end
        
        -- Mecânica 3: Se for um perigo crítico (Classe 5), removemos a colisão por segurança
        if classe == 5 then
            instancia.CanCollide = false
            -- Nota: Evitamos usar :Destroy() na peça inteira para o jogo não detectar que o mapa sumiu
        end
    end)
end

-- -----------------------------------------------------------------------------
-- GERENCIADOR DE VERIFICAÇÃO CONTÍNUA
-- -----------------------------------------------------------------------------
function LoopBypass.Iniciar(analisador)
    if LoopBypass.Ativo then return end
    LoopBypass.Ativo = true
    AnalisadorReferencia = analisador
    
    print("[BYPASS LOOP] Iniciando varredura contínua contra hitboxes letais...")
    
    -- GATILHO 1: Escuta o Workspace em tempo real. Se o jogo spawnar uma armadilha nova, age na hora
    local conexaoCriacao = Workspace.DescendantAdded:Connect(function(descendente)
        if not LoopBypass.Ativo or not AnalisadorReferencia then return end
        
        -- Se o objeto recém-criado já estiver no nosso log negro com classe de risco ativa:
        local dadosRisco = AnalisadorReferencia.LogDeColisoes[descendente.Name]
        if dadosRisco and LoopBypass.ClassesAlvo[dadosRisco.Classe] then
            NeutralizarGatilho(descendente, dadosRisco.Classe)
        end
    end)
    table.insert(ConexoesInternas, conexaoCriacao)
    
    -- GATILHO 2: Loop de Varredura Ultra Rápido (Roda a cada atualização de quadro/frame da memória)
    local conexaoFrame = RunService.Stepped:Connect(function()
        if not LoopBypass.Ativo or not AnalisadorReferencia then return end
        
        -- Varre a lista de objetos que o analisador catalogou até agora
        for nomeObjeto, dados in pairs(AnalisadorReferencia.LogDeColisoes) do
            if LoopBypass.ClassesAlvo[dados.Classe] then
                -- Se a instância física ainda existir no jogo, força a neutralização
                if dados.Instancia and dados.Instancia.Parent then
                    NeutralizarGatilho(dados.Instancia, dados.Classe)
                else
                    -- Limpa referências mortas para economizar memória do celular
                    -- Procura no mapa por clones que usam o mesmo nome do perigo
                    for _, pecaNoMapa in pairs(Workspace:GetDescendants()) do
                        if pecaNoMapa.Name == nomeObjeto then
                            NeutralizarGatilho(pecaNoMapa, dados.Classe)
                        end
                    end
                end
            end
        end
    end)
    table.insert(ConexoesInternas, conexaoFrame)
end

-- -----------------------------------------------------------------------------
-- PARADA E LIMPEZA DE MEMÓRIA
-- -----------------------------------------------------------------------------
function LoopBypass.Parar()
    LoopBypass.Ativo = false
    
    -- Desconecta todos os loops e listeners para restaurar o desempenho do processador
    for _, conexao in pairs(ConexoesInternas) do
        if conexao then conexao:Disconnect() end
    end
    table.clear(ConexoesInternas)
    
    print("[BYPASS LOOP] Varredura em loop desativada.")
end

return LoopBypass
