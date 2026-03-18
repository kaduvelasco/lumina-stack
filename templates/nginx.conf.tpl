# ==============================================================================
# LuminaStack - Configuração Nginx
# ==============================================================================
# Gerado automaticamente pelo install.sh. Não edite manualmente.
# Para alterar o PHP padrão, execute novamente a opção 4 do instalador.
# ==============================================================================

# --- BLOCO 1: DASHBOARD (localhost) ---
# Serve o index.php com a versão PHP padrão definida na instalação.
server {
    listen 80;
    server_name localhost 127.0.0.1;
    root /var/www/html;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass {{DEFAULT_PHP}}:9000;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}

# --- BLOCO 2: ROTEAMENTO DINÂMICO (phpXX.localhost) ---
# Roteia para o container PHP correspondente à versão do subdomínio.
# Exemplo: php81.localhost → container php81:9000
server {
    listen 80;
    server_name ~^php(?<p_ver>[0-9]+)\.localhost$;

    resolver 127.0.0.11 valid=30s;
    root /var/www/html;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ [^/]\.php(/|$) {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        include fastcgi_params;
        if ($p_ver = "") { set $p_ver {{DEFAULT_PHP_VER}}; }
        set $php_upstream php$p_ver:9000;
        fastcgi_pass $php_upstream;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }
}
