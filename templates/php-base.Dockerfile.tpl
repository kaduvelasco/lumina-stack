FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
git \
unzip \
libzip-dev \
libpng-dev \
libicu-dev \
libxml2-dev \
libonig-dev \
libjpeg-dev \
libfreetype6-dev \
libpq-dev \
libcurl4-openssl-dev \
libxslt-dev \
pkg-config \
build-essential \
autoconf \
&& rm -rf /var/lib/apt/lists/*
