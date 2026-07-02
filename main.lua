-- [[ MAIN.LUA - ORQUESTRADOR E CARREGADOR CENTRAL ]] --
-- Esse script roda na raiz e gerencia a inicialização dos subsistemas brasileiros

print("[ANTI-DEATH] Inicializando orquestrador principal...")

-- CONFIGURAÇÃO DO SEU REPOSITÓRIO (Altere com os dados da sua conta alt)
local GitHubConfig = {
    Usuario = "SeuUsuarioDaContaAlt", -- Coloques o seu nome de usuário do GitHub aqui
    Repo    = "roblox-anti-death-studio", -- O nome do repositório que o HTML criou
    Branch  = "main"
}

-- Tabela com os caminhos exatos das subpastas que estruturamos
local Subsistemas = {
    UI      = "src/UI/MiniPanel.lua",
    Ground  = "src/Core/SafeGround.lua",
    Analyzer = "src/Core/HitboxAnalyzer.lua",
    Bypass   = "src/Core/LoopBypass.lua"
}

local modulosCarregados = {}

-- Função interna para puxar os códigos direto do GitHub usando HTTP básico de executores
local function CarregarModuloDoGithub(caminhoArquivo)
    local url = string.format("https://raw.githubusercontent.com/%s/%s/%s/%s", 
        GitHubConfig.Usuario, 
        GitHubConfig.Repo, 
        GitHubConfig.Branch, 
        caminhoArquivo
    )
    
    -- Utiliza a função padrão de requisição de redes de executores Roblox (loadstring + game:HttpGet)
    local sucesso, codigo = pcall(function()
        return game:HttpGet(url)
    end)
    
    if sucesso and codigo then
        local funcao, erroScript = loadstring(codigo)
        if funcao then
            local status, modulo = pcall(funcao)
            if status then
                return modulo
            else
                warn("[ERRO INTERNO] Falha ao executar o script: " .. caminhoArquivo .. " | " .. tostring(modulo))
            end
        else
            warn("[ERRO SINTAXE] Script baixado contém erros: " .. caminhoArquivo .. " | " .. tostring(erroScript))
        end
    else
        warn("[ERRO HTTP] Não foi possível baixar o arquivo da nuvem: " .. caminhoArquivo)
    end
    return nil
end

-- -----------------------------------------------------------------------------
-- INICIALIZAÇÃO EM ORDEM DOS MÓDULOS
-- -----------------------------------------------------------------------------

-- 1. Carrega a Interface Gráfica primeiro para o usuário ter o controle visual
print("[STUDIO] Baixando Painel Visual...")
modulosCarregados.UI = CarregarModuloDoGithub(Subsistemas.UI)

-- 2. Carrega a base física (SafeGround) para garantir estabilidade do personagem
print("[STUDIO] Baixando Sistema de Plataforma...")
modulosCarregados.Ground = CarregarModuloDoGithub(Subsistemas.Ground)

-- 3. Carrega o Analisador de Danos e o Loop de Limpeza
print("[STUDIO] Baixando Analisadores e Sistema de Loops...")
modulosCarregados.Analyzer = CarregarModuloDoGithub(Subsistemas.Analyzer)
modulosCarregados.Bypass = CarregarModuloDoGithub(Subsistemas.Bypass)

-- -----------------------------------------------------------------------------
-- VERIFICAÇÃO FINAL DE INTEGRIDADE
-- -----------------------------------------------------------------------------
local todosProntos = true
for nome, ref in pairs(modulosCarregados) do
    if not ref then
        todosProntos = false
        warn(string.format("[AVISO] O subsistema '%s' falhou ao inicializar.", nome))
    end
end

if todosProntos then
    print("[ANTI-DEATH STUDIO] Tudo pronto! Todos os módulos brasileiros foram injetados com sucesso.")
    
    -- Aqui você pode fazer os módulos conversarem entre si se necessário, ex:
    -- modulosCarregados.UI.Iniciar(modulosCarregados.Analyzer)
else
    warn("[ANTI-DEATH STUDIO] O script inicializou com dependências faltando. Verifique os logs acima.")
end

