# 🚀 LuminaStack

Ambiente de desenvolvimento PHP modular com roteamento dinâmico via Docker.

O **LuminaStack** automatiza a criação de um ecossistema completo para desenvolvimento PHP local. Através de scripts inteligentes, você configura **Nginx**, **múltiplas versões de PHP** e **MariaDB** em minutos, mantendo seu sistema operacional hospedeiro limpo e performático.

---

## ✨ Funcionalidades

- [x] **Setup Automático:** Instalação de pré-requisitos (curl, git, openssl, lsof).
- [x] **Docker Nativo:** Instalação otimizada para Ubuntu, Linux Mint, Fedora e Arch Linux.
- [x] **Roteamento Dinâmico:** Use `phpXX.localhost` para alternar entre versões instantaneamente.
- [x] **Workspace Organizado:** Estrutura de pastas padronizada no seu `$HOME`.
- [x] **Comandos Globais:** Gerencie sua stack de qualquer lugar com o comando `lumina` e o Banco de Dados com `lumina-db`.
- [x] **Moodle Ready:** Função de otimização de performance específica para o ecossistema Moodle e bancos de dados robustos.
- [x] **Backups Inteligentes:** Sistema de dump automático com timestamp (ANOMESDIA-HORA).
- [x] **Logs Segregados:** Debug facilitado com logs individuais por versão de PHP.
- [x] **Permissões Automáticas:** Ajuste de permissões de escrita integrado para evitar conflitos entre Host e Container.

---

## 📦 Tecnologias

- **Docker & Docker Compose**
- **Nginx** (Reverse Proxy Dinâmico)
- **PHP-FPM** (Versões 7.4 a 8.4)
- **MariaDB 11**
- **Bash Scripting**

---

## 📁 Estrutura do Workspace

Ao finalizar a instalação, o diretório `~/workspace` terá a seguinte estrutura:

```text
workspace
 ├── www/
 │   ├── html/         # Seus projetos PHP (index.php, Moodle, etc)
 │   └── data/         # Arquivos de dados (ex: moodledata)
 ├── logs/             # Logs de Erro e Acesso (Nginx e PHP-FPM isolados)
 ├── backups/          # Onde o comando 'lumina-db' salva seus backups .sql
 ├── databases/        # Arquivos binários reais do banco (ignorado pelo Git)
 └── docker/           # Configurações da Stack
     ├── docker-compose.yml
     ├── .env          # Credenciais e Versões
     ├── nginx/        # Configuração do Proxy
     ├── php/          # Dockerfile base
     ├── php-config/   # php.ini customizado
     └── mariadb/      # Pasta conf.d para otimizações de performance
```

# 🚀 Instalação

Clone o projeto:

```Bash
git clone [https://github.com/kaduvelasco/lumina-stack.git](https://github.com/kaduvelasco/lumina-stack.git)
cd lumina-stack
```

Execute o instalador e siga o menu numárico:

```Bash
sudo chmod +x install.sh
./install.sh
```

# 🖥 Menu do Instalador

Basta seguir a ordem numérica para um setup completo:

1. **Instalar pré-requisitos:** Detecta sua distro e instala ferramentas base.

2. **Instalar Docker:** Configura o engine e permissões de grupo.

3. **Criar workspace:** Gera a estrutura de pastas.

4. **Gerar stack Docker:** Define versões, usuários e senhas.

5. **Instalar Gestão da Stack:** Torna o comando `lumina` global.

6. **Instalar DB Manager:** Torna o comando `lumina-db` global.

# 🧰 Comandos Globais

## 🐘 `lumina` (Gestão da Stack)

- **Iniciar/Parar:** Sobe ou desce todos os serviços.

- **Logs:** Monitoramento em tempo real do PHP e Nginx.

- **Dados do Banco:** Consulta rápida de host, usuário e senhas.

- **Fix Perms:** Ajusta automaticamente permissões de escrita nas pastas www e backups.

## 🗄️ `lumina-db` (Gestão do Banco de Dados)

- **Backup:** Gera dumps automáticos em ~/workspace/backups.

- **Restore:** Interface visual para selecionar e restaurar arquivos SQL.

- **Otimização Moodle:** Aplica innodb_buffer_pool e pacotes de rede ideais para o Moodle baseados na sua RAM atual.

- **Limpeza:** Remoção seletiva de bancos de dados.

# 🌐 Acesso Dinâmico às Versões

O grande diferencial deste ambiente é o mapeamento automático por subdomínios:

| URL                    | Destino Interno   |
| ---------------------- | ----------------- |
| http://php74.localhost | Container PHP 7.4 |
| http://php81.localhost | Container PHP 8.1 |
| http://php83.localhost | Container PHP 8.3 |

Dica: Se o navegador não abrir, certifique-se de digitar o **http://** explicitamente na primeira vez. Navegadores modernos podem tentar forçar o HTTPS (porta 443), o que resultará em erro de conexão.

# ⚠️ Requisitos e Avisos

- Porta 80: Certifique-se de que nenhum outro serviço (como Apache ou Nginx local) esteja usando a porta 80.

- Firewall: Em distribuições como Fedora, verifique se as regras do firewall permitem a comunicação da ponte do Docker (docker0).

- UID: O usuário www-data dentro do container é mapeado para o UID 1000 para evitar problemas de permissão de escrita no Linux.

# 📅 Fluxo de Trabalho Diário

1. Abra o terminal e digite `lumina`.

2. Selecione 1 para iniciar o ambiente.

3. Desenvolva em `~/workspace/www/html/`.

4. Teste em http://phpXX.localhost.

5. Antes de desligar, use 'lumina-db` para garantir seu backup.

# 🔧 Solução de Problemas (FAQ)

1. O subdomínio não resolve (Erro de Conexão)

Verifique se o script atualizou seu **/etc/hosts**. Caso use navegadores como Firefox ou Zen Browser, desative o **DNS sobre HTTPS (DoH)** nas configurações de rede do navegador. Verifique as permissões das pastas.

2. Permissões de Escrita:

Se o PHP não conseguir gravar arquivos, execute o comando `lumina` e escolha a Opção 5 (Fix Perms).

3. Porta 80 em uso

Se você já tem o Apache ou Nginx instalado diretamente no seu Linux, o Docker não conseguirá subir.

Solução: Desative o serviço local: sudo systemctl stop apache2 ou sudo systemctl stop nginx.

# 📜 Licença

Distribuído sob a licença GPL-3.0. Veja LICENSE para mais informações.

---

Feito com ❤️ e IA por Kadu Velasco
