# gromox-core with a PHP 8.4.28 engine — built ahead of the openSUSE Leap 16
# php8 rpm (still 8.4.27 as of 2026-11-20, CVE-2026-115560 RCE family).
#
# Strategy: keep the grommunio community gromox-core image completely intact
# and only replace the PHP *engine binaries* (/usr/bin/php, /usr/sbin/php-fpm)
# with a source-built PHP 8.4.28 compiled to consume the SAME ini layout:
#   php.ini /etc/php8/fpm/php.ini, scan dir /etc/php8/conf.d
#   (mapi.ini, redis.ini, pdo_*.ini, ... unchanged, extension_dir points at
#   the distro /usr/lib64/php8/extensions). 8.4.27 -> 8.4.28 is ABI-stable
#   (ZEND_MODULE_API_NO 20240924), so the rpm-built .so extensions (mapi,
#   redis, pdo_mysql, ...) load unchanged.
#
# Builder runs on opensuse/leap:16.0 (same distro/glibc as the runtime) so all
# linked libraries resolve against the versions present in gromox-core.
#
# Upstream tracking: revert to the stock grommunio image once the Leap php8
# rpm reaches 8.4.28 (then delete this context).

FROM container.grommunio.com/community/gromox-core:2026.11-202611200110@sha256:9de818a5aaab1dc0640b525ab293416659a479ba86f9e6640df493115a7f5b93 AS gromoxbase

FROM opensuse/leap:16.0 AS phpbuild
ARG PHP_VERSION=8.4.28
ARG PHP_SHA256=0c8ec360e5dd8154f270b2fd50cd44ecc824e6ee39c85f911312b80d4daecd72
RUN set -eux; \
    zypper --non-interactive refresh \
    && zypper --non-interactive install --no-recommends \
        gcc gcc-c++ make autoconf bison re2c pkg-config tar xz curl \
        libxml2-devel libcurl-devel openssl-devel sqlite3-devel zlib-devel \
        libpng-devel freetype2-devel libjpeg8-devel libwebp-devel \
        libsodium-devel libzip-devel libicu-devel gettext-devel pcre2-devel \
        oniguruma-devel \
    && zypper --non-interactive clean --all
WORKDIR /src
RUN set -eux; \
    curl -fsSL "https://www.php.net/distributions/php-${PHP_VERSION}.tar.xz" -o php.tar.xz \
    && echo "${PHP_SHA256}  php.tar.xz" | sha256sum -c - \
    && tar -xf php.tar.xz
COPY build-php.sh /src/build-php.sh
WORKDIR /src/php-${PHP_VERSION}
RUN sh /src/build-php.sh

FROM gromoxbase
ARG PHP_VERSION=8.4.28
# Replace the php engine binaries (rpm php8-cli-8.4.27) with the 8.4.28 build.
COPY --from=phpbuild /usr/local/php-fixed/bin/php /usr/bin/php
COPY --from=phpbuild /usr/local/php-fixed/sbin/php-fpm /usr/sbin/php-fpm
RUN set -eux; \
    [ -L /usr/bin/php8 ] || ln -s php /usr/bin/php8; \
    for ini in /etc/php8/fpm/php.ini /etc/php8/cli/php.ini; do \
        if [ -f "$ini" ] && ! grep -q '^extension_dir = .*extensions' "$ini"; then \
            printf '\n; set by php-fixed-images/gromox (source-built PHP %s)\nextension_dir = /usr/lib64/php8/extensions\n' "$PHP_VERSION" >> "$ini"; \
        fi; \
    done; \
    # The 8.4.28 build compiles every module in. The stock Leap php8 rpm ships \
    # every module as .so + a conf.d ini, so drop all those inis to avoid \
    # double-load "already loaded" warnings and to guarantee OUR fixed session \
    # engine (CVE-2026-115560) is the one that runs. mapi.so + redis.so are \
    # gromox/rpm-specific and stay .so-loaded. \
    for ini in /etc/php8/conf.d/*.ini; do \
        case "$(basename "$ini")" in \
            mapi.ini|redis.ini) ;; \
            *) rm -f "$ini" ;; \
        esac; \
    done; \
    # provide the compiled-default dirs (prefix var) that php-fpm expects: \
    # $prefix/var/log/php-fpm.log (global error_log) and run/ socket dirs \
    mkdir -p /usr/local/php-fixed/var/log /usr/local/php-fixed/var/run; \
    chmod 1777 /usr/local/php-fixed/var/log /usr/local/php-fixed/var/run; \
    mkdir -p /run/php-fpm \
    && chown groweb:groweb /run/php-fpm 2>/dev/null || chmod 1777 /run/php-fpm; \
    php -v | head -1; \
    echo -n 'modules: '; php -m 2>/dev/null | tr '\n' ' '; echo; \
    php-fpm -i 2>/dev/null | grep -E 'loaded Config|Scan this dir|^extension_dir|MAPI Support' | head -4
