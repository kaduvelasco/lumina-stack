x-logging: &default-logging
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"

services:
  nginx:
    container_name: nginx
    image: nginx:1.26-alpine
    restart: unless-stopped
    ports:
      - "127.0.0.1:${NGINX_PORT:-80}:80"
    volumes:
      - ${HOME}/workspace/www/html:/var/www/html
      - ${HOME}/workspace/www/data:/var/www/data
      - ../logs/nginx:/var/log/nginx
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      mariadb:
        condition: service_healthy
{{NGINX_DEPENDS_ON}}
    healthcheck:
      test: ["CMD-SHELL", "wget -q --spider http://127.0.0.1/ > /dev/null 2>&1"]
      start_period: 10s
      interval: 15s
      timeout: 5s
      retries: 3
    logging: *default-logging
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 256M
    networks:
      - docker-php-network

{{PHP_SERVICES}}

  mariadb:
    container_name: mariadb
    image: mariadb:11.4
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
      MYSQL_USER: ${DB_USER}
      MYSQL_PASSWORD: ${DB_PASS}
      MYSQL_DATABASE: dev_db
    ports:
      - "127.0.0.1:${MARIADB_PORT:-3306}:3306"
    volumes:
      - ../databases/mariadb:/var/lib/mysql
      - ./mariadb/conf.d:/etc/mysql/conf.d
      - ./mariadb/init:/docker-entrypoint-initdb.d
    healthcheck:
      test: ["CMD", "mariadb-admin", "ping", "-h", "localhost", "--silent"]
      start_period: 60s
      interval: 10s
      timeout: 10s
      retries: 10
    logging: *default-logging
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
    networks:
      - docker-php-network

networks:
  docker-php-network:
    name: docker-php-network
    driver: bridge
