FROM php:7.1-fpm-alpine3.8

RUN apk add --no-cache --virtual .persistent-deps git curl supervisor nginx icu-dev && \
  docker-php-ext-install intl && \
  docker-php-ext-install opcache && \
  docker-php-ext-install pdo_mysql

ARG PHP_INI="$PHP_INI_DIR/php.ini"
ARG TIMEZONE="Europe/Rome"
RUN \
  cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI" && \
  sed -i "s/^;date.timezone =$/date.timezone = \"$(echo $TIMEZONE | sed -e 's/\\/\\\\/g; s/\//\\\//g; s/&/\\\&/g')\"/" $PHP_INI

WORKDIR /var/www/html
#USER www-data

RUN \
  curl -s http://getcomposer.org/installer | php && \
  php -d memory_limit=-1 composer.phar create-project -s dev sshversioncontrol/git-web-client

WORKDIR /var/www/html/git-web-client
RUN php app/check.php


COPY supervisord.conf /etc/supervisord.conf
COPY nginx.conf /etc/nginx/conf.d/
COPY parameters.yml /var/www/html/git-web-client/app/config/parameters.yml
COPY init.sh /init.sh

RUN \
  adduser nginx www-data && \
  mkdir \
    /var/log/supervisor \
    /var/log/init \
    /run/nginx && \
  chown -R www-data:www-data \
    /var/log/supervisor \
    /var/log/init \
    /run/nginx \
    /var/www/html/git-web-client/app/cache \
    /var/www/html/git-web-client/app/logs \
    /var/www/html/git-web-client/app/config && \
  chmod -R g+w /var/www/html/git-web-client/app/cache /var/www/html/git-web-client/app/logs /var/www/html/git-web-client/app/config && \
  wget -q https://raw.githubusercontent.com/eficode/wait-for/master/wait-for -O /wait-for && \
  chmod a+x /wait-for

# Expose ports
EXPOSE 8080

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
