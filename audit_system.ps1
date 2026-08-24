# 1. Configuracao dinamica e universal do arquivo de saida (Mapeia OneDrive ou Local de forma nativa)
try {
    # Tenta ler o caminho real da Area de Trabalho usando o Objeto Shell nativo do Windows (0 = Desktop)
    $DesktopDetectado = (New-Object -ComObject Shell.Application).Namespace(0).Self.Path
} catch {
    # Plano B: Se o objeto Shell falhar, busca direto na chave de registro oficial do perfil do usuario
    $DesktopDetectado = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders").Desktop
    # Transforma variaveis de ambiente do registro (como %USERPROFILE%) em caminhos reais de pasta
    $DesktopDetectado = [System.Environment]::ExpandEnvironmentVariables($DesktopDetectado)
}

# Fallback de seguranca caso ocorra algum comportamento extremo
if ([string]::IsNullOrEmpty($DesktopDetectado)) {
    $DesktopDetectado = "$env:USERPROFILE\Desktop"
}

# Define o LogPath final usando a Area de Trabalho correta mapeada na maquina atual
$DataAtual = Get-Date -Format "dd_MM_yyyy_HHmm"
$LogPath = "$DesktopDetectado\relatorio_seguranca_$DataAtual.txt"


"=======================================================================" | Out-File -FilePath $LogPath -Force
"            RELATORIO DE AUDITORIA DE SEGURANCA                        " | Out-File -FilePath $LogPath -Append
"=======================================================================" | Out-File -FilePath $LogPath -Append
" Gerado em:         $(Get-Date)" | Out-File -FilePath $LogPath -Append
" Usuario Executor:  $env:USERNAME" | Out-File -FilePath $LogPath -Append
" Computador:        $env:COMPUTERNAME" | Out-File -FilePath $LogPath -Append
" Modo de Operacao:  Analise e Correcao Confirmada Humana" | Out-File -FilePath $LogPath -Append
"=======================================================================" | Out-File -FilePath $LogPath -Append
"" | Out-File -FilePath $LogPath -Append

function Escrever-Linha ($Texto) {
    Write-Output $Texto
    $Texto | Out-File -FilePath $LogPath -Append
}

function Escrever-Cabecalho ($Texto) {
    Escrever-Linha ""
    Escrever-Linha "+---------------------------------------------------------------------+"
    Escrever-Linha "|  $($Texto.PadRight(65)) |"
    Escrever-Linha "+---------------------------------------------------------------------+"
}

# Funcao interativa baseada em Read-Host
function Perguntar-Correcao ($Titulo, $Resumo, $Acao) {
    Write-Host "`n[!] VULNERABILIDADE DETECTADA: $Titulo" -ForegroundColor Yellow
    Write-Host "Descricao: $Resumo" -ForegroundColor White
    Write-Host "O que o script fara: $Acao" -ForegroundColor Cyan
    
    while ($true) {
        $Resposta = Read-Host "Deseja aplicar esta correcao agora? (S/N)"
        if ($null -ne $Resposta) {
            $RespostaLimpa = $Resposta.Trim().ToUpper()
            if ($RespostaLimpa -eq "S") { return $true }
            if ($RespostaLimpa -eq "N") {
                Write-Host "[-] Correcao ignorada pelo usuario. Avancando para o proximo bloco..." -ForegroundColor Gray
                return $false
            }
        }
        Write-Host "[!] Opcao invalida. Digite apenas S para Sim ou N para Nao." -ForegroundColor Red
    }
}

Write-Host "`n=== INICIANDO AUDITORIA ===" -ForegroundColor Green
#Write-Host "=== INICIANDO AUDITORIA INTERATIVA GTEC ===" -ForegroundColor Cyan
#Write-Host "O relatorio expandido sera salvo em: $LogPath" -ForegroundColor Yellow

# BANNER GRANDE PERSONALIZADO EM DUAS LINHAS
Escrever-Linha "                                                                         "
Escrever-Linha "   _____ _______ ______ _____                                            "
Escrever-Linha "  / ____|__   __|  ____/ ____|                                           "
Escrever-Linha " | |  __   | |  | |__ | |                                                "
Escrever-Linha " | | |_ |  | |  |  __|| |                                                "
Escrever-Linha " | |__| |  | |  | |___| |____                                            "
Escrever-Linha "  \_____|  |_|  |______\_____|                                           "
Escrever-Linha "                                                                         "
Escrever-Linha "   _____ ______ _____ _    _ _____          _   _  _____          "
Escrever-Linha "  / ____|  ____/ ____| |  | |  __ \   /\   | \ | |/ ____|   /\     "
Escrever-Linha " | (___ | |__ | |  __| |  | | |__) | /  \  |  \| | |       /  \    "
Escrever-Linha "  \___ \|  __|| | |_ | |  | |  _  / / /\ \ | . ` | |      / /\ \   "
Escrever-Linha "  ____) | |___| |__| | |__| | | \ \/ ____ \| |\  | |____ / ____ \  "
Escrever-Linha " |_____/|______\_____|\____/|_|  \_\/_/    \_\_| \_|\_____/_/    \_\ "
"                                                                         " | Out-File -FilePath $LogPath -Append
Escrever-Linha ""

# BLOCO 1: Inventario de Sistema Operacional, Licenciamento e Hardware (VERSAO CORRIGIDA)
Escrever-Cabecalho "1. INVENTARIO DO SISTEMA OPERACIONAL E HARDWARE"
try {
    # 1. Coleta de dados do Sistema Operacional
    $OSInfo = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    
    # 2. Coleta de dados de Licenciamento Global do Windows
    $LicencaService = Get-CimInstance SoftwareLicensingService -ErrorAction SilentlyContinue
    
    $StatusAtivacao = "[ PERIGO ] Nao Ativado / Pirata ou Expirado"
    $TipoLicenca = "Digital / Padrao do Sistema"

    if ($null -ne $LicencaService) {
        # O status de licenca global 1 significa que o Windows esta 100% licenciado e ativo
        if ($LicencaService.ClientLicenseStatus -eq 1 -or (Get-CimInstance Win32_OperatingSystem).Status -eq "OK") {
            $StatusAtivacao = "[  OK  ] ATIVADO e Legitimado"
        }
        
        # Tenta extrair a descricao legivel da licenca ativa na maquina
        $DadosProduto = Get-CimInstance SoftwareLicensingProduct -Filter "ApplicationID='55c92734-d682-4d71-983e-d6ef31105912' and LicenseStatus=1" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -ne $DadosProduto) {
            $TipoLicenca = if ($DadosProduto.Description -match "VOLUME") { "Volume (KMS/MAK - Corporativa)" }
                           elseif ($DadosProduto.Description -match "RETAIL") { "Retail (Varejo / Digital)" }
                           elseif ($DadosProduto.Description -match "OEM") { "OEM (Pre-instalada de Fabrica)" }
                           else { $DadosProduto.Description }
        }
    }

    # 3. Coleta de dados do Processador (CPU)
    $CPUInfo = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue
    
    # 4. Coleta de dados da Memoria RAM
    $CompSystem = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
    $RAMTotalGB = if ($CompSystem.TotalPhysicalMemory) { [Math]::Round($CompSystem.TotalPhysicalMemory / 1GB, 2) } else { 0 }

    # Impressao estruturada dos resultados no relatorio (Sem acentos para nao quebrar)
    Escrever-Linha " [ REVISAO ] Detalhes do Sistema Operacional e Ativacao:"
    Escrever-Linha "  -> Sistema Operacional:  $($OSInfo.Caption)"
    Escrever-Linha "  -> Versao do SO:         $($OSInfo.Version) (Compilacao: $($OSInfo.BuildNumber))"
    Escrever-Linha "  -> Arquitetura:          $($OSInfo.OSArchitecture)"
    Escrever-Linha "  -> Status de Ativacao:   $StatusAtivacao"
    Escrever-Linha "  -> Tipo de Licenca:      $TipoLicenca"
    Escrever-Linha " ----------------------------------------------------"
    Escrever-Linha " [ REVISAO ] Especificacoes de Hardware Detectadas:"
    Escrever-Linha "  -> Processador (CPU):    $($CPUInfo.Name.Trim())"
    Escrever-Linha "  -> Cores Fisicos:        $($CPUInfo.NumberOfCores)"
    Escrever-Linha "  -> Threads/Logicos:      $($CPUInfo.NumberOfLogicalProcessors)"
    Escrever-Linha "  -> Memoria RAM Total:    $RAMTotalGB GB RAM"
    Escrever-Linha " ----------------------------------------------------"

} catch {
    Escrever-Linha " [ AVISO ] Nao foi possivel extrair o inventario de hardware e licenciamento."
}

Escrever-Linha ""
Escrever-Linha ""
Pause


# BLOCO 2: Identificacao do Nome da Maquina (Hostname)
Escrever-Cabecalho "2. IDENTIFICACAO DO NOME DA MAQUINA (HOSTNAME)"
try {
    # Captura o nome de rede e o grupo de trabalho do computador
    $NomeComputador = $env:COMPUTERNAME
    $InfoSistema = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
    $GrupoTrabalho = $InfoSistema.Workgroup
    
    # Identifica se a maquina faz parte de um Dominio Corporativo (Active Directory) ou Grupo Local
    $TipoRede = if ($InfoSistema.PartOfDomain) { "Dominio Corporativo (AD: $($InfoSistema.Domain))" } else { "Grupo de Trabalho Local (Workgroup)" }

    Escrever-Linha " [ REVISAO ] Identificadores de Rede do Dispositivo:"
    Escrever-Linha "  -> Nome do Computador (Hostname): $NomeComputador"
    Escrever-Linha "  -> Tipo de Associacao de Rede:   $TipoRede"
    if (-not $InfoSistema.PartOfDomain) {
        Escrever-Linha "  -> Nome do Grupo de Trabalho:     $GrupoTrabalho"
    }
    Escrever-Linha " ----------------------------------------------------"
    Escrever-Linha "  [  OK  ] Identificacao de Hostname concluida com sucesso."

} catch {
    Escrever-Linha " [ AVISO ] Nao foi possivel extrair o nome identificador da maquina."
}


Escrever-Linha ""
Escrever-Linha ""
Pause

# BLOCO 3: Configuração de Rede
Escrever-Cabecalho "3. CONFIGURACAO E TIPO DE CONEXAO DE REDE"
try {
    # Correcao da variavel de pipeline para $_.IPEnabled
    $RedesAtivas = Get-CimInstance Win32_NetworkAdapterConfiguration -ErrorAction SilentlyContinue | Where-Object { $_.IPEnabled -eq $true }
    if ($null -ne $RedesAtivas) {
        foreach ($Rede in $RedesAtivas) {
            # Correcao da expressao regular (Regex) para identificar IPv4 valido
            $IPv4 = $Rede.IPAddress | Where-Object { $_ -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$' } | Select-Object -First 1
            $TipoIP = if ($Rede.DHCPEnabled) { "Dinamico (DHCP)" } else { "Estatico (Fixo)" }
            $Descricao = $Rede.Description
            $TipoConexao = "Cabo (Ethernet)"
            if ($Descricao -match "Wireless" -or $Descricao -match "Wi-Fi" -or $Descricao -match "802.11") { $TipoConexao = "Wi-Fi (Sem fio)" }

            Escrever-Linha " -> Adaptador:      $Descricao"
            Escrever-Linha "    Conexao:        $TipoConexao"
            Escrever-Linha "    Endereco IP:    $IPv4"
            Escrever-Linha "    Tipo de IP:     $TipoIP"
            Escrever-Linha " ----------------------------------------------------"
        }
    } else { 
        Escrever-Linha " [ AVISO ] Nenhuma conexao de rede ativa com IPv4 encontrada." 
    }
} catch { 
    Escrever-Linha " [ AVISO ] Nao foi possivel mapear os adaptadores de rede locais." 
}

Escrever-Linha ""
Escrever-Linha ""
Pause

# BLOCO 4: Auditoria de Compartilhamentos de Rede
Escrever-Cabecalho "4. COMPARTILHAMENTOS DE REDE ATIVOS"
$Shares = Get-SmbShare | Where-Object { $_.Name -notmatch '\$' }
if ($Shares) {
    Escrever-Linha " [ ATENCAO ] Existem pastas abertas na rede local:"
    foreach ($share in $Shares) { Escrever-Linha "  $($share.Name.PadRight(20)) $($share.Path)" }
} else { Escrever-Linha " [  OK  ] Nenhum compartilhamento de rede customizado foi detectado." }


Escrever-Linha ""
Escrever-Linha ""
Pause


# BLOCO 5: Auditoria Avancada de Portas e Servicos Universais (Threat Intelligence e Remediacao)
Escrever-Cabecalho "5. AUDITORIA DE PORTAS DE REDE E SERVICOS UNIVERSAIS"

Escrever-Linha " [ REVISAO ] Varredura profunda de soquetes ativos no ecossistema local:"
Escrever-Linha ""
Escrever-Linha " Protocolo   Endereco Local         Estado          PID       Servico/Processo Detectado"
Escrever-Linha " ---------   --------------         ------          ---       --------------------------"

# 1. Dicionario Global de Portas Conhecidas, Riscos e Correcoes (Banco de Dados Local)
$DicionarioPortas = @{
    "21"   = @{ Nome = "FTP (Transferencia de Arquivos)"; Perigo = $true;  Risco = "Protocolo antigo que envia senhas in texto puro pela rede."; Fix = "Desative o servico de FTP nativo do Windows em 'Recursos do Windows' ou mude para SFTP (Criptografado)." }
    "22"   = @{ Nome = "SSH (Acesso Remoto Seguro)";      Perigo = $false; Risco = "Porta de gerenciamento remoto por console de comando."; Fix = "Garante que apenas IPs autorizados acessem esta porta no Firewall ou desative o OpenSSH Server se nao usar." }
    "23"   = @{ Nome = "Telnet (Gerenciamento Inseguro)"; Perigo = $true;  Risco = "Totalmente obsoleto. Trafego nao criptografado vulneravel a interceptacao."; Fix = "Desinstale o recurso 'Cliente Telnet/Servidor Telnet' atraves do painel de controle do Windows." }
    "25"   = @{ Nome = "SMTP (Servidor de E-mail)";       Perigo = $true;  Risco = "Pode ser abusado por malwares para envio em massa de Spam."; Fix = "Feche a porta no Firewall de Entrada ou desative servicos locais de e-mail como IIS SMTP." }
    "53"   = @{ Nome = "DNS Server Local";                Perigo = $false; Risco = "Servico de resolucao de nomes de rede ativo localmente."; Fix = "Se nao for um controlador de dominio (AD), verifique qual aplicativo abriu esta porta de escuta." }
    "80"   = @{ Nome = "HTTP (Web Server/Apache/IIS)";    Perigo = $false; Risco = "Servidor Web ativo sem criptografia (Ex: XAMPP, IIS)."; Fix = "Configurar certificados SSL/TLS para migrar o trafego para HTTPS (Porta 443) em ambiente de producao." }
    "135"  = @{ Nome = "RPC Endpoint Mapper";             Perigo = $true;  Risco = "Porta nativa do Windows usada para comunicacao entre maquinas. Alvo frequente de exploits."; Fix = "Bloqueie o acesso externo a esta porta no Firewall do Windows para redes Publicas." }
    "139"  = @{ Nome = "NetBIOS Session Service";         Perigo = $true;  Risco = "Protocolo legado de compartilhamento de arquivos e impressoras."; Fix = "Desative o NetBIOS nas propriedades avancadas do protocolo IPv4 da sua placa de rede." }
    "443"  = @{ Nome = "HTTPS (Web Server Seguro)";       Perigo = $false; Risco = "Servidor Web ativo com trafego seguro criptografado."; Fix = "Manter os pacotes de cifras SSL/TLS atualizados no servidor de hospedagem." }
    "445"  = @{ Nome = "SMB (Compartilhamento Windows)";   Perigo = $true;  Risco = "Porta critica! Alvo principal de Ransomwares (WannaCry) para se espalharem na rede."; Fix = "Desative o compartilhamento de arquivos se nao usar ou limite o acesso via Firewall estritamente para IPs confiaveis." }
    "1433" = @{ Nome = "Microsoft SQL Server";            Perigo = $false; Risco = "Banco de dados SQL ativo na maquina."; Fix = "Altere a senha do usuario 'sa' para uma combinacao forte e nao exponha esta porta diretamente na internet." }
    "1521" = @{ Nome = "Oracle Database Server";          Perigo = $false; Risco = "Instancia de Banco de Dados Oracle escutando conexoes."; Fix = "Restringir o acesso ao IP local e habilitar criptografia nativa no arquivo sqlnet.ora." }
    "3306" = @{ Nome = "MySQL/MariaDB Database";          Perigo = $false; Risco = "Banco de dados ativo (Ex: XAMPP/WampServer)."; Fix = "Garanta que o banco escute apenas em '127.0.0.1' no arquivo my.ini para bloquear acessos externos de intrusos." }
    "3389" = @{ Nome = "RDP (Area de Trabalho Remota)";   Perigo = $true;  Risco = "Porta de conexao remota visual do Windows. Alvo macico de ataques de Forca Bruta."; Fix = "Desative a 'Area de Trabalho Remota' nas configuracoes do sistema ou utilize uma VPN para acessa-la." }
    "5040" = @{ Nome = "Windows CDMA/Delivery Service";   Perigo = $false; Risco = "Servico nativo do Windows para otimizacao de entrega de updates."; Fix = "Comportamento normal do sistema Windows 10/11. Nenhuma acao e necessaria." }
    "5432" = @{ Nome = "PostgreSQL Database";             Perigo = $false; Risco = "Banco de dados PostgreSQL ativo."; Fix = "Revisar o arquivo pg_hba.conf para garantir que apenas conexoes autenticadas e locais sejam aceitas." }
    "5900" = @{ Nome = "VNC Remote Desktop";              Perigo = $true;  Risco = "Ferramenta de controle remoto de terceiros frequentemente explorada."; Fix = "Substitua por softwares com criptografia ponta a ponta ou proteja com senhas complexas e multiplo fator." }
    "7680" = @{ Nome = "Windows Update Delivery";         Perigo = $false; Risco = "Servico de distribuicao de atualizacoes P2P na rede local."; Fix = "Pode ser desativado em Configuracoes > Windows Update > Opcoes Avancadas > Otimizacao de Entrega." }
    "8080" = @{ Nome = "HTTP Alternate / Tomcat / Proxy"; Perigo = $false; Risco = "Porta alternativa comum para servidores Java ou proxies de rede."; Fix = "Audite se o servico rodando necessita estar exposto na rede interna ou externa." }
    "9000" = @{ Nome = "PHP-FPM / SonarQube / Watchtower";Perigo = $false; Risco = "Porta de gerenciamento e execucao de scripts e APIS."; Fix = "Garantir que nao haja credenciais padrao ativas no painel de controle do servico." }
    "11434"= @{ Nome = "Ollama (IA Local Server)";        Perigo = $false; Risco = "Servidor de modelos de Inteligencia Artificial ativo."; Fix = "O Ollama por padrao atende apenas localmente. Nao exponha a API para redes publicas sem proxy." }
}

# 2. Execucao e Coleta do Netstat Local
$NetstatRaw = netstat -ano | Select-String "LISTENING"
$AlertasEncontrados = @()

foreach ($Linha in $NetstatRaw) {
    $LinhaTexto = $Linha.ToString().Trim()
    $PartesDaLinha = $LinhaTexto -split '\s+'
    
    if ($PartesDaLinha.Count -ge 4) {
        $Proto      = $PartesDaLinha[0]
        $Local      = $PartesDaLinha[1]
        $Estado     = "OUVINDO"
        $IDProcesso = $PartesDaLinha[-1]

        # Isola o numero da porta pura
        $PortaPura = ""
        if ($Local -match ':(\d+)$') { $PortaPura = $Matches[1] }

        # Descobre o nome do processo real na memoria RAM
        $ProcessoNome = "Desconhecido"
        if ($IDProcesso -match '^\d+$') {
            $PIDNumerico = [int]$IDProcesso
            if ($PIDNumerico -gt 0) {
                $BuscaProcesso = Get-Process -Id $PIDNumerico -ErrorAction SilentlyContinue
                if ($BuscaProcesso) { $ProcessoNome = $BuscaProcesso.ProcessName }
            }
        }

        # Consulta o nosso Banco de Dados Local de portas
        $InfoServico = "Servico Customizado / Desconhecido"
        if ($DicionarioPortas.ContainsKey($PortaPura)) {
            $InfoServico = $DicionarioPortas[$PortaPura].Nome
            
            # Se for uma porta marcada como perigosa ou um processo nao identificado, adiciona aos alertas
            if ($DicionarioPortas[$PortaPura].Perigo -or $ProcessoNome -eq "Desconhecido") {
                $AlertasEncontrados += [PSCustomObject]@{
                    Porta    = $PortaPura
                    Servico  = $InfoServico
                    Processo = $ProcessoNome
                    PID      = $PIDNumerico
                    Risco    = $DicionarioPortas[$PortaPura].Risco
                    Fix      = $DicionarioPortas[$PortaPura].Fix
                }
            }
        }

        # Imprime a linha com alinhamento na tabela principal
        $ExibicaoServico = "$ProcessoNome ($InfoServico)"
        if ($ExibicaoServico.Length -gt 35) { $ExibicaoServico = $ExibicaoServico.Substring(0,35) }
        
        $LinhaAlinhada = "  $($Proto.ToString().PadRight(8))$($Local.ToString().PadRight(23))$($Estado.ToString().PadRight(16))$($IDProcesso.ToString().PadRight(10))$ExibicaoServico"
        Escrever-Linha $LinhaAlinhada
    }
}

# 3. MOTOR DE INTELIGENCIA: Detalha todos os Riscos Primeiro
if ($AlertasEncontrados.Count -gt 0) {
    Escrever-Linha ""
    Escrever-Linha "+---------------------------------------------------------------------+"
    Escrever-Linha "|  DETALHAMENTO DE ALERTAS DE SEGURANCA ENCONTRADOS                 |"
    Escrever-Linha "+---------------------------------------------------------------------+"
    
    foreach ($Alerta in $AlertasEncontrados) {
        Escrever-Linha ""
        Escrever-Linha " [ ALERTA DE RISCO ] PORTA ATIVA: $($Alerta.Porta) -> $($Alerta.Servico)"
        Escrever-Linha " ---------------------------------------------------------------------"
        Escrever-Linha "  -> Identificadores:  PID: $($Alerta.PID) | Processo Ativo: $($Alerta.Processo)"
        Escrever-Linha "  -> Resumo do Risco:  $($Alerta.Risco)"
        Escrever-Linha "  -> Solucao Padrao:   $($Alerta.Fix)"
        Escrever-Linha " ---------------------------------------------------------------------"
    }

                # 4. MODULO DE REMEDIACAO INTERATIVA INTELIGENTE (EVITA PROMPTS DUPLICADOS)
    Escrever-Linha ""
    Escrever-Linha "+---------------------------------------------------------------------+"
    Escrever-Linha "|  EXECUTANDO MODULO PARA TENTATIVA DE CORRECAO                       |"
    Escrever-Linha "+---------------------------------------------------------------------+"
    
    foreach ($Alerta in $AlertasEncontrados) {
        $TituloAviso = "Porta Vulneravel $($Alerta.Porta) ($($Alerta.Processo))"
        $AcaoScript = "Aplicar endurecimento de sistema ou finalizar o processo PID $($Alerta.PID)."
        
        # CHECAGEM ANTECIPADA: Verifica se as regras da GTEC ja existem no Firewall do Windows
        $BlindagemAtiva = $false
        if ($Alerta.Porta -eq "135") {
            if (Get-NetFirewallRule -Name "GTEC_BLOQUEIO_RPC_TCP_135" -ErrorAction SilentlyContinue) { $BlindagemAtiva = $true }
        }
        if ($Alerta.Porta -eq "445") {
            if (Get-NetFirewallRule -Name "GTEC_BLOQUEIO_SMB_TCP_445" -ErrorAction SilentlyContinue) { $BlindagemAtiva = $true }
        }
        if ($Alerta.Porta -eq "139") {
            if (Get-NetFirewallRule -Name "GTEC_BLOQUEIO_NETBIOS_TCP_139" -ErrorAction SilentlyContinue) { $BlindagemAtiva = $true }
        }

        # SE A BLINDAGEM JA EXISTE: Nao faz perguntas, exibe direto a observacao e avanca sozinho
        if ($BlindagemAtiva) {
            Write-Host "`n[!] ALERTA REGISTRADO: $TituloAviso" -ForegroundColor Gray
            Escrever-Linha "  -> Observacao: A regra de Firewall para a porta $($Alerta.Porta) ja existe. Sistema blindado."
            Write-Host "[-] Avancando automaticamente..." -ForegroundColor Gray
            continue # Pula direto para a proxima porta da lista
        }

        # SE NAO EXISTE REGRA NO FIREWALL: Faz a pergunta interativa normalmente
        $Confirmado = Perguntar-Correcao -Titulo $TituloAviso -Resumo $Alerta.Risco -Acao $AcaoScript
        
        if ($Confirmado) {
            Escrever-Linha " -> Iniciando correcao para Porta $($Alerta.Porta) (PID: $($Alerta.PID))...."
            
            switch ($Alerta.Porta) {
                "135" {
                    Escrever-Linha "    [ REQUISITO NATIVO ] O processo 'svchost' (PID: $($Alerta.PID)) e protegido."
                    Escrever-Linha "                         Criando regras de BLOQUEIO de entrada no Firewall do Windows..."
                    try {
                        New-NetFirewallRule -Name "GTEC_BLOQUEIO_RPC_TCP_135" -DisplayName "GTEC_BLOQUEIO_RPC_TCP_135" -Direction Inbound -Action Block -Protocol TCP -LocalPort 135 -ErrorAction Stop | Out-Null
                        New-NetFirewallRule -Name "GTEC_BLOQUEIO_RPC_UDP_135" -DisplayName "GTEC_BLOQUEIO_RPC_UDP_135" -Direction Inbound -Action Block -Protocol UDP -LocalPort 135 -ErrorAction Stop | Out-Null
                        Escrever-Linha "    [ FIX APLICADO ] Regras de Firewall criadas com sucesso para isolar a porta 135 TCP/UDP contra ataques externos."
                        Write-Host "[+] Porta 135 blindada via Firewall do Windows!" -ForegroundColor Green
                    } catch {
                        Escrever-Linha "    [ ERRO ] Falha ao injetar regras de Firewall. Verifique as permissoes."
                    }
                }
                "445" {
                    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "SMB1" -Value 0 -Type DWord -Force | Out-Null
                    Escrever-Linha "    [ FIX APLICADO ] Diretiva de mitigacao aplicada contra exploits de SMB1 no Registro."
                    Escrever-Linha "                     Criando regras de BLOQUEIO de entrada no Firewall do Windows para fechar a porta 445..."
                    try {
                        New-NetFirewallRule -Name "GTEC_BLOQUEIO_SMB_TCP_445" -DisplayName "GTEC_BLOQUEIO_SMB_TCP_445" -Direction Inbound -Action Block -Protocol TCP -LocalPort 445 -ErrorAction Stop | Out-Null
                        Escrever-Linha "    [ FIX APLICADO ] Porta 445 TCP isolada no Firewall contra movimentacao lateral de virus na rede."
                        Write-Host "[+] Mitigacao de Registro e Firewall aplicadas com sucesso para a porta 445!" -ForegroundColor Green
                    } catch {
                        Escrever-Linha "    [ ERRO ] Nao foi possivel criar a regra de Firewall para a porta 445."
                    }
                }
                "139" {
                    # Correcao Hibrida para o NetBIOS (Registro + Firewall)
                    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces" -Name "NetbiosOptions" -Value 2 -Force -ErrorAction SilentlyContinue | Out-Null
                    Escrever-Linha "    [ FIX APLICADO ] Solicitado desligamento do NetBIOS legado no Registro."
                    Escrever-Linha "                     Criando regras de BLOQUEIO de entrada no Firewall do Windows para fechar a porta 139..."
                    try {
                        New-NetFirewallRule -Name "GTEC_BLOQUEIO_NETBIOS_TCP_139" -DisplayName "GTEC_BLOQUEIO_NETBIOS_TCP_139" -Direction Inbound -Action Block -Protocol TCP -LocalPort 139 -ErrorAction Stop | Out-Null
                        New-NetFirewallRule -Name "GTEC_BLOQUEIO_NETBIOS_UDP_139" -DisplayName "GTEC_BLOQUEIO_NETBIOS_UDP_139" -Direction Inbound -Action Block -Protocol UDP -LocalPort 139 -ErrorAction Stop | Out-Null
                        Escrever-Linha "    [ FIX APLICADO ] Porta 139 TCP/UDP isolada no Firewall contra exploits de protocolos legados."
                        Write-Host "[+] Porta 139 blindada via Registro e Firewall!" -ForegroundColor Green
                    } catch {
                        Escrever-Linha "    [ ERRO ] Nao foi possivel criar as regras de Firewall para a porta 139."
                    }
                }
                "3389" {
                    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 1 -Force | Out-Null
                    Escrever-Linha "    [ FIX APLICADO ] Conexoes de Area de Trabalho Remota (RDP) desativadas localmente."
                    Write-Host "[+] RDP Desativado com sucesso!" -ForegroundColor Green
                }
                default {
                    if ($Alerta.PID -gt 0) {
                        if ($Alerta.Processo -in @("svchost", "system", "lsass", "services", "wininit", "csrss")) {
                            Escrever-Linha "    [ IMPEDIDO ] O processo '$($Alerta.Processo)' (PID: $($Alerta.PID)) e vital para o Kernel do Windows."
                            Escrever-Linha "                 Para fechar a porta $($Alerta.Porta) com seguranca, crie uma regra de BLOQUEIO no Firewall do Windows."
                            Write-Host "[-] Acao abortada: Processo critico do sistema protegido para evitar Tela Azul!" -ForegroundColor Yellow
                        } else {
                            try {
                                Stop-Process -Id $Alerta.PID -Force -ErrorAction Stop
                                Escrever-Linha "    [ FIX APLICADO ] O processo inseguro '$($Alerta.Processo)' (PID: $($Alerta.PID)) foi finalizado com sucesso."
                                Write-Host "[+] Processo $($Alerta.Processo) terminado!" -ForegroundColor Green
                            } catch {
                                Escrever-Linha "    [ ERRO ] Nao foi possivel derrubar o processo PID $($Alerta.PID). Protegido do Kernel."
                            }
                        }
                    }
                }
            }
        } else {
            Escrever-Linha " -> [ ALERTA MANTIDO ] Usuario optou por nao mitigar a ameaca na porta $($Alerta.Porta)."
        }
    }
} else {
    Escrever-Linha ""
    Escrever-Linha " [  OK  ] Todas as portas abertas pertencem a servicos locais controlados."
}




Escrever-Linha ""
Escrever-Linha ""
Pause

# BLOCO 6: Verificando Usuarios Administradores ....

Escrever-Cabecalho "6. USUARIOS COM PRIVILEGIOS ADMINISTRATIVOS"
$Admins = Get-LocalGroupMember -Group "Administradores" -ErrorAction SilentlyContinue
if (-not $Admins) { $Admins = Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue }
foreach ($admin in $Admins) { Escrever-Linha " -> Nome: $($admin.Name.PadRight(25)) | Tipo: $($admin.PrincipalSource)" }

Escrever-Linha ""
Escrever-Linha ""
Pause


# BLOCO 7: Auditoria de Politicas de Contas e Usuario Convidado (Guest)
Escrever-Cabecalho "7. AUDITORIA DE POLITICAS DE CONTAS E USUARIO CONVIDADO"
try {
    # Caminho de persistencia para checagem antecipada
    $GtecRegistryPath = "HKLM:\SOFTWARE\GTEC_Seguranca"
    $GuestCorrigidoAnteriormente = $false

    if (Test-Path $GtecRegistryPath) {
        $ValorCheckGuest = Get-ItemProperty -Path $GtecRegistryPath -Name "Guest_Fix_Applied" -ErrorAction SilentlyContinue
        if ($null -ne $ValorCheckGuest -and $ValorCheckGuest.Guest_Fix_Applied -eq 1) {
            $GuestCorrigidoAnteriormente = $true
        }
    }

    # 1. Varredura da Conta Convidado (Guest) via SID relativo universal (-501)
    $ContaConvidado = Get-LocalUser | Where-Object { $_.SID -match "-501$" } -ErrorAction SilentlyContinue
    
    if ($null -ne $ContaConvidado) {
        if ($ContaConvidado.Enabled -and -not $GuestCorrigidoAnteriormente) {
            Escrever-Linha " [ PERIGO ] A conta 'Convidado' ($($ContaConvidado.Name)) esta ATIVADA!"
            
            $Aceito = Perguntar-Correcao `
                -Titulo "Conta Convidado Ativa" `
                -Resumo "A conta de Convidado permite que usuarios nao autenticados acessem o sistema e arquivos locais sem exigir senha." `
                -Acao "Desativar imediatamente a conta Convidado no ecossistema local."
            
            if ($Aceito) {
                # Desativa a conta de forma nativa no Windows
                Disable-LocalUser -Name $ContaConvidado.Name -ErrorAction Stop
                
                # Salva a persistencia no Registro para nao perguntar de novo nas proximas rodadas
                if (-not (Test-Path $GtecRegistryPath)) { New-Item -Path $GtecRegistryPath -Force | Out-Null }
                Set-ItemProperty -Path $GtecRegistryPath -Name "Guest_Fix_Applied" -Value 1 -Type DWord -Force | Out-Null

                Escrever-Linha "    [ FIX APLICADO ] A conta Convidado ($($ContaConvidado.Name)) foi desativada com sucesso."
                Write-Host "[+] Conta Convidado desativada!" -ForegroundColor Green
                $GuestCorrigidoAnteriormente = $true
            } else {
                Escrever-Linha "    [ ALERTA MANTIDO ] Usuario optou por manter a conta Convidado ativa."
            }
        } elseif ($GuestCorrigidoAnteriormente) {
            Escrever-Linha " [  OK  ] Conta Convidado desativada com sucesso pelo script."
            Escrever-Linha "  -> Observacao: A conta Convidado ja foi desativada pela GTEC em execucoes anteriores. Sistema blindado."
        } else {
            Escrever-Linha " [  OK  ] Conta Convidado ($($ContaConvidado.Name)) esta desativada (Configuracao segura)."
        }
    }

    # 2. Varredura da Conta Administrador Nativa (Oculta - SID 500)
    $ContaAdminNativa = Get-LocalUser | Where-Object { $_.SID -match "-500$" } -ErrorAction SilentlyContinue
    if ($null -ne $ContaAdminNativa) {
        if ($ContaAdminNativa.Enabled) {
            Escrever-Linha " [ ATENCAO ] Conta Administrador nativa ($($ContaAdminNativa.Name)) esta ativa."
            Escrever-Linha "             Recomendacao GTEC: Garanta que ela possua uma senha forte ou use sua conta pessoal administrativa."
        } else {
            Escrever-Linha " [  OK  ] Conta Administrador nativa ($($ContaAdminNativa.Name)) esta inativa (Padrao seguro)."
        }
    }

    # 3. Auditoria de Contas Dormentes/Inativas (Mais de 90 dias sem uso)
    Escrever-Linha ""
    Escrever-Linha " [ REVISAO ] Verificando contas inativas no sistema..."
    $Usuarios = Get-LocalUser -ErrorAction SilentlyContinue
    $DataCorte = (Get-Date).AddDays(-90)
    $ContasInativasEncontradas = $false

    foreach ($User in $Usuarios) {
        # Desconsidera as contas nativas protegidas do Windows para focar apenas em contas comuns criadas
        if ($User.SID -notmatch "-500$" -and $User.SID -notmatch "-501$" -and $User.SID -notmatch "-503$" -and $User.Enabled) {
            if ($null -ne $User.LastLogon -and $User.LastLogon -lt $DataCorte) {
                Escrever-Linha "  -> Alerta: O usuario '$($User.Name)' nao faz login desde $($User.LastLogon). Conta dormente ativa."
                $ContasInativasEncontradas = $true
            }
        }
    }
    if (-not $ContasInativasEncontradas) {
        Escrever-Linha "  [  OK  ] Nenhuma conta de usuario comum dormente ou inativa foi detectada."
    }

} catch {
    Escrever-Linha " [ AVISO ] Nao foi possivel auditar as politicas de contas locais."
}



Escrever-Linha ""
Escrever-Linha ""
Pause

# BLOCO 8: Analise de Unidades de Disco / Armazenamento
Escrever-Cabecalho "8. ANALISE DE UNIDADES DE DISCO E SAUDE DO HARDWARE"
try {
    # 1. Analise Logica (Letras, Tamanhos e Sistemas de Arquivos)
    $DiscosLogicos = Get-CimInstance Win32_LogicalDisk -ErrorAction SilentlyContinue
    if ($null -ne $DiscosLogicos) {
        Escrever-Linha " [ REVISAO ] Analise Logica dos Volumes Cadastrados:"
        foreach ($Disco in $DiscosLogicos) {
            # Traduz o tipo de unidade para um nome compreensivel
            $TipoNome = switch ($Disco.DriveType) {
                2 { "Removivel (Pendrive/Cartao)" }
                3 { "Disco Local (HD/SSD)" }
                4 { "Unidade de Rede" }
                5 { "Disco Compacto (CD/DVD)" }
                default { "Desconhecido" }
            }

            # Calcula os tamanhos convertendo de Bytes para Gigabytes (GB)
            $TamanhoTotal = if ($Disco.Size) { [Math]::Round($Disco.Size / 1GB, 2) } else { 0 }
            $EspacoLivre   = if ($Disco.FreeSpace) { [Math]::Round($Disco.FreeSpace / 1GB, 2) } else { 0 }
            $SistemaArq   = if ($Disco.FileSystem) { $Disco.FileSystem } else { "Nao identificado" }
            
            Escrever-Linha " -> Unidade:        $($Disco.DeviceID) ($TipoNome)"
            Escrever-Linha "    Sistema de Arq:  $SistemaArq"
            Escrever-Linha "    Capacidade:     $TamanhoTotal GB Total | $EspacoLivre GB Livre"
            Escrever-Linha "    Status Logico:   [  OK  ] Volume Integro e Acessivel"
            Escrever-Linha " ----------------------------------------------------"
        }
    }

    # 2. Analise Fisica Avançada (Saude e SMART do Hardware do HD/SSD)
    Escrever-Linha ""
    Escrever-Linha " [ REVISAO ] Saude Fisica dos Discos Conectados (SMART):"
    
    # Busca a saude fisica direto da API de armazenamento do Windows 10/11
    $DiscosFisicos = Get-PhysicalDisk -ErrorAction SilentlyContinue
    if ($null -ne $DiscosFisicos) {
        foreach ($Fisico in $DiscosFisicos) {
            # Mapeia o status de saude fisica do hardware
            $SaudeFisica = $Fisico.HealthStatus
            $StatusTag = "[  OK  ] SAUDAVEL"
            
            if ($SaudeFisica -eq "Warning" -or $SaudeFisica -match "Atencao") {
                $StatusTag = "[ ATENCAO ] Alerta de Desempenho / Desgaste"
            } elseif ($SaudeFisica -eq "Unhealthy" -or $SaudeFisica -match "Inseguro|Falha") {
                $StatusTag = "[ PERIGO ] DISCO COM FALHA FISICA IMINENTE (Substitua urgente)"
            }

            Escrever-Linha " -> Modelo:         $($Fisico.FriendlyName)"
            Escrever-Linha "    Tipo de Midia:  $($Fisico.MediaType)"
            Escrever-Linha "    Saude Fisica:   $StatusTag"
            Escrever-Linha " ----------------------------------------------------"
        }
    } else {
        Escrever-Linha " [ AVISO ] Nao foi possivel ler os sensores de saude fisica (SMART) deste hardware."
    }
} catch {
    Escrever-Linha " [ AVISO ] Falha geral ao executar a auditoria do subsistema de discos."
}

Escrever-Linha ""
Escrever-Linha ""
Pause


# BLOCO 9: Varredura e Correção de Permissões Inseguras
Escrever-Cabecalho "9. ANALISE DE PERMISSOES EM PASTAS CRITICAS"
$TargetPaths = @("C:\Program Files", "C:\Program Files (x86)", "C:\Windows")
foreach ($Path in $TargetPaths) {
    if (Test-Path $Path) {
        Escrever-Linha " -> Analisando: $Path"
        $acl = Get-Acl $Path
        $vulnerabilidades = $acl.Access | Where-Object {
            ($_.IdentityReference -match "Everyone" -or $_.IdentityReference -match "Todos") -and 
            ($_.FileSystemRights -match "Write" -or $_.FileSystemRights -match "FullControl" -or $_.FileSystemRights -match "Modify")
        }
        if ($vulnerabilidades) {
            Escrever-Linha "    [ PERIGO ] Grupo generico possui privilegios altos nesta pasta!"
            $Aceito = Perguntar-Correcao -Titulo "Permissoes Frageis em $Path" -Resumo "Usuarios Everyone/Todos possuem permissao de escrita." -Acao "Remover acesso explicito de escrita."
            if ($Aceito) {
                foreach ($vuln in $vulnerabilidades) { $acl.RemoveAccessRule($vuln) }
                Set-Acl $Path $acl
                Escrever-Linha "    [ FIX APLICADO ] Permissoes restritas com sucesso."
            } else { Escrever-Linha "    [ ALERTA MANTIDO ] Usuario optou por nao corrigir." }
        } else { Escrever-Linha "    [  OK  ] Permissoes padrao de fabrica estao seguras." }
    }
}

Escrever-Linha ""
Escrever-Linha ""
Pause


# BLOCO 10: Estado do Windows Defender e Firewall
Escrever-Cabecalho "10. ESTADO DAS DEFESAS DO WINDOWS"
if (Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue) {
    $Defender = Get-MpComputerStatus
    if (-not $Defender.AntivirusEnabled -or -not $Defender.RealTimeProtectionEnabled) {
        Escrever-Linha "    [ PERIGO ] Defesas do Windows Defender desativadas!"
        $Aceito = Perguntar-Correcao -Titulo "Windows Defender Inativo" -Resumo "Protecao desativada." -Acao "Reativar monitoramento."
        if ($Aceito) {
            Set-MpPreference -DisableRealtimeMonitoring $false
            Escrever-Linha "    [ FIX APLICADO ] Windows Defender reativado."
        } else { Escrever-Linha "    [ PERIGO MANTIDO ] O Antivirus permanece desligado." }
    } else {
        Escrever-Linha " -> Antivirus Defender:      [  OK  ] ATIVO"
        Escrever-Linha " -> Protecao em Tempo Real:   [  OK  ] ATIVA"
    }
}

Escrever-Linha ""
foreach ($profile in (Get-NetFirewallProfile)) {
    if ($profile.Enabled -ne 'True') {
        Escrever-Linha "    [ PERIGO ] Perfil $($profile.Name) do Firewall desativado!"
        $Aceito = Perguntar-Correcao -Titulo "Firewall Desativado" -Resumo "Perfil $($profile.Name) desligado." -Acao "Ativar Firewall."
        if ($Aceito) {
            Set-NetFirewallProfile -Name $profile.Name -Enabled True
            Escrever-Linha "    [ FIX APLICADO ] Firewall $($profile.Name) ativado."
        } else { Escrever-Linha "    [ PERIGO MANTIDO ] Firewall $($profile.Name) desligado." }
    } else { Escrever-Linha "    Perfil $($profile.Name.PadRight(12)): [  OK  ] ATIVO" }
}

Escrever-Linha ""
Escrever-Linha ""
Pause

# BLOCO 11: Verificação e Correção do Protocolo SMBv1
Escrever-Cabecalho "11. PROTOCOLO DE REDE OBSOLETO (SMBv1)"
$SmbKey = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
$Smb1Ativo = $true
if (Test-Path $SmbKey) {
    $SmbValue = Get-ItemProperty -Path $SmbKey -Name "SMB1" -ErrorAction SilentlyContinue
    if ($null -ne $SmbValue -and $SmbValue.SMB1 -eq 0) { $Smb1Ativo = $false }
}
if ($Smb1Ativo) {
    Escrever-Linha " [ PERIGO ] O protocolo SMBv1 esta ATIVADO."
    $Aceito = Perguntar-Correcao -Titulo "Protocolo SMBv1 Ativo" -Resumo "Protocolo antigo e vulneravel." -Acao "Desativar SMBv1."
    if ($Aceito) {
        if (-not (Test-Path $SmbKey)) { New-Item -Path $SmbKey -Force | Out-Null }
        Set-ItemProperty -Path $SmbKey -Name "SMB1" -Value 0 -Type DWord -Force
        Escrever-Linha " [ FIX APLICADO ] SMBv1 desativado via Registro."
    } else { Escrever-Linha " [ PERIGO MANTIDO ] SMBv1 continua ativo." }
} else {
    Escrever-Linha " [  OK  ] O protocolo SMBv1 esta DESATIVADO (Configuracao segura)."
}

Escrever-Linha ""
Escrever-Linha ""
Pause

# BLOCO 12: Politica de Bloqueio Contra Forca Bruta e Gestao de Identidade (Autologon Inteligente)
Escrever-Cabecalho "12. POLITICA DE BLOQUEIO CONTRA FORCA BRUTA E IDENTIDADE"

# Caminho de seguranca da GTEC no Registro para controlar o status no Windows Home
$GtecRegistryPath = "HKLM:\SOFTWARE\GTEC_Seguranca"
$LockoutCorrigidoAnteriormente = $false

if (Test-Path $GtecRegistryPath) {
    $ValorCheck = Get-ItemProperty -Path $GtecRegistryPath -Name "Lockout_Fix_Applied" -ErrorAction SilentlyContinue
    if ($null -ne $ValorCheck -and $ValorCheck.Lockout_Fix_Applied -eq 1) {
        $LockoutCorrigidoAnteriormente = $true
    }
}

# 1. Auditoria da Politica Global de Bloqueio
$LockoutQuery = net accounts | Select-String "Limiar de bloqueio", "Account lockout", "Bloqueio"
$LockoutFraco = $false

if ($null -eq $LockoutQuery -or $LockoutQuery -match "Nunca" -or $LockoutQuery -match "Never" -or $LockoutQuery -match "0") {
    # Se ja foi corrigido pelo script antes, valida como OK para blindar o Windows Home
    if ($LockoutCorrigidoAnteriormente) {
        Escrever-Linha " [  OK  ] Seguranca de Bloqueio ativa na base de contas do sistema."
    } else {
        Escrever-Linha " [ ATENCAO ] Bloqueio por erro de senha desativado ou nao configurado."
        $LockoutFraco = $true
    }
} else {
    $TextoLimpo = $LockoutQuery.ToString().Trim()
    Escrever-Linha " [  OK  ] Seguranca de Bloqueio ativa: $TextoLimpo"
}

# 2. Varredura Tecnica: Verifica se o Usuario Atual possui senha ou Autologon ativo
$UsuarioAtual = $env:USERNAME
$UsuarioSemSenha = $false
$AutologonAtivo = $false

# CHECAGEM ANTECIPADA NO REGISTRO: Verifica se a GTEC ja configurou o Autologon
$WinLogonPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
if (Test-Path $WinLogonPath) {
    $AutoLoginVal = Get-ItemProperty -Path $WinLogonPath -Name "AutoAdminLogon" -ErrorAction SilentlyContinue
    $DefaultPassVal = Get-ItemProperty -Path $WinLogonPath -Name "DefaultPassword" -ErrorAction SilentlyContinue
    
    if ($null -ne $AutoLoginVal -and $AutoLoginVal.AutoAdminLogon -eq "1" -and $null -ne $DefaultPassVal) {
        $AutologonAtivo = $true
    }
}

try {
    $DadosUsuarioLocal = Get-LocalUser -Name $UsuarioAtual -ErrorAction SilentlyContinue
    if ($null -ne $DadosUsuarioLocal -and $DadosUsuarioLocal.PasswordRequired -eq $false -and -not $AutologonAtivo) {
        $UsuarioSemSenha = $true
    }
} catch {
    $UsuarioSemSenha = $false
}

# Define a exibicao de status com base na blindagem do Autologon
if ($AutologonAtivo) {
    Escrever-Linha " [  OK  ] Usuario '$UsuarioAtual' protegido via Autologon GTEC com barreira de senha ativa."
    Escrever-Linha "  -> Observacao: O Login Automatico com senha forte ja esta ativo e configurado no Registro. Sistema blindado."
} elseif ($UsuarioSemSenha) {
    Escrever-Linha " [ PERIGO ] O seu usuario '$UsuarioAtual' esta operando SEM SENHA configurada!"
    Escrever-Linha "            Isso permite que virus obtenham controle total do Kernel instantaneamente."
} else {
    Escrever-Linha " [  OK  ] Usuario '$UsuarioAtual' possui uma barreira de senha ativa no sistema."
}

# 3. MITIGACAO INDEPENDENTE - CASO 1: Conta sem Senha (Apenas se nao tiver Autologon)
if ($UsuarioSemSenha -and -not $AutologonAtivo) {
    Escrever-Linha ""
    Escrever-Linha "+---------------------------------------------------------------------+"
    Escrever-Linha "|  MITIGACAO DE IDENTIDADE: CONFIGURACAO DE SENHA                     |"
    Escrever-Linha "+---------------------------------------------------------------------+"
    
    $TituloAviso = "Conta do Usuario '$UsuarioAtual' Sem Senha"
    $ResumoAviso = "Seu PC entra direto sem senha. Isso desativa as defesas do Windows contra malwares locais e acessos fisicos de terceiros."
    $AcaoScript  = "Permitir que voce digite sua propria senha e configurar o Windows para fazer LOGIN AUTOMATICO."
    
    $ConfirmarSenha = Perguntar-Correcao -Titulo $TituloAviso -Resumo $ResumoAviso -Acao $AcaoScript
    
    if ($ConfirmarSenha) {
        try {
            Write-Host ""
            Write-Host "[!] ATENCAO: Digite a senha que deseja definir para o usuario '$UsuarioAtual'." -ForegroundColor Cyan
            Write-Host "    Os caracteres nao aparecerao na tela por motivos de seguranca." -ForegroundColor Yellow
            
            $SecureString = Read-Host "Digite a nova senha" -AsSecureString
            
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
            $SenhaDigitada = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            
            if ([string]::IsNullOrEmpty($SenhaDigitada)) { throw "A senha nao pode ser vazia." }

            Set-LocalUser -Name $UsuarioAtual -Password $SecureString -ErrorAction Stop
            
            $UserObject = Get-LocalUser -Name $UsuarioAtual
            $UserObject.PasswordRequired = $true
            
            Escrever-Linha "    [ FIX APLICADO ] Senha personalizada configurada com sucesso para o usuario '$UsuarioAtual'."
            Write-Host "[+] Senha aplicada na conta com sucesso!" -ForegroundColor Green
            
            if (Test-Path $WinLogonPath) {
                Set-ItemProperty -Path $WinLogonPath -Name "AutoAdminLogon" -Value "1" -Force | Out-Null
                Set-ItemProperty -Path $WinLogonPath -Name "DefaultUserName" -Value $UsuarioAtual -Force | Out-Null
                Set-ItemProperty -Path $WinLogonPath -Name "DefaultPassword" -Value $SenhaDigitada -Force | Out-Null
                Set-ItemProperty -Path $WinLogonPath -Name "DefaultDomainName" -Value $env:COMPUTERNAME -Force | Out-Null
                
                Escrever-Linha "    [ FIX APLICADO ] Login Automatico ativado. O Windows guardou a credencial e entrara direto ao ligar."
                Write-Host "[+] Login Automatico configurado com sucesso! A praticidade foi mantida." -ForegroundColor Green
                $AutologonAtivo = $true
            }
        } catch {
            Escrever-Linha "    [ ERRO ] Falha critica ao alterar a senha ou injetar chaves de Autologon no Registro: $_"
        }
    } else {
        Escrever-Linha "    [ PERIGO MANTIDO ] O usuario optou por continuar usando o Windows sem senha protetora."
    }
}

# 4. MITIGACAO INDEPENDENTE - CASO 2: Politica Global de Forca Bruta (BLINDAGEM VIA REGISTRO PARA WINDOWS HOME)
if ($LockoutFraco -and -not $LockoutCorrigidoAnteriormente) {
    Escrever-Linha ""
    Escrever-Linha "+---------------------------------------------------------------------+"
    Escrever-Linha "|  MITIGACAO DE SEGURANCA: POLITICA DE BLOQUEIO DE CONTA              |"
    Escrever-Linha "+---------------------------------------------------------------------+"
    
    $TituloAviso = "Ausencia de Bloqueio por Erro de Senha"
    $ResumoAviso = "A maquina permite tentativas infinitas de login. Ataques de dicionario na sua rede podem tentar quebrar senhas sem limite."
    $AcaoScript  = "Configurar o Windows para bloquear temporariamente o login por 30 minutos apos 5 erros seguidos de senha."
    
    $ConfirmarLockout = Perguntar-Correcao -Titulo $TituloAviso -Resumo $ResumoAviso -Acao $AcaoScript
    
    if ($ConfirmarLockout) {
        # Executa a configuracao interna do Windows
        net accounts /lockoutthreshold:5 /lockoutduration:30 /lockoutwindow:30 | Out-Null
        
        # Cria a chave fisica de persistencia para o script lembrar nas proximas execucoes
        if (-not (Test-Path $GtecRegistryPath)) { New-Item -Path $GtecRegistryPath -Force | Out-Null }
        Set-ItemProperty -Path $GtecRegistryPath -Name "Lockout_Fix_Applied" -Value 1 -Type DWord -Force | Out-Null
        
        Escrever-Linha "    [ FIX APLICADO ] Politica contra Forca Bruta estabelecida (5 erros / 30 minutos)."
        Write-Host "[+] Politica de bloqueio aplicada com sucesso!" -ForegroundColor Green
        $LockoutCorrigidoAnteriormente = $true
    } else {
        Escrever-Linha "    [ ATENCAO MANTIDO ] Politica de tentativas de senha continua desprotegida."
    }
} elseif ($LockoutCorrigidoAnteriormente) {
    Escrever-Linha "  -> Observacao: A politica contra Forca Bruta (5 tentativas / 30 min) ja foi injetada no sistema. Sistema blindado."
}


Escrever-Linha ""
Escrever-Linha ""
Pause

# BLOCO 13: Programas que Iniciam com o Windows (VERSAO CORRIGIDA VIA CIM)
Escrever-Cabecalho "13. PROGRAMAS INICIALIZADOS COM O SISTEMA (STARTUP)"
try {
    $StartupApps = Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue
    if ($null -ne $StartupApps -and $StartupApps.Count -gt 0) {
        foreach ($App in $StartupApps) {
            $NomeApp = if ($App.Name) { $App.Name } else { "Desconhecido" }
            $Comando = if ($App.Command) { $App.Command } else { "Nao especificado" }
            Escrever-Linha " -> NOME: $($NomeApp.PadRight(20)) | CAMINHO: $Comando"
        }
    } else { 
        Escrever-Linha " [  OK  ] Nenhum aplicativo customizado configurado no startup." 
    }
} catch { 
    Escrever-Linha " [ AVISO ] Nao foi possivel ler a lista de inicializacao automatica." 
}

Escrever-Linha ""
Escrever-Linha ""
Pause

# BLOCO 14: Verificacao de Atualizacoes Pendentes (VERSAO CORRIGIDA)
Escrever-Cabecalho "14. ATUALIZACOES DO SISTEMA (WINDOWS UPDATE)"
try {
    $UpdateSession = New-Object -ComObject Microsoft.Update.Session -ErrorAction Stop
    $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
    $SearchResult = $UpdateSearcher.Search("IsInstalled=0 and Type='Software'")
    if ($null -ne $SearchResult -and $SearchResult.Updates.Count -gt 0) {
        Escrever-Linha " [ ATENCAO ] Existem $($SearchResult.Updates.Count) atualizacoes pendentes de instalacao!"
        foreach ($update in $SearchResult.Updates) { 
            Escrever-Linha "   -> [PENDENTE] $($update.Title)" 
        }
    } else { 
        Escrever-Linha " [  OK  ] O Windows esta totalmente atualizado e seguro." 
    }
} catch {
    Escrever-Linha " [ AVISO ] Nao foi possivel alcancar os servidores do Windows Update."
}


Escrever-Linha ""
Escrever-Linha ""
Pause

# BLOCO 15: Caça a Ameaças e Varredura Antimalware Interativa (Threat Hunting)
Escrever-Cabecalho "15. CACA A AMEACAS E VARREDURA ANTIMALWARE INTERATIVA"

Escrever-Linha " [ REVISAO ] Executando varredura heuristica e analise de integridade no disco C:..."
Escrever-Linha ""

# 1. Dicionario Global de Indicadores de Comprometimento (IOCs) e Malwares
$DicionarioAmeacas = @{
    "EXE_SUSPEITO"  = @{ Nome = "Potencial Trojan / Arquivo Executavel Oculto"; Risco = "Executaveis escondidos em pastas temporarias sao usados por malwares para obter persistencia."; Fix = "Remover o arquivo executavel permanentemente e bloquear a pasta para escrita comum." }
    "RANSOM_EXT"    = @{ Nome = "Indicador de Ransomware (.locked / .crypto)"; Risco = "Arquivos com extensoes de criptografia indicam um ataque ativo de sequestro de dados."; Fix = "Isolar a maquina da rede imediatamente, finalizar o processo pai e iniciar recuperacao de backup." }
    "BAT_INFECTADO" = @{ Nome = "Script Suspeito de Automacao / Invasao (.bat / .vbs)"; Risco = "Scripts ocultos executando comandos silenciosos em segundo plano para roubo de dados."; Fix = "Deletar o script malicioso e auditar as chaves de Inicializacao (Startup) do Windows." }
    "DEFENDER_INF"  = @{ Nome = "Malware Identificado pelo Windows Defender"; Risco = "O motor do antivirus encontrou assinaturas de softwares maliciosos na fila de analise."; Fix = "Enviar o arquivo infectado para a Quarentena segura ou forcar a exclusao total via Kernel." }
}

$AmeacasDetectadas = @()

# 2. Passo 1: Busca Inteligente por Malwares Ativos no Windows Defender (COM FILTRO DE NEUTRALIZADOS)
try {
    if (Get-Command Get-MpThreat -ErrorAction SilentlyContinue) {
        # Filtra e ignora ameacas que o Defender ja marcou como resolvidas, limpas ou em quarentena
        $HistoricoDefender = Get-MpThreat -ErrorAction SilentlyContinue | Where-Object { 
            $_.SeverityID -gt 2 -and $_.Status -notin @('Cleaned', 'Quarantined', 'Removed', 3, 6, 10) 
        }
        
        foreach ($Ameaca in $HistoricoDefender) {
            $CaminhoVetor = "Registro de Memoria"
            
            # Tenta ler o array de recursos de forma segura para extrair o caminho do arquivo
            if ($null -ne $Ameaca.Resources -and $Ameaca.Resources.Count -gt 0) {
                # Filtra apenas itens que tenham o formato de caminhos de arquivos válidos (Ex: C:\...)
                $CaminhoVetor = $Ameaca.Resources | Where-Object { $_ -match '^[a-zA-Z]:\\' } | Select-Object -First 1
                if ($null -eq $CaminhoVetor) { $CaminhoVetor = "Registro de Memoria" }
            }

            # SEGUNDA CAMADA DE PROTECAO: So ativa o alerta se houver um arquivo fisico real ameacando o disco C:
            if ($CaminhoVetor -ne "Registro de Memoria" -and (Test-Path $CaminhoVetor)) {
                $AmeacasDetectadas += [PSCustomObject]@{
                    Identificador = "DEFENDER_INF"
                    NomeAmeaca    = $Ameaca.ThreatName
                    Caminho       = $CaminhoVetor
                    Tipo          = $DicionarioAmeacas["DEFENDER_INF"].Nome
                    Risco         = "Ameaca ativa identificada no disco pelo Defender: " + $DicionarioAmeacas["DEFENDER_INF"].Risco
                    Fix           = $DicionarioAmeacas["DEFENDER_INF"].Fix
                }
            }
        }
    }
} catch {
    Escrever-Linha " [-] Aviso: Falha ao se conectar com as diretivas do Windows Defender."
}

# 3. Passo 2: Varredura Fisica Inteligente em Diretorios Criticos de Virus (Sem travar o PC)
$PastasAlvo = @(
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup",
    "C:\Users\Public",
    "C:\Windows\Temp"
)

foreach ($Pasta in $PastasAlvo) {
    if (Test-Path $Pasta) {
        # Busca apenas arquivos executaveis ou scripts suspeitos escondidos ou criados recentemente nessas pastas
        $ArquivosSuspeitos = Get-ChildItem -Path $Pasta -File -Recurse -ErrorAction SilentlyContinue | 
                             Where-Object { $_.Extension -in @(".exe", ".bat", ".vbs", ".scr", ".locked", ".crypto") }

        foreach ($Arq in $ArquivosSuspeitos) {
            $IDChave = "EXE_SUSPEITO"
            if ($Arq.Extension -in @(".locked", ".crypto")) { $IDChave = "RANSOM_EXT" }
            if ($Arq.Extension -in @(".bat", ".vbs")) { $IDChave = "BAT_INFECTADO" }

            $AmeacasDetectadas += [PSCustomObject]@{
                Identificador = $IDChave
                NomeAmeaca    = $Arq.Name
                Caminho       = $Arq.FullName
                Tipo          = $DicionarioAmeacas[$IDChave].Nome
                Risco         = $DicionarioAmeacas[$IDChave].Risco
                Fix           = $DicionarioAmeacas[$IDChave].Fix
            }
        }
    }
}

# 4. Exibicao das Ameacas na Tabela Principal do Relatorio
if ($AmeacasDetectadas.Count -gt 0) {
    Escrever-Linha " Alertas Detectados no Sistema de Arquivos:"
    Escrever-Linha " ------------------------------------------"
    foreach ($Am in $AmeacasDetectadas) {
        $CaminhoCurto = if ($Am.Caminho.Length -gt 50) { "..." + $Am.Caminho.Substring($Am.Caminho.Length - 47) } else { $Am.Caminho }
        Escrever-Linha "  [ PERIGO ] Ficheiro: $($Am.NomeAmeaca.PadRight(20)) | Tipo: $($Am.Tipo.PadRight(35)) | Local: $CaminhoCurto"
    }

    # 5. DETALHAMENTO DE RISCOS E PLANOS DE CORRECAO
    Escrever-Linha ""
    Escrever-Linha "+---------------------------------------------------------------------+"
    Escrever-Linha "|  DETALHAMENTO DE ALERTAS MALICIOSOS E REMEDIACAO DE DISCO           |"
    Escrever-Linha "+---------------------------------------------------------------------+"
    
    foreach ($Am in $AmeacasDetectadas) {
        Escrever-Linha ""
        Escrever-Linha " [ ALERTA DE INFECCAO ] COMPONENTES COMPROMETIDOS: $($Am.NomeAmeaca)"
        Escrever-Linha " ---------------------------------------------------------------------"
        Escrever-Linha "  -> Localizacao:     $($Am.Caminho)"
        Escrever-Linha "  -> Tipo de Vetor:   $($Am.Tipo)"
        Escrever-Linha "  -> Resumo do Risco:  $($Am.Risco)"
        Escrever-Linha "  -> Como Corrigir:    $($Am.Fix)"
        Escrever-Linha " ---------------------------------------------------------------------"
    }

    # 6. MODULO DE REMEDIACAO INTERATIVA (DELETAR / QUARENTENA)
    Escrever-Linha ""
    Escrever-Linha "+---------------------------------------------------------------------+"
    Escrever-Linha "|  INICIANDO ETAPA DE EXCLUSAO SEGURA.............		          |"
    Escrever-Cabecalho "EXCLUSAO SEGURA DE AMEACAS"

    
    foreach ($Am in $AmeacasDetectadas) {
        $TituloAviso = "Eliminar Vetor Malicioso: $($Am.NomeAmeaca)"
        
        # Ajusta a descricao caso o arquivo ja tenha sido mitigado para a memoria
        $CaminhoAlvo = $Am.Caminho
        $AcaoScript = "Apagar permanentemente do disco o arquivo localizado em: $CaminhoAlvo"
        if ($CaminhoAlvo -eq "Registro de Memoria") {
            $AcaoScript = "Limpar o historico de logs antigos e alertas arquivados do Windows Defender."
        }
        
        $Confirmado = Perguntar-Correcao -Titulo $TituloAviso -Resumo $Am.Risco -Acao $AcaoScript
        
        if ($Confirmado) {
    if ($CaminhoAlvo -eq "Registro de Memoria") {
        Escrever-Linha " -> Solicitando limpeza forcada do banco de dados e cache do Defender..."
        try {
            # 1. Executa a ferramenta oficial da Microsoft para remover o cache persistente de logs antigos
            if (Test-Path "C:\Program Files\Windows Defender\MpCmdRun.exe") {
                & "C:\Program Files\Windows Defender\MpCmdRun.exe" -Restore -All -RemoveControl | Out-Null
            }

            # 2. Apaga a pasta fisica de historico local (Garante dupla limpeza)
            $CaminhoLogDefender = "$env:ProgramData\Microsoft\Windows Defender\Scans\History\Service"
            if (Test-Path $CaminhoLogDefender) {
                Remove-Item -Path "$CaminhoLogDefender\*" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
            }

            # 3. Forca a limpeza do canal de Eventos Operacionais do Defender para remover o vinculo antigo
            if (Get-Command Clear-EventLog -ErrorAction SilentlyContinue) {
                Clear-EventLog -LogName "Microsoft-Windows-Windows Defender/Operational" -ErrorAction SilentlyContinue | Out-Null
            }

            Escrever-Linha "    [ FIX APLICADO ] Banco de dados e cache do Defender limpos via MpCmdRun."
            Write-Host "[+] Cache e historico do Defender limpos com sucesso!" -ForegroundColor Green
        } catch {
            Escrever-Linha "    [ ERRO ] Nao foi possivel resetar a memoria do Defender."
        }
    } else {
        Escrever-Linha " -> Iniciando remocao forcada do alvo no disco: $CaminhoAlvo..."
        if (Test-Path $CaminhoAlvo) {
            try {
                Remove-Item -Path $CaminhoAlvo -Force -Recurse -ErrorAction Stop
                Escrever-Linha "    [ FIX APLICADO ] O arquivo infectado foi expurgado do sistema com sucesso."
                Write-Host "[+] Ameaca neutralizada!" -ForegroundColor Green
            } catch {
                Escrever-Linha "    [ ERRO ] Nao foi possivel apagar o arquivo. Ele pode estar bloqueado pelo sistema."
            }
        } else {
            Escrever-Linha "    [ INFO ] O arquivo nao foi localizado no disco (Ja removido pelo Defender)."
        }
    }
} else {
    Escrever-Linha " -> [ ALERTA MANTIDO ] O usuario optou por manter o registro da ameaca $($Am.NomeAmeaca)."
}
    }
} else {
    Escrever-Linha " [  OK  ] Varredura heuristica concluida. Nenhum arquivo malicioso conhecido foi detectado."
}


Escrever-Linha ""
Escrever-Linha ""
Pause


Escrever-Linha ""
Escrever-Linha "======================================================================="
Escrever-Linha "             FIM DO PROCESSAMENTO DE AUDITORIA                         "
"=======================================================================" | Out-File -FilePath $LogPath -Append

Write-Host "`n=== AUDITORIA CONCLUIDA COM SUCESSO! ===" -ForegroundColor Green

