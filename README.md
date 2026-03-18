# 🚀 LuminaStack

> Ambiente de desenvolvimento PHP modular com roteamento dinâmico via Docker.

[![License](https://img.shields.io/badge/license-GPL--3.0-blue)](https://www.gnu.org/licenses/gpl-3.0)
[![Shell](https://img.shields.io/badge/shell-bash-green)](https://www.gnu.org/software/bash/)
[![Distros](https://img.shields.io/badge/distros-Ubuntu%20%7C%20Debian%20%7C%20Fedora%20%7C%20Arch-orange)](#️-compatibilidade)
[![GitHub](https://img.shields.io/badge/GitHub-kaduvelasco%2Flumina--stack-181717?logo=github)](https://github.com/kaduvelasco/lumina-stack)
[![CI](https://img.shields.io/github/actions/workflow/status/kaduvelasco/lumina-stack/lint.yml?label=lint%20%26%20smoke%20test)](https://github.com/kaduvelasco/lumina-stack/actions)

O **LuminaStack** automatiza a criação de um ecossistema completo para desenvolvimento PHP local. Através de scripts inteligentes, você configura **Nginx**, **múltiplas versões de PHP-FPM** e **MariaDB** em minutos, mantendo seu sistema operacional limpo e performático.

---

## ✨ Funcionalidades

| Recurso                    | Descrição                                                                          |
| -------------------------- | ---------------------------------------------------------------------------------- |
| **Setup Automático**       | Instalação de pré-requisitos e Docker com detecção automática de distro            |
| **Multi-versão PHP**       | Execute PHP 7.4 a 8.4 simultaneamente, cada um em seu próprio container            |
| **Roteamento Dinâmico**    | Acesse `http://phpXX.localhost` para alternar entre versões instantaneamente       |
| **Workspace Organizado**   | Estrutura de pastas padronizada e sincronizável via MegaSync                       |
| **Comandos Globais**       | Gerencie toda a stack com `lumina` e o banco de dados com `lumina-db`              |
| **Moodle Ready**           | Otimização de performance do MariaDB baseada na RAM disponível                     |
| **Backups Inteligentes**   | Dumps automáticos com timestamp, mantendo os 3 mais recentes localmente            |
| **Logs Segregados**        | Logs individuais por versão de PHP e por Nginx para debug facilitado               |
| **Permissões Automáticas** | Ajuste automático de permissões a cada inicialização, sem conflitos Host/Container |

---

## 📦 Tecnologias

- **Docker & Docker Compose**
- **Nginx** — Reverse proxy com roteamento dinâmico por subdomínio
- **PHP-FPM** — Versões 7.4, 8.0, 8.1, 8.2, 8.3 e 8.4
- **MariaDB 11**
- **Bash Scripting**

---

## 🖥️ Compatibilidade

| Distribuição                            | Suporte                         |
| --------------------------------------- | ------------------------------- |
| Ubuntu / Linux Mint / Pop!\_OS / Debian | ✅ Completo                     |
| Fedora                                  | ✅ Completo ⚠️ Ver nota SELinux |
| Arch Linux / Manjaro                    | ✅ Completo                     |

> **Fedora — SELinux:** Se os containers não conseguirem ler/escrever nos volumes, execute:
>
> ```bash
> sudo setsebool -P container_manage_cgroup on
> ```

---

## 📁 Estrutura do Projeto

```text
lumina-stack/
 ├── install.sh              # Ponto de entrada — instalador interativo
 ├── lib/
 │   ├── colors.sh           # Paleta de cores ANSI centralizada
 │   ├── menu.sh             # Menu do instalador
 │   ├── system.sh           # Detecção de distro, Docker e /etc/hosts
 │   ├── workspace.sh        # Criação da estrutura de pastas
 │   ├── docker.sh           # Geração da stack Docker
 │   └── scripts-installer.sh# Instalação dos comandos globais
 ├── scripts/
 │   ├── lumina.sh           # Comando global: gestão da stack
 │   └── lumina-db.sh        # Comando global: gestão do banco de dados
 └── templates/
     ├── docker-compose.tpl
     ├── nginx.conf.tpl
     ├── php.Dockerfile.tpl
     ├── php-base.Dockerfile.tpl
     ├── php.ini.tpl
     ├── index.php.tpl
     └── info.php.tpl
```

---

## 📂 Estrutura do Workspace

Após a instalação, o diretório `~/workspace` terá a seguinte estrutura:

```text
workspace/
 ├── www/
 │   ├── html/         # Seus projetos PHP            🔄 Sincronizado via MegaSync (opcional)
 │   └── data/         # Dados do Moodle (moodledata) 🔄 Sincronizado via MegaSync (opcional)
 ├── backups/          # Dumps SQL do lumina-db       🔄 Sincronizado via MegaSync (opcional)
 ├── logs/             # Logs por versão de PHP e Nginx
 ├── databases/        # Arquivos binários do MariaDB  🚫 Não sincronizado
 └── docker/
     ├── docker-compose.yml
     ├── .env          # Credenciais (chmod 600)
     ├── nginx/        # Configuração do proxy
     ├── php/          # Dockerfile por versão
     ├── php-config/   # php.ini customizado
     └── mariadb/      # Configurações e otimizações
```

---

## 🚀 Instalação

**1. Clone o repositório:**

```bash
git clone https://github.com/kaduvelasco/lumina-stack.git
cd lumina-stack
```

**2. Dê permissão de execução e inicie o instalador:**

```bash
chmod +x install.sh
./install.sh
```

**3. Siga a ordem numérica do menu para um setup completo:**

| Passo | Opção                    | Descrição                                                     |
| ----- | ------------------------ | ------------------------------------------------------------- |
| 1     | Instalar pré-requisitos  | Detecta sua distro e instala `curl`, `git`, `openssl`, `lsof` |
| 2     | Instalar Docker          | Configura o engine e as permissões de grupo                   |
| 3     | Criar workspace          | Gera a estrutura de pastas em `~/workspace`                   |
| 4     | Gerar stack Docker       | Define versões PHP, usuário e senha do banco                  |
| 5     | Instalar Gestão da Stack | Torna o comando `lumina` disponível globalmente               |
| 6     | Instalar DB Manager      | Torna o comando `lumina-db` disponível globalmente            |

> **Após a opção 2**, pode ser necessário reiniciar a sessão para aplicar as permissões do grupo `docker`.

---

## 🧰 Comandos Globais

### `lumina` — Gestão da Stack

```
====================================
      LUMINA STACK MANAGER
====================================
   1. Iniciar ambiente
   2. Visualizar logs
   3. Dados do banco (MariaDB)
   4. Finalizar ambiente
   5. Corrigir permissões
   0. Sair
====================================
```

| Opção                   | Função                                                           |
| ----------------------- | ---------------------------------------------------------------- |
| **Iniciar**             | Ajusta permissões automaticamente e sobe todos os containers     |
| **Logs**                | Monitoramento em tempo real por versão de PHP ou Nginx           |
| **Dados do banco**      | Exibe host, porta, usuário e senha do MariaDB                    |
| **Finalizar**           | Oferece backup via `lumina-db` antes de derrubar os containers   |
| **Corrigir permissões** | Realinha permissões entre host e containers (útil após MegaSync) |

---

### `lumina-db` — Gestão do Banco de Dados

```
====================================
    LUMINA-DB :: GESTÃO DE DADOS
====================================
   1. Backup (dump)
   2. Remover bancos
   3. Restaurar (restore)
   4. Verificar / Otimizar tabelas
   5. Otimizar MariaDB para Moodle
   0. Sair
====================================
```

| Opção                    | Função                                                                                          |
| ------------------------ | ----------------------------------------------------------------------------------------------- |
| **Backup**               | Gera dump completo em `~/workspace/backups` com timestamp. Mantém os 3 mais recentes localmente |
| **Remover bancos**       | Remoção seletiva e interativa de bancos de dados                                                |
| **Restore**              | Seleção numerada dos backups disponíveis para restauração                                       |
| **Verificar / Otimizar** | Executa `mariadb-check --optimize` em todos os bancos                                           |
| **Otimizar para Moodle** | Detecta a RAM disponível e configura `innodb_buffer_pool_size` automaticamente                  |

---

## 🌐 Roteamento Dinâmico

O Nginx roteia automaticamente cada subdomínio para o container PHP correspondente:

| URL                      | Container                                          |
| ------------------------ | -------------------------------------------------- |
| `http://localhost`       | Dashboard — PHP padrão (primeira versão instalada) |
| `http://php74.localhost` | Container PHP 7.4                                  |
| `http://php81.localhost` | Container PHP 8.1                                  |
| `http://php83.localhost` | Container PHP 8.3                                  |
| `http://php84.localhost` | Container PHP 8.4                                  |

> **Dica:** Digite sempre com `http://` explícito. Navegadores modernos podem tentar forçar HTTPS, resultando em erro de conexão.

---

## 📅 Fluxo de Trabalho Diário

```bash
# 1. Inicia o ambiente
lumina          # → opção 1

# 2. Desenvolva seus projetos em:
~/workspace/www/html/

# 3. Teste no navegador:
http://phpXX.localhost

# 4. Ao encerrar, faça backup e derrube o ambiente:
lumina          # → opção 4 (oferece backup automaticamente)
```

---

## 🧨 Reset Completo do Ambiente

Para reinstalar o LuminaStack do zero — mantendo seus projetos e backups intactos — utilize o script `clean-docker.sh`:

```bash
chmod +x clean-docker.sh
./clean-docker.sh
```

O script solicita confirmação antes de executar e informa claramente o que será e o que não será removido:

|                                                   | O que acontece                                 |
| ------------------------------------------------- | ---------------------------------------------- |
| 🗑️ Containers, imagens, volumes e networks Docker | **Removidos**                                  |
| 🗑️ `~/workspace/databases/`                       | **Removido** — MariaDB recria ao subir         |
| 🗑️ `~/workspace/docker/`                          | **Removido** — configs geradas pelo instalador |
| ✅ `~/workspace/www/html/`                        | **Preservado** — seus projetos PHP             |
| ✅ `~/workspace/www/data/`                        | **Preservado** — moodledata                    |
| ✅ `~/workspace/backups/`                         | **Preservado** — dumps SQL                     |

Após a limpeza, execute o instalador novamente a partir da **opção 3**:

```bash
./install.sh
# Opções: 3 → 4 → 5 → 6
```

> As opções 1 e 2 só precisam ser repetidas se você mudou de máquina ou reinstalou o sistema operacional.

---

## 🔧 Solução de Problemas

**Subdomínio não resolve (erro de conexão)**

Verifique se o `/etc/hosts` foi atualizado com as entradas `# lumina-stack`. Se usar Firefox ou Zen Browser, desative o **DNS sobre HTTPS (DoH)** nas configurações de rede do navegador.

**PHP não consegue gravar arquivos**

Execute `lumina` → opção **5 (Corrigir permissões)**. Isso é especialmente comum após sincronização via MegaSync, que não preserva permissões de arquivo.

**Porta 80 em uso**

Outro serviço (Apache ou Nginx local) está ocupando a porta. Desative-o antes de subir a stack:

```bash
sudo systemctl stop apache2
# ou
sudo systemctl stop nginx
```

**Containers sobem mas não leem os volumes (Fedora)**

O SELinux está bloqueando o acesso. Execute:

```bash
sudo setsebool -P container_manage_cgroup on
```

**Preciso reiniciar a sessão após instalar o Docker?**

Sim. A opção 2 adiciona seu usuário ao grupo `docker`, mas a mudança só é aplicada após fazer logout e login novamente.

---

## ⚠️ Requisitos

- Sistema operacional Linux (Ubuntu, Fedora ou Arch — ver tabela de compatibilidade)
- Porta **80** disponível no host
- Usuário com permissão de `sudo`
- Conexão com a internet durante a instalação

---

## 🤝 Contribuindo

Contribuições são bem-vindas! Para contribuir:

1. Faça um fork do repositório
2. Crie uma branch: `git checkout -b feature/minha-melhoria`
3. Siga o padrão dos scripts existentes (cabeçalho, `source lib/colors.sh`, idempotência)
4. Certifique-se de que o ShellCheck passa sem warnings: `shellcheck --severity=warning seu-script.sh`
5. Abra um Pull Request descrevendo o que foi alterado

---

## 📋 Changelog

### v2.0.0

**Segurança**

- Substituído `eval` por expansão segura de `~` em `lumina.sh`
- Credenciais MariaDB passadas via `MYSQL_PWD` (evita exposição no `ps aux`)
- `chmod 600` aplicado no `.env` gerado pelo instalador
- Senha root do banco gerada dinamicamente (não mais hardcoded)
- Validação de caracteres no nome de usuário do banco

**Novas funcionalidades**

- Adicionado `lib/colors.sh` com paleta ANSI centralizada
- Aviso de último backup exibido ao iniciar o ambiente (`lumina`)
- `fix_permissions` executado automaticamente a cada inicialização
- Limpeza automática de backups: mantém os 3 mais recentes localmente
- Restore do banco com seleção numerada (sem digitação manual do nome)
- Detecção automática de RAM em `otimizar_mariadb_moodle`
- Placeholder `{{DEFAULT_PHP}}` no `nginx.conf` elimina `php81` hardcoded
- `depends_on` com `condition: service_healthy` no `docker-compose`
- `update_hosts` cirúrgico com marcador `# lumina-stack`
- Feedback de conclusão com pausa após cada opção do instalador
- Script `clean-docker.sh` para reset completo do ambiente

**Correções**

- Corrigido `cut -d= -f2` → `f2-` para senhas com caracteres `=`
- Removido `-t` do `docker exec` em `verificar_tabelas`
- Fallbacks inseguros removidos do `docker-compose.yml`

**Padronização**

- Cabeçalho de documentação adicionado em todos os arquivos `.sh`
- Cores e mensagens padronizadas em todos os scripts
- Aviso de SELinux adicionado para usuários Fedora
- README reescrito com tabelas, estrutura do projeto e seção de reset

---

## 📜 Licença

Distribuído sob a licença **GPL-3.0**. Consulte o arquivo [LICENSE](LICENSE) para mais informações.

---

Feito com ❤️ e IA por **Kadu Velasco**
