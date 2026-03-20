services:
  nginx:
    container_name: nginx
    image: nginx:latest
    restart: unless-stopped
    ports:
      - "${NGINX_PORT:-80}:80"
    volumes:
      - ${HOME}/workspace/www/html:/var/www/html
      - ${HOME}/workspace/www/data:/var/www/data
      - ../logs/nginx:/var/log/nginx
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      mariadb:
        condition: service_healthy
    networks:
      - docker-php-network

{{PHP_SERVICES}}

  mariadb:
    container_name: mariadb
    image: mariadb:11
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
      MYSQL_USER: ${DB_USER}
      MYSQL_PASSWORD: ${DB_PASS}
      MYSQL_DATABASE: dev_db
    ports:
      - "${MARIADB_PORT:-3306}:3306"
    volumes:
      - ../databases/mariadb:/var/lib/mysql
      - ./mariadb/conf.d:/etc/mysql/conf.d
      - ./mariadb/init:/docker-entrypoint-initdb.d
    networks:
      - docker-php-network
    healthcheck:
      test: ["CMD", "mariadb-admin", "ping", "-h", "localhost", "--silent"]
      start_period: 30s
      interval: 10s
      timeout: 5s
      retries: 5

networks:
  docker-php-network:
    name: docker-php-network
    driver: bridge
