#!/usr/bin/env bash
# Compile PHP 8.4.28 (php.net 2026-11-19 security release) inside the
# opensuse/leap:16.0 builder stage, feature-set mirroring the OpenSUSE php8
# rpm that gromox-core ships (see php -m of the base image), compiled to use
# the distro ini layout so the stock rpm php.ini/conf.d files keep working:
#   - php.ini            -> /etc/php8/fpm/php.ini   (config-file-path)
#   - additional inis    -> /etc/php8/conf.d        (scan dir; mapi.ini,
#                                                    redis.ini, pdo_*.ini...)
#   - extensions (.so)   -> /usr/lib64/php8/extensions  (set via extension_dir
#                                                    in the runtime stage)
# php-fpm's compiled default master config -> /etc/php8/fpm/php-fpm.conf
#   (via --sysconfdir, matches the supervisord `/usr/sbin/php-fpm -F` launch).
set -euo pipefail

./configure \
  --prefix=/usr/local/php-fixed \
  --sysconfdir=/etc/php8/fpm \
  --with-config-file-path=/etc/php8/fpm \
  --with-config-file-scan-dir=/etc/php8/conf.d \
  --enable-fpm \
  --with-fpm-user=groweb \
  --with-fpm-group=groweb \
  --disable-cgi \
  --with-pear=no \
  --enable-bcmath \
  --enable-pcntl \
  --enable-shmop \
  --enable-sysvshm \
  --enable-posix \
  --enable-mbstring \
  --enable-mbregex \
  --enable-intl \
  --with-gettext \
  --with-sodium \
  --with-zip \
  --with-zlib \
  --with-curl \
  --with-openssl \
  --with-mysqli=mysqlnd \
  --with-pdo-mysql=mysqlnd \
  --with-pdo-sqlite \
  --enable-gd \
  --with-jpeg \
  --with-freetype \
  --with-webp \
  --enable-soap \
  --enable-simplexml \
  --enable-dom \
  --enable-xml \
  --enable-xmlreader \
  --enable-xmlwriter \
  --enable-filter \
  --enable-session \
  --enable-fileinfo \
  --enable-tokenizer

make -j"$(nproc)"
make install
