# --- BLOCO 1: DASHBOARD ---
server {
    listen 80;
    server_name localhost 127.0.0.1; # Adicionado 127.0.0.1 para evitar captura indesejada
    root /var/www/html;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass php81:9000;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}

# --- BLOCO 2: DINÂMICO ---
server {
    listen 80;

    # ADICIONE OS NOMES EXPLÍCITOS ANTES DO REGEX
    server_name php74.localhost php81.localhost php82.localhost php83.localhost php84.localhost ~^php(?<p_ver>[0-9]+)\.localhost$;

    resolver 127.0.0.11 valid=30s;
    root /var/www/html;
    index index.php index.html;

    # O Restante do seu código de PHP (com PATH_INFO) continua igual...
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ [^/]\.php(/|$) {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        include fastcgi_params;
        if ($p_ver = "") { set $p_ver 81; } # Fallback de segurança
        set $php_upstream php$p_ver:9000;
        fastcgi_pass $php_upstream;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }
}
