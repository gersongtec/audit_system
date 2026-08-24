# audit_system
Assistente interativo de auditoria, caça a ameaças e remediação tática universal para sistemas Windows.

# GTEC SEGURANÇA 🛡️
> Assistente Interativo de Auditoria, Threat Hunting e Remediação Tática Universal para Windows.

O **GTEC SEGURANÇA** é uma suíte de scripts em PowerShell 5.1 desenvolvida para atuar como um assistente tático de segurança cibernética (EDR/Blue Team). A ferramenta realiza auditorias profundas no sistema operacional, caça vulnerabilidades ativas e oferece um ecossistema de remediação interativa onde o administrador pode aplicar correções cirúrgicas em tempo real.

O projeto foi exaustivamente testado módulo a módulo, alcançando **100% de estabilidade e funcionalidade** em ambientes reais (Windows 10/11 Home, Pro, Enterprise e Single Language - 64 bits).

---

## 🚀 Diferenciais de Engenharia e Arquitetura

Este script foi blindado contra falhas comuns de automação em PowerShell, apresentando soluções para os seguintes desafios técnicos:

* **Mapeamento Dinâmico de Ambiente (Agnóstico a OneDrive):** O script utiliza chamadas nativas à API COM do Windows (`Shell.Application`). Ele detecta automaticamente se a Área de Trabalho do usuário está local ou sincronizada na nuvem (`...\OneDrive\Desktop`), garantindo a gravação do relatório em qualquer máquina sem quebras de caminho.
* **Proteção Contra Tela Azul (Kernel Whitelist):** Durante a remediação de portas de rede, o script possui uma lista branca que impede a finalização acidental de processos vitais do Windows (como o `svchost.exe` na porta 135). Ações perigosas são abortadas com elegância, sugerindo o isolamento correto via Firewall.
* **Mitigação Inteligente Sem Duplicação:** O motor de Firewall interativo verifica a existência de regras anteriores antes de aplicar novas barreiras. Se o sistema já estiver blindado, ele avança silenciosamente, evitando o empilhamento de regras duplicadas no Windows.
* **Persistência Híbrida para Windows Home:** Versões Home do Windows possuem limitações nativas para aplicar diretivas locais via linha de comando (`net accounts`). O script resolve isso criando chaves de persistência física no Registro, tornando a auditoria universal.
* **Compatibilidade Multidioma:** Os scanners de soquetes e usuários foram projetados usando SIDs universais (como `-501` para Guest) e filtros híbridos (PT-BR/EN), eliminando falhas regionais do interpretador.

---

## 📊 Os 15 Blocos de Auditoria e Resposta a Incidentes

1. **Inventário do Sistema Operacional e Hardware:** Mapeamento de arquitetura, CPU, núcleos, memória RAM total e validação do status real de licenciamento/ativação do Windows.
2. **Identificação da Máquina (Hostname):** Rastreamento nominal do dispositivo e identificação de associação de rede (Grupo de Trabalho Local vs. Domínio Active Directory).
3. **Configuração e Conexão de Rede:** Diagnóstico de adaptadores físicos ativos, tipo de mídia (Wi-Fi ou Cabo Ethernet) e tipo de atribuição de IP (Estático ou DHCP).
4. **Compartilhamentos de Rede Ativos:** Varredura de pastas abertas expostas de forma customizada na rede local.
5. **Auditoria Avançada de Portas e Serviços Universais:** Scanner de soquetes ativos (estilo *netstat*) cruzando portas com PIDs e nomes de processos. Conta com dicionário de risco para mais de 25 portas de mercado (XAMPP Apache/MySQL, Ollama IA, bases SQL) e remediação tática por Firewall.
6. **Usuários com Privilégios Administrativos:** Varredura estruturada de contas locais que possuem controle elevado no sistema.
7. **Auditoria de Políticas de Contas e Usuário Convidado (Guest):** Localização universal e desativação da conta legada de Convidado (SID 501) e mapeamento de contas inativas/dormentes há mais de 90 dias.
8. **Análise de Unidades de Disco e Saúde do Hardware:** Cálculo preciso de capacidade (GB Total/Livre) e telemetria avançada de saúde física dos discos via SMART (capturando falhas imensas de HD/SSD).
9. **Análise de Permissões em Pastas Críticas:** Rastreamento de privilégios frágeis de escrita ou controle total dados a grupos genéricos (`Everyone` / `Todos`) em diretórios raiz do sistema.
10. **Estado das Defesas do Windows:** Verificação em tempo real do status de atividade do Windows Defender (Proteção em Tempo Real) e dos perfis ativos do Firewall do Windows.
11. **Protocolo de Rede Obsoleto (SMBv1):** Diagnóstico e desativação de protocolo legado altamente vulnerável a ataques de Ransomware (como o WannaCry).
12. **Política de Bloqueio Contra Força Bruta e Identidade:** Proteção preventiva contra tentativas infinitas de login e módulo interativo para aplicação de senha mascarada com provisionamento automático de *Autologon* seguro no registro.
13. **Programas Inicializados com o Sistema (Startup):** Inventário de softwares e caminhos configurados para iniciar em segundo plano com o Windows.
14. **Atualizações do Sistema (Windows Update):** Consulta direta à API da Microsoft rastreando atualizações críticas de software pendentes de instalação.
15. **Caça a Ameaças e Varredura Antimalware Interativa (Threat Hunting):** Varredura heurística focada em diretórios táticos de infecção (scripts `.bat`/`.vbs` ocultos, executáveis temporários e extensões de criptografia) integrada ao histórico de mitigação de incidentes do Windows Defender.

---

## 🛠️ Como Executar o Projeto

Como o script realiza alterações de endurecimento de sistema em chaves de nível de Kernel e regras de Firewall, ele exige privilégios elevados:

1. Abra o **PowerShell** como **Administrador**.
2. Caso as políticas de execução da sua máquina estejam restritas, libere a sessão atual com o comando:
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force
   ```
3. Navegue até a pasta do arquivo e execute o assistente interativo:
   ```powershell
   .\audit_system.ps1
   ```

*Nota: Ao final de cada execução, um relatório de texto puro detalhado e formatado contendo todas as decisões tomadas pelo operador (Ex: `[ FIX APLICADO ]` ou `[ ALERTA MANTIDO ]`) será salvo automaticamente na Área de Trabalho do usuário atual com a respectiva data e hora.*

---

## 📄 Licença

Este projeto está sob a licença **MIT**. Isso significa que você é livre para usar, estudar, modificar e distribuir este código, desde que inclua os créditos originais. Veja o arquivo `LICENSE` para mais detalhes.

---
**Desenvolvido e Validado por GTEC SEGURANÇA.** 🖥️🔒
