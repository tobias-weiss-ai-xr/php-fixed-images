# php-fixed-images — PHP security-release images (2026-11-19)

Our own builds of the **php.net 2026-11-19 critical security release**
(8.5.13 / 8.4.28 / 8.3.37 / 8.2.36 — includes CVE-2026-115560 session-RCE),
built ahead of the upstream app images (mailcow phpfpm, nextcloud, invoiceninja)
while they lagged.

## Published images

| Image | Contents |
|---|---|
| `ghcr.io/tobias-weiss-ai-xr/php-fixed-images/php:8.5.13-fpm-alpine3.24` | php 8.5.13 fpm, Alpine 3.24 |
| `ghcr.io/tobias-weiss-ai-xr/php-fixed-images/php:8.2.36-fpm-alpine3.24` | php 8.2.36 fpm, Alpine 3.24 |
| `ghcr.io/tobias-weiss-ai-xr/php-fixed-images/php:8.5.13-apache-trixie` | php 8.5.13 apache, Debian trixie |
| `ghcr.io/tobias-weiss-ai-xr/php-fixed-images/php:8.5.13-apache-bookworm` | php 8.5.13 apache, Debian bookworm |
| `ghcr.io/tobias-weiss-ai-xr/php-fixed-images/nextcloud:35.0.3-apache-php8.5.13` | Nextcloud 35.0.3 on php 8.5.13 |
| `ghcr.io/tobias-weiss-ai-xr/php-fixed-images/mailcow-phpfpm:8.2.36` | mailcow php-fpm on php 8.2.36 (alpine 3.24; adds runtime `libwebp`) |
| `ghcr.io/tobias-weiss-ai-xr/php-fixed-images/invoiceninja:5-php8.5.13` | Invoice Ninja 5 on php 8.5.13 (alpine) |
| `ghcr.io/tobias-weiss-ai-xr/php-fixed-images/gromox-core:8.4.28-20261120` | **grommunio** gromox-core with a source-built PHP **8.4.28** engine (8.4.27 rpm lags; Leap 16.0 build, engine-binary swap, rpm extensions kept) |

Same images are mirrored to `registry.openedusuite.org/php-fixed/<name>:<tag>`
(anonymous pull).

## Provenance

- php sources: official php.net tarballs, sha256-verified in the docker-library
  Dockerfiles (GPG keys are the stock docker-library set).
- Bases: `docker-library/php` @ `3b25f41` (first release carrying 8.5.13/8.2.36),
  unmodified Dockerfiles.
- `nextcloud`: `nextcloud/docker` @ `18bc14c`, 35/apache template, FROM swapped to
  the fixed php base. NC version 35.0.3 unchanged.
- `mailcow-phpfpm`: mailcow `data/Dockerfiles/phpfpm` Dockerfile (from
  mailcow-dockerized), FROM swapped to fixed 8.2 base + explicit runtime `libwebp`
  (alpine 3.24's `apk del` purges the transitive dep that 3.21 kept).
- `invoiceninja`: `invoiceninja/dockerfiles` @ `e53f6fc`, alpine/5 Dockerfile,
  phpbuild FROM swapped to fixed 8.5 base.
- `gromox-core`: `grommunio` community gromox-core 2026.11-202611200110 as runtime
  base; PHP 8.4.28 compiled from php.net source in an opensuse/leap:16.0 builder
  (same distro/glibc as the runtime) with the stock ini wiring
  (`/etc/php8/fpm/php.ini` + shared scan dir `/etc/php8/conf.d`), then only the
  engine binaries are copied over. 8.4.27->8.4.28 is ABI-stable, so the rpm .so
  extensions (mapi, redis, ...) load unchanged. Revert once the Leap php8 rpm
  ships 8.4.28.

Rebuild locally: `bash build.sh` (needs docker; ~30 min cold).
