#!/usr/bin/env bash
# Reproducible build of the php-fixed-images set (php.net 2026-11-19 security release).
# Usage:
#   bash build.sh [registry-prefix] [build|push]        # build all images
#   GITHUB_TOKEN=... bash build.sh <registry> push      # push all images (logs in to ghcr.io)
set -euo pipefail

REGISTRY="${1:-php-fixed}"
MODE="${2:-build}"

PHP_LIB_REF="3b25f4162a9bd144d3f447d03cb8fe16c0d2c9cc" # docker-library/php — first master carrying 8.5.13/8.2.36

imgs=(
  "php:8.5.13-fpm-alpine3.24|php-library/8.5/alpine3.24/fpm"
  "php:8.2.36-fpm-alpine3.24|php-library/8.2/alpine3.24/fpm"
  "php:8.5.13-apache-trixie|php-library/8.5/trixie/apache"
  "php:8.5.13-apache-bookworm|php-library/8.5/bookworm/apache"
  "nextcloud:35.0.3-apache-php8.5.13|nextcloud"
  "mailcow-phpfpm:8.2.36|mailcow"
  "invoiceninja:5-php8.5.13|invn"
  "gromox-core:8.4.28-20261120|gromox"
)

if [ "$MODE" = push ]; then
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    printf '%s' "$GITHUB_TOKEN" | docker login ghcr.io -u "${GITHUB_ACTOR:-tobias-weiss-ai-xr}" --password-stdin
  fi
  for e in "${imgs[@]}"; do docker push "$REGISTRY/${e%%|*}"; done
  exit 0
fi

# Pinned php-library checkout (cacheable between runs)
if [ ! -d php-library ] || [ "$(git -C php-library rev-parse HEAD 2>/dev/null)" != "$PHP_LIB_REF" ]; then
  rm -rf php-library
  git clone --quiet https://github.com/docker-library/php.git php-library
  git -C php-library checkout --quiet "$PHP_LIB_REF"
fi

for e in "${imgs[@]}"; do
  name="${e%%|*}"; ctx="${e#*|}"
  docker build -q -t "$REGISTRY/$name" "$ctx"
  case "$name" in
    php:*) docker tag "$REGISTRY/$name" "php-fixed:${name#php:}" ;; # app Dockerfiles reference the local name
  esac
done
echo "all images built; push with: GITHUB_TOKEN=... bash build.sh '$REGISTRY' push"
