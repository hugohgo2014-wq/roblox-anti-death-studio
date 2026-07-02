-- [[ HITBOXANALYZER.LUA - MÓDULO DE ANÁLISE E CLASSIFICAÇÃO DE RISCO ]] --
-- Este módulo monitora as colisões do personagem em tempo real e cataloga os objetos do mapa.

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local HitboxAnalyzer = {}

-- Tabela interna para armazenar os logs de objetos analisados em tempo real
HitboxAnalyzer.LogDeColisoes = {}

-- Callback opcional para avisar a interface (MiniPanel) quando um novo risco for achado
HitboxAnalyzer.AoAtualizarLog = nil

-- Definição conceitual das 5 classes de risco que você estruturou
local CLASSES_RISCO = {
    [1] = {Nome = "Classe 1", Descricao = "Sem Risco (Estrutura ou cenário comum)"},
    [2] = {Nome = "Classe 2", Descricao = "Classe 2 (Interações comuns ou botões)"},
    [3] = {Nome = "Classe 3", Descricao = "Classe 3 (Gatilho invisível ou região)"},
    [4] = {Nome = "Classe 4", Descricao = "Classe 4 (Alto Risco / Dano provável)"},
    [5] = {Nome = "Classe 5", Descricao = "Classe 5 (Crítico / Sensor de eliminação direta)"}
}

-- -----------------------------------------------------------------------------
-- FUNÇÃO INTERNA DE VERIFICAÇÃO E ESCANEAMENTO
-- -----------------------------------------------------------------------------
local function ClassificarPeca(part)
    if not part or not part:IsA("BasePart") then return nil end
    
    local nomeLower = string.lower(part.Name)
    local classeSugerida = 1
    
    -- Checagem de componentes internos injetados pelo motor do jogo
    local possuiTouchTransmitter = part:FindFirstChildOfClass("TouchTransmitter")
    local possuiScriptDano = part:FindFirstChildOfClass("Script") or part:FindFirstChildOfClass("LocalScript")
    
    -- Lógica de afunilamento para decidir a gravidade do objeto
    if possuiTouchTransmitter or string.find(nomeLower, "kill") or string.find(nomeLower, "morte") or string.find(nomeLower, "piggy") then
        classeSugerida = 5 -- Classe 5: Contém gatilho de transmissão de toque letal ou nome explícito do bot
    elseif string.find(nomeLower, "dmg") or string.find(nomeLower, "dano") or string.find(nomeLower, "trap") or string.find(nomeLower, "hitbox") then
        classeSugerida = 4 -- Classe 4: Termos associados a perda de vida ou armadilhas
    elseif part.CanCollide == false and part.Transparency > 0.4 then
        classeSugerida = 3 -- Classe 3: Peças invisíveis/atravessáveis (comum em zonas de checagem)
    elseif possuiScriptDano or (part.CanTouch == true and part.CanCollide == false) then
        classeSugerida = 2 -- Classe 2: Objetos interativos que guardam códigos locais
    else
        classeSugerida = 1 -- Classe 1: Paredes, chãos e blocos decorativos normais
    end
    
    return classeSugerida
end

-- -----------------------------------------------------------------------------
-- PROCESSAMENTO DO IMPACTO (TOUCH INTERCEPTION)
-- -----------------------------------------------------------------------------
function HitboxAnalyzer.AnalisarToque(parteDoCorpo, parteTocada)
    if not parteTocada or not parteTocada:IsA("BasePart") then return end
    
    -- Evita que o script analise colisões causadas pelo próprio corpo do jogador
    if parteTocada:IsDescendantOf(LocalPlayer.Character) then return end
    
    local nomeObjeto = parteTocada.Name
    local classe = ClassificarPeca(parteTocada)
    
    -- Evita inundar o sistema: se o objeto já foi catalogado com risco igual ou maior, ignora
    if HitboxAnalyzer.LogDeColisoes[nomeObjeto] and HitboxAnalyzer.LogDeColisoes[nomeObjeto].Classe >= classe then
        return
    end
    
    -- Registra o objeto na memória volátil do script
    HitboxAnalyzer.LogDeColisoes[nomeObjeto] = {
        Instancia = parteTocada,
        Classe = classe,
        NomeClasse = CLASSES_RISCO[classe].Nome,
        Descricao = CLASSES_RISCO[classe].Descricao,
        Timestamp = os.date("%X")
    }
    
    -- Imprime um relatório detalhado no painel F9 do desenvolvedor
    print(string.format("[ANALISADOR BR] [%s] Impacto Detectado em '%s' -> %s | %s", 
        HitboxAnalyzer.LogDeColisoes[nomeObjeto].Timestamp,
        nomeObjeto, 
        CLASSES_RISCO[classe].Nome, 
        CLASSES_RISCO[classe].Descricao
    ))
    
    -- Dispara o gatilho visual para atualizar o painel se a UI estiver aberta
    if HitboxAnalyzer.AoAtualizarLog then
        HitboxAnalyzer.AoAtualizarLog(nomeObjeto, HitboxAnalyzer.LogDeColisoes[nomeObjeto])
    end
end

-- -----------------------------------------------------------------------------
-- ATIVAÇÃO DOS EVENTOS DO AVATAR
-- -----------------------------------------------------------------------------
function HitboxAnalyzer.IniciarMonitoramento()
    local conexoes = {}
    
    local function ConectarSinaisDoCorpo(char)
        if not char then return end
        
        -- Limpa escutas antigas se o jogador tiver morrido ou renascido
        for _, c in pairs(conexoes) do
            if c then c:Disconnect() end
        end
        table.clear(conexoes)
        
        -- Vincula o sensor de toque a cada extremidade física do avatar (braços, pernas, torso)
        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                local conexaoToque = part.Touched:Connect(function(parteTocada)
                    HitboxAnalyzer.AnalisarToque(part, parteTocada)
                end)
                table.insert(conexoes, conexaoToque)
            end
        end
    end
    
    -- Inicializa no personagem atual e se prepara para as próximas vidas (Respawns)
    if LocalPlayer.Character then
        ConectarSinaisDoCorpo(LocalPlayer.Character)
    end
    LocalPlayer.CharacterAdded:Connect(ConectarSinaisDoCorpo)
    
    print("[ANALISADOR] Varredura de colisões ativada na estrutura do avatar.")
end

-- -----------------------------------------------------------------------------
-- FUNÇÕES DE UTILIDADE PARA OUTROS MÓDULOS
-- -----------------------------------------------------------------------------
function HitboxAnalyzer.ObterObjetosPorClasse(classeAlvo)
    local filtrados = {}
    for nome, dados in pairs(HitboxAnalyzer.LogDeColisoes) do
        if dados.Classe == classeAlvo then
            filtrados[nome] = dados
        end
    end
    return filtrados
end

function HitboxAnalyzer.LimparHistorico()
    table.clear(HitboxAnalyzer.LogDeColisoes)
    print("[ANALISADOR] Lista de riscos redefinida.")
end

return HitboxAnalyzer
